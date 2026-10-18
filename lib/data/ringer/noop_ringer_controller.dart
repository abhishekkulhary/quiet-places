import '../../domain/entities/ringer_mode.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/services/ringer_controller.dart';
import 'platform_locale.dart';

/// Desktop/web fallback. There is no ringer concept on these platforms, so every
/// operation is inert and the controller honestly reports it is unsupported.
class NoopRingerController implements RingerController {
  const NoopRingerController();

  @override
  bool get isSupported => false;

  @override
  String get unsupportedReason =>
      platformL().unsupportedDesktop;

  @override
  bool get postsNotificationOnApply => false;

  @override
  Future<CapturedRingerState> capture() async => CapturedRingerState.unknown;

  @override
  Future<bool> isDndAccessGranted() async => false;

  @override
  Future<void> requestDndAccess() async {}

  @override
  Future<void> applyState(CapturedRingerState target) async {}

  @override
  Future<void> notifyUnsupportedEntry(QuietPlace place) async {}
}
