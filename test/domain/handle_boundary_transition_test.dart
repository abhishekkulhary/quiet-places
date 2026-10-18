import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/app_settings.dart';
import 'package:quiet_places/domain/entities/boundary_transition.dart';
import 'package:quiet_places/domain/entities/ringer_mode.dart';
import 'package:quiet_places/domain/entities/trip_log_entry.dart';
import 'package:quiet_places/domain/entities/engagement.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/domain/usecases/handle_boundary_transition.dart';

import 'fakes.dart';

void main() {
  late FakeRinger ringer;
  late FakeQuietPlaceRepository places;
  late FakeEngagementRepository engagements;
  late FakeSettingsRepository settings;
  late FakeTripLogRepository log;
  late HandleBoundaryTransition handle;
  late FakeDeviceClock deviceClock;

  final now = DateTime(2026, 8, 23, 12, 0, 0);

  void build({AppSettings? appSettings}) {
    places = FakeQuietPlaceRepository([
      place('office', behaviour: QuietPlaceBehaviour.silent),
      place('library', behaviour: QuietPlaceBehaviour.dnd),
      place('gym', behaviour: QuietPlaceBehaviour.vibrate),
    ]);
    engagements = FakeEngagementRepository();
    settings = FakeSettingsRepository(appSettings);
    log = FakeTripLogRepository();
    deviceClock = FakeDeviceClock(DateTime(2026, 8, 24, 9));
    handle = HandleBoundaryTransition(
      places: places,
      engagements: engagements,
      settings: settings,
      tripLog: log,
      ringer: ringer,
      deviceClock: deviceClock,
      settleDelay: Duration.zero,
      clock: () => now,
    );
  }

  QuietPlaceTransitionEvent enter(String id) => QuietPlaceTransitionEvent(
      placeId: id, transition: BoundaryTransition.enter, occurredAt: now);
  QuietPlaceTransitionEvent exit(String id) => QuietPlaceTransitionEvent(
      placeId: id, transition: BoundaryTransition.exit, occurredAt: now);

  setUp(() {
    ringer = FakeRinger(); // starts at normal, no DND
  });

  test('enter captures prior state and applies the place behaviour', () async {
    build();
    await handle(enter('office'));

    expect(ringer.state.ringerMode, RingerMode.silent);
    final eng = await engagements.get();
    expect(eng, isNotNull);
    expect(eng!.activePlaceIds, {'office'});
    expect(eng.capturedState.ringerMode, RingerMode.normal);
    expect(eng.appliedBehaviour, QuietPlaceBehaviour.silent);
    expect(log.last.action, TripAction.applied);
  });

  test('exit restores the captured state, not a blind normal', () async {
    // Device starts on VIBRATE — restoring must return to vibrate, not normal.
    ringer = FakeRinger(
      state: const CapturedRingerState(
          ringerMode: RingerMode.vibrate, dndEnabled: false),
    );
    build();

    await handle(enter('office')); // → silent
    expect(ringer.state.ringerMode, RingerMode.silent);

    await handle(exit('office')); // → back to vibrate
    expect(ringer.state.ringerMode, RingerMode.vibrate);
    expect(await engagements.get(), isNull);
    expect(log.last.action, TripAction.restored);
  });

  test('overlapping places resolve most-restrictive, then step back down',
      () async {
    build();
    await handle(enter('office')); // silent
    expect(ringer.state.ringerMode, RingerMode.silent);

    await handle(enter('library')); // dnd wins
    expect(ringer.state.dndEnabled, isTrue);
    expect((await engagements.get())!.appliedBehaviour, QuietPlaceBehaviour.dnd);
    expect(log.last.action, TripAction.reResolved);

    await handle(exit('library')); // back to silent, NOT restore
    final eng = await engagements.get();
    expect(eng, isNotNull);
    expect(eng!.appliedBehaviour, QuietPlaceBehaviour.silent);
    expect(eng.activePlaceIds, {'office'});

    await handle(exit('office')); // now restore to normal
    expect(await engagements.get(), isNull);
    expect(ringer.state.ringerMode, RingerMode.normal);
    expect(log.last.action, TripAction.restored);
  });

  test('DND side-effect on the ringer read is not a false override', () async {
    // Regression: on Android, enabling DND makes getRingerMode() report
    // silent. Storing the *predicted* state made the next transition look like
    // the user had changed the ringer, so DND places never restored.
    ringer = FakeRinger()..dndForcesSilentRead = true;
    build();

    await handle(enter('library')); // DND place
    expect(log.last.action, TripAction.applied);

    final eng = await engagements.get();
    // We recorded what the device really looks like, side-effect included.
    expect(eng!.appliedState.ringerMode, RingerMode.silent);
    expect(eng.appliedState.dndEnabled, isTrue);
    expect(eng.overridden, isFalse);

    // The exit must restore, not skip as an override.
    await handle(exit('library'));
    expect(log.last.action, TripAction.restored);
    expect(ringer.state.ringerMode, RingerMode.normal);
    expect(ringer.state.dndEnabled, isFalse);
    expect(await engagements.get(), isNull);
  });

  test('a genuine override is still detected with the DND side-effect present',
      () async {
    ringer = FakeRinger()..dndForcesSilentRead = true;
    build();

    await handle(enter('library'));
    // User really does change things afterwards.
    ringer.state = const CapturedRingerState(
        ringerMode: RingerMode.normal, dndEnabled: false);

    await handle(exit('library'));
    expect(log.last.action, TripAction.skippedOverride);
    expect(ringer.state.ringerMode, RingerMode.normal);
  });

  test('manual override while inside: do not restore on exit', () async {
    build();
    await handle(enter('office')); // silent applied
    expect(ringer.state.ringerMode, RingerMode.silent);

    // User manually turns the ringer back to normal.
    ringer.state = const CapturedRingerState(
        ringerMode: RingerMode.normal, dndEnabled: false);

    await handle(exit('office'));
    // We must NOT fight the user: leave it at normal (their choice) and clear.
    expect(ringer.state.ringerMode, RingerMode.normal);
    expect(await engagements.get(), isNull);
    expect(log.last.action, TripAction.skippedOverride);
  });

  test('manual override is sticky across a later entry', () async {
    build();
    await handle(enter('office')); // silent
    ringer.state = const CapturedRingerState(
        ringerMode: RingerMode.normal, dndEnabled: false); // user overrides

    await handle(enter('gym')); // should detect override, not re-apply
    final eng = await engagements.get();
    expect(eng!.overridden, isTrue);
    expect(ringer.state.ringerMode, RingerMode.normal);
    expect(log.last.action, TripAction.skippedOverride);
  });

  test('global pause makes entry inert (no capture, no engagement)', () async {
    build(appSettings: AppSettings.defaults.copyWith(globalPaused: true));
    await handle(enter('office'));
    expect(ringer.state.ringerMode, RingerMode.normal);
    expect(await engagements.get(), isNull);
    expect(log.last.action, TripAction.skippedPaused);
  });

  test('active snooze makes entry inert', () async {
    build(
      appSettings: AppSettings.defaults
          .copyWith(snoozeUntil: () => now.add(const Duration(hours: 1))),
    );
    await handle(enter('office'));
    expect(await engagements.get(), isNull);
    expect(log.last.action, TripAction.skippedPaused);
  });

  test('disabled place entry is skipped', () async {
    build();
    await places.setEnabled('office', false);
    await handle(enter('office'));
    expect(await engagements.get(), isNull);
    expect(log.last.action, TripAction.skippedDisabled);
  });

  test('iOS (unsupported + notifies) logs notified and never engages',
      () async {
    ringer = FakeRinger(isSupported: false, postsNotificationOnApply: true);
    build();
    await handle(enter('office'));
    expect(await engagements.get(), isNull);
    expect(ringer.calls, contains('notify:office')); // posted notification
    expect(log.last.action, TripAction.notified);
  });

  test('desktop (unsupported, no notify) logs skippedUnsupported', () async {
    ringer = FakeRinger(isSupported: false, postsNotificationOnApply: false);
    build();
    await handle(enter('office'));
    expect(await engagements.get(), isNull);
    expect(log.last.action, TripAction.skippedUnsupported);
  });

  test('exiting a place we never engaged is a benign no-op', () async {
    build();
    await handle(exit('office'));
    expect(await engagements.get(), isNull);
    expect(log.last.action, TripAction.observed);
  });

  group('surviving a reboot', () {
    test('an engagement from a previous boot is discarded, not read as an '
        'override', () async {
      // Observed on a real device: after a reboot the ringer is reset by the
      // OS, the stored appliedState no longer matches, and the next transition
      // was misread as the user overriding us — which disabled the app until
      // they left every Quiet Place.
      ringer = FakeRinger();
      build();

      await handle(enter('library')); // DND applied, engagement stamped
      expect(log.last.action, TripAction.applied);

      // The device reboots: ringer reset, and the boot instant moves.
      ringer.state = const CapturedRingerState(
          ringerMode: RingerMode.normal, dndEnabled: false);
      deviceClock.boot = DateTime(2026, 8, 24, 11);

      await handle(enter('library'));

      // Re-applied from scratch rather than skipped.
      expect(log.last.action, TripAction.applied);
      expect(ringer.state.dndEnabled, isTrue);
      final eng = await engagements.get();
      expect(eng!.overridden, isFalse);
      expect(eng.bootTime, DateTime(2026, 8, 24, 11));
    });

    test('within the same boot, a genuine override is still detected',
        () async {
      ringer = FakeRinger();
      build();

      await handle(enter('office'));
      // Same boot; the user really did change it.
      ringer.state = const CapturedRingerState(
          ringerMode: RingerMode.normal, dndEnabled: false);

      await handle(exit('office'));
      expect(log.last.action, TripAction.skippedOverride);
    });

    test('an engagement with no boot stamp is treated as stale', () async {
      ringer = FakeRinger();
      build();
      await engagements.save(const Engagement(
        activePlaceIds: {'office'},
        capturedState:
            CapturedRingerState(ringerMode: RingerMode.normal, dndEnabled: false),
        appliedBehaviour: QuietPlaceBehaviour.silent,
        appliedState:
            CapturedRingerState(ringerMode: RingerMode.silent, dndEnabled: false),
        overridden: true,
      ));

      await handle(enter('office'));
      expect(log.last.action, TripAction.applied);
    });

    test('with no clock available the engagement is trusted', () async {
      ringer = FakeRinger();
      build();
      deviceClock.boot = null;

      await handle(enter('office'));
      ringer.state = const CapturedRingerState(
          ringerMode: RingerMode.normal, dndEnabled: false);
      await handle(exit('office'));
      expect(log.last.action, TripAction.skippedOverride);
    });
  });

  group('moving between overlapping places (reported from real use)', () {
    // Stand where a DND place and a Silent place overlap: DND wins. Walk out of
    // the DND place while staying inside the Silent one. DND must come off and
    // Silent must go on.
    test('leaving the stricter place steps down to the laxer one', () async {
      ringer = FakeRinger()..dndForcesSilentRead = true;
      build();

      await handle(enter('library')); // DND
      await handle(enter('office')); // Silent; DND still wins
      expect(ringer.state.dndEnabled, isTrue);

      await handle(exit('library')); // now only inside the Silent place

      expect(ringer.state.dndEnabled, isFalse,
          reason: 'DND must be lifted when the DND place is left');
      expect(ringer.state.ringerMode, RingerMode.silent,
          reason: 'the remaining place still wants silent');
      expect(log.last.action, TripAction.reResolved);
      final eng = await engagements.get();
      expect(eng!.appliedBehaviour, QuietPlaceBehaviour.silent);
      expect(eng.activePlaceIds, {'office'});
    });

    test('the same step-down survives the ringer reading drifting', () async {
      // The real failure: any drift between what we recorded and what the OS
      // reports later (volume keys, OEM quirks, DND reporting) was read as
      // "the user took over", which stuck the engine permanently because the
      // override flag only clears on leaving the last place.
      ringer = FakeRinger()..dndForcesSilentRead = true;
      build();

      await handle(enter('library'));
      await handle(enter('office'));

      // DND is still on — we are still in control — but the ringer mode reads
      // differently than when we applied it.
      ringer.state = const CapturedRingerState(
          ringerMode: RingerMode.normal, dndEnabled: true);

      await handle(exit('library'));

      expect(log.last.action, TripAction.reResolved,
          reason: 'drift on an axis we do not control is not an override');
      expect(ringer.state.dndEnabled, isFalse);
      expect(ringer.state.ringerMode, RingerMode.silent);
    });

    test('turning DND off yourself is still respected', () async {
      ringer = FakeRinger()..dndForcesSilentRead = true;
      build();

      await handle(enter('library'));
      await handle(enter('office'));

      // The user genuinely undoes what we did.
      ringer.state = const CapturedRingerState(
          ringerMode: RingerMode.normal, dndEnabled: false);

      await handle(exit('library'));
      expect(log.last.action, TripAction.skippedOverride);
    });

    test('stepping down again to vibrate works', () async {
      ringer = FakeRinger();
      build();

      await handle(enter('library')); // DND
      await handle(enter('office')); // Silent
      await handle(enter('gym')); // Vibrate
      expect(ringer.state.dndEnabled, isTrue);

      await handle(exit('library')); // -> Silent
      expect(ringer.state.ringerMode, RingerMode.silent);
      expect(ringer.state.dndEnabled, isFalse);

      await handle(exit('office')); // -> Vibrate
      expect(ringer.state.ringerMode, RingerMode.vibrate);

      await handle(exit('gym')); // -> restore
      expect(ringer.state.ringerMode, RingerMode.normal);
      expect(await engagements.get(), isNull);
    });
  });
}
