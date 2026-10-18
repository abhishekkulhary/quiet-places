import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:native_geofence/native_geofence.dart' as ng;

import '../data/db/app_database.dart';
import '../data/device/native_device_clock.dart';
import '../data/notifications/notification_service.dart';
import '../data/repositories/drift_settings_repository.dart';
import '../data/repositories/drift_trip_log_repository.dart';
import '../data/repositories/drift_quiet_place_repository.dart';
import '../data/ringer/platform_locale.dart';
import '../data/ringer/ringer_controller_factory.dart';
import '../domain/entities/boundary_transition.dart';
import '../domain/usecases/handle_boundary_transition.dart';

/// Entry point invoked by `native_geofence` when a boundary is crossed.
///
/// This runs in a **separate background isolate** that `native_geofence` starts
/// (potentially from a cold process after reboot). It has none of the UI
/// isolate's state, so it rebuilds the data layer from scratch and uses no
/// Riverpod. It must be a top-level function marked `@pragma('vm:entry-point')`
/// so the AOT compiler keeps it and its handle stays resolvable across restarts.
@pragma('vm:entry-point')
Future<void> geofenceCallback(ng.GeofenceCallbackParams params) async {
  // The background engine is created without app plugins registered; this call
  // registers all federated plugins (path_provider, flutter_local_notifications,
  // native_ringer) onto this isolate so the data layer below actually works.
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Short-lived foreground promotion: on Android 14+ this makes the ringer work
  // reliable when starting from the background. We demote as soon as we're done,
  // so there is no permanent foreground service / notification.
  final bg = ng.NativeGeofenceBackgroundManager.instance;
  var promoted = false;
  try {
    await bg.promoteToForeground();
    promoted = true;
  } catch (_) {
    // Promotion may be unavailable (older OS, iOS); proceed regardless.
  }

  final db = AppDatabase();
  try {
    // This isolate never builds the UI, so nothing else would tell it which
    // language the user reads; without this its notifications would follow the
    // device language and contradict the app.
    final settingsRepo = DriftSettingsRepository(db);
    setPreferredLanguage((await settingsRepo.get()).localeCode);

    final handle = HandleBoundaryTransition(
      places: DriftQuietPlaceRepository(db),
      engagements: DriftEngagementRepository(db),
      settings: settingsRepo,
      tripLog: DriftTripLogRepository(db),
      ringer: createRingerController(),
      announcer: NotificationAnnouncer(NotificationService()),
      deviceClock: const NativeDeviceClock(),
    );

    final transition = _mapTransition(params.event);
    final now = DateTime.now();
    for (final geofence in params.geofences) {
      await handle(QuietPlaceTransitionEvent(
        placeId: geofence.id,
        transition: transition,
        occurredAt: now,
      ));
    }
  } finally {
    await db.close();
    if (promoted) {
      try {
        await bg.demoteToBackground();
      } catch (_) {}
    }
  }
}

BoundaryTransition _mapTransition(ng.GeofenceEvent event) {
  switch (event) {
    case ng.GeofenceEvent.enter:
      return BoundaryTransition.enter;
    case ng.GeofenceEvent.exit:
      return BoundaryTransition.exit;
    case ng.GeofenceEvent.dwell:
      return BoundaryTransition.dwell;
  }
}
