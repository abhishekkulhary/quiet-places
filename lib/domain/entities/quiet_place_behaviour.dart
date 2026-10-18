import 'ringer_mode.dart';

/// What a place should do to the device when the user is inside it.
///
/// The [severity] ordering is the single source of truth for overlap
/// resolution: when several places are active at once, the most restrictive
/// behaviour wins (see `ResolveActiveBehaviour`).
enum QuietPlaceBehaviour {
  /// Ringer to vibrate. Least restrictive.
  vibrate(severity: 1),

  /// Ringer to silent.
  silent(severity: 2),

  /// Do Not Disturb (interruption filter). Most restrictive.
  dnd(severity: 3);

  const QuietPlaceBehaviour({required this.severity});

  /// Higher = more restrictive. Used to pick a winner among overlapping places.
  final int severity;

  /// The ringer mode this behaviour targets. DND keeps the ringer as-is at the
  /// audio-mode level and instead flips the interruption filter, so it maps to
  /// [RingerMode.silent] as its audible fallback where DND is unavailable.
  RingerMode get targetRingerMode {
    switch (this) {
      case QuietPlaceBehaviour.vibrate:
        return RingerMode.vibrate;
      case QuietPlaceBehaviour.silent:
        return RingerMode.silent;
      case QuietPlaceBehaviour.dnd:
        return RingerMode.silent;
    }
  }

  bool get requiresDnd => this == QuietPlaceBehaviour.dnd;

  String get label {
    switch (this) {
      case QuietPlaceBehaviour.vibrate:
        return 'Vibrate';
      case QuietPlaceBehaviour.silent:
        return 'Silent';
      case QuietPlaceBehaviour.dnd:
        return 'Do Not Disturb';
    }
  }
}
