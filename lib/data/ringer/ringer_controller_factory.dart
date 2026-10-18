import 'dart:io' show Platform;

import '../../domain/services/ringer_controller.dart';
import '../notifications/notification_service.dart';
import 'android_ringer_controller.dart';
import 'ios_ringer_controller.dart';
import 'noop_ringer_controller.dart';

/// Selects the right [RingerController] for the current platform at runtime.
///
/// Called identically from the UI isolate and the geofence background isolate,
/// so the engine's behaviour is consistent no matter where a transition is
/// handled. The domain layer never calls this directly — it receives the chosen
/// controller through its interface.
RingerController createRingerController({NotificationService? notifications}) {
  if (Platform.isAndroid) {
    return const AndroidRingerController();
  }
  if (Platform.isIOS) {
    return IosRingerController(notifications ?? NotificationService());
  }
  // macOS, Windows, Linux — no ringer concept.
  return const NoopRingerController();
}
