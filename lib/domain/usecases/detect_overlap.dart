import '../entities/quiet_place.dart';
import '../entities/quiet_place_behaviour.dart';
import 'geodesy.dart';
import 'resolve_active_behaviour.dart';

/// A Quiet Place whose circle intersects the one being edited.
class PlaceOverlap {
  final QuietPlace other;

  /// Distance between the two centres, metres.
  final double centreSeparationMeters;

  /// The behaviour that would actually win inside the shared area, per the
  /// most-restrictive-wins rule already used by the engine.
  final QuietPlaceBehaviour winner;

  /// True when [other]'s behaviour is the one that wins, i.e. the place being
  /// edited would be overridden inside the overlap.
  final bool otherWins;

  const PlaceOverlap({
    required this.other,
    required this.centreSeparationMeters,
    required this.winner,
    required this.otherWins,
  });
}

/// Finds saved places whose circles intersect the one being edited.
///
/// Two circles overlap when the distance between their centres is less than the
/// sum of their radii. The winning behaviour is resolved with the same
/// [resolveActiveBehaviour] the engine uses, so the warning shown in the editor
/// can never disagree with what the device will actually do.
List<PlaceOverlap> detectOverlaps({
  required double latitude,
  required double longitude,
  required double radiusMeters,
  required QuietPlaceBehaviour behaviour,
  required Iterable<QuietPlace> others,
  String? editingId,
}) {
  final overlaps = <PlaceOverlap>[];

  for (final other in others) {
    if (other.id == editingId) continue;
    if (!other.enabled) continue;

    final separation = geodesicDistance(
        latitude, longitude, other.latitude, other.longitude);
    if (separation >= radiusMeters + other.radiusMeters) continue;

    // Resolve exactly as the engine would if both were active at once.
    final draft = QuietPlace(
      id: editingId ?? '__draft__',
      name: '',
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      behaviour: behaviour,
      enabled: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    final winner = resolveActiveBehaviour([draft, other]) ?? behaviour;

    overlaps.add(PlaceOverlap(
      other: other,
      centreSeparationMeters: separation,
      winner: winner,
      // Ties go to the place being edited: nothing changes for the user, so
      // there is nothing to warn about beyond the overlap itself.
      otherWins: winner.severity > behaviour.severity,
    ));
  }

  overlaps.sort((a, b) =>
      a.centreSeparationMeters.compareTo(b.centreSeparationMeters));
  return overlaps;
}
