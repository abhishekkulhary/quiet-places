import 'ringer_mode.dart';
import 'quiet_place_behaviour.dart';

/// The engine's persistent memory of "we are currently inside one or more places
/// and have changed the ringer". It survives process death because geofence
/// callbacks run in a background isolate that may be started fresh each time.
///
/// There is at most one active engagement. It is created on the first entry
/// (0 → 1 active places) and cleared on the last exit (1 → 0), at which point the
/// captured state is restored.
class Engagement {
  /// Ids of places the device is currently inside.
  final Set<String> activePlaceIds;

  /// The device audio state captured *before* the first mutation, restored on
  /// the final exit.
  final CapturedRingerState capturedState;

  /// The behaviour currently applied to the device (the resolved winner across
  /// [activePlaceIds]).
  final QuietPlaceBehaviour appliedBehaviour;

  /// The device state we expect to see if the user hasn't touched anything.
  /// Compared against the live state to detect manual overrides.
  final CapturedRingerState appliedState;

  /// Once the user manually changes the ringer while inside, we stop managing
  /// and never restore on exit — we don't fight the user.
  final bool overridden;

  /// When the device booted, as seen at the time this engagement was written.
  ///
  /// If the device has rebooted since, the applied ringer state was wiped by
  /// the reboot rather than by the user, so the engagement is stale and must
  /// not be read as an override. Null for engagements written before this was
  /// tracked, which are treated as stale.
  final DateTime? bootTime;

  const Engagement({
    required this.activePlaceIds,
    required this.capturedState,
    required this.appliedBehaviour,
    required this.appliedState,
    required this.overridden,
    this.bootTime,
  });

  bool get isEmpty => activePlaceIds.isEmpty;

  /// True when this engagement was written before the device's current boot,
  /// so everything it believes about the ringer is out of date.
  ///
  /// Compared with a tolerance because the boot instant is derived from a
  /// monotonic counter against wall-clock time, which drifts by a few hundred
  /// milliseconds between reads.
  bool isStaleFor(DateTime? currentBoot) {
    if (currentBoot == null) return false; // cannot tell; assume valid
    final written = bootTime;
    if (written == null) return true; // predates tracking
    return written.difference(currentBoot).abs() > const Duration(seconds: 30);
  }

  Engagement copyWith({
    Set<String>? activePlaceIds,
    CapturedRingerState? capturedState,
    QuietPlaceBehaviour? appliedBehaviour,
    CapturedRingerState? appliedState,
    bool? overridden,
    DateTime? bootTime,
  }) {
    return Engagement(
      activePlaceIds: activePlaceIds ?? this.activePlaceIds,
      capturedState: capturedState ?? this.capturedState,
      appliedBehaviour: appliedBehaviour ?? this.appliedBehaviour,
      appliedState: appliedState ?? this.appliedState,
      overridden: overridden ?? this.overridden,
      bootTime: bootTime ?? this.bootTime,
    );
  }
}
