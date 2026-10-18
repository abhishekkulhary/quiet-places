import 'package:native_geofence/native_geofence.dart' as ng;

import '../../domain/entities/quiet_place.dart';
import '../../domain/services/quiet_place_monitor.dart';

/// [QuietPlaceMonitor] backed by `native_geofence`, which uses Android's
/// OS-managed `GeofencingClient` and iOS's `CLLocationManager` region
/// monitoring. Transitions are delivered to [callback] in a background isolate.
class NativeGeofenceMonitor implements QuietPlaceMonitor {
  /// Top-level `@pragma('vm:entry-point')` callback (see
  /// `background/geofence_callback.dart`). Must be a top-level or static
  /// function for its handle to be resolvable after process death. Typed
  /// structurally because the plugin does not export its `GeofenceCallback`
  /// typedef.
  final Future<void> Function(ng.GeofenceCallbackParams) callback;

  NativeGeofenceMonitor(this.callback);

  @override
  Future<void> initialize() => ng.NativeGeofenceManager.instance.initialize();

  @override
  Future<void> register(QuietPlace place) => ng.NativeGeofenceManager.instance
      .createGeofence(_toNative(place), callback);

  @override
  Future<void> unregister(String placeId) =>
      ng.NativeGeofenceManager.instance.removeGeofenceById(placeId);

  @override
  Future<void> unregisterAll() =>
      ng.NativeGeofenceManager.instance.removeAllGeofences();

  @override
  Future<List<String>> registeredPlaceIds() =>
      ng.NativeGeofenceManager.instance.getRegisteredGeofenceIds();

  @override
  Future<void> syncPlaces(List<QuietPlace> places) async {
    final desired = {for (final z in places.where((z) => z.enabled)) z.id: z};
    final registered = await registeredPlaceIds();

    // Remove geofences that are gone or disabled.
    for (final id in registered) {
      if (!desired.containsKey(id)) {
        await unregister(id);
      }
    }
    // (Re)create every desired place. createGeofence overwrites by id, so this
    // also picks up radius/location edits.
    for (final place in desired.values) {
      await register(place);
    }
  }

  ng.Geofence _toNative(QuietPlace place) => ng.Geofence(
        id: place.id,
        location:
            ng.Location(latitude: place.latitude, longitude: place.longitude),
        radiusMeters: place.radiusMeters,
        // Dwell is Android-only; the plugin tolerates it in the set on iOS as
        // long as it isn't the sole trigger.
        triggers: {
          ng.GeofenceEvent.enter,
          ng.GeofenceEvent.exit,
          ng.GeofenceEvent.dwell,
        },
        iosSettings: const ng.IosGeofenceSettings(initialTrigger: true),
        androidSettings: const ng.AndroidGeofenceSettings(
          initialTriggers: {ng.GeofenceEvent.enter},
          loiteringDelay: Duration(minutes: 5),
        ),
      );
}
