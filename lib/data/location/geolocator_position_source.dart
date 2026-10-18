import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/position_fix.dart';
import '../../domain/services/position_source.dart';

/// [PositionSource] backed by geolocator.
///
/// Every timed call passes an explicit `timeLimit`; the previous implementation
/// omitted it, which is why a bad fix could block the add-place flow forever.
class GeolocatorPositionSource implements PositionSource {
  const GeolocatorPositionSource();

  @override
  Future<PositionFix?> lastKnown() async {
    final p = await Geolocator.getLastKnownPosition();
    return p == null ? null : _toFix(p, FixStage.lastKnown);
  }

  @override
  Future<PositionFix> coarse({required Duration timeout}) async {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: timeout,
      ),
    ).timeout(timeout);
    return _toFix(p, FixStage.coarse);
  }

  @override
  Future<PositionFix> precise({required Duration timeout}) async {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeout,
      ),
    ).timeout(timeout);
    return _toFix(p, FixStage.precise);
  }

  /// Low-power positions used to keep a recent fix warm while the app is in the
  /// foreground. `distanceFilter` throttles delivery so an idle phone on a desk
  /// costs essentially nothing.
  @override
  Stream<PositionFix> warmUp() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.reduced,
        distanceFilter: 25,
      ),
    ).map((p) => _toFix(p, FixStage.coarse));
  }

  @override
  Stream<PositionFix> watch({
    required Duration interval,
    required bool highAccuracy,
  }) {
    final accuracy =
        highAccuracy ? LocationAccuracy.high : LocationAccuracy.reduced;

    // On Android, intervalDuration throttles the OS fix rate itself — the part
    // that actually costs power. A client-side throttle alone would leave the
    // GNSS chip busy for nothing. Other platforms get the portable settings.
    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: accuracy,
            distanceFilter: 0,
            intervalDuration: interval,
          )
        : LocationSettings(accuracy: accuracy, distanceFilter: 0);
    return Geolocator.getPositionStream(locationSettings: settings)
        .map((p) => _toFix(p, FixStage.precise));
  }

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<PositionFailure?> ensurePermission() async {
    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    switch (status) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return null;
      case LocationPermission.deniedForever:
        return PositionFailure.permissionDeniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return PositionFailure.permissionDenied;
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  PositionFix _toFix(Position p, FixStage stage) => PositionFix(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracyMeters: p.accuracy,
        stage: stage,
        timestamp: p.timestamp,
      );
}
