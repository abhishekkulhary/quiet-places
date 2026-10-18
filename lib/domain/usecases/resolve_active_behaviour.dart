import '../entities/quiet_place.dart';
import '../entities/quiet_place_behaviour.dart';

/// Overlap resolution rule: **most restrictive wins**.
///
/// When the device is inside several places at once, the behaviour with the
/// highest [QuietPlaceBehaviour.severity] is applied (DND > Silent > Vibrate). This is
/// deterministic and independent of entry order or reboot state, which matters
/// because the active set is rebuilt from persisted membership after process
/// death.
///
/// Disabled places are ignored. Returns null when no active place qualifies.
QuietPlaceBehaviour? resolveActiveBehaviour(Iterable<QuietPlace> activePlaces) {
  QuietPlaceBehaviour? winner;
  for (final place in activePlaces) {
    if (!place.enabled) continue;
    if (winner == null || place.behaviour.severity > winner.severity) {
      winner = place.behaviour;
    }
  }
  return winner;
}
