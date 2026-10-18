import '../domain/entities/boundary_transition.dart';
import '../domain/entities/app_settings.dart';
import '../domain/entities/position_fix.dart';
import '../domain/entities/quiet_place.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/trip_log_repository.dart';
import '../domain/repositories/quiet_place_repository.dart';
import '../data/ringer/platform_locale.dart';
import '../domain/services/position_source.dart';
import '../domain/services/quiet_place_monitor.dart';
import '../domain/services/device_clock.dart';
import '../domain/services/ringer_controller.dart';
import '../domain/services/transition_announcer.dart';
import '../domain/usecases/handle_boundary_transition.dart';
import '../domain/usecases/places_containing.dart';

/// UI-isolate orchestration: keeps the OS geofence registrations in sync with
/// the place database and mediates global pause / snooze. The heavy lifting on
/// transitions lives in [HandleBoundaryTransition], which also runs in the
/// background isolate — this class only drives the *foreground* concerns.
class QuietPlaceCoordinator {
  final QuietPlaceRepository places;
  final EngagementRepository engagements;
  final SettingsRepository settings;
  final TripLogRepository tripLog;
  final RingerController ringer;
  final QuietPlaceMonitor engine;
  final TransitionAnnouncer? announcer;
  final DeviceClock? deviceClock;

  /// Used only by [reconcileNow]; without it, reconciliation is skipped rather
  /// than guessed at.
  final PositionSource? positionSource;

  QuietPlaceCoordinator({
    required this.places,
    required this.engagements,
    required this.settings,
    required this.tripLog,
    required this.ringer,
    required this.engine,
    this.announcer,
    this.deviceClock,
    this.positionSource,
  });

  Future<void> initialize() async {
    await engine.initialize();
    await resync();
  }

  /// Register exactly the enabled places with the OS.
  Future<void> resync() async => engine.syncPlaces(await places.getAll());

  Future<void> savePlace(QuietPlace place) async {
    await places.upsert(place);
    await resync();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    // Turning a place off while standing in it has to release the device the
    // same way walking out would: restore if it was the only place, or step
    // down to whatever else still covers you. Order matters -- the place is
    // disabled first so the re-resolve cannot pick it as the winner again.
    final wasEngaged = !enabled && await _isEngagedWith(id);
    final place = wasEngaged ? await places.getById(id) : null;

    await places.setEnabled(id, enabled);
    await resync();

    if (enabled) {
      // Enabling a place you are already standing in is the same blind spot as
      // un-pausing: no crossing will ever arrive.
      await reconcileNow();
    } else if (place != null) {
      await _releaseAsExit(place);
    }
  }

  Future<void> deletePlace(String id) async {
    // Released *before* the row goes, so the exit can still be logged under the
    // place's real name. Skipping this would strand its id inside the
    // engagement's active set, which then never empties -- leaving the device
    // silenced with nothing left to switch it back.
    if (await _isEngagedWith(id)) {
      final place = await places.getById(id);
      if (place != null) await _releaseAsExit(place);
    }
    await places.delete(id);
    await engine.unregister(id);
  }

  Future<void> setGlobalPause(bool paused) async {
    final s = await settings.get();
    await settings.save(s.copyWith(globalPaused: paused));
    if (paused) {
      await _restoreIfEngaged();
    } else {
      // Un-pausing inside a place produces no boundary crossing, so without
      // this the engine would stay idle until the user physically left and
      // came back.
      await reconcileNow();
    }
  }

  Future<void> snoozeForOneHour() async {
    final s = await settings.get();
    await settings.save(
        s.copyWith(snoozeUntil: () => DateTime.now().add(const Duration(hours: 1))));
    await _restoreIfEngaged();
  }

  Future<void> clearSnooze() async {
    final s = await settings.get();
    await settings.save(s.copyWith(snoozeUntil: () => null));
    await reconcileNow();
  }

  Future<void> setGpsWarmup(bool enabled) async {
    final s = await settings.get();
    await settings.save(s.copyWith(gpsWarmupEnabled: enabled));
  }

  Future<void> setMapsEnabled(bool enabled) async {
    final s = await settings.get();
    await settings.save(s.copyWith(mapsEnabled: enabled));
  }

  /// Sets the app language; null follows the device.
  ///
  /// The cached copy is updated too, so notifications posted from this isolate
  /// switch language immediately rather than at the next launch.
  Future<void> setLocale(String? code) async {
    final s = await settings.get();
    await settings.save(s.copyWith(localeCode: () => code));
    setPreferredLanguage(code);
  }

  Future<void> setUnits(UnitSystem units) async {
    final s = await settings.get();
    await settings.save(s.copyWith(units: units));
  }

  Future<void> markOnboardingComplete() async {
    final s = await settings.get();
    await settings.save(s.copyWith(onboardingComplete: true));
  }

  /// When the user pauses/snoozes while inside a place, undo our change so the
  /// device isn't left silenced. We don't fight a manual override.
  Future<bool> _isEngagedWith(String id) async {
    final e = await engagements.get();
    return e != null && e.activePlaceIds.contains(id);
  }

  /// Drives the place through the normal exit path.
  ///
  /// Removing a place from under a live engagement -- by switching it off or
  /// deleting it -- means exactly what walking out of it means, so it runs the
  /// same restore / step-down / override logic rather than a second copy of it.
  Future<void> _releaseAsExit(QuietPlace place) => _handler()(
        QuietPlaceTransitionEvent(
          placeId: place.id,
          transition: BoundaryTransition.exit,
          occurredAt: DateTime.now(),
        ),
      );

  HandleBoundaryTransition _handler() => HandleBoundaryTransition(
        places: places,
        engagements: engagements,
        settings: settings,
        tripLog: tripLog,
        ringer: ringer,
        announcer: announcer,
        deviceClock: deviceClock,
      );

  /// Re-derives what should be applied *right now* from the device's actual
  /// position, rather than waiting for a boundary crossing.
  ///
  /// The engine is edge-triggered: it only ever acts when the OS reports a
  /// crossing. That leaves it blind to everything that changes while the user
  /// stands still — un-pausing, clearing a snooze, a snooze expiring, enabling
  /// a place they are already inside. This closes that gap by synthesising the
  /// enter events the OS will never send, so the *same* handler applies them
  /// with the same capture, overlap-resolution and logging as a real crossing.
  ///
  /// Safe to call speculatively: it is a no-op when paused, when no position is
  /// available, when the user is inside nothing, or when an engagement already
  /// covers the places they are in.
  Future<void> reconcileNow() async {
    final source = positionSource;
    if (source == null) return;

    final s = await settings.get();
    if (s.isPausedAt(DateTime.now())) return;

    final enabled = await places.getEnabled();
    if (enabled.isEmpty) return;

    PositionFix? fix;
    try {
      fix = await source.precise(timeout: reconcilePositionTimeout);
    } catch (_) {
      // A denied or unavailable fix must never break the toggle the user just
      // flipped; fall back to whatever the OS last knew.
      try {
        fix = await source.lastKnown();
      } catch (_) {
        fix = null;
      }
    }
    if (fix == null) return;

    final inside = placesContaining(
      latitude: fix.latitude,
      longitude: fix.longitude,
      places: enabled,
    );
    if (inside.isEmpty) return;

    // An engagement that already covers these places means a real crossing got
    // there first; re-entering would re-capture the *silenced* state as the one
    // to restore later.
    final existing = await engagements.get();
    if (existing != null &&
        inside.every((p) => existing.activePlaceIds.contains(p.id))) {
      return;
    }

    final handle = _handler();
    final now = DateTime.now();
    for (final p in inside) {
      await handle(QuietPlaceTransitionEvent(
        placeId: p.id,
        transition: BoundaryTransition.enter,
        occurredAt: now,
      ));
    }
  }

  Future<void> _restoreIfEngaged() async {
    final e = await engagements.get();
    if (e == null) return;
    if (!e.overridden && ringer.isSupported) {
      await ringer.applyState(e.capturedState);
    }
    await engagements.clear();
  }

  /// Debug/testing hook: drive a synthetic transition through the *exact* same
  /// handler the OS callback uses. This is how transitions are exercised without
  /// physically walking across a boundary (see the developer menu).
  Future<void> debugInject(String placeId, BoundaryTransition transition) async {
    await _handler()(QuietPlaceTransitionEvent(
      placeId: placeId,
      transition: transition,
      occurredAt: DateTime.now(),
    ));
  }
}
