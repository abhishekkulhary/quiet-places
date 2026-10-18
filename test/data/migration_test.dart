import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/data/db/app_database.dart';
import 'package:quiet_places/data/repositories/drift_quiet_place_repository.dart';
import 'package:quiet_places/data/repositories/drift_settings_repository.dart';
import 'package:quiet_places/domain/entities/app_settings.dart';
import 'package:quiet_places/domain/entities/ringer_mode.dart';

/// Verifies the whole v1 → v6 upgrade chain against a real on-disk database.
///
/// v3 renamed the product concept from "Zone" to "Quiet Place", which touched
/// table and column names. A rename that dropped user data would not be a
/// rename, so this seeds a genuine v1 database and asserts every row survives
/// with its values intact.
void main() {
  late Directory tmp;
  late File dbFile;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('phonesilent_migration');
    dbFile = File('${tmp.path}/app.sqlite');
  });

  tearDown(() async => tmp.delete(recursive: true));

  /// Builds the current schema, then reshapes it back into v1 and stamps the
  /// file as v1 so the real MigrationStrategy has genuine work to do.
  Future<void> seedV1Database() async {
    final seed = AppDatabase.forTesting(NativeDatabase(dbFile));

    // Undo the v3 renames.
    await seed.customStatement('ALTER TABLE quiet_places RENAME TO zones');
    await seed.customStatement(
        'ALTER TABLE trip_logs RENAME COLUMN place_id TO zone_id');
    await seed.customStatement(
        'ALTER TABLE trip_logs RENAME COLUMN place_name TO zone_name');
    await seed.customStatement('ALTER TABLE engagement_rows '
        'RENAME COLUMN active_place_ids TO active_zone_ids');
    // v6's column must not exist yet, or its migration re-adds a duplicate.
    await seed.customStatement(
        'ALTER TABLE engagement_rows DROP COLUMN boot_time_ms');
    // v7's column likewise must not exist yet.
    await seed.customStatement('ALTER TABLE trip_logs DROP COLUMN behaviour');
    // v8's column likewise must not exist yet.
    await seed.customStatement(
        'ALTER TABLE settings_rows DROP COLUMN locale_code');

    // Undo v2: drop back to the settings shape that shipped in v1.
    await seed.customStatement('DROP TABLE settings_rows');
    await seed.customStatement('''
      CREATE TABLE settings_rows (
        id INTEGER NOT NULL DEFAULT 0,
        global_paused INTEGER NOT NULL DEFAULT 0 CHECK (global_paused IN (0, 1)),
        snooze_until_ms INTEGER NULL,
        onboarding_complete INTEGER NOT NULL DEFAULT 0 CHECK (onboarding_complete IN (0, 1)),
        PRIMARY KEY (id)
      )
    ''');

    // Real user data, in v1 shape.
    await seed.customStatement(
      'INSERT INTO settings_rows (id, global_paused, snooze_until_ms, '
      'onboarding_complete) VALUES (0, 1, NULL, 1)',
    );
    await seed.customStatement(
      "INSERT INTO zones (id, name, latitude, longitude, radius_meters, "
      "behaviour, enabled, created_at_ms) "
      "VALUES ('z1', 'Cinema', 51.5, -0.12, 200.0, 2, 1, 1700000000000)",
    );
    await seed.customStatement(
      "INSERT INTO trip_logs (zone_id, zone_name, transition, action, detail, "
      "timestamp_ms) VALUES ('z1', 'Cinema', 0, 0, 'normal to Silent', 1700000001000)",
    );
    await seed.customStatement(
      "INSERT INTO engagement_rows (id, active_zone_ids, captured_ringer, "
      "captured_dnd, applied_behaviour, applied_ringer, applied_dnd, overridden) "
      "VALUES (0, 'z1', 2, 0, 1, 0, 0, 0)",
    );

    await seed.customStatement('PRAGMA user_version = 1');
    await seed.close();
  }

  test('v1 to v8 preserves places, history and engagement across the rename',
      () async {
    await seedV1Database();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final settingsRepo = DriftSettingsRepository(db);

    final places = await DriftQuietPlaceRepository(db).getAll();
    final settings = await settingsRepo.get();
    final engagement = await DriftEngagementRepository(db).get();
    final history = await db.select(db.tripLogs).get();

    // The renamed table kept its row and every value.
    expect(places, hasLength(1));
    expect(places.single.id, 'z1');
    expect(places.single.name, 'Cinema');
    expect(places.single.radiusMeters, 200.0);
    expect(places.single.latitude, closeTo(51.5, 1e-9));
    expect(places.single.enabled, isTrue);

    // Renamed columns kept their data.
    expect(history.single.placeId, 'z1');
    expect(history.single.placeName, 'Cinema');
    expect(history.single.detail, 'normal to Silent');

    expect(engagement, isNotNull);
    expect(engagement!.activePlaceIds, {'z1'});
    expect(engagement.capturedState.ringerMode, RingerMode.normal);

    // v2's column is present and defaulted for an install that predates it.
    expect(settings.globalPaused, isTrue);
    expect(settings.onboardingComplete, isTrue);
    expect(settings.gpsWarmupEnabled, isTrue);

    // v4 added the opt-in map. It must default OFF on upgrade: a user who
    // installed a network-free app is never silently switched to one that
    // makes requests.
    expect(settings.mapsEnabled, isFalse);

    // v5 added the unit preference, defaulting to metric.
    expect(settings.units, UnitSystem.metric);

    // v6: a pre-existing engagement has no boot stamp, so it is treated as
    // stale rather than trusted after an upgrade.
    expect(engagement.bootTime, isNull);
    expect(engagement.isStaleFor(DateTime(2026, 8, 24)), isTrue);

    // v7: pre-existing history has no recorded behaviour and must survive as
    // null rather than being invented -- the UI falls back to reading the
    // detail for these rows.
    expect(history.single.behaviour, isNull);

    // v8: an install that predates the language setting keeps following the
    // device, which is exactly what it did before the setting existed.
    expect(settings.localeCode, isNull);

    await db.close();
  });

  test('the upgraded database is writable through the new names', () async {
    await seedV1Database();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final repo = DriftQuietPlaceRepository(db);

    await repo.setEnabled('z1', false);
    expect((await repo.getAll()).single.enabled, isFalse);

    final settingsRepo = DriftSettingsRepository(db);
    final settings = await settingsRepo.get();
    await settingsRepo.save(settings.copyWith(gpsWarmupEnabled: false));
    expect((await settingsRepo.get()).gpsWarmupEnabled, isFalse);

    await db.close();
  });
}
