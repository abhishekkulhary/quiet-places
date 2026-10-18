import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/app_settings.dart';
import 'package:quiet_places/domain/entities/place_distance.dart';
import 'package:quiet_places/l10n/app_localizations.dart';
import 'package:quiet_places/presentation/distance_format.dart';

void main() {
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  PlaceDistance at(double signedEdge, {double? accuracy = 8}) => PlaceDistance(
        placeId: 'a',
        centreMeters: signedEdge + 150,
        signedEdgeMeters: signedEdge,
        accuracyMeters: accuracy,
      );

  group('metric', () {
    final f = DistanceFormat(units: UnitSystem.metric, localeName: 'en');

    test('metres below a kilometre', () {
      expect(f.format(85), '85 m');
      expect(f.format(999), '999 m');
    });

    test('one decimal kilometre above', () {
      expect(f.format(1000), '1.0 km');
      expect(f.format(1449), '1.4 km');
    });
  });

  group('imperial', () {
    final f = DistanceFormat(units: UnitSystem.imperial, localeName: 'en');

    test('converts metres to feet', () {
      // 100 m is ~328 ft, bucketed to the nearest 25 above 300 ft.
      expect(f.format(100), '325 ft');
    });

    test('short distances bucket to the nearest 10 ft', () {
      // 30 m is ~98.4 ft.
      expect(f.format(30), '100 ft');
    });

    test('switches to miles past 1000 ft', () {
      final miles = f.format(1609.34); // one mile
      expect(miles, endsWith(' mi'));
      expect(miles, startsWith('1.0'));
    });
  });

  group('locale-aware separators', () {
    test('German uses a comma as the decimal separator', () {
      final de = DistanceFormat(units: UnitSystem.metric, localeName: 'de');
      expect(de.format(1449), '1,4 km');
    });

    test('English uses a full stop', () {
      final en = DistanceFormat(units: UnitSystem.metric, localeName: 'en');
      expect(en.format(1449), '1.4 km');
    });
  });

  group('display model', () {
    PlaceDistanceDisplay build(PlaceDistance d,
            {UnitSystem units = UnitSystem.metric}) =>
        PlaceDistanceDisplay.from(d, l: l, units: units, localeName: 'en');

    test('outside reads as distance to the edge', () {
      expect(build(at(87)).detail, '85 m to edge');
    });

    test('inside reads as how far inside', () {
      expect(build(at(-42)).detail, 'inside by 40 m');
    });

    test('respects the imperial preference', () {
      final d = build(at(-42), units: UnitSystem.imperial);
      expect(d.detail, contains('ft'));
      expect(d.detail, startsWith('inside by'));
    });

    test('no position says so explicitly, never 0 m', () {
      final d = build(const PlaceDistance.unknown('a'));
      expect(d.detail, 'Distance unavailable');
      expect(d.centre, isNull);
      expect(d.confidence, DistanceConfidence.unknown);
    });

    test('equality is over displayed text, so noise does not rebuild a card',
        () {
      // 81 m and 82 m both round to 80 m.
      expect(build(at(81)), equals(build(at(82))));
      expect(build(at(81)), isNot(equals(build(at(120)))));
    });

    test('accuracy is formatted in the chosen units too', () {
      expect(build(at(200, accuracy: 12)).accuracy, '±12 m');
      expect(build(at(200, accuracy: 12), units: UnitSystem.imperial).accuracy,
          contains('ft'));
    });
  });
}
