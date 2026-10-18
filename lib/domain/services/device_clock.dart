/// Tells the engine when the device last booted.
///
/// This exists because a reboot resets the ringer without telling the app.
/// Without it, a persisted engagement claiming "we applied DND" survives a
/// reboot, the live state no longer matches, and override-detection misreads
/// that as the user having changed the ringer — silently disabling the app
/// until they leave every Quiet Place. Observed on a real device.
abstract interface class DeviceClock {
  /// Approximate wall-clock instant the device booted, or null if unknown.
  ///
  /// Derived from a monotonic since-boot counter, so it is stable across clock
  /// adjustments but shifts if the device reboots.
  Future<DateTime?> bootTime();
}
