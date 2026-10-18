/// How a position was obtained. Ordered from least to most trustworthy — the
/// ordinal is meaningful and is used by the supersede rule.
enum FixStage {
  /// No fix yet.
  none,

  /// Cached OS position from a previous session. Instant (tens of ms) but may
  /// be stale or absent entirely.
  lastKnown,

  /// Coarse/network fix.
  coarse,

  /// High-accuracy GNSS fix.
  precise,
}

/// A position sample with the provenance and accuracy needed to decide whether
/// it should replace what we already have.
///
/// Pure value object: the add-place flow renders whatever fix it currently holds
/// and upgrades progressively as better ones arrive.
class PositionFix {
  final double latitude;
  final double longitude;

  /// Radius of 68% confidence, in metres, as reported by the OS.
  final double accuracyMeters;

  final FixStage stage;
  final DateTime timestamp;

  const PositionFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.stage,
    required this.timestamp,
  });

  /// Accuracy good enough that we stop trying to improve on it.
  static const double goodEnoughAccuracyMeters = 20;

  bool get isGoodEnough =>
      stage == FixStage.precise && accuracyMeters <= goodEnoughAccuracyMeters;

  @override
  String toString() =>
      'PositionFix(${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}, '
      '±${accuracyMeters.round()}m, ${stage.name})';
}

/// Whether [candidate] should replace [current] as the fix we display and save.
///
/// Rules, in order:
///  * anything beats nothing;
///  * a later stage always wins (coarse beats lastKnown, precise beats coarse) —
///    provenance outranks a flattering accuracy number from a stale cache;
///  * never regress to an earlier stage;
///  * within the same stage, accept only a *materially* better reading, so the
///    pin doesn't jitter on every noisy sample.
bool shouldSupersede(PositionFix? current, PositionFix candidate) {
  if (current == null) return true;
  if (candidate.stage.index > current.stage.index) return true;
  if (candidate.stage.index < current.stage.index) return false;
  return isMateriallyBetter(current, candidate);
}

/// True when [candidate] improves on [baseline]'s accuracy enough to be worth
/// acting on (a 20% tightening, or any improvement crossing the good-enough
/// line). Used both for same-stage updates and for deciding whether to rewrite
/// a place the user saved before the fix settled.
bool isMateriallyBetter(PositionFix baseline, PositionFix candidate) {
  if (candidate.accuracyMeters <= 0) return false;
  if (baseline.accuracyMeters <= 0) return true;
  return candidate.accuracyMeters < baseline.accuracyMeters * 0.8;
}
