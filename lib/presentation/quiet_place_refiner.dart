import 'dart:async';

import '../domain/entities/position_fix.dart';
import '../domain/repositories/quiet_place_repository.dart';
import '../domain/usecases/distance_tracking.dart';
import '../domain/usecases/resolve_position.dart';
import 'coordinator.dart';

/// Keeps improving a place's coordinates for a short window after the user saves
/// it with an approximate fix.
///
/// This is what makes "Save is enabled from stage 0" safe: the user is never
/// blocked waiting for GPS, and if a materially better fix lands within
/// [window] the record is quietly corrected and the geofence re-registered.
///
/// Deliberately conservative — it abandons the update if the place was deleted or
/// its location edited in the meantime, so it can never overwrite a deliberate
/// user choice with a stale background result.
class QuietPlaceRefiner {
  final ResolvePosition resolve;
  final QuietPlaceCoordinator coordinator;
  final QuietPlaceRepository places;

  QuietPlaceRefiner({
    required this.resolve,
    required this.coordinator,
    required this.places,
  });

  /// Fire-and-forget. Never throws into the caller.
  Future<void> refine({
    required String placeId,
    required PositionFix savedWith,
    Duration window = DistanceTrackingPolicy.postSaveRefinementWindow,
  }) async {
    if (savedWith.isGoodEnough) return;

    try {
      final deadline = DateTime.now().add(window);
      await for (final resolution
          in resolve(seed: savedWith).timeout(window, onTimeout: (sink) {
        sink.close();
      })) {
        if (DateTime.now().isAfter(deadline)) break;
        final candidate = resolution.fix;
        if (candidate == null) continue;
        if (!isMateriallyBetter(savedWith, candidate)) continue;

        // Only correct the record if it still holds exactly what we saved.
        final current = await places.getById(placeId);
        if (current == null) return;
        if (current.latitude != savedWith.latitude ||
            current.longitude != savedWith.longitude) {
          return; // user moved it deliberately — leave it alone
        }

        await coordinator.savePlace(current.copyWith(
          latitude: candidate.latitude,
          longitude: candidate.longitude,
        ));
        if (candidate.isGoodEnough) return;
      }
    } catch (_) {
      // Refinement is best effort; the saved place remains valid regardless.
    }
  }
}
