import 'package:native_ringer/native_ringer.dart';

import '../../domain/entities/ringer_mode.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/services/ringer_controller.dart';

/// Real Android ringer control, delegating to the [NativeRinger] local plugin
/// (which works in both the UI and geofence background isolates).
class AndroidRingerController implements RingerController {
  const AndroidRingerController();

  @override
  bool get isSupported => true;

  @override
  String get unsupportedReason => '';

  @override
  bool get postsNotificationOnApply => false;

  @override
  Future<CapturedRingerState> capture() async {
    final snap = await NativeRinger.capture();
    return CapturedRingerState(
      ringerMode: _wireToMode(snap.ringerMode),
      dndEnabled: snap.dndEnabled,
    );
  }

  @override
  Future<bool> isDndAccessGranted() => NativeRinger.isDndAccessGranted();

  @override
  Future<void> requestDndAccess() => NativeRinger.openDndSettings();

  @override
  Future<void> applyState(CapturedRingerState target) {
    return NativeRinger.applyState(
      ringerMode: _modeToWire(target.ringerMode),
      dndEnabled: target.dndEnabled,
    );
  }

  @override
  Future<void> notifyUnsupportedEntry(QuietPlace place) async {
    // Supported platform — nothing to notify.
  }

  static RingerMode _wireToMode(int wire) {
    switch (wire) {
      case NativeRinger.wireSilent:
        return RingerMode.silent;
      case NativeRinger.wireVibrate:
        return RingerMode.vibrate;
      case NativeRinger.wireNormal:
        return RingerMode.normal;
      default:
        return RingerMode.unknown;
    }
  }

  static int _modeToWire(RingerMode mode) {
    switch (mode) {
      case RingerMode.silent:
        return NativeRinger.wireSilent;
      case RingerMode.vibrate:
        return NativeRinger.wireVibrate;
      case RingerMode.normal:
      case RingerMode.unknown:
        // Never intentionally set "unknown"; fall back to normal so restoration
        // of an unreadable prior state at least leaves the phone audible.
        return NativeRinger.wireNormal;
    }
  }
}
