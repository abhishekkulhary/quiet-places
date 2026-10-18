import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/data/db/app_database.dart';
import 'package:quiet_places/data/repositories/drift_settings_repository.dart';
import 'package:quiet_places/data/repositories/drift_quiet_place_repository.dart';
import 'package:quiet_places/domain/entities/engagement.dart';
import 'package:quiet_places/domain/entities/ringer_mode.dart';
import 'package:quiet_places/domain/entities/quiet_place.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('schema opens at the current version', () async {
    expect(db.schemaVersion, 8);
    // Force the connection open and ensure createAll ran.
    final places = await db.select(db.quietPlaces).get();
    expect(places, isEmpty);
  });

  test('place round-trips through the repository with enum fidelity', () async {
    final repo = DriftQuietPlaceRepository(db);
    final z = QuietPlace(
      id: 'z1',
      name: 'Office',
      latitude: 37.7749,
      longitude: -122.4194,
      radiusMeters: 150,
      behaviour: QuietPlaceBehaviour.dnd,
      enabled: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    await repo.upsert(z);

    final loaded = await repo.getById('z1');
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Office');
    expect(loaded.behaviour, QuietPlaceBehaviour.dnd);
    expect(loaded.latitude, closeTo(37.7749, 1e-9));

    await repo.setEnabled('z1', false);
    expect((await repo.getEnabled()), isEmpty);
    expect((await repo.getAll()).single.enabled, isFalse);

    await repo.delete('z1');
    expect(await repo.getById('z1'), isNull);
  });

  test('engagement (background bookkeeping) round-trips', () async {
    final repo = DriftEngagementRepository(db);
    expect(await repo.get(), isNull);

    const eng = Engagement(
      activePlaceIds: {'a', 'b'},
      capturedState:
          CapturedRingerState(ringerMode: RingerMode.vibrate, dndEnabled: true),
      appliedBehaviour: QuietPlaceBehaviour.silent,
      appliedState:
          CapturedRingerState(ringerMode: RingerMode.silent, dndEnabled: true),
      overridden: false,
    );
    await repo.save(eng);

    final loaded = await repo.get();
    expect(loaded!.activePlaceIds, {'a', 'b'});
    expect(loaded.capturedState.ringerMode, RingerMode.vibrate);
    expect(loaded.capturedState.dndEnabled, isTrue);
    expect(loaded.appliedBehaviour, QuietPlaceBehaviour.silent);

    await repo.clear();
    expect(await repo.get(), isNull);
  });
}
