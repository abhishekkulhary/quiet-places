import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

/// The user's saved Quiet Places.
@DataClassName('QuietPlaceRow')
class QuietPlaces extends Table {
  /// Also used as the `native_geofence` region id.
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radiusMeters => real()();

  /// [QuietPlaceBehaviour] stored as its enum index.
  IntColumn get behaviour => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Entry/exit history for the "why didn't it fire?" screen.
@DataClassName('TripLogRow')
class TripLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get placeId => text()();
  TextColumn get placeName => text()();

  /// [BoundaryTransition] index.
  IntColumn get transition => integer()();

  /// [TripAction] index.
  IntColumn get action => integer()();

  /// The behaviour that was in force after this entry, as a
  /// [QuietPlaceBehaviour] index. Null for entries that applied nothing
  /// (skips, errors, dwell). Recorded structurally because [detail] is prose:
  /// a step-down reads "Do Not Disturb → Vibrate", and anything scanning it for
  /// a behaviour name finds the one being *left*, not the one now in force.
  IntColumn get behaviour => integer().nullable()();
  TextColumn get detail => text().nullable()();
  IntColumn get timestampMs => integer()();
}

/// Single-row user settings (id is always 0).
@DataClassName('SettingsRow')
class SettingsRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get globalPaused => boolean().withDefault(const Constant(false))();
  IntColumn get snoozeUntilMs => integer().nullable()();
  BoolColumn get onboardingComplete =>
      boolean().withDefault(const Constant(false))();

  /// Added in schema v2. Defaults true so existing installs get the warm-up
  /// behaviour without needing to visit settings.
  BoolColumn get gpsWarmupEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Added in schema v4. Defaults false: the map is opt-in, so an upgrading
  /// install keeps making no network requests until the user says otherwise.
  BoolColumn get mapsEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Added in schema v5. [UnitSystem] index; defaults to metric.
  IntColumn get units => integer().withDefault(const Constant(0))();

  /// Language override ("en", "de"); null follows the device.
  TextColumn get localeCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row engine engagement bookkeeping (id is always 0). Written from the
/// background isolate; see [Engagement].
@DataClassName('EngagementRow')
class EngagementRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  /// Comma-separated active place ids (ids never contain commas — they are uuids).
  TextColumn get activePlaceIds => text().withDefault(const Constant(''))();
  IntColumn get capturedRinger => integer()();
  BoolColumn get capturedDnd => boolean()();
  IntColumn get appliedBehaviour => integer()();
  IntColumn get appliedRinger => integer()();
  BoolColumn get appliedDnd => boolean()();
  BoolColumn get overridden => boolean().withDefault(const Constant(false))();

  /// Added in schema v6. Boot instant when this engagement was written; null
  /// for rows that predate it, which are treated as stale.
  IntColumn get bootTimeMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [QuietPlaces, TripLogs, SettingsRows, EngagementRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());

  /// Used by tests to inject an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        // Every schema bump adds a `from < N` branch here and a matching case in
        // test/data/migration_test.dart.
        onUpgrade: (m, from, to) async {
          // v2: opt-out switch for the foreground GPS warm-up listener.
          if (from < 2) {
            await m.addColumn(settingsRows, settingsRows.gpsWarmupEnabled);
          }
          // v3: "Zone" became "Quiet Place" throughout the product. The tables
          // and columns are renamed in place so existing installs keep their
          // data — a rename that dropped user data would not be a rename.
          if (from < 3) {
            await m.renameTable(quietPlaces, 'zones');
            await m.renameColumn(tripLogs, 'zone_id', tripLogs.placeId);
            await m.renameColumn(tripLogs, 'zone_name', tripLogs.placeName);
            await m.renameColumn(
                engagementRows, 'active_zone_ids', engagementRows.activePlaceIds);
          }
          // v4: opt-in map tiles. Defaults off so upgrading users are not
          // silently switched from "no network" to "network".
          if (from < 4) {
            await m.addColumn(settingsRows, settingsRows.mapsEnabled);
          }
          // v5: metric/imperial preference.
          if (from < 5) {
            await m.addColumn(settingsRows, settingsRows.units);
          }
          // v6: stamp engagements with the boot they belong to, so a reboot
          // is not mistaken for the user overriding the ringer.
          if (from < 6) {
            await m.addColumn(engagementRows, engagementRows.bootTimeMs);
          }
          // v7: record the applied behaviour on each log entry instead of
          // inferring it from the prose in `detail`. Existing rows stay null
          // and fall back to parsing, so old history still renders.
          if (from < 7) {
            await m.addColumn(tripLogs, tripLogs.behaviour);
          }
          // v8: in-app language choice. Null keeps existing installs on the
          // device language, which is what they had before the setting existed.
          if (from < 8) {
            await m.addColumn(settingsRows, settingsRows.localeCode);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
