import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/place_distance.dart';
import 'package:quiet_places/domain/entities/quiet_place.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/domain/usecases/distance_tracking.dart';

QuietPlace place(String id, {double radius = 150, double lat = 51.5, double lon = -0.12}) =>
    QuietPlace(
      id: id,
      name: 'Place $id',
      latitude: lat,
      longitude: lon,
      radiusMeters: radius,
      behaviour: QuietPlaceBehaviour.silent,
      enabled: true,
      createdAt: DateTime(2026, 1, 1),
    );

PlaceDistance at(double signedEdge, {double? accuracy, String id = 'a'}) =>
    PlaceDistance(
      placeId: id,
      centreMeters: signedEdge + 150,
      signedEdgeMeters: signedEdge,
      accuracyMeters: accuracy,
    );

void main() {
  group('signed edge distance', () {
    test('zero radius means the edge is the centre', () {
      final d = PlaceDistance.compute(
        place: place('a', radius: 0),
        fromLat: 51.501,
        fromLon: -0.12,
        accuracyMeters: 5,
      );
      expect(d.centreMeters, closeTo(111.2, 0.5));
      expect(d.signedEdgeMeters, closeTo(111.2, 0.5));
      expect(d.isInside, isFalse);
    });

    test('identical point is fully inside by the radius', () {
      final d = PlaceDistance.compute(
        place: place('a', radius: 150),
        fromLat: 51.5,
        fromLon: -0.12,
        accuracyMeters: 5,
      );
      expect(d.centreMeters, 0);
      expect(d.signedEdgeMeters, -150);
      expect(d.isInside, isTrue);
      expect(d.edgeMeters, 150);
    });

    test('exactly on the boundary counts as inside', () {
      final d = at(0, accuracy: 5);
      expect(d.side, BoundarySide.inside);
    });

    test('outside is positive, inside is negative', () {
      expect(at(40, accuracy: 5).side, BoundarySide.outside);
      expect(at(-40, accuracy: 5).side, BoundarySide.inside);
      expect(at(-40, accuracy: 5).edgeMeters, 40);
    });

    test('works across the antimeridian', () {
      final d = PlaceDistance.compute(
        place: place('a', radius: 100, lat: 0, lon: 179.9999),
        fromLat: 0,
        fromLon: -179.9999,
        accuracyMeters: 5,
      );
      // ~22 m apart, so comfortably inside a 100 m radius.
      expect(d.centreMeters, lessThan(50));
      expect(d.isInside, isTrue);
    });

    test('no position yields the unknown state, not a zero', () {
      final d = PlaceDistance.compute(
        place: place('a'),
        fromLat: null,
        fromLon: null,
        accuracyMeters: null,
      );
      expect(d.hasPosition, isFalse);
      expect(d.centreMeters, isNull);
      expect(d.signedEdgeMeters, isNull);
      expect(d.side, isNull);
      expect(d.confidence, DistanceConfidence.unknown);
    });
  });

  group('confidence', () {
    test('confident when well inside relative to accuracy', () {
      expect(at(-80, accuracy: 10).confidence, DistanceConfidence.confident);
    });

    test('uncertain when inside by less than the accuracy radius', () {
      // The brief's example: +-40 m accuracy, 30 m inside.
      expect(at(-30, accuracy: 40).confidence, DistanceConfidence.uncertain);
    });

    test('uncertain symmetrically when just outside', () {
      expect(at(25, accuracy: 40).confidence, DistanceConfidence.uncertain);
    });

    test('confident when far outside', () {
      expect(at(500, accuracy: 20).confidence, DistanceConfidence.confident);
    });

    test('a missing accuracy figure is never reported as confident', () {
      expect(at(-80).confidence, DistanceConfidence.uncertain);
      expect(at(-80, accuracy: 0).confidence, DistanceConfidence.uncertain);
    });
  });

  group('roundForDisplay', () {
    test('below 100 m rounds to the nearest 5', () {
      expect(roundForDisplay(82), 80);
      expect(roundForDisplay(83), 85);
      expect(roundForDisplay(97), 95);
    });

    test('100 m and above rounds to the nearest 10', () {
      expect(roundForDisplay(104), 100);
      expect(roundForDisplay(106), 110);
      expect(roundForDisplay(985), 990);
    });

    test('preserves sign so inside stays inside', () {
      expect(roundForDisplay(-42), -40);
      expect(roundForDisplay(-104), -100);
    });

    test('leaves kilometre-scale values exact for one-decimal formatting', () {
      expect(roundForDisplay(1449), 1449);
    });

    test('rounding is what stops the readout flickering', () {
      // 82..87 m of GPS noise must all present as one or two stable values.
      final shown = [82.0, 84.0, 86.0, 87.0].map(roundForDisplay).toSet();
      expect(shown.length, lessThanOrEqualTo(2));
    });
  });

  group('adaptive polling cadence', () {
    test('1 Hz when inside or within 2x the radius', () {
      expect(pollingIntervalFor(nearestEdgeMeters: -50, nearestRadiusMeters: 150),
          DistanceTrackingPolicy.nearInterval);
      expect(pollingIntervalFor(nearestEdgeMeters: 100, nearestRadiusMeters: 150),
          DistanceTrackingPolicy.nearInterval);
    });

    test('steps down to 10 s, then 60 s, as you get further away', () {
      expect(pollingIntervalFor(nearestEdgeMeters: 400, nearestRadiusMeters: 150),
          DistanceTrackingPolicy.midInterval);
      expect(pollingIntervalFor(nearestEdgeMeters: 3000, nearestRadiusMeters: 150),
          DistanceTrackingPolicy.farInterval);
    });

    test('stops polling entirely beyond the far range', () {
      expect(pollingIntervalFor(nearestEdgeMeters: 9000, nearestRadiusMeters: 150),
          isNull);
    });

    test('an unknown position does not sit at 1 Hz', () {
      final interval =
          pollingIntervalFor(nearestEdgeMeters: null, nearestRadiusMeters: null);
      expect(interval, isNot(DistanceTrackingPolicy.nearInterval));
    });
  });

  group('DistanceSmoother', () {
    test('damps small jitter while standing still', () {
      final s = DistanceSmoother();
      s.smooth(at(85));
      final out = s.smooth(at(91));
      // Pulled towards the new value, not snapped to it.
      expect(out.signedEdgeMeters, greaterThan(85));
      expect(out.signedEdgeMeters, lessThan(91));
    });

    test('converges towards a steady reading', () {
      final s = DistanceSmoother();
      s.smooth(at(100));
      late double last;
      for (var i = 0; i < 25; i++) {
        last = s.smooth(at(80)).signedEdgeMeters!;
      }
      expect(last, closeTo(80, 0.5));
    });

    test('adopts a large genuine movement immediately', () {
      final s = DistanceSmoother();
      s.smooth(at(50));
      final out = s.smooth(at(400));
      expect(out.signedEdgeMeters, 400);
    });

    test('unknown positions reset the filter', () {
      final s = DistanceSmoother();
      s.smooth(at(50));
      s.smooth(const PlaceDistance.unknown('a'));
      final out = s.smooth(at(300));
      expect(out.signedEdgeMeters, 300);
    });
  });

  group('reorder hysteresis', () {
    test('sorts by edge distance when there is no previous order', () {
      final order = orderWithHysteresis(
        previousOrder: const [],
        distances: {
          'far': at(500, id: 'far'),
          'near': at(10, id: 'near'),
          'mid': at(100, id: 'mid'),
        },
      );
      expect(order, ['near', 'mid', 'far']);
    });

    test('does not swap two places over noise-sized differences', () {
      // 'a' was first; 'b' is now nominally 5 m closer — well within noise.
      final order = orderWithHysteresis(
        previousOrder: const ['a', 'b'],
        distances: {'a': at(100, id: 'a'), 'b': at(95, id: 'b')},
      );
      expect(order, ['a', 'b']);
    });

    test('does swap once the difference is decisive', () {
      final order = orderWithHysteresis(
        previousOrder: const ['a', 'b'],
        distances: {'a': at(100, id: 'a'), 'b': at(40, id: 'b')},
      );
      expect(order, ['b', 'a']);
    });

    test('unknown distances sort last', () {
      final order = orderWithHysteresis(
        previousOrder: const [],
        distances: {
          'unknown': const PlaceDistance.unknown('unknown'),
          'known': at(300, id: 'known'),
        },
      );
      expect(order, ['known', 'unknown']);
    });

    test('order is stable across repeated identical input', () {
      var order = ['a', 'b', 'c'];
      final distances = {
        'a': at(100, id: 'a'),
        'b': at(105, id: 'b'),
        'c': at(110, id: 'c'),
      };
      for (var i = 0; i < 10; i++) {
        order = orderWithHysteresis(previousOrder: order, distances: distances);
      }
      expect(order, ['a', 'b', 'c']);
    });
  });
}
