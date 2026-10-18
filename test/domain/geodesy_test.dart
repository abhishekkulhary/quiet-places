import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/usecases/geodesy.dart';

/// Fixtures are published WGS-84 geodesic values, so this tests the maths
/// rather than testing the implementation against itself.
void main() {
  group('known-good published fixtures', () {
    test('Flinders Peak to Buninyong (Geoscience Australia benchmark)', () {
      // The canonical Vincenty test line, in its published DMS form:
      //   Flinders Peak  -37 57 03.72030 / 144 25 29.52440
      //   Buninyong      -37 39 10.15610 / 143 55 35.38390
      // Published geodesic distance: 54 972.271 m. Tolerance is 1 mm because
      // Vincenty's inverse is specified to about half a millimetre.
      double dms(int d, int m, double s) => d + m / 60 + s / 3600;
      final d = geodesicDistance(
        -dms(37, 57, 3.72030), dms(144, 25, 29.52440),
        -dms(37, 39, 10.15610), dms(143, 55, 35.38390),
      );
      expect(d, closeTo(54972.271, 0.001));
    });

    test('one degree of latitude at the equator is 110 574.389 m', () {
      expect(geodesicDistance(0, 0, 1, 0), closeTo(110574.389, 0.05));
    });

    test('one degree of longitude at the equator is 111 319.491 m', () {
      expect(geodesicDistance(0, 0, 0, 1), closeTo(111319.491, 0.05));
    });

    test('equator to pole (quarter meridian) is 10 001 965.729 m', () {
      expect(geodesicDistance(0, 0, 90, 0), closeTo(10001965.729, 1.0));
    });

    test('Pythagoras on raw lat/lng degrees is wildly wrong', () {
      // The specific mistake the brief warns against. Note the honest nuance:
      // an equirectangular approximation that *does* apply cos(latitude) is
      // only ~67 m out over this 344 km line, so it is not the villain. The
      // real error is treating a degree of longitude as a degree of latitude,
      // which at this latitude overstates east-west distance by ~1.5x.
      const lat1 = 51.5074, lon1 = -0.1278; // London
      const lat2 = 48.8566, lon2 = 2.3522; // Paris

      final geodesic = geodesicDistance(lat1, lon1, lat2, lon2);

      const metresPerDegree = 111320.0;
      final dxNaive = (lon2 - lon1) * metresPerDegree; // no cos(lat) — the bug
      final dy = (lat2 - lat1) * metresPerDegree;
      final naive = math.sqrt(dxNaive * dxNaive + dy * dy);

      expect((geodesic - naive).abs(), greaterThan(20000),
          reason: 'uncorrected degree maths must not pass for a distance');
      expect(geodesic / 1000, closeTo(344, 5));
    });
  });

  group('degenerate and edge cases', () {
    test('identical points are exactly zero', () {
      expect(geodesicDistance(51.5, -0.12, 51.5, -0.12), 0);
      expect(geodesicDistance(0, 0, 0, 0), 0);
      expect(geodesicDistance(90, 0, 90, 0), 0);
    });

    test('is symmetric', () {
      final a = geodesicDistance(10, 20, -30, 140);
      final b = geodesicDistance(-30, 140, 10, 20);
      expect(a, closeTo(b, 1e-6));
    });

    test('crossing the antimeridian measures the short way', () {
      // 179.9E to 179.9W is 0.2 degrees apart, not 359.8.
      final d = geodesicDistance(0, 179.9, 0, -179.9);
      expect(d, closeTo(111319.491 * 0.2, 5));
    });

    test('longitude wrapping is consistent either side of the dateline', () {
      final east = geodesicDistance(10, 179.0, 10, -179.0);
      final west = geodesicDistance(10, -179.0, 10, 179.0);
      expect(east, closeTo(west, 1e-6));
      // 2 degrees of longitude at latitude 10, well under 250 km.
      expect(east, lessThan(250000));
    });

    test('both poles: pole to pole is half the meridian circumference', () {
      final d = geodesicDistance(90, 0, -90, 0);
      expect(d, closeTo(20003931.5, 50));
    });

    test('longitude is irrelevant at the poles', () {
      // Same physical point expressed with different longitudes.
      expect(geodesicDistance(90, 0, 90, 137), closeTo(0, 0.01));
      expect(geodesicDistance(-90, -20, -90, 95), closeTo(0, 0.01));
    });

    test('near-antipodal pairs return a sane number, not NaN', () {
      // Vincenty famously fails to converge here; the fallback must hold.
      final d = geodesicDistance(0, 0, 0.5, 179.5);
      expect(d.isFinite, isTrue);
      expect(d.isNaN, isFalse);
      expect(d, greaterThan(19000000));
      expect(d, lessThan(20100000));
    });

    test('exactly antipodal returns a finite half-circumference', () {
      final d = geodesicDistance(0, 0, 0, 180);
      expect(d.isFinite, isTrue);
      expect(d, greaterThan(19900000));
      expect(d, lessThan(20100000));
    });
  });

  group('short distances (the range that actually matters here)', () {
    test('a few metres resolves accurately', () {
      // ~11.1 m north at the equator.
      expect(geodesicDistance(0, 0, 0.0001, 0), closeTo(11.06, 0.05));
    });

    test('typical Quiet Place scale', () {
      // 0.001 degrees of latitude is ~111 m anywhere.
      expect(geodesicDistance(51.5, -0.12, 51.501, -0.12), closeTo(111.2, 0.5));
    });

    test('distance grows monotonically as you walk away', () {
      var previous = 0.0;
      for (var i = 1; i <= 20; i++) {
        final d = geodesicDistance(51.5, -0.12, 51.5 + i * 0.0005, -0.12);
        expect(d, greaterThan(previous));
        previous = d;
      }
    });
  });
}
