import Flutter
import UIKit

/// iOS has **no public API** to change the ringer or mute the device, by design
/// of the platform. This plugin therefore reports `isSupported == false` and
/// makes every mutating call a no-op. The app surfaces the limitation to the
/// user and posts a local notification on geofence entry instead (handled in
/// Dart via flutter_local_notifications).
public class NativeRingerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "native_ringer", binaryMessenger: registrar.messenger())
    let instance = NativeRingerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(false)
    case "elapsedRealtime":
      // Monotonic since boot, matching Android's SystemClock.elapsedRealtime.
      result(Int(ProcessInfo.processInfo.systemUptime * 1000))
    case "isDndAccessGranted":
      result(false)
    case "capture":
      result(["ringerMode": -1, "dndEnabled": false])
    case "applyState", "openDndSettings":
      // Intentionally inert: cannot control the ringer on iOS.
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
