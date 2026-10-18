import '../../domain/entities/ringer_mode.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/services/ringer_controller.dart';
import 'platform_locale.dart';
import '../notifications/notification_service.dart';

/// iOS has no public API to change the ringer, so this controller never mutates
/// audio state. On place entry it posts an honest local-notification prompt; the
/// UI separately documents the Shortcuts/Focus automation the user can wire up.
class IosRingerController implements RingerController {
  final NotificationService notifications;
  IosRingerController(this.notifications);

  @override
  bool get isSupported => false;

  @override
  String get unsupportedReason =>
      platformL().unsupportedIos;

  @override
  bool get postsNotificationOnApply => true;

  @override
  Future<CapturedRingerState> capture() async => CapturedRingerState.unknown;

  @override
  Future<bool> isDndAccessGranted() async => false;

  @override
  Future<void> requestDndAccess() async {}

  @override
  Future<void> applyState(CapturedRingerState target) async {
    // Cannot change the ringer on iOS.
  }

  @override
  Future<void> notifyUnsupportedEntry(QuietPlace place) =>
      notifications.showArrivalPrompt(place);
}
