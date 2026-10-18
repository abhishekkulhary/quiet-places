import 'boundary_transition.dart';
import 'quiet_place_behaviour.dart';

/// What the engine decided to do in response to a transition. Recorded so the
/// user can answer "why didn't it fire?" from the history screen.
enum TripAction {
  /// Applied a ringer behaviour on entry.
  applied,

  /// Restored the pre-entry ringer state on exit.
  restored,

  /// Did nothing because the app was globally paused or snoozed.
  skippedPaused,

  /// Did nothing because the place was disabled.
  skippedDisabled,

  /// Did nothing because the platform cannot change the ringer (iOS/desktop);
  /// on iOS a local notification is posted instead.
  skippedUnsupported,

  /// Left the ringer alone because the user manually overrode it while inside.
  skippedOverride,

  /// Re-resolved to a still-active place's behaviour instead of restoring.
  reResolved,

  /// Posted a notification prompt (iOS entry).
  notified,

  /// Logged for the record but no device change was warranted (e.g. a dwell
  /// event, or an exit of a place we were never engaged with).
  observed,

  /// An error occurred while handling the transition.
  error,
}

/// One row in the entry/exit history log.
class TripLogEntry {
  final int? id;
  final String placeId;
  final String placeName;
  final BoundaryTransition transition;
  final TripAction action;

  /// Free-form detail, e.g. "silent → normal" or an error message.
  /// The behaviour in force after this entry, when one was applied.
  ///
  /// Null for entries that changed nothing. Kept as data rather than derived
  /// from [detail]: the prose names two behaviours on a step-down and reading
  /// it back picks the wrong one.
  final QuietPlaceBehaviour? behaviour;

  final String? detail;
  final DateTime timestamp;

  const TripLogEntry({
    this.id,
    required this.placeId,
    required this.placeName,
    required this.transition,
    required this.action,
    this.behaviour,
    this.detail,
    required this.timestamp,
  });
}
