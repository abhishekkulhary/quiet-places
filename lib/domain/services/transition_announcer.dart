import '../entities/quiet_place.dart';
import '../entities/quiet_place_behaviour.dart';

/// Tells the user that the engine just changed (or restored) their ringer.
///
/// This is the app's signature moment, and it usually happens while the app is
/// closed — so the announcement has to originate from the background isolate.
/// The domain layer only knows this interface; the notification plumbing lives
/// in `data/`.
abstract interface class TransitionAnnouncer {
  /// The phone was just silenced/vibrated/DND'd on entering [place].
  Future<void> announceApplied(QuietPlace place, QuietPlaceBehaviour behaviour);

  /// The prior ringer state was restored on leaving [place].
  Future<void> announceRestored(QuietPlace place);
}
