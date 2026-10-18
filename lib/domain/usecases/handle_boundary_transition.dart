import '../entities/engagement.dart';
import '../entities/boundary_transition.dart';
import '../entities/ringer_mode.dart';
import '../entities/trip_log_entry.dart';
import '../entities/quiet_place.dart';
import '../entities/quiet_place_behaviour.dart';
import '../repositories/settings_repository.dart';
import '../repositories/trip_log_repository.dart';
import '../repositories/quiet_place_repository.dart';
import '../services/device_clock.dart';
import '../services/ringer_controller.dart';
import '../services/transition_announcer.dart';
import 'resolve_active_behaviour.dart';

typedef Clock = DateTime Function();

/// The device state we expect to observe after applying [behaviour] on top of
/// [captured]. Silent/Vibrate change only the ringer mode; DND changes only the
/// interruption filter. Kept pure so the fake ringer in tests mirrors it exactly
/// and manual-override detection is deterministic.
CapturedRingerState expectedStateAfter(
  CapturedRingerState captured,
  QuietPlaceBehaviour behaviour,
) {
  switch (behaviour) {
    case QuietPlaceBehaviour.vibrate:
      return captured.copyWith(ringerMode: RingerMode.vibrate);
    case QuietPlaceBehaviour.silent:
      return captured.copyWith(ringerMode: RingerMode.silent);
    case QuietPlaceBehaviour.dnd:
      return captured.copyWith(dndEnabled: true);
  }
}

/// Applies the state-restoration rules to a single geofence transition.
///
/// This is the engine's brain and runs identically in the UI isolate and the
/// background isolate. It owns no state itself — everything it needs is read
/// from and written to repositories, so it survives process death.
///
/// Rules implemented:
///  * Capture the ringer state *before* the first mutation; restore it on the
///    final exit — never blindly set "normal".
///  * Overlapping places resolve most-restrictive-wins, re-resolved on every
///    transition (see [resolveActiveBehaviour]).
///  * If the user changes the ringer manually while inside, treat it as an
///    override: stop managing and don't restore on exit.
///  * Global pause / snooze makes entry inert; exits still restore so the device
///    is never left stuck silent.
class HandleBoundaryTransition {
  /// How long to let the OS settle before reading back what we just applied.
  ///
  /// setInterruptionFilter and setRingerMode are asynchronous inside Android:
  /// capturing immediately can read the pre-change value, which then never
  /// matches on the next transition and is misreported as a manual override.
  /// Seen in the log as spurious 'manual change detected' entries moments
  /// after a successful apply.
  static const Duration settleAfterApply = Duration(milliseconds: 250);

  final QuietPlaceRepository places;
  final EngagementRepository engagements;
  final SettingsRepository settings;
  final TripLogRepository tripLog;
  final RingerController ringer;

  /// Optional: announces the moment to the user. Null in tests and on
  /// platforms where announcing isn't wanted.
  final TransitionAnnouncer? announcer;

  /// Used to notice that the device rebooted since the engagement was written.
  final DeviceClock? deviceClock;

  /// Overrides [settleAfterApply]; tests pass [Duration.zero].
  final Duration? settleDelay;

  final Clock clock;

  HandleBoundaryTransition({
    required this.places,
    required this.engagements,
    required this.settings,
    required this.tripLog,
    required this.ringer,
    this.announcer,
    this.deviceClock,
    this.settleDelay,
    Clock? clock,
  }) : clock = clock ?? DateTime.now;

  Future<void> call(QuietPlaceTransitionEvent event) async {
    try {
      final place = await places.getById(event.placeId);
      if (place == null) {
        await _log(event.placeId, '(deleted)', event.transition,
            TripAction.error, 'unknown place id');
        return;
      }

      // Dwell is Android-only and carries no restoration meaning; record it for
      // debugging and stop.
      if (event.transition == BoundaryTransition.dwell) {
        await _log(place.id, place.name, event.transition, TripAction.observed,
            'dwell');
        return;
      }

      if (event.transition == BoundaryTransition.enter) {
        await _handleEnter(place);
      } else {
        await _handleExit(place);
      }
    } catch (e) {
      await _log(event.placeId, '(error)', event.transition, TripAction.error,
          e.toString());
    }
  }

  /// Loads the engagement, discarding it if the device has rebooted since it
  /// was written.
  ///
  /// A reboot resets the ringer without telling us. Left alone, the stored
  /// appliedState no longer matches reality and the next transition is misread
  /// as the user having overridden us — which silently disables the app until
  /// they leave every Quiet Place. Seen on a real device after a reboot.
  Future<Engagement?> _liveEngagement() async {
    final existing = await engagements.get();
    if (existing == null) return null;

    final boot = await deviceClock?.bootTime();
    if (existing.isStaleFor(boot)) {
      await engagements.clear();
      return null;
    }
    return existing;
  }

  Future<void> _handleEnter(QuietPlace place) async {
    if (!place.enabled) {
      await _log(place.id, place.name, BoundaryTransition.enter,
          TripAction.skippedDisabled, null);
      return;
    }

    final now = clock();
    final appSettings = await settings.get();
    if (appSettings.isPausedAt(now)) {
      await _log(place.id, place.name, BoundaryTransition.enter,
          TripAction.skippedPaused, null);
      return;
    }

    // Unsupported platform: iOS posts a notification; desktop no-ops. Either
    // way there is nothing to capture or restore, so we don't engage.
    if (!ringer.isSupported) {
      await ringer.notifyUnsupportedEntry(place);
      await _log(
        place.id,
        place.name,
        BoundaryTransition.enter,
        ringer.postsNotificationOnApply
            ? TripAction.notified
            : TripAction.skippedUnsupported,
        ringer.unsupportedReason,
      );
      return;
    }

    final existing = await _liveEngagement();
    if (existing == null || existing.isEmpty) {
      await _beginEngagement(place);
      return;
    }

    final active = {...existing.activePlaceIds, place.id};
    if (existing.overridden) {
      await engagements.save(existing.copyWith(activePlaceIds: active));
      await _log(place.id, place.name, BoundaryTransition.enter,
          TripAction.skippedOverride, 'user override active');
      return;
    }

    // Manual-override check: has the user undone what we applied?
    final live = await ringer.capture();
    if (_userUndidOurChange(existing, live)) {
      await engagements.save(
          existing.copyWith(activePlaceIds: active, overridden: true));
      await _log(place.id, place.name, BoundaryTransition.enter,
          TripAction.skippedOverride, 'manual change detected');
      return;
    }

    await _reResolve(active, existing, place, BoundaryTransition.enter);
  }

  Future<void> _handleExit(QuietPlace place) async {
    final existing = await _liveEngagement();
    if (existing == null || !existing.activePlaceIds.contains(place.id)) {
      // We never engaged with this place (e.g. entered while paused). Nothing to
      // undo.
      await _log(place.id, place.name, BoundaryTransition.exit,
          TripAction.observed, 'not engaged');
      return;
    }

    final active = {...existing.activePlaceIds}..remove(place.id);

    if (existing.overridden) {
      if (active.isEmpty) {
        await engagements.clear();
        await _log(place.id, place.name, BoundaryTransition.exit,
            TripAction.skippedOverride, 'cleared without restore');
      } else {
        await engagements.save(existing.copyWith(activePlaceIds: active));
        await _log(place.id, place.name, BoundaryTransition.exit,
            TripAction.skippedOverride, 'user override active');
      }
      return;
    }

    if (active.isEmpty) {
      // Final exit: restore — unless the user changed the ringer themselves.
      final live = await ringer.capture();
      if (_userUndidOurChange(existing, live)) {
        await engagements.clear();
        await _log(place.id, place.name, BoundaryTransition.exit,
            TripAction.skippedOverride, 'manual change, not restoring');
        return;
      }
      await ringer.applyState(existing.capturedState);
      await engagements.clear();
      await _announce(() => announcer?.announceRestored(place));
      await _log(
        place.id,
        place.name,
        BoundaryTransition.exit,
        TripAction.restored,
        '${existing.appliedBehaviour.label} → '
            '${existing.capturedState.ringerMode.name}',
        behaviour: existing.appliedBehaviour,
      );
      return;
    }

    // Still inside other places: re-resolve against what remains.
    final live = await ringer.capture();
    if (_userUndidOurChange(existing, live)) {
      await engagements.save(
          existing.copyWith(activePlaceIds: active, overridden: true));
      await _log(place.id, place.name, BoundaryTransition.exit,
          TripAction.skippedOverride, 'manual change detected');
      return;
    }
    await _reResolve(active, existing, place, BoundaryTransition.exit);
  }

  /// First entry into any place: snapshot current state, apply, and persist.
  Future<void> _beginEngagement(QuietPlace place) async {
    final captured = await ringer.capture();
    await ringer.applyState(expectedStateAfter(captured, place.behaviour));
    await _settle();
    // Record what the device ACTUALLY looks like afterwards, not what we
    // predicted. Enabling DND makes Android report the ringer as silent, so a
    // predicted signature would never match on the next transition and every
    // subsequent event would be misread as a manual override.
    final applied = await ringer.capture();
    final boot = await deviceClock?.bootTime();
    await engagements.save(Engagement(
      bootTime: boot,
      activePlaceIds: {place.id},
      capturedState: captured,
      appliedBehaviour: place.behaviour,
      appliedState: applied,
      overridden: false,
    ));
    await _log(
      place.id,
      place.name,
      BoundaryTransition.enter,
      TripAction.applied,
      '${captured.ringerMode.name} → ${place.behaviour.label}',
      behaviour: place.behaviour,
    );
    await _announce(() => announcer?.announceApplied(place, place.behaviour));
  }

  /// Recompute the winning behaviour across [active] and apply it if it changed.
  Future<void> _reResolve(
    Set<String> active,
    Engagement existing,
    QuietPlace triggeringPlace,
    BoundaryTransition transition,
  ) async {
    final all = await places.getAll();
    final activePlaces = all.where((z) => active.contains(z.id));
    final desired = resolveActiveBehaviour(activePlaces);

    // Shouldn't happen (active is non-empty here), but guard anyway.
    if (desired == null) {
      await engagements.save(existing.copyWith(activePlaceIds: active));
      return;
    }

    if (desired == existing.appliedBehaviour) {
      await engagements.save(existing.copyWith(activePlaceIds: active));
      await _log(triggeringPlace.id, triggeringPlace.name, transition,
          TripAction.observed, 'no change (${desired.label})',
          behaviour: desired);
      return;
    }

    await ringer.applyState(
        expectedStateAfter(existing.capturedState, desired));
    await _settle();
    // As above: trust the observed state, not the prediction.
    final applied = await ringer.capture();
    await engagements.save(existing.copyWith(
      activePlaceIds: active,
      appliedBehaviour: desired,
      appliedState: applied,
    ));
    await _log(
      triggeringPlace.id,
      triggeringPlace.name,
      transition,
      TripAction.reResolved,
      '${existing.appliedBehaviour.label} → ${desired.label}',
      behaviour: desired,
    );
    await _announce(
        () => announcer?.announceApplied(triggeringPlace, desired));
  }


  /// Whether the user has undone the change we made.
  ///
  /// Compares only the axis the applied behaviour actually controls. Full-state
  /// equality was far too brittle: enabling DND makes Android report the ringer
  /// as silent, volume keys move the ringer mode, and OEMs report both
  /// inconsistently. Any such drift was read as "the user took over" — and
  /// because the override flag only clears when the last Quiet Place is exited,
  /// that permanently disabled the engine for anyone standing inside one.
  ///
  /// Reported from real use: walking out of an overlapping DND place into a
  /// Silent one left DND on and Silent unapplied, because the step-down was
  /// being skipped as an override.
  bool _userUndidOurChange(Engagement existing, CapturedRingerState live) {
    // If we cannot read the device we cannot claim the user changed anything.
    if (!live.isKnown && !live.dndEnabled) return false;

    switch (existing.appliedBehaviour) {
      case QuietPlaceBehaviour.dnd:
        // We control the interruption filter; the ringer mode is a side effect.
        return !live.dndEnabled;
      case QuietPlaceBehaviour.silent:
        return live.ringerMode != RingerMode.silent;
      case QuietPlaceBehaviour.vibrate:
        return live.ringerMode != RingerMode.vibrate;
    }
  }

  /// Gives the OS a moment to apply an audio change before we read it back.
  /// Overridable so tests do not pay the delay.
  Future<void> _settle() =>
      Future<void>.delayed(settleDelay ?? settleAfterApply);

  /// Announcing is cosmetic — a failure here must never affect the ringer
  /// state machine or leave the engagement inconsistent.
  Future<void> _announce(Future<void>? Function() body) async {
    try {
      await body();
    } catch (_) {}
  }

  Future<void> _log(
    String placeId,
    String placeName,
    BoundaryTransition transition,
    TripAction action,
    String? detail, {
    QuietPlaceBehaviour? behaviour,
  }) {
    return tripLog.add(TripLogEntry(
      placeId: placeId,
      placeName: placeName,
      transition: transition,
      action: action,
      behaviour: behaviour,
      detail: detail,
      timestamp: clock(),
    ));
  }
}
