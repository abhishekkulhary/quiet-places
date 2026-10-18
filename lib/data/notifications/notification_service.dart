import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../l10n/app_localizations.dart';
import '../ringer/platform_locale.dart';

import '../../domain/entities/quiet_place.dart';
import '../../domain/entities/quiet_place_behaviour.dart';
import '../../domain/services/transition_announcer.dart';

/// Thin wrapper over flutter_local_notifications used for the iOS geofence-entry
/// prompt ("You've arrived at Office — silence your phone?"). It is a real
/// federated plugin, so it is available in the geofence background isolate after
/// `DartPluginRegistrant.ensureInitialized()`.
class NotificationService {
  /// Notification copy is resolved here rather than passed in, because these
  /// are posted from the geofence background isolate, which has no
  /// BuildContext and therefore no `L.of(context)`.
  /// Duplicated from `presentation/l10n_extensions.dart` on purpose: `data/`
  /// must not import `presentation/`, and this is the only place outside the
  /// UI that needs a translated behaviour name.
  static String _behaviourLabel(L l, QuietPlaceBehaviour b) => switch (b) {
        QuietPlaceBehaviour.vibrate => l.behaviourVibrate,
        QuietPlaceBehaviour.silent => l.behaviourSilent,
        QuietPlaceBehaviour.dnd => l.behaviourDnd,
      };

  static const _channelId = 'geofence_arrival';

  /// Separate channel for the silencing moment so the user can tune (or
  /// silence) it independently of arrival prompts. Deliberately low-importance
  /// and silent: announcing that the phone just went quiet must not make a
  /// sound.
  static const _momentChannelId = 'silence_moment';

  /// Fixed id so the moment notification replaces itself rather than stacking.
  static const _momentId = 424242;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  Future<void> initialize() async {
    if (_initialised) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      // We request permission explicitly during onboarding, not on first init.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
    );
    _initialised = true;
  }

  /// Ask the user (iOS/macOS) for permission to post notifications.
  Future<bool> requestPermission() async {
    await initialize();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// The signature moment: the phone has just been silenced.
  Future<void> showSilenced(QuietPlace place, QuietPlaceBehaviour behaviour) async {
    await initialize();
    final l = platformL();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _momentChannelId,
        l.notifChannelMomentName,
        channelDescription: l.notifChannelMomentDesc,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        silent: true,
        category: AndroidNotificationCategory.status,
      ),
      iOS: DarwinNotificationDetails(presentSound: false),
      macOS: DarwinNotificationDetails(presentSound: false),
    );
    await _plugin.show(
      id: _momentId,
      title: l.notifSilencedTitle(place.name, _behaviourLabel(l, behaviour).toLowerCase()),
      body: l.notifSilencedBody,
      notificationDetails: details,
    );
  }

  /// The counterpart: the prior ringer state has been put back.
  Future<void> showRestored(QuietPlace place) async {
    await initialize();
    final l = platformL();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _momentChannelId,
        l.notifChannelMomentName,
        channelDescription: l.notifChannelMomentDesc,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        silent: true,
        category: AndroidNotificationCategory.status,
      ),
      iOS: DarwinNotificationDetails(presentSound: false),
      macOS: DarwinNotificationDetails(presentSound: false),
    );
    await _plugin.show(
      id: _momentId,
      title: l.notifRestoredTitle(place.name),
      body: l.notifRestoredBody,
      notificationDetails: details,
    );
  }

  /// Posts the honest iOS prompt on place entry, since we cannot mute for them.
  Future<void> showArrivalPrompt(QuietPlace place) async {
    await initialize();
    final l = platformL();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l.notifChannelArrivalName,
        channelDescription: l.notifChannelArrivalDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: place.id.hashCode & 0x7fffffff,
      title: l.notifArrivalTitle(place.name),
      body: l.notifArrivalBody,
      notificationDetails: details,
    );
  }
}

/// [TransitionAnnouncer] backed by local notifications.
///
/// Runs in the geofence background isolate, so it must not touch Riverpod or
/// any UI state — it builds its own [NotificationService].
class NotificationAnnouncer implements TransitionAnnouncer {
  final NotificationService notifications;
  NotificationAnnouncer(this.notifications);

  @override
  Future<void> announceApplied(QuietPlace place, QuietPlaceBehaviour behaviour) =>
      notifications.showSilenced(place, behaviour);

  @override
  Future<void> announceRestored(QuietPlace place) =>
      notifications.showRestored(place);
}
