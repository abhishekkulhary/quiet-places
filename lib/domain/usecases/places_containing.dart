import '../entities/quiet_place.dart';
import 'geodesy.dart';

/// The enabled Quiet Places whose circle contains the given point.
///
/// The engine is otherwise driven entirely by boundary crossings, which means
/// it is blind to anything that changes while you are already standing inside a
/// place — unpausing, clearing a snooze, or enabling a place you are currently
/// in all produce no transition, so nothing was ever applied. This lets those
/// moments be reconciled against where you actually are.
///
/// Ordered by how deeply inside you are, so the caller can engage the most
/// relevant place first; the behaviour that wins is still resolved by
/// [resolveActiveBehaviour], not by this order.
/// How long a reconciliation waits for a fix before falling back to the last
/// known position.
///
/// Shorter than the editor's precise timeout: this runs behind a toggle the
/// user just flipped, so a slow answer is worse than a slightly coarser one.
const reconcilePositionTimeout = Duration(seconds: 10);

List<QuietPlace> placesContaining({
  required double latitude,
  required double longitude,
  required Iterable<QuietPlace> places,
}) {
  final inside = <(QuietPlace, double)>[];
  for (final place in places) {
    if (!place.enabled) continue;
    final distance = geodesicDistance(
        latitude, longitude, place.latitude, place.longitude);
    // Matches PlaceDistance.side: exactly on the boundary counts as inside.
    if (distance <= place.radiusMeters) {
      inside.add((place, distance - place.radiusMeters));
    }
  }
  inside.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final (place, _) in inside) place];
}
