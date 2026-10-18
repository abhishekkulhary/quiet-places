/// Radius validation and the hardware-reliability guidance shown on the save
/// sheet.
class RadiusPolicy {
  /// Minimum selectable radius. Below this, OS geofencing is essentially noise.
  static const double minMeters = 50;

  /// Maximum selectable radius.
  static const double maxMeters = 1000;

  /// Default for a new place.
  static const double defaultMeters = 150;

  /// Radii under this are accepted but flagged as unreliable on most hardware.
  static const double reliableThresholdMeters = 100;
}

enum RadiusValidation {
  ok,

  /// Within range but under the reliability threshold — accept with a warning.
  unreliable,

  tooSmall,
  tooLarge,
  notANumber,
}

extension RadiusValidationX on RadiusValidation {
  bool get isAccepted =>
      this == RadiusValidation.ok || this == RadiusValidation.unreliable;
}

/// Validate a radius in metres against [RadiusPolicy].
RadiusValidation validateRadius(double? meters) {
  if (meters == null || meters.isNaN || meters.isInfinite) {
    return RadiusValidation.notANumber;
  }
  if (meters < RadiusPolicy.minMeters) return RadiusValidation.tooSmall;
  if (meters > RadiusPolicy.maxMeters) return RadiusValidation.tooLarge;
  if (meters < RadiusPolicy.reliableThresholdMeters) {
    return RadiusValidation.unreliable;
  }
  return RadiusValidation.ok;
}

/// Clamp any input into the accepted range (used by the slider/field pairing).
double clampRadius(double meters) =>
    meters.clamp(RadiusPolicy.minMeters, RadiusPolicy.maxMeters).toDouble();
