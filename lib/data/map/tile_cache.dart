import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// On-disk cache for map tiles.
///
/// Written by hand rather than pulling in a caching package because the OSM
/// tile policy has specific obligations we need to hold precisely:
///
///  * cache tiles for **at least 7 days**, so a tile is never re-fetched while
///    it is still valid;
///  * **never bulk download** — this cache is only ever filled by tiles the
///    user is actively viewing, and exposes no prefetch API;
///  * give the user a way to clear it (Settings), with a size cap so it cannot
///    grow without bound.
class TileCache {
  /// Policy minimum is 7 days; 30 is well within the spirit and cuts requests.
  static const Duration maxAge = Duration(days: 30);

  /// Total on-disk budget. Oldest tiles are evicted first past this.
  static const int maxBytes = 60 * 1024 * 1024;

  Directory? _dir;

  Future<Directory> _directory() async {
    final existing = _dir;
    if (existing != null) return existing;
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'map_tiles'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dir = dir;
    return dir;
  }

  File _fileFor(Directory dir, int z, int x, int y) =>
      File(p.join(dir.path, '${z}_${x}_$y.tile'));

  /// Returns cached bytes if present and still fresh, else null.
  Future<List<int>?> read(int z, int x, int y) async {
    try {
      final file = _fileFor(await _directory(), z, x, y);
      if (!file.existsSync()) return null;
      final age = DateTime.now().difference(file.lastModifiedSync());
      if (age > maxAge) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Returns cached bytes regardless of age — used when the network is
  /// unavailable, where a stale tile beats an empty grid.
  Future<List<int>?> readStale(int z, int x, int y) async {
    try {
      final file = _fileFor(await _directory(), z, x, y);
      return file.existsSync() ? await file.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(int z, int x, int y, List<int> bytes) async {
    try {
      final dir = await _directory();
      await _fileFor(dir, z, x, y).writeAsBytes(bytes, flush: false);
      await _enforceBudget(dir);
    } catch (_) {
      // A cache write failing must never break rendering.
    }
  }

  /// Evicts least-recently-modified tiles until the directory fits the budget.
  Future<void> _enforceBudget(Directory dir) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .map((f) => (file: f, stat: f.statSync()))
        .toList();

    var total = files.fold<int>(0, (sum, e) => sum + e.stat.size);
    if (total <= maxBytes) return;

    files.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    for (final entry in files) {
      if (total <= maxBytes) break;
      try {
        entry.file.deleteSync();
        total -= entry.stat.size;
      } catch (_) {}
    }
  }

  Future<int> sizeInBytes() async {
    try {
      final dir = await _directory();
      return dir
          .listSync()
          .whereType<File>()
          .fold<int>(0, (sum, f) => sum + f.statSync().size);
    } catch (_) {
      return 0;
    }
  }

  Future<void> clear() async {
    try {
      final dir = await _directory();
      for (final f in dir.listSync().whereType<File>()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }
}
