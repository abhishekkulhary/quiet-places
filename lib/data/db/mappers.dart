import 'package:drift/drift.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/engagement.dart';
import '../../domain/entities/boundary_transition.dart';
import '../../domain/entities/ringer_mode.dart';
import '../../domain/entities/trip_log_entry.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/entities/quiet_place_behaviour.dart';
import 'app_database.dart';

/// Mapping helpers between drift rows and domain entities. Enums are persisted
/// by index; these guards keep decoding total even if a row is corrupt.
extension QuietPlaceMapper on QuietPlace {
  QuietPlacesCompanion toCompanion() => QuietPlacesCompanion(
        id: Value(id),
        name: Value(name),
        latitude: Value(latitude),
        longitude: Value(longitude),
        radiusMeters: Value(radiusMeters),
        behaviour: Value(behaviour.index),
        enabled: Value(enabled),
        createdAtMs: Value(createdAt.millisecondsSinceEpoch),
      );
}

QuietPlace quietPlaceFrom(QuietPlaceRow row) => QuietPlace(
      id: row.id,
      name: row.name,
      latitude: row.latitude,
      longitude: row.longitude,
      radiusMeters: row.radiusMeters,
      behaviour: _behaviourFromIndex(row.behaviour),
      enabled: row.enabled,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
    );

TripLogEntry tripLogFrom(TripLogRow row) => TripLogEntry(
      id: row.id,
      placeId: row.placeId,
      placeName: row.placeName,
      transition: _transitionFromIndex(row.transition),
      action: _actionFromIndex(row.action),
      behaviour:
          row.behaviour == null ? null : _behaviourFromIndex(row.behaviour!),
      detail: row.detail,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row.timestampMs),
    );

TripLogsCompanion tripLogToCompanion(TripLogEntry e) => TripLogsCompanion(
      placeId: Value(e.placeId),
      placeName: Value(e.placeName),
      transition: Value(e.transition.index),
      action: Value(e.action.index),
      behaviour: Value(e.behaviour?.index),
      detail: Value(e.detail),
      timestampMs: Value(e.timestamp.millisecondsSinceEpoch),
    );

AppSettings settingsFrom(SettingsRow row) => AppSettings(
      globalPaused: row.globalPaused,
      snoozeUntil: row.snoozeUntilMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.snoozeUntilMs!),
      onboardingComplete: row.onboardingComplete,
      gpsWarmupEnabled: row.gpsWarmupEnabled,
      mapsEnabled: row.mapsEnabled,
      units: row.units == 1 ? UnitSystem.imperial : UnitSystem.metric,
      localeCode: row.localeCode,
    );

SettingsRowsCompanion settingsToCompanion(AppSettings s) => SettingsRowsCompanion(
      id: const Value(0),
      globalPaused: Value(s.globalPaused),
      snoozeUntilMs: Value(s.snoozeUntil?.millisecondsSinceEpoch),
      onboardingComplete: Value(s.onboardingComplete),
      gpsWarmupEnabled: Value(s.gpsWarmupEnabled),
      mapsEnabled: Value(s.mapsEnabled),
      units: Value(s.units.index),
      localeCode: Value(s.localeCode),
    );

Engagement engagementFrom(EngagementRow row) => Engagement(
      activePlaceIds: row.activePlaceIds.isEmpty
          ? <String>{}
          : row.activePlaceIds.split(',').toSet(),
      capturedState: CapturedRingerState(
        ringerMode: _ringerFromIndex(row.capturedRinger),
        dndEnabled: row.capturedDnd,
      ),
      appliedBehaviour: _behaviourFromIndex(row.appliedBehaviour),
      appliedState: CapturedRingerState(
        ringerMode: _ringerFromIndex(row.appliedRinger),
        dndEnabled: row.appliedDnd,
      ),
      overridden: row.overridden,
      bootTime: row.bootTimeMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.bootTimeMs!),
    );

EngagementRowsCompanion engagementToCompanion(Engagement e) =>
    EngagementRowsCompanion(
      id: const Value(0),
      activePlaceIds: Value(e.activePlaceIds.join(',')),
      capturedRinger: Value(e.capturedState.ringerMode.index),
      capturedDnd: Value(e.capturedState.dndEnabled),
      appliedBehaviour: Value(e.appliedBehaviour.index),
      appliedRinger: Value(e.appliedState.ringerMode.index),
      appliedDnd: Value(e.appliedState.dndEnabled),
      overridden: Value(e.overridden),
      bootTimeMs: Value(e.bootTime?.millisecondsSinceEpoch),
    );

QuietPlaceBehaviour _behaviourFromIndex(int i) =>
    (i >= 0 && i < QuietPlaceBehaviour.values.length)
        ? QuietPlaceBehaviour.values[i]
        : QuietPlaceBehaviour.silent;

RingerMode _ringerFromIndex(int i) => (i >= 0 && i < RingerMode.values.length)
    ? RingerMode.values[i]
    : RingerMode.unknown;

BoundaryTransition _transitionFromIndex(int i) =>
    (i >= 0 && i < BoundaryTransition.values.length)
        ? BoundaryTransition.values[i]
        : BoundaryTransition.enter;

TripAction _actionFromIndex(int i) => (i >= 0 && i < TripAction.values.length)
    ? TripAction.values[i]
    : TripAction.observed;
