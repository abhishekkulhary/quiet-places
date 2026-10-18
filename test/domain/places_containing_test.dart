import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/quiet_place.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/domain/usecases/geodesy.dart';
import 'package:quiet_places/domain/usecases/places_containing.dart';

QuietPlace place(
  String id, {
  required double lat,
  double lon = -0.12,
  double radius = 150,
  bool enabled = true,
}) =>
    QuietPlace(
      id: id,
      name: id,
      latitude: lat,
      longitude: lon,
      radiusMeters: radius,
      behaviour: QuietPlaceBehaviour.silent,
      enabled: enabled,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  const lat = 51.5;
  const lon = -0.12;

  test('finds the place you are standing in', () {
    final inside = placesContaining(
      latitude: lat,
      longitude: lon,
      places: [place('here', lat: lat)],
    );
    expect(inside.map((p) => p.id), ['here']);
  });

  test('excludes places you are outside', () {
    // ~1110 m away, radius 150.
    final inside = placesContaining(
      latitude: lat,
      longitude: lon,
      places: [place('far', lat: 51.51)],
    );
    expect(inside, isEmpty);
  });

  test('exactly on the boundary counts as inside, matching the readout', () {
    // Deriving the radius from the same function is the only way to land
    // exactly on the circle; a printed decimal loses low bits and reads as
    // outside.
    final exact = geodesicDistance(lat, lon, 51.501, lon);
    expect(
      placesContaining(
        latitude: lat,
        longitude: lon,
        places: [place('edge', lat: 51.501, radius: exact)],
      ).map((p) => p.id),
      ['edge'],
    );
    expect(
      placesContaining(
        latitude: lat,
        longitude: lon,
        places: [place('edge', lat: 51.501, radius: exact - 0.01)],
      ),
      isEmpty,
    );
  });

  test('ignores disabled places', () {
    final inside = placesContaining(
      latitude: lat,
      longitude: lon,
      places: [place('off', lat: lat, enabled: false)],
    );
    expect(inside, isEmpty);
  });

  test('returns every overlapping place, deepest first', () {
    final inside = placesContaining(
      latitude: lat,
      longitude: lon,
      places: [
        place('shallow', lat: lat, radius: 200), // 200 m of slack
        place('deep', lat: lat, radius: 900), // 900 m of slack
        place('elsewhere', lat: 51.6),
      ],
    );
    expect(inside.map((p) => p.id), ['deep', 'shallow']);
  });

  test('no places at all is not an error', () {
    expect(placesContaining(latitude: lat, longitude: lon, places: const []),
        isEmpty);
  });
}
