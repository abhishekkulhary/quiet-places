import '../usecases/geodesy.dart';
import 'quiet_place.dart';

/// Which side of a Quiet Place's boundary the device is on.
enum BoundarySide { inside, outside }

/// How much to trust the numbers in a [PlaceDistance].
enum DistanceConfidence {
  /// The GPS accuracy is small compared with the distance to the edge, so the
  /// inside/outside call is trustworthy.
  confident,

  /// We are closer to the edge than the accuracy radius: the side we report
  /// could be wrong. Must be shown with a distinct treatment — never rendered
  /// as a plain precise number.
  uncertain,

  /// No position at all (permission denied, services off, no fix yet).
  unknown,
}

/// The device's relationship to one Quiet Place at a moment in time.
///
/// Pure value object computed from a single position sample; see
/// `distance_tracking.dart` for how a stream of these is smoothed and paced.
class PlaceDistance {
  final String placeId;

  /// Geodesic distance to the centre, metres. Null when position is unknown.
  final double? centreMeters;

  /// [centreMeters] minus the radius. Negative means inside. Null when unknown.
  ///
  /// This is the number that answers "which side am I on, and by how much" —
  /// one value carrying both facts.
  final double? signedEdgeMeters;

  /// Reported accuracy of the fix these were derived from, metres.
  final double? accuracyMeters;

  const PlaceDistance({
    required this.placeId,
    required this.centreMeters,
    required this.signedEdgeMeters,
    required this.accuracyMeters,
  });

  /// The state shown when we have no usable position.
  const PlaceDistance.unknown(this.placeId)
      : centreMeters = null,
        signedEdgeMeters = null,
        accuracyMeters = null;

  bool get hasPosition => centreMeters != null && signedEdgeMeters != null;

  BoundarySide? get side {
    final edge = signedEdgeMeters;
    if (edge == null) return null;
    return edge <= 0 ? BoundarySide.inside : BoundarySide.outside;
  }

  bool get isInside => side == BoundarySide.inside;

  /// Distance from the boundary, unsigned.
  double? get edgeMeters => signedEdgeMeters?.abs();

  DistanceConfidence get confidence {
    final edge = signedEdgeMeters;
    if (edge == null) return DistanceConfidence.unknown;
    final accuracy = accuracyMeters;
    // Without an accuracy figure we cannot claim confidence.
    if (accuracy == null || accuracy <= 0) return DistanceConfidence.uncertain;
    // Closer to the edge than the fix is accurate: the side could flip.
    return accuracy >= edge.abs()
        ? DistanceConfidence.uncertain
        : DistanceConfidence.confident;
  }

  /// Computes the relationship between [fromLat]/[fromLon] and [place].
  static PlaceDistance compute({
    required QuietPlace place,
    required double? fromLat,
    required double? fromLon,
    required double? accuracyMeters,
  }) {
    if (fromLat == null || fromLon == null) {
      return PlaceDistance.unknown(place.id);
    }
    final centre =
        geodesicDistance(fromLat, fromLon, place.latitude, place.longitude);
    return PlaceDistance(
      placeId: place.id,
      centreMeters: centre,
      signedEdgeMeters: centre - place.radiusMeters,
      accuracyMeters: accuracyMeters,
    );
  }

  PlaceDistance copyWith({double? centreMeters, double? signedEdgeMeters}) {
    return PlaceDistance(
      placeId: placeId,
      centreMeters: centreMeters ?? this.centreMeters,
      signedEdgeMeters: signedEdgeMeters ?? this.signedEdgeMeters,
      accuracyMeters: accuracyMeters,
    );
  }

  @override
  String toString() => 'PlaceDistance($placeId, centre=$centreMeters, '
      'edge=$signedEdgeMeters, ±$accuracyMeters, ${confidence.name})';
}

/// Rounds a distance for display, per the product rule:
///  * below 100 m — nearest 5 m;
///  * 100 m to under 1 km — nearest 10 m;
///  * 1 km and above — kept exact here and formatted to one decimal km.
///
/// Rounding *before* formatting is what stops the readout flickering between
/// adjacent values while standing still.
double roundForDisplay(double meters) {
  final m = meters.abs();
  if (m >= 1000) return meters;
  final step = m < 100 ? 5 : 10;
  final rounded = (m / step).round() * step;
  return meters.isNegative ? -rounded.toDouble() : rounded.toDouble();
}
