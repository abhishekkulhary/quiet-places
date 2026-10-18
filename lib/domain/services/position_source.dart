import '../entities/position_fix.dart';

/// Why a position could not be produced. Each maps to an inline, recoverable
/// message in the Quiet Place editor — never a blocking dialog or a dead spinner.
enum PositionFailure {
  /// Device location services are switched off system-wide.
  serviceDisabled,

  /// The user declined the permission this time.
  permissionDenied,

  /// Declined permanently; only an app-settings trip can fix it.
  permissionDeniedForever,

  /// No fix arrived within the allotted time (indoors, poor sky view).
  timeout,

  unknown,
}

/// The progressively-refined result of trying to locate the device.
///
/// Both a [fix] and a [failure] can be present at once: we may be showing a
/// cached last-known position while the precise attempt is timing out. The UI
/// renders whatever it has and explains the rest.
class PositionResolution {
  final PositionFix? fix;

  /// True while a better fix is still being sought.
  final bool resolving;

  final PositionFailure? failure;

  const PositionResolution({
    this.fix,
    this.resolving = false,
    this.failure,
  });

  static const initial = PositionResolution(resolving: true);

  /// True when there is nothing to show and nothing left to wait for — the only
  /// state in which the sheet must fall back to manual entry.
  bool get isDeadEnd => fix == null && !resolving;

  PositionResolution copyWith({
    PositionFix? fix,
    bool? resolving,
    PositionFailure? failure,
    bool clearFailure = false,
  }) {
    return PositionResolution(
      fix: fix ?? this.fix,
      resolving: resolving ?? this.resolving,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

/// Staged access to the device's position.
///
/// Split by cost so the UI can render the cheapest result immediately and
/// upgrade in place, rather than awaiting the expensive one. Measured on a
/// mid-range device: [lastKnown] ~40 ms (or null), [coarse] ~120 ms warm but up
/// to ~10 s cold, [precise] similar cold. Hence [warmUpStream].
abstract interface class PositionSource {
  /// Cached OS position. Instant, possibly null, possibly stale.
  Future<PositionFix?> lastKnown();

  /// Coarse fix. [timeout] is required: an unbounded location await is what
  /// let the original implementation hang the UI forever.
  Future<PositionFix> coarse({required Duration timeout});

  /// High-accuracy fix. [timeout] is required for the same reason.
  Future<PositionFix> precise({required Duration timeout});

  /// Low-power stream used to keep a recent fix in hand *before* the user taps
  /// Add, which is what actually makes the flow feel instant on a cold device.
  Stream<PositionFix> warmUp();

  /// Continuous positions for the live-distance readout.
  ///
  /// [interval] is a hint to the OS about how often a fix is wanted, and
  /// [highAccuracy] selects GNSS versus a cheaper provider. The caller
  /// re-subscribes with different values as the user moves between distance
  /// tiers — that re-tiering, not client-side throttling, is what actually
  /// saves battery.
  Stream<PositionFix> watch({
    required Duration interval,
    required bool highAccuracy,
  });

  Future<bool> isServiceEnabled();

  /// Ensures foreground permission, returning null on success or the reason it
  /// could not be obtained.
  Future<PositionFailure?> ensurePermission();

  /// Opens the OS app-settings page (recovery for a permanent denial).
  Future<void> openAppSettings();

  /// Opens the OS location-services page (recovery for services being off).
  Future<void> openLocationSettings();
}
