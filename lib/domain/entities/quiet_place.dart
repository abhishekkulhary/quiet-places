import 'quiet_place_behaviour.dart';

/// A saved circular location that triggers an automatic ringer change.
///
/// Pure value object — no persistence or plugin concerns. The `data` layer maps
/// this to/from drift rows and to `native_geofence` regions.
class QuietPlace {
  /// Stable identifier. Also used as the geofence region id, so it must be
  /// unique and non-empty.
  final String id;

  final String name;
  final double latitude;
  final double longitude;

  /// Radius in metres. Validated by `ValidateRadius` (50–1000 m).
  final double radiusMeters;

  final QuietPlaceBehaviour behaviour;

  /// When false, the place is retained but not monitored and never fires.
  final bool enabled;

  final DateTime createdAt;

  const QuietPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.behaviour,
    required this.enabled,
    required this.createdAt,
  });

  QuietPlace copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    QuietPlaceBehaviour? behaviour,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return QuietPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      behaviour: behaviour ?? this.behaviour,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QuietPlace &&
      other.id == id &&
      other.name == name &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.radiusMeters == radiusMeters &&
      other.behaviour == behaviour &&
      other.enabled == enabled &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        latitude,
        longitude,
        radiusMeters,
        behaviour,
        enabled,
        createdAt,
      );

  @override
  String toString() =>
      'QuietPlace($id, "$name", ${radiusMeters.round()}m, ${behaviour.name}, '
      'enabled: $enabled)';
}
