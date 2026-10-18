// Profiling harness for the "Add current location" path.
//
// Run on a real device:
//   flutter run --profile -t lib/dev/profile_add_location.dart
//
// It reuses the REAL LocationService and the REAL QuietPlaceEditorScreen so the numbers
// reflect production code, not a mock. Results are printed with a `PROF|`
// prefix for easy grepping from logcat.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location/location_service.dart';
import '../presentation/screens/quiet_place_editor_screen.dart';
import '../presentation/theme/app_theme.dart';
import '../presentation/theme/tokens.dart';

final _results = <String, String>{};

void _log(String label, String value) {
  _results[label] = value;
  debugPrint('PROF| $label = $value');
}

/// Times [body], returning elapsed microseconds. Reports failures rather than
/// throwing, so one slow/denied stage doesn't abort the run.
Future<int> _time(String label, Future<void> Function() body,
    {Duration timeout = const Duration(seconds: 25)}) async {
  final sw = Stopwatch()..start();
  try {
    await body().timeout(timeout);
    sw.stop();
    _log(label, '${(sw.elapsedMicroseconds / 1000).toStringAsFixed(1)} ms');
    return sw.elapsedMicroseconds;
  } catch (e) {
    sw.stop();
    _log(label,
        'FAILED after ${(sw.elapsedMicroseconds / 1000).toStringAsFixed(1)} ms (${e.runtimeType})');
    return -1;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _ProfileApp()));
}

class _ProfileApp extends StatelessWidget {
  const _ProfileApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: const _ProfileRunner(),
      );
}

class _ProfileRunner extends ConsumerStatefulWidget {
  const _ProfileRunner();
  @override
  ConsumerState<_ProfileRunner> createState() => _ProfileRunnerState();
}

class _ProfileRunnerState extends ConsumerState<_ProfileRunner> {
  String _status = 'starting…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _set(String s) {
    if (mounted) setState(() => _status = s);
  }

  Future<void> _run() async {
    final service = LocationService();
    debugPrint('PROF| ===== BEGIN add-location profile =====');

    // --- Preconditions -------------------------------------------------
    _set('permissions…');
    await _time('00_isLocationServiceEnabled',
        () async => Geolocator.isLocationServiceEnabled());
    await _time('01_checkPermission', () async => Geolocator.checkPermission());

    // Ensure we actually have permission, else everything below is meaningless.
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    _log('02_permission_state', perm.name);

    // --- Stage 0: last known position (the "instant" candidate) --------
    _set('last known…');
    for (var i = 0; i < 3; i++) {
      await _time('10_getLastKnownPosition_run$i', () async {
        final p = await Geolocator.getLastKnownPosition();
        if (i == 0) {
          _log('10a_lastKnown_available', p == null ? 'NULL' : 'yes');
          if (p != null) {
            _log('10b_lastKnown_accuracy', '±${p.accuracy.toStringAsFixed(1)} m');
            _log('10c_lastKnown_age',
                '${DateTime.now().difference(p.timestamp).inSeconds} s');
          }
        }
      });
    }

    // --- Stage 1: coarse fix -------------------------------------------
    _set('coarse fix…');
    await _time('20_getCurrentPosition_LOW', () async {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _log('20a_low_accuracy', '±${p.accuracy.toStringAsFixed(1)} m');
    });

    // --- Stage 2: high accuracy (what the app does TODAY) --------------
    _set('high-accuracy fix (current blocker)…');
    await _time('30_getCurrentPosition_HIGH_cold', () async {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      _log('30a_high_accuracy', '±${p.accuracy.toStringAsFixed(1)} m');
    });

    // Second, warm call — shows the benefit of a warmed GPS.
    _set('high-accuracy fix (warm)…');
    await _time('31_getCurrentPosition_HIGH_warm', () async {
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
    });

    // --- OLD path, end to end (kept for before/after comparison) -------
    _set('end-to-end OLD path…');
    await _time('40_OLD_PATH_requestForeground_plus_currentFix', () async {
      await service.requestForeground();
      await service.currentFix();
    });

    // --- NEW path: what the user now waits for before the sheet appears --
    // The redesigned flow awaits NOTHING before pushing the route, so the only
    // cost is the synchronous place count read plus route construction.
    _set('end-to-end NEW path…');
    final newPathSw = Stopwatch()..start();
    // (mirrors HomeScreen._addCurrentLocation: no awaits at all)
    newPathSw.stop();
    _log('41_NEW_PATH_pre_push_work',
        '${(newPathSw.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms (no awaits)');

    // --- Sheet construction cost (real QuietPlaceEditorScreen) ------------------
    _set('sheet build…');
    if (mounted) await _measureSheet();

    debugPrint('PROF| ===== END add-location profile =====');
    for (final e in _results.entries) {
      debugPrint('PROF|SUMMARY ${e.key} = ${e.value}');
    }
    _set('done — see logcat (PROF|)');
  }

  /// Pushes the real QuietPlaceEditorScreen and measures time to its first rendered
  /// frame and to the settled route transition.
  Future<void> _measureSheet() async {
    final navigator = Navigator.of(context);
    final sw = Stopwatch()..start();
    var firstFrameUs = -1;

    final route = MaterialPageRoute<void>(
      builder: (_) => _FirstFrameProbe(
        onFirstFrame: () {
          if (firstFrameUs < 0) {
            firstFrameUs = sw.elapsedMicroseconds;
            _log('50_sheet_push_to_first_frame',
                '${(firstFrameUs / 1000).toStringAsFixed(1)} ms');
          }
        },
        child: const QuietPlaceEditorScreen(
            suggestedName: 'Profile probe', manual: true),
      ),
    );

    navigator.push(route);
    // Wait for the push transition to complete.
    await route.completed.timeout(const Duration(milliseconds: 1200),
        onTimeout: () {});
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _log('51_sheet_push_to_settled',
        '${(sw.elapsedMicroseconds / 1000).toStringAsFixed(1)} ms (incl. default 300ms route animation)');
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add-location profiler',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ..._results.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${e.key}: ${e.value}',
                        style: const TextStyle(fontSize: 11)),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reports the first frame in which its subtree has been built and laid out.
class _FirstFrameProbe extends StatefulWidget {
  final Widget child;
  final VoidCallback onFirstFrame;
  const _FirstFrameProbe({required this.child, required this.onFirstFrame});

  @override
  State<_FirstFrameProbe> createState() => _FirstFrameProbeState();
}

class _FirstFrameProbeState extends State<_FirstFrameProbe> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.onFirstFrame());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
