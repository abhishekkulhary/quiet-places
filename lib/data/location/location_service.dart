import 'package:geolocator/geolocator.dart';

/// Thin wrapper over geolocator for the one-tap "add current location" flow and
/// permission checks. All calls are on-device; no reverse geocoding is attempted
/// (it requires a network geocoder, which this app deliberately does not use).
class LocationService {
  /// Whether foreground location permission is granted.
  Future<bool> hasLocationPermission() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  /// Whether "Allow all the time" (background) is granted — required for
  /// geofences to fire when the app isn't open.
  Future<bool> hasBackgroundPermission() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.always;
  }

  /// Request foreground location permission. Returns true if granted.
  Future<bool> requestForeground() async {
    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  /// Capture the current GPS fix for a new place.
  Future<({double latitude, double longitude})> currentFix() async {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (latitude: pos.latitude, longitude: pos.longitude);
  }

  /// Opens the OS app settings so the user can grant "Allow all the time".
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
