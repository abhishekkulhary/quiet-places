import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/quiet_place.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/domain/usecases/detect_overlap.dart';

QuietPlace place(
  String id, {
  required double lat,
  required double lon,
  double radius = 150,
  QuietPlaceBehaviour behaviour = QuietPlaceBehaviour.silent,
  bool enabled = true,
}) =>
    QuietPlace(
      id: id,
      name: 'Place $id',
      latitude: lat,
      longitude: lon,
      radiusMeters: radius,
      behaviour: behaviour,
      enabled: enabled,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  const lat = 51.5;
  const lon = -0.12;

  // 0.001 degrees of latitude is ~111 m.
  const near = 51.501; // ~111 m away
  const far = 51.51; // ~1110 m away

  group('detectOverlaps', () {
    test('finds a place whose circle intersects', () {
      final result = detectOverlaps(
        latitude: lat,
        longitude: lon,
        radiusMeters: 150,
        behaviour: QuietPlaceBehaviour.silent,
        others: [place('other', lat: near, lon: lon, radius: 150)],
      );
      expect(result, hasLength(1));
      expect(result.single.other.id, 'other');
      expect(result.single.centreSeparationMeters, closeTo(111, 2));
    });

    test('ignores places that are comfortably clear', () {
      final result = detectOverlaps(
        latitude: lat,
        longitude: lon,
        radiusMeters: 150,
        behaviour: QuietPlaceBehaviour.silent,
        others: [place('other', lat: far, lon: lon, radius: 150)],
      );
      expect(result, isEmpty);
    });

    test('circles that merely touch do not count as overlapping', () {
      // Separation exactly equals the sum of radii.
      final result = detectOverlaps(
        latitude: 0,
        longitude: 0,
        radiusMeters: 100,
        behaviour: QuietPlaceBehaviour.silent,
        others: [
          // ~111.32 m east at the equator, radii 100 + 11.32 would just touch;
          // use a clearly non-overlapping pair instead.
          place('other', lat: 0, lon: 0.002, radius: 100),
        ],
      );
      expect(result, isEmpty);
    });

    test('never reports the place being edited against itself', () {
      final result = detectOverlaps(
        latitude: lat,
        longitude: lon,
        radiusMeters: 150,
        behaviour: QuietPlaceBehaviour.silent,
        editingId: 'me',
        others: [place('me', lat: lat, lon: lon, radius: 150)],
      );
      expect(result, isEmpty);
    });

    test('disabled places cannot win, so they are not warned about', () {
      final result = detectOverlaps(
        latitude: lat,
        longitude: lon,
        radiusMeters: 150,
        behaviour: QuietPlaceBehaviour.silent,
        others: [
          place('off',
              lat: near,
              lon: lon,
              behaviour: QuietPlaceBehaviour.dnd,
              enabled: false),
        ],
      );
      expect(result, isEmpty);
    });
  });

  group('who wins, consistent with the engine', () {
    test('a stricter neighbour overrides the place being edited', () {
      final result = detectOverlaps(
        latitude: lat,
        longitude: lon,
        radiusMeters: 150,
        behaviour: QuietPlaceBehaviour.vibrate,
        others: [
          place('strict',
              lat: near, lon: lon, behaviour: QuietPlaceBehaviour.dnd),
        ],
      );
      expect(result.single.winner, QuietPlaceBehaviour.dnd);
      expect(result.single.otherWins, isTrue);
    });

    test('a laxer neighbour does not override', () {
      final result = detectOverlaps(
        latitude: lat,
        longitude: lon,
        radiusMeters: 150,
        behaviour: QuietPlaceBehaviour.dnd,
        others: [
          place('lax',
              lat: near, lon: lon, behaviour: QuietPlaceBehaviour.vibrate),
        ],
      );
      expect(result.single.winner, QuietPlaceBehaviour.dnd);
      expect(result.single.otherWins, isFalse);
    });

    test('an equal neighbour changes nothing for the user', () {
      final result = detectOverlaps(
        latitude: lat,
        longitude: lon,
        radiusMeters: 150,
        behaviour: QuietPlaceBehaviour.silent,
        others: [
          place('same',
              lat: near, lon: lon, behaviour: QuietPlaceBehaviour.silent),
        ],
      );
      expect(result.single.otherWins, isFalse);
    });
  });

  test('overlaps are ordered nearest first', () {
    final result = detectOverlaps(
      latitude: lat,
      longitude: lon,
      radiusMeters: 400,
      behaviour: QuietPlaceBehaviour.silent,
      others: [
        place('mid', lat: 51.5018, lon: lon, radius: 150),
        place('closest', lat: 51.5003, lon: lon, radius: 150),
      ],
    );
    expect(result.map((o) => o.other.id).toList(), ['closest', 'mid']);
  });
}
