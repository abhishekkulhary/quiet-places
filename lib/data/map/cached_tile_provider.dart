import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'tile_cache.dart';

/// The User-Agent sent with every tile request.
///
/// The OSM tile policy requires "a clear, unique User-Agent string that names
/// your app" and forbids using a library's generic default. This is that
/// string; changing it to something anonymous would put us out of compliance.
const String osmUserAgent =
    'QuietPlaces/1.0 (+https://github.com/abhishekkulhary/quiet-places; contact: https://github.com/abhishekkulhary/quiet-places/issues)';

/// Standard OSM raster tiles.
const String osmTileUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Minimum gap between outbound tile requests, so a fast pan cannot burst.
const Duration _minRequestGap = Duration(milliseconds: 60);

/// A [TileProvider] that serves from [TileCache] first and only reaches the
/// network for tiles it does not already hold.
///
/// Three obligations shape this class:
///  * **never re-fetch a tile we already have** (cache is checked first);
///  * **never prefetch** — there is deliberately no API to warm the cache, so
///    only tiles the user is actively viewing are ever requested;
///  * **rate-limit** outbound requests and identify ourselves honestly.
///
/// Offline, it falls back to any stale cached tile and otherwise yields a
/// transparent tile so the map degrades to a neutral grid rather than an error
/// wall.
class CachedOsmTileProvider extends TileProvider {
  final TileCache cache;

  /// Called the first time a tile has to fall back to cache or a blank tile,
  /// so the editor can say the map is offline rather than looking broken.
  final VoidCallback? onNetworkFailure;

  final http.Client _client;

  CachedOsmTileProvider({
    required this.cache,
    this.onNetworkFailure,
    http.Client? client,
  })
      : _client = client ?? http.Client(),
        // Deliberately NOT a const map: flutter_map mutates this to inject its
        // own User-Agent, and a const default throws "Cannot modify
        // unmodifiable map" at first paint. The header that actually goes on
        // the wire is set explicitly on each request in _load() below.
        super(headers: {'User-Agent': osmUserAgent});

  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _CachedTileImage(
      coordinates: coordinates,
      url: getTileUrl(coordinates, options),
      cache: cache,
      client: _client,
      onNetworkFailure: onNetworkFailure,
    );
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  /// Spaces outbound requests so panning cannot hammer the tile server.
  static Future<void> throttle() async {
    final since = DateTime.now().difference(_lastRequest);
    if (since < _minRequestGap) {
      await Future<void>.delayed(_minRequestGap - since);
    }
    _lastRequest = DateTime.now();
  }
}

@immutable
class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  final TileCoordinates coordinates;
  final String url;
  final TileCache cache;
  final http.Client client;
  final VoidCallback? onNetworkFailure;

  const _CachedTileImage({
    required this.coordinates,
    required this.url,
    required this.cache,
    required this.client,
    this.onNetworkFailure,
  });

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_CachedTileImage>(this);

  @override
  ImageStreamCompleter loadImage(
      _CachedTileImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode),
      scale: 1,
      debugLabel: key.url,
    );
  }

  Future<ui.Codec> _load(
      _CachedTileImage key, ImageDecoderCallback decode) async {
    final z = key.coordinates.z;
    final x = key.coordinates.x;
    final y = key.coordinates.y;

    // 1. A fresh cached tile is used as-is — never re-fetched.
    final cached = await key.cache.read(z, x, y);
    if (cached != null) {
      return decode(await ui.ImmutableBuffer.fromUint8List(
          Uint8List.fromList(cached)));
    }

    // 2. Otherwise fetch it, politely.
    try {
      await CachedOsmTileProvider.throttle();
      final response = await key.client
          .get(Uri.parse(key.url), headers: const {'User-Agent': osmUserAgent})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await key.cache.write(z, x, y, response.bodyBytes);
        final buffer =
            await ui.ImmutableBuffer.fromUint8List(response.bodyBytes);
        return await decode(buffer);
      }
    } catch (_) {
      // Fall through to the offline paths below.
    }
    key.onNetworkFailure?.call();

    // 3. Offline: a stale tile is far better than a hole.
    final stale = await key.cache.readStale(z, x, y);
    if (stale != null) {
      return decode(
          await ui.ImmutableBuffer.fromUint8List(Uint8List.fromList(stale)));
    }

    // 4. Nothing at all: a transparent tile, so the map shows the neutral grid
    //    painted underneath instead of an error.
    return decode(await ui.ImmutableBuffer.fromUint8List(_transparentPng));
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// 1x1 fully transparent PNG.
final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
