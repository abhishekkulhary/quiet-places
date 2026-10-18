import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quiet_places/data/map/nominatim_service.dart';

/// Pins the obligations in Nominatim's usage policy, which are easy to break
/// accidentally and get an app blocked rather than throw an error.
void main() {
  late List<http.Request> requests;

  http.Client clientReturning(String body, {int status = 200}) {
    return MockClient((request) async {
      requests.add(request);
      return http.Response(body, status,
          headers: {'content-type': 'application/json'});
    });
  }

  setUp(() => requests = []);

  final searchBody = jsonEncode([
    {
      'lat': '50.9413',
      'lon': '6.9583',
      'display_name': 'Cathedral, Old Town, Cologne, Germany',
    },
    {
      'lat': '50.9430',
      'lon': '6.9590',
      'display_name': 'Central Station, Cologne, Germany',
    },
  ]);

  group('search', () {
    test('parses results into coordinates and a short label', () async {
      final service = NominatimService(client: clientReturning(searchBody));
      final results = await service.search('cologne cathedral');

      expect(results, hasLength(2));
      expect(results.first.primary, 'Cathedral');
      expect(results.first.displayName, contains('Cologne'));
      expect(results.first.latitude, closeTo(50.9413, 1e-6));
      expect(results.first.longitude, closeTo(6.9583, 1e-6));
    });

    test('sends a User-Agent naming the app, not a library default', () async {
      final service = NominatimService(client: clientReturning(searchBody));
      await service.search('anything');

      final ua = requests.single.headers['User-Agent'];
      expect(ua, isNotNull);
      expect(ua, contains('QuietPlaces'));
      expect(ua, contains('contact'));
    });

    test('identical queries are served from cache, not re-requested', () async {
      // The policy treats repeated identical queries as faulty behaviour.
      final service = NominatimService(client: clientReturning(searchBody));
      await service.search('cologne');
      await service.search('cologne');
      await service.search('cologne');

      expect(requests, hasLength(1));
    });

    test('an empty query never reaches the network', () async {
      final service = NominatimService(client: clientReturning(searchBody));
      expect(await service.search('   '), isEmpty);
      expect(requests, isEmpty);
    });

    test('a failed request degrades to no results rather than throwing',
        () async {
      final service =
          NominatimService(client: clientReturning('nope', status: 500));
      expect(await service.search('cologne'), isEmpty);
    });

    test('malformed entries are skipped, not crashed on', () async {
      final body = jsonEncode([
        {'lat': 'not-a-number', 'lon': '6.9', 'display_name': 'Bad'},
        {'lat': '50.9', 'lon': '6.9', 'display_name': 'Good'},
        {'lat': '50.9', 'lon': '6.9'}, // no name
      ]);
      final service = NominatimService(client: clientReturning(body));
      final results = await service.search('mixed');
      expect(results, hasLength(1));
      expect(results.single.primary, 'Good');
    });
  });

  group('reverse geocoding', () {
    final reverseBody = jsonEncode({
      'name': '',
      'display_name': 'Taubenweg, Hesselbach, Germany',
      'address': {'road': 'Taubenweg', 'village': 'Hesselbach'},
    });

    test('prefers the most specific available name', () async {
      final service = NominatimService(client: clientReturning(reverseBody));
      expect(await service.reverseName(51.0, 7.6), 'Taubenweg');
    });

    test('falls back through the address hierarchy', () async {
      final body = jsonEncode({
        'display_name': 'Somewhere, Cologne, Germany',
        'address': {'city': 'Cologne'},
      });
      final service = NominatimService(client: clientReturning(body));
      expect(await service.reverseName(51.0, 7.6), 'Cologne');
    });

    test('nearby coordinates reuse the cached answer', () async {
      // Keyed to ~11 m, so nudging the pin does not produce systematic
      // reverse lookups — a bannable pattern.
      final service = NominatimService(client: clientReturning(reverseBody));
      await service.reverseName(51.000000, 7.600000);
      await service.reverseName(51.000012, 7.600018); // ~2 m away
      expect(requests, hasLength(1));
    });

    test('a clearly different coordinate does issue a new lookup', () async {
      final service = NominatimService(client: clientReturning(reverseBody));
      await service.reverseName(51.0, 7.6);
      await service.reverseName(51.5, 7.9);
      expect(requests, hasLength(2));
    });

    test('failure returns null rather than throwing', () async {
      final service =
          NominatimService(client: clientReturning('', status: 429));
      expect(await service.reverseName(51.0, 7.6), isNull);
    });
  });

  group('rate limiting', () {
    test('successive distinct requests are spaced by at least a second',
        () async {
      final service = NominatimService(client: clientReturning(searchBody));

      final started = DateTime.now();
      await service.search('one');
      await service.search('two');
      final elapsed = DateTime.now().difference(started);

      expect(requests, hasLength(2));
      // The policy's absolute maximum is 1 request per second, app-wide.
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(900));
    });
  });
}
