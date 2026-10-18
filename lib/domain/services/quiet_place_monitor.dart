import '../entities/quiet_place.dart';

/// Registers and monitors OS-level geofences.
///
/// Implemented in `data/geofence/` on top of `native_geofence`, which wraps
/// Android's `GeofencingClient` and iOS's `CLLocationManager` region
/// monitoring. The domain layer expresses intent ("watch these places"); the
/// implementation owns the platform callback plumbing.
abstract interface class QuietPlaceMonitor {
  /// One-time initialisation of the underlying platform manager. Safe to call
  /// repeatedly.
  Future<void> initialize();

  /// Ensure exactly the given [places] are registered: adds new ones, updates
  /// changed ones, removes those no longer present. Disabled places must not be
  /// registered.
  Future<void> syncPlaces(List<QuietPlace> places);

  /// Register a single place (add or replace by id).
  Future<void> register(QuietPlace place);

  /// Stop monitoring a place.
  Future<void> unregister(String placeId);

  /// Remove every registered geofence.
  Future<void> unregisterAll();

  /// Ids currently registered with the OS.
  Future<List<String>> registeredPlaceIds();
}
