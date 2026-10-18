/// The kind of boundary crossing reported by the OS geofencing service.
enum BoundaryTransition {
  enter,
  exit,

  /// The user has remained inside the region past the loitering delay. Android
  /// only; unused for ringer decisions today but logged for debugging.
  dwell,
}

/// A single transition event for one place, as delivered to the background
/// handler. This is the domain-level shape; the `data` layer adapts the
/// `native_geofence` callback payload into these.
class QuietPlaceTransitionEvent {
  final String placeId;
  final BoundaryTransition transition;
  final DateTime occurredAt;

  const QuietPlaceTransitionEvent({
    required this.placeId,
    required this.transition,
    required this.occurredAt,
  });

  @override
  String toString() =>
      'QuietPlaceTransitionEvent($placeId, ${transition.name}, $occurredAt)';
}
