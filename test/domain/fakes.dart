import 'package:quiet_places/domain/entities/app_settings.dart';
import 'package:quiet_places/domain/entities/engagement.dart';
import 'package:quiet_places/domain/entities/ringer_mode.dart';
import 'package:quiet_places/domain/entities/trip_log_entry.dart';
import 'package:quiet_places/domain/entities/quiet_place.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/domain/repositories/settings_repository.dart';
import 'package:quiet_places/domain/repositories/trip_log_repository.dart';
import 'package:quiet_places/domain/repositories/quiet_place_repository.dart';
import 'package:quiet_places/domain/services/device_clock.dart';
import 'package:quiet_places/domain/services/ringer_controller.dart';

/// A fully in-memory ringer that mirrors [expectedStateAfter], so applying a
/// behaviour then capturing yields exactly what the engine predicts. Tests can
/// mutate [state] directly to simulate the user changing the ringer by hand.
class FakeRinger implements RingerController {
  CapturedRingerState state;
  @override
  bool isSupported;
  @override
  bool postsNotificationOnApply;
  bool dndGranted;

  final List<String> calls = [];

  FakeRinger({
    this.state = const CapturedRingerState(
      ringerMode: RingerMode.normal,
      dndEnabled: false,
    ),
    this.isSupported = true,
    this.postsNotificationOnApply = false,
    this.dndGranted = true,
  });

  @override
  String get unsupportedReason => 'fake unsupported';

  @override
  Future<CapturedRingerState> capture() async => state;

  @override
  Future<bool> isDndAccessGranted() async => dndGranted;

  @override
  Future<void> requestDndAccess() async {}

  /// When true, the fake reproduces real Android behaviour: turning DND on
  /// also makes the ringer read back as silent. This is what broke
  /// override-detection on a real device.
  bool dndForcesSilentRead = false;

  @override
  Future<void> applyState(CapturedRingerState target) async {
    calls.add('applyState:${target.signature}');
    state = dndForcesSilentRead && target.dndEnabled
        ? target.copyWith(ringerMode: RingerMode.silent)
        : target;
  }

  @override
  Future<void> notifyUnsupportedEntry(QuietPlace place) async {
    calls.add('notify:${place.id}');
  }
}

class FakeQuietPlaceRepository implements QuietPlaceRepository {
  final Map<String, QuietPlace> _zones = {};

  FakeQuietPlaceRepository([List<QuietPlace> initial = const []]) {
    for (final z in initial) {
      _zones[z.id] = z;
    }
  }

  @override
  Future<List<QuietPlace>> getAll() async => _zones.values.toList();

  @override
  Future<List<QuietPlace>> getEnabled() async =>
      _zones.values.where((z) => z.enabled).toList();

  @override
  Future<QuietPlace?> getById(String id) async => _zones[id];

  @override
  Future<void> upsert(QuietPlace place) async => _zones[place.id] = place;

  @override
  Future<void> setEnabled(String id, bool enabled) async {
    final z = _zones[id];
    if (z != null) _zones[id] = z.copyWith(enabled: enabled);
  }

  @override
  Future<void> delete(String id) async => _zones.remove(id);

  @override
  Stream<List<QuietPlace>> watchAll() => Stream.value(_zones.values.toList());
}

class FakeEngagementRepository implements EngagementRepository {
  Engagement? _current;

  @override
  Future<Engagement?> get() async => _current;

  @override
  Future<void> save(Engagement engagement) async => _current = engagement;

  @override
  Future<void> clear() async => _current = null;
}

class FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings;

  FakeSettingsRepository([AppSettings? settings])
      : _settings = settings ?? AppSettings.defaults;

  @override
  Future<AppSettings> get() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;

  @override
  Stream<AppSettings> watch() => Stream.value(_settings);
}

class FakeTripLogRepository implements TripLogRepository {
  final List<TripLogEntry> entries = [];

  @override
  Future<void> add(TripLogEntry entry) async => entries.add(entry);

  @override
  Future<void> clear() async => entries.clear();

  @override
  Stream<List<TripLogEntry>> watchRecent({int limit = 200}) =>
      Stream.value(entries);

  TripLogEntry get last => entries.last;
}

/// Convenience builder for places in tests.
QuietPlace place(
  String id, {
  QuietPlaceBehaviour behaviour = QuietPlaceBehaviour.silent,
  bool enabled = true,
  double radius = 150,
}) {
  return QuietPlace(
    id: id,
    name: 'QuietPlace $id',
    latitude: 0,
    longitude: 0,
    radiusMeters: radius,
    behaviour: behaviour,
    enabled: enabled,
    createdAt: DateTime(2026, 1, 1),
  );
}

/// Lets a test pretend the device rebooted.
class FakeDeviceClock implements DeviceClock {
  DateTime? boot;
  FakeDeviceClock([this.boot]);

  @override
  Future<DateTime?> bootTime() async => boot;
}
