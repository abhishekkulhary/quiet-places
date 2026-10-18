import '../entities/ringer_mode.dart';
import '../entities/quiet_place.dart';

/// Platform-agnostic control over the device ringer.
///
/// Per-platform implementations live in `data/ringer/`. The domain layer only
/// ever sees this interface and never learns which platform it is on.
///
/// - Android: real implementation via a `MethodChannel` to `AudioManager` /
///   `NotificationManager`.
/// - iOS: cannot change the ringer (no public API). [isSupported] is false;
///   [notifyUnsupportedEntry] posts a local notification prompt instead.
/// - Desktop/web: no-op that reports it is unsupported.
///
/// Design note: mutation is expressed as an **absolute target state**
/// ([applyState]) rather than "apply this behaviour". The engine translates a
/// [QuietPlaceBehaviour] plus the captured baseline into a concrete
/// [CapturedRingerState] and asks the controller to make the device match it.
/// This keeps re-resolution across overlapping places deterministic and makes
/// restoration just another [applyState] call.
abstract interface class RingerController {
  /// Whether this platform can actually change the ringer. When false, the UI
  /// must communicate the limitation rather than pretending to work.
  bool get isSupported;

  /// Human-readable reason shown when [isSupported] is false
  /// (e.g. "iOS has no public API to silence the ringer").
  String get unsupportedReason;

  /// True when [notifyUnsupportedEntry] posts a local notification (iOS). Lets
  /// the engine log "notified" vs "unsupported" honestly.
  bool get postsNotificationOnApply;

  /// Read the current device audio state. Returns [CapturedRingerState.unknown]
  /// where reading is impossible.
  Future<CapturedRingerState> capture();

  /// Whether Do Not Disturb policy access has been granted by the user. Only
  /// meaningful on Android; other platforms return true (nothing to grant) or
  /// false as appropriate.
  Future<bool> isDndAccessGranted();

  /// Open the OS settings screen where the user grants DND policy access.
  /// No-op where not applicable.
  Future<void> requestDndAccess();

  /// Drive the device to an absolute [target] (both ringer mode and DND). Used
  /// for applying a behaviour and for restoring the captured state. No-op on
  /// unsupported platforms.
  Future<void> applyState(CapturedRingerState target);

  /// Called on place entry when [isSupported] is false. iOS posts a local
  /// notification prompt referencing [place]; desktop/web do nothing.
  Future<void> notifyUnsupportedEntry(QuietPlace place);
}
