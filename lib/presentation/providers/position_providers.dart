import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location/geolocator_position_source.dart';
import '../../domain/entities/position_fix.dart';
import '../../domain/services/position_source.dart';
import '../../domain/usecases/resolve_position.dart';
import 'providers.dart';

final positionSourceProvider =
    Provider<PositionSource>((ref) => const GeolocatorPositionSource());

final resolvePositionProvider = Provider(
    (ref) => ResolvePosition(ref.watch(positionSourceProvider)));

/// Keeps a recent fix in hand while the app is foregrounded, so tapping "Add
/// current location" starts from a warm position instead of a cold acquisition.
///
/// Profiling on a mid-range device showed a cold `getCurrentPosition` taking
/// ~9.6 s, versus ~120 ms once the provider is warm — this listener is the main
/// reason the redesigned flow feels instant, more so than the staged ladder.
/// It stops on background to protect battery, and honours the user's setting.
class GpsWarmup extends StateNotifier<PositionFix?> with WidgetsBindingObserver {
  final PositionSource _source;
  StreamSubscription<PositionFix>? _sub;
  bool _enabled = true;

  GpsWarmup(this._source) : super(null) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Latest warm fix, if it is still fresh enough to seed the add-place flow.
  PositionFix? get seed {
    final fix = state;
    if (fix == null) return null;
    final age = DateTime.now().difference(fix.timestamp);
    return age > const Duration(minutes: 2) ? null : fix;
  }

  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    if (enabled) {
      start();
    } else {
      stop();
    }
  }

  Future<void> start() async {
    if (!_enabled || _sub != null) return;
    // Never prompt from here — warming is a background nicety, not a reason to
    // interrupt the user with a permission dialog.
    if (!await _source.isServiceEnabled()) return;
    try {
      _sub = _source.warmUp().listen(
        (fix) {
          if (shouldSupersede(state, fix) || state == null) state = fix;
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      // Warming is best-effort; failure must never affect the user flow.
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        start();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        stop();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stop();
    super.dispose();
  }
}

final gpsWarmupProvider =
    StateNotifierProvider<GpsWarmup, PositionFix?>((ref) {
  final warmup = GpsWarmup(ref.watch(positionSourceProvider));

  // Follow the user's setting reactively.
  ref.listen(settingsStreamProvider, (_, next) {
    final enabled = next.valueOrNull?.gpsWarmupEnabled ?? true;
    warmup.setEnabled(enabled);
  }, fireImmediately: true);

  ref.onDispose(warmup.stop);
  return warmup;
});
