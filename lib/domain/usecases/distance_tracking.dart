import '../entities/place_distance.dart';

/// Every tunable that governs live-distance cost, in one place.
///
/// Battery is the binding constraint: a 1 Hz GPS stream is only justified when
/// the user is close enough for the number to be changing meaningfully. Further
/// away we step down, and past the last tier we stop polling entirely and let
/// the OS geofence do its job.
abstract final class DistanceTrackingPolicy {
  /// Poll at this rate when the nearest place is within
  /// [nearRadiusMultiple] x its own radius.
  static const Duration nearInterval = Duration(seconds: 1);
  static const double nearRadiusMultiple = 2.0;

  /// Second tier, out to [midRangeMeters] beyond the edge.
  static const Duration midInterval = Duration(seconds: 10);
  static const double midRangeMeters = 1000;

  /// Third tier, out to [farRangeMeters] beyond the edge.
  static const Duration farInterval = Duration(seconds: 60);
  static const double farRangeMeters = 5000;

  /// Beyond [farRangeMeters] we do not poll at all — OS geofencing only.
  static const Duration? idleInterval = null;

  /// Displayed distance is smoothed with an exponential moving average over
  /// roughly this window, so the readout does not flicker while standing
  /// still. Display only — geofence triggering always uses raw values.
  static const Duration smoothingWindow = Duration(seconds: 3);

  /// Maximum UI rebuild rate.
  static const Duration maxUiRefresh = Duration(milliseconds: 500);

  /// A place must beat the one above it by this many metres before the list
  /// reorders, so GPS noise cannot make cards swap places.
  static const double reorderHysteresisMeters = 25;

  /// How long after saving on an approximate fix we keep trying to improve it.
  /// Behavioural config, not animation — it lives here with the other cost
  /// knobs rather than in the theme.
  static const Duration postSaveRefinementWindow = Duration(seconds: 15);
}

/// Chooses a polling interval from the closest place's edge distance.
///
/// Null means "stop polling" — the caller falls back to OS geofencing.
Duration? pollingIntervalFor({
  required double? nearestEdgeMeters,
  required double? nearestRadiusMeters,
}) {
  if (nearestEdgeMeters == null || nearestRadiusMeters == null) {
    return DistanceTrackingPolicy.farInterval;
  }

  // Inside, or within 2x the radius of the edge: the number is changing fast
  // enough to be worth 1 Hz.
  final nearThreshold =
      nearestRadiusMeters * (DistanceTrackingPolicy.nearRadiusMultiple - 1);
  if (nearestEdgeMeters <= nearThreshold) {
    return DistanceTrackingPolicy.nearInterval;
  }
  if (nearestEdgeMeters <= DistanceTrackingPolicy.midRangeMeters) {
    return DistanceTrackingPolicy.midInterval;
  }
  if (nearestEdgeMeters <= DistanceTrackingPolicy.farRangeMeters) {
    return DistanceTrackingPolicy.farInterval;
  }
  return DistanceTrackingPolicy.idleInterval;
}

/// Exponential moving average for one place's displayed distance.
///
/// Display-only smoothing. A large jump (say, a corrected fix landing) is
/// adopted immediately rather than crawled towards, so the reading stays
/// truthful when the position genuinely changes.
class DistanceSmoother {
  /// Jumps larger than this are treated as real movement, not noise.
  static const double _jumpThresholdMeters = 60;

  final double alpha;
  double? _centre;
  double? _edge;

  DistanceSmoother({this.alpha = 0.35});

  void reset() {
    _centre = null;
    _edge = null;
  }

  PlaceDistance smooth(PlaceDistance raw) {
    final centre = raw.centreMeters;
    final edge = raw.signedEdgeMeters;
    if (centre == null || edge == null) {
      reset();
      return raw;
    }

    final previousCentre = _centre;
    if (previousCentre == null ||
        (centre - previousCentre).abs() > _jumpThresholdMeters) {
      _centre = centre;
      _edge = edge;
    } else {
      _centre = previousCentre + alpha * (centre - previousCentre);
      _edge = _edge! + alpha * (edge - _edge!);
    }

    return raw.copyWith(centreMeters: _centre, signedEdgeMeters: _edge);
  }
}

/// Orders places by proximity while resisting GPS noise.
///
/// A place only moves ahead of another once it is clearly closer — by
/// [DistanceTrackingPolicy.reorderHysteresisMeters] — which stops cards
/// swapping back and forth while the user stands still.
List<String> orderWithHysteresis({
  required List<String> previousOrder,
  required Map<String, PlaceDistance> distances,
}) {
  final ids = distances.keys.toList();

  double keyOf(String id) {
    final d = distances[id]?.signedEdgeMeters;
    // Unknown distances sort last, stably.
    return d ?? double.infinity;
  }

  final previousIndex = <String, int>{
    for (var i = 0; i < previousOrder.length; i++) previousOrder[i]: i,
  };

  ids.sort((a, b) {
    final da = keyOf(a);
    final db = keyOf(b);
    final gap = (da - db).abs();

    // Both previously ranked and the gap is within noise: keep the old order.
    final ia = previousIndex[a];
    final ib = previousIndex[b];
    if (ia != null &&
        ib != null &&
        gap < DistanceTrackingPolicy.reorderHysteresisMeters) {
      return ia.compareTo(ib);
    }

    final byDistance = da.compareTo(db);
    if (byDistance != 0) return byDistance;
    // Deterministic tie-break so equal distances never shuffle.
    return a.compareTo(b);
  });

  return ids;
}
