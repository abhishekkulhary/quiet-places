import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../background/geofence_callback.dart';
import '../../data/db/app_database.dart';
import '../../data/device/native_device_clock.dart';
import '../../data/geofence/native_geofence_monitor.dart';
import '../../data/location/location_service.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/repositories/drift_settings_repository.dart';
import '../../data/repositories/drift_trip_log_repository.dart';
import '../../data/repositories/drift_quiet_place_repository.dart';
import '../../data/ringer/ringer_controller_factory.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/trip_log_entry.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/services/ringer_controller.dart';
import '../coordinator.dart';
import '../quiet_place_refiner.dart';
import 'position_providers.dart';

/// Riverpod owns the **UI isolate only**. The geofence background isolate builds
/// its own dependencies directly (see `background/geofence_callback.dart`) and
/// never touches these providers.

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final quietPlaceRepositoryProvider = Provider(
    (ref) => DriftQuietPlaceRepository(ref.watch(appDatabaseProvider)));

final tripLogRepositoryProvider = Provider(
    (ref) => DriftTripLogRepository(ref.watch(appDatabaseProvider)));

final settingsRepositoryProvider = Provider(
    (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)));

final engagementRepositoryProvider = Provider(
    (ref) => DriftEngagementRepository(ref.watch(appDatabaseProvider)));

final notificationServiceProvider = Provider((ref) => NotificationService());

final locationServiceProvider = Provider((ref) => LocationService());

final ringerControllerProvider = Provider<RingerController>((ref) {
  return createRingerController(
      notifications: ref.watch(notificationServiceProvider));
});

final geofenceEngineProvider =
    Provider((ref) => NativeGeofenceMonitor(geofenceCallback));

final coordinatorProvider = Provider<QuietPlaceCoordinator>((ref) {
  return QuietPlaceCoordinator(
    places: ref.watch(quietPlaceRepositoryProvider),
    engagements: ref.watch(engagementRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    tripLog: ref.watch(tripLogRepositoryProvider),
    ringer: ref.watch(ringerControllerProvider),
    engine: ref.watch(geofenceEngineProvider),
    announcer:
        NotificationAnnouncer(ref.watch(notificationServiceProvider)),
    deviceClock: const NativeDeviceClock(),
    positionSource: ref.watch(positionSourceProvider),
  );
});

/// Background refinement of a place saved on an approximate fix.
final quietPlaceRefinerProvider = Provider<QuietPlaceRefiner>((ref) {
  return QuietPlaceRefiner(
    resolve: ref.watch(resolvePositionProvider),
    coordinator: ref.watch(coordinatorProvider),
    places: ref.watch(quietPlaceRepositoryProvider),
  );
});

/// True where the device can actually change the ringer (Android).
final ringerSupportedProvider =
    Provider<bool>((ref) => ref.watch(ringerControllerProvider).isSupported);

final ringerUnsupportedReasonProvider = Provider<String>(
    (ref) => ref.watch(ringerControllerProvider).unsupportedReason);

// --- reactive streams (UI-isolate writes update live) ---

final placesStreamProvider = StreamProvider<List<QuietPlace>>(
    (ref) => ref.watch(quietPlaceRepositoryProvider).watchAll());

final settingsStreamProvider = StreamProvider<AppSettings>(
    (ref) => ref.watch(settingsRepositoryProvider).watch());

final tripLogStreamProvider = StreamProvider<List<TripLogEntry>>(
    (ref) => ref.watch(tripLogRepositoryProvider).watchRecent());
