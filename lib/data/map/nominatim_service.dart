import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cached_tile_provider.dart' show osmUserAgent;

/// One search result.
class PlaceSearchResult {
  final String displayName;

  /// Short label for the first line of the row.
  final String primary;
  final double latitude;
  final double longitude;

  const PlaceSearchResult({
    required this.displayName,
    required this.primary,
    required this.latitude,
    required this.longitude,
  });
}

/// Address search and reverse geocoding via the public Nominatim service.
///
/// The usage policy is strict and shapes this class more than the feature does:
///
///  * **No autocomplete.** The policy states outright that as-you-type search
///    "is not yet supported by Nominatim and you must not implement such a
///    service on the client side". So [search] is only ever called on an
///    explicit submit — there is deliberately no debounce-and-query-as-you-type
///    path, and adding one would get the app blocked.
///  * **At most 1 request per second across the whole app**, enforced by a
///    single global gate here rather than trusted to callers.
///  * **Cache results**; repeated identical queries are treated as faulty
///    behaviour. Both lookups are memoised.
///  * **Identify the app** with a real User-Agent; library defaults are banned.
///
/// Reverse geocoding is issued only when the user finishes moving the pin, and
/// keyed on coordinates rounded to ~11 m, so nudging the pin does not produce a
/// stream of systematic lookups (also a bannable pattern).
class NominatimService {
  static const String _base = 'https://nominatim.openstreetmap.org';
  static const Duration _minGap = Duration(seconds: 1);

  final http.Client _client;
  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  static Future<void>? _gate;

  final Map<String, List<PlaceSearchResult>> _searchCache = {};
  final Map<String, String?> _reverseCache = {};

  /// Serialises every outbound call and spaces them by at least one second.
  Future<void> _rateLimit() async {
    final previous = _gate;
    final completer = Completer<void>();
    _gate = completer.future;
    if (previous != null) await previous;

    final since = DateTime.now().difference(_lastRequest);
    if (since < _minGap) await Future<void>.delayed(_minGap - since);
    _lastRequest = DateTime.now();
    completer.complete();
  }

  /// Free-text search. Call only from an explicit user submit.
  Future<List<PlaceSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final cached = _searchCache[trimmed];
    if (cached != null) return cached;

    await _rateLimit();
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'q': trimmed,
      'format': 'jsonv2',
      'limit': '6',
      'addressdetails': '0',
    });

    try {
      final response = await _client
          .get(uri, headers: const {'User-Agent': osmUserAgent})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const [];

      final results = <PlaceSearchResult>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final lat = double.tryParse('${entry['lat']}');
        final lon = double.tryParse('${entry['lon']}');
        final name = '${entry['display_name'] ?? ''}';
        if (lat == null || lon == null || name.isEmpty) continue;
        results.add(PlaceSearchResult(
          displayName: name,
          primary: name.split(',').first.trim(),
          latitude: lat,
          longitude: lon,
        ));
      }
      _searchCache[trimmed] = results;
      return results;
    } catch (_) {
      return const [];
    }
  }

  /// A short human name for a coordinate, or null if none can be found.
  ///
  /// Call on gesture *end*, never continuously while dragging.
  Future<String?> reverseName(double latitude, double longitude) async {
    // ~4 decimal places is about 11 m: fine enough to be useful, coarse enough
    // that small pin nudges reuse the cached answer.
    final key = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(key)) return _reverseCache[key];

    await _rateLimit();
    final uri = Uri.parse('$_base/reverse').replace(queryParameters: {
      'lat': '$latitude',
      'lon': '$longitude',
      'format': 'jsonv2',
      'zoom': '18',
      'addressdetails': '1',
    });

    try {
      final response = await _client
          .get(uri, headers: const {'User-Agent': osmUserAgent})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        _reverseCache[key] = null;
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      final name = _bestName(decoded);
      _reverseCache[key] = name;
      return name;
    } catch (_) {
      return null;
    }
  }

  /// Prefers a specific feature name, then a street, then a locality — the
  /// order that produces a label someone would actually recognise.
  String? _bestName(Map<dynamic, dynamic> json) {
    final direct = '${json['name'] ?? ''}'.trim();
    if (direct.isNotEmpty) return direct;

    final address = json['address'];
    if (address is Map) {
      for (final key in const [
        'amenity',
        'building',
        'road',
        'neighbourhood',
        'suburb',
        'village',
        'town',
        'city',
      ]) {
        final value = '${address[key] ?? ''}'.trim();
        if (value.isNotEmpty) return value;
      }
    }

    final display = '${json['display_name'] ?? ''}'.trim();
    return display.isEmpty ? null : display.split(',').first.trim();
  }

  void dispose() => _client.close();
}
