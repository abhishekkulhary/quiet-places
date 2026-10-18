import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Minimal, profile-mode-only instruments for the add-location path and the
/// frame budget.
///
/// Compiled out of release builds (`kProfileMode` is false there) and costs a
/// single boolean check otherwise. Kept in the tree so both numbers can be
/// re-measured whenever this code changes.
class PerfProbe {
  static Stopwatch? _tapToSheet;

  /// Called the instant the user taps "Add current location".
  static void markAddTapped() {
    if (!kProfileMode) return;
    _tapToSheet = Stopwatch()..start();
  }

  /// Called from the Quiet Place editor's first rendered frame.
  static void markSheetFirstFrame() {
    if (!kProfileMode) return;
    final sw = _tapToSheet;
    if (sw == null) return;
    sw.stop();
    debugPrint('PROF| tap_to_sheet_first_frame = '
        '${(sw.elapsedMicroseconds / 1000).toStringAsFixed(1)} ms');
    _tapToSheet = null;
  }

  // --- frame budget ------------------------------------------------------

  static final List<int> _build = [];
  static final List<int> _raster = [];
  static bool _listening = false;

  /// Starts collecting per-frame build/raster times from the engine. This is
  /// the authoritative source for the 60/120 fps bar — `dumpsys gfxinfo` does
  /// not see Flutter's pipeline.
  static void startFrameStats() {
    if (!kProfileMode || _listening) return;
    _listening = true;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        _build.add(t.buildDuration.inMicroseconds);
        _raster.add(t.rasterDuration.inMicroseconds);
      }
      if (_build.length >= 120) reportFrameStats();
    });
  }

  /// Prints p50/p95/worst for build and raster, plus how many frames exceeded
  /// the 60 fps (16.7 ms) and 120 fps (8.3 ms) budgets.
  static void reportFrameStats() {
    if (!kProfileMode || _build.isEmpty) return;
    final build = [..._build]..sort();
    final raster = [..._raster]..sort();
    String pct(List<int> xs, double p) =>
        (xs[(xs.length * p).clamp(0, xs.length - 1).toInt()] / 1000)
            .toStringAsFixed(1);

    final total = _build.length;
    var over60 = 0;
    var over120 = 0;
    for (var i = 0; i < total; i++) {
      final frame = _build[i] + _raster[i];
      if (frame > 16700) over60++;
      if (frame > 8300) over120++;
    }

    debugPrint('PROF|FRAMES n=$total '
        'build p50=${pct(build, 0.5)} p95=${pct(build, 0.95)} '
        'max=${(build.last / 1000).toStringAsFixed(1)} | '
        'raster p50=${pct(raster, 0.5)} p95=${pct(raster, 0.95)} '
        'max=${(raster.last / 1000).toStringAsFixed(1)} | '
        'over16.7ms=$over60 over8.3ms=$over120');
    _build.clear();
    _raster.clear();
  }
}
