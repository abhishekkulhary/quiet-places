import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/data/ringer/platform_locale.dart';
import 'package:quiet_places/domain/entities/app_settings.dart';
import 'package:quiet_places/domain/entities/boundary_transition.dart';
import 'package:quiet_places/domain/entities/position_fix.dart';
import 'package:quiet_places/domain/entities/quiet_place.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/domain/entities/ringer_mode.dart';
import 'package:quiet_places/domain/services/position_source.dart';
import 'package:quiet_places/domain/services/quiet_place_monitor.dart';
import 'package:quiet_places/presentation/coordinator.dart';

import '../domain/fakes.dart';

class FakeMonitor implements QuietPlaceMonitor {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> syncPlaces(List<QuietPlace> places) async {}
  @override
  Future<void> register(QuietPlace place) async {}
  @override
  Future<void> unregister(String placeId) async {}
  @override
  Future<void> unregisterAll() async {}
  @override
  Future<List<String>> registeredPlaceIds() async => const [];
}

/// Reports a position, or refuses to produce one at all.
class FakePositionSource implements PositionSource {
  PositionFix? fix;
  bool throwOnPrecise;
  int preciseCalls = 0;

  FakePositionSource({this.fix, this.throwOnPrecise = false});

  PositionFix _at(double lat, double lon) => PositionFix(
        latitude: lat,
        longitude: lon,
        accuracyMeters: 8,
        stage: FixStage.precise,
        timestamp: DateTime(2026, 8, 24),
      );

  @override
  Future<PositionFix?> lastKnown() async => fix;

  @override
  Future<PositionFix> coarse({required Duration timeout}) async => fix!;

  @override
  Future<PositionFix> precise({required Duration timeout}) async {
    preciseCalls++;
    if (throwOnPrecise) throw StateError('no fix');
    return fix!;
  }

  @override
  Stream<PositionFix> warmUp() => const Stream.empty();

  @override
  Stream<PositionFix> watch({
    required Duration interval,
    required bool highAccuracy,
  }) =>
      const Stream.empty();

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<PositionFailure?> ensurePermission() async => null;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}

  void moveTo(double lat, double lon) => fix = _at(lat, lon);
}

QuietPlace placeAt(
  String id, {
  required double lat,
  double lon = -0.12,
  double radius = 200,
  QuietPlaceBehaviour behaviour = QuietPlaceBehaviour.dnd,
  bool enabled = true,
}) =>
    QuietPlace(
      id: id,
      name: id,
      latitude: lat,
      longitude: lon,
      radiusMeters: radius,
      behaviour: behaviour,
      enabled: enabled,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  const lat = 51.5;
  const lon = -0.12;

  late FakeRinger ringer;
  late FakeQuietPlaceRepository places;
  late FakeEngagementRepository engagements;
  late FakeSettingsRepository settings;
  late FakeTripLogRepository tripLog;
  late FakePositionSource position;

  QuietPlaceCoordinator build() => QuietPlaceCoordinator(
        places: places,
        engagements: engagements,
        settings: settings,
        tripLog: tripLog,
        ringer: ringer,
        engine: FakeMonitor(),
        positionSource: position,
      );

  setUp(() {
    ringer = FakeRinger();
    places = FakeQuietPlaceRepository([placeAt('office', lat: lat)]);
    engagements = FakeEngagementRepository();
    settings = FakeSettingsRepository();
    tripLog = FakeTripLogRepository();
    position = FakePositionSource()..moveTo(lat, lon);
  });

  test('un-pausing while inside a place re-applies its behaviour', () async {
    final c = build();

    // Walk in: DND applied over a normal ringer.
    await c.debugInject('office', BoundaryTransition.enter);
    expect(ringer.state.dndEnabled, isTrue);

    // Pause: the device is handed back to the user.
    await c.setGlobalPause(true);
    expect(ringer.state.dndEnabled, isFalse);
    expect(ringer.state.ringerMode, RingerMode.normal);
    expect(await engagements.get(), isNull);

    // Un-pause without moving an inch. This is the reported bug: nothing
    // happened, because no boundary is ever crossed while standing still.
    await c.setGlobalPause(false);
    expect(ringer.state.dndEnabled, isTrue,
        reason: 'un-pausing inside a place must re-silence the device');
    expect((await engagements.get())!.activePlaceIds, {'office'});
  });

  test('the state captured for later restore is the un-paused one', () async {
    // Start on vibrate so a wrongly-captured state is visible.
    ringer.state = const CapturedRingerState(
        ringerMode: RingerMode.vibrate, dndEnabled: false);
    final c = build();

    await c.setGlobalPause(true);
    await c.setGlobalPause(false);

    final e = await engagements.get();
    expect(e!.capturedState.ringerMode, RingerMode.vibrate);
    expect(e.capturedState.dndEnabled, isFalse);

    // And leaving really does put it back.
    await c.debugInject('office', BoundaryTransition.exit);
    expect(ringer.state.ringerMode, RingerMode.vibrate);
    expect(ringer.state.dndEnabled, isFalse);
  });

  test('un-pausing outside every place changes nothing', () async {
    position.moveTo(51.6, lon); // ~11 km away
    final c = build();

    await c.setGlobalPause(true);
    await c.setGlobalPause(false);

    expect(ringer.state.dndEnabled, isFalse);
    expect(await engagements.get(), isNull);
  });

  test('overlapping places resolve to the most restrictive on un-pause',
      () async {
    places = FakeQuietPlaceRepository([
      placeAt('vibrate-zone',
          lat: lat, radius: 900, behaviour: QuietPlaceBehaviour.vibrate),
      placeAt('dnd-zone',
          lat: lat, radius: 200, behaviour: QuietPlaceBehaviour.dnd),
    ]);
    final c = build();

    await c.setGlobalPause(false);

    expect(ringer.state.dndEnabled, isTrue);
    final e = await engagements.get();
    expect(e!.activePlaceIds, {'vibrate-zone', 'dnd-zone'});
    expect(e.appliedBehaviour, QuietPlaceBehaviour.dnd);
  });

  test('clearing a snooze re-applies just like un-pausing', () async {
    settings = FakeSettingsRepository(AppSettings.defaults
        .copyWith(snoozeUntil: () => DateTime.now().add(const Duration(hours: 1))));
    final c = build();

    await c.clearSnooze();
    expect(ringer.state.dndEnabled, isTrue);
  });

  test('enabling a place you are standing in applies it immediately', () async {
    places = FakeQuietPlaceRepository([placeAt('office', lat: lat, enabled: false)]);
    final c = build();

    await c.setEnabled('office', true);
    expect(ringer.state.dndEnabled, isTrue);
  });

  test('disabling never triggers a reconcile', () async {
    final c = build();
    await c.setEnabled('office', false);
    expect(position.preciseCalls, 0);
    expect(ringer.state.dndEnabled, isFalse);
  });

  group('app language', () {
    test('defaults to following the device', () async {
      expect((await settings.get()).localeCode, isNull);
    });

    test('a choice is persisted and mirrored to the out-of-tree cache',
        () async {
      final c = build();
      await c.setLocale('de');

      expect((await settings.get()).localeCode, 'de');
      // The notification path reads this, not the widget tree.
      expect(platformL().behaviourDnd, 'Bitte nicht stören');
    });

    test('choosing System clears it again', () async {
      final c = build();
      await c.setLocale('de');
      await c.setLocale(null);

      expect((await settings.get()).localeCode, isNull);
      setPreferredLanguage(null);
    });

    test('language does not disturb anything else', () async {
      final c = build();
      await c.debugInject('office', BoundaryTransition.enter);
      await c.setLocale('de');

      expect(ringer.state.dndEnabled, isTrue);
      expect((await engagements.get())!.activePlaceIds, {'office'});
      await c.setLocale(null);
    });
  });

  test('history records the applied behaviour, not just prose', () async {
    places = FakeQuietPlaceRepository([
      placeAt('vibrate-zone',
          lat: lat, radius: 900, behaviour: QuietPlaceBehaviour.vibrate),
      placeAt('dnd-zone',
          lat: lat, radius: 200, behaviour: QuietPlaceBehaviour.dnd),
    ]);
    final c = build();

    await c.reconcileNow();
    // Step down by switching the strict place off.
    await c.setEnabled('dnd-zone', false);

    final stepDown = tripLog.entries.last;
    expect(stepDown.detail, contains('Vibrate'));
    // The prose names Do Not Disturb first; the recorded value must be the
    // behaviour now in force.
    expect(stepDown.detail, startsWith('Do Not Disturb'));
    expect(stepDown.behaviour, QuietPlaceBehaviour.vibrate);
  });

  group('individual place toggle', () {
    test('switching off the place you are in restores the ringer', () async {
      ringer.state = const CapturedRingerState(
          ringerMode: RingerMode.normal, dndEnabled: false);
      final c = build();

      await c.debugInject('office', BoundaryTransition.enter);
      expect(ringer.state.dndEnabled, isTrue);

      await c.setEnabled('office', false);

      expect(ringer.state.dndEnabled, isFalse,
          reason: 'switching a place off must release the device');
      expect(ringer.state.ringerMode, RingerMode.normal);
      expect(await engagements.get(), isNull);
    });

    test('switching one of two off steps down to the other', () async {
      places = FakeQuietPlaceRepository([
        placeAt('vibrate-zone',
            lat: lat, radius: 900, behaviour: QuietPlaceBehaviour.vibrate),
        placeAt('dnd-zone',
            lat: lat, radius: 200, behaviour: QuietPlaceBehaviour.dnd),
      ]);
      final c = build();

      await c.reconcileNow();
      expect(ringer.state.dndEnabled, isTrue);

      // Switch off the strict one: the laxer place still covers us.
      await c.setEnabled('dnd-zone', false);

      expect(ringer.state.dndEnabled, isFalse);
      expect(ringer.state.ringerMode, RingerMode.vibrate);
      final e = await engagements.get();
      expect(e!.activePlaceIds, {'vibrate-zone'});
      expect(e.appliedBehaviour, QuietPlaceBehaviour.vibrate);
    });

    test('switching it back on re-applies it', () async {
      final c = build();
      await c.debugInject('office', BoundaryTransition.enter);
      await c.setEnabled('office', false);
      expect(ringer.state.dndEnabled, isFalse);

      await c.setEnabled('office', true);
      expect(ringer.state.dndEnabled, isTrue);
    });

    test('switching off a place you are not in leaves the engagement alone',
        () async {
      places = FakeQuietPlaceRepository([
        placeAt('office', lat: lat),
        placeAt('elsewhere', lat: 51.6),
      ]);
      final c = build();
      await c.debugInject('office', BoundaryTransition.enter);

      await c.setEnabled('elsewhere', false);

      expect(ringer.state.dndEnabled, isTrue);
      expect((await engagements.get())!.activePlaceIds, {'office'});
      // No spurious history entry for a place that was never engaged.
      expect(tripLog.entries.where((e) => e.placeId == 'elsewhere'), isEmpty);
    });

    test('a genuine override is still respected when switching off', () async {
      final c = build();
      await c.debugInject('office', BoundaryTransition.enter);

      // User turns DND off by hand.
      ringer.state = const CapturedRingerState(
          ringerMode: RingerMode.normal, dndEnabled: false);

      await c.setEnabled('office', false);

      // Nothing re-applied, nothing forced back.
      expect(ringer.state.dndEnabled, isFalse);
      expect(ringer.state.ringerMode, RingerMode.normal);
      expect(await engagements.get(), isNull);
    });

    test('deleting the place you are in restores rather than stranding it',
        () async {
      final c = build();
      await c.debugInject('office', BoundaryTransition.enter);
      expect(ringer.state.dndEnabled, isTrue);

      await c.deletePlace('office');

      expect(ringer.state.dndEnabled, isFalse,
          reason: 'a deleted place can never fire an exit of its own');
      expect(await engagements.get(), isNull);
      // Logged under its real name, not "(deleted)".
      expect(tripLog.last.placeName, 'office');
    });

    test('deleting one of two steps down instead of restoring', () async {
      places = FakeQuietPlaceRepository([
        placeAt('vibrate-zone',
            lat: lat, radius: 900, behaviour: QuietPlaceBehaviour.vibrate),
        placeAt('dnd-zone',
            lat: lat, radius: 200, behaviour: QuietPlaceBehaviour.dnd),
      ]);
      final c = build();
      await c.reconcileNow();

      await c.deletePlace('dnd-zone');

      expect(ringer.state.dndEnabled, isFalse);
      expect(ringer.state.ringerMode, RingerMode.vibrate);
      expect((await engagements.get())!.activePlaceIds, {'vibrate-zone'});
    });
  });

  test('an existing engagement is not re-captured', () async {
    final c = build();
    await c.debugInject('office', BoundaryTransition.enter);
    final before = await engagements.get();

    await c.reconcileNow();

    // Same captured state: reconciling must not overwrite "normal" with the
    // silenced state it just observed.
    expect((await engagements.get())!.capturedState.signature,
        before!.capturedState.signature);
  });

  test('a refused fix leaves the pause toggle working', () async {
    position.throwOnPrecise = true;
    position.fix = null;
    final c = build();

    await c.setGlobalPause(false);
    expect((await settings.get()).globalPaused, isFalse);
    expect(ringer.state.dndEnabled, isFalse);
  });

  test('still paused means reconcile does nothing', () async {
    settings = FakeSettingsRepository(
        AppSettings.defaults.copyWith(globalPaused: true));
    final c = build();

    await c.reconcileNow();
    expect(position.preciseCalls, 0);
    expect(ringer.state.dndEnabled, isFalse);
  });
}
