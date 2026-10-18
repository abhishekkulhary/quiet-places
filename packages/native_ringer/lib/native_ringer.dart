import 'package:flutter/services.dart';

/// Low-level platform bridge to the device ringer / Do-Not-Disturb.
///
/// This is a **local Flutter plugin** rather than an app-level `MethodChannel`
/// on purpose: `native_geofence`'s Android background worker spins up its own
/// `FlutterEngine` without re-registering app plugins, so an Activity-scoped
/// channel would be dead in the geofence isolate. As a federated plugin, this
/// class's native handler is registered on *any* engine — including the
/// background one — after `DartPluginRegistrant.ensureInitialized()`.
///
/// Only Android implements real behaviour. iOS/others return "unsupported".
class NativeRinger {
  static const MethodChannel _channel = MethodChannel('native_ringer');

  /// Wire values for the ringer mode, matching Android `AudioManager`.
  static const int wireSilent = 0;
  static const int wireVibrate = 1;
  static const int wireNormal = 2;
  static const int wireUnknown = -1;

  /// True on platforms that can actually change the ringer (Android).
  static Future<bool> isSupported() async {
    final result = await _channel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  /// Reads the current ringer mode (one of the `wire*` constants) and whether
  /// Do Not Disturb (interruption filter != all) is active.
  static Future<RingerSnapshot> capture() async {
    final map = await _channel.invokeMapMethod<String, dynamic>('capture');
    if (map == null) {
      return const RingerSnapshot(ringerMode: wireUnknown, dndEnabled: false);
    }
    return RingerSnapshot(
      ringerMode: (map['ringerMode'] as int?) ?? wireUnknown,
      dndEnabled: (map['dndEnabled'] as bool?) ?? false,
    );
  }

  /// Drives the device to an absolute state: sets the ringer mode and toggles
  /// the DND interruption filter. Ordering is handled natively so a change is
  /// not blocked by an active filter.
  static Future<void> applyState({
    required int ringerMode,
    required bool dndEnabled,
  }) {
    return _channel.invokeMethod<void>('applyState', {
      'ringerMode': ringerMode,
      'dndEnabled': dndEnabled,
    });
  }

  /// Whether the user has granted DND policy access
  /// (`NotificationManager.isNotificationPolicyAccessGranted`).
  static Future<bool> isDndAccessGranted() async {
    final result = await _channel.invokeMethod<bool>('isDndAccessGranted');
    return result ?? false;
  }

  /// Milliseconds since the device booted (monotonic; unaffected by clock
  /// changes). Returns null where the platform cannot report it.
  static Future<int?> elapsedRealtime() =>
      _channel.invokeMethod<int>('elapsedRealtime');

  /// Opens the system settings screen where the user grants DND policy access.
  static Future<void> openDndSettings() {
    return _channel.invokeMethod<void>('openDndSettings');
  }
}

/// Immutable read of the device audio state.
class RingerSnapshot {
  final int ringerMode;
  final bool dndEnabled;

  const RingerSnapshot({required this.ringerMode, required this.dndEnabled});
}
