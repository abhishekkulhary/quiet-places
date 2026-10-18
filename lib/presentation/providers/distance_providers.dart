import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/place_distance.dart';
import '../../domain/entities/position_fix.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/services/position_source.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/distance_tracking.dart';
import '../../l10n/app_localizations.dart';
import '../distance_format.dart';
import 'position_providers.dart';
import 'providers.dart';

/// Everything the Quiet Places list needs to render live distances.
@immutable
class LiveDistances {
  /// Display models keyed by place id.
  final Map<String, PlaceDistanceDisplay> byPlace;

  /// Place ids in display order (nearest first, with hysteresis applied).
  final List<String> order;

  /// True when we have no usable position at all.
  final bool positionUnavailable;

  const LiveDistances({
    required this.byPlace,
    required this.order,
    required this.positionUnavailable,
  });

  static const empty = LiveDistances(
    byPlace: {},
    order: [],
    positionUnavailable: true,
  );
}

/// Computes live distances for every Quiet Place from **one** location
/// subscription.
///
/// Deliberately the only place in the app that subscribes for distance: cards
/// read derived state rather than each opening their own stream. The stream is
/// re-subscribed at a coarser cadence as the user moves away
/// (see [DistanceTrackingPolicy]), runs only while a screen asks for it, and
/// emits at most twice a second.
class LiveDistanceController extends StateNotifier<LiveDistances>
    with WidgetsBindingObserver {
  final PositionSource _source;
  final Ref _ref;

  StreamSubscription<PositionFix>? _sub;
  Timer? _idleTimer;

  /// Guarantees a refresh even when the OS stops emitting.
  ///
  /// Measured on a real device: while stationary, `getPositionStream` delivered
  /// exactly one fix in 40 seconds — the fused provider deduplicates unchanged
  /// positions, so `distanceFilter: 0` does not force periodic delivery. The
  /// stream alone therefore left the distance frozen at whatever the first fix
  /// said until the app was restarted. The stream is still used, because it is
  /// the cheapest way to get prompt updates *while moving*; this ticker is the
  /// floor that makes the documented cadence real.
  Timer? _ticker;

  /// Set while a polled fix is in flight, so a slow fix cannot pile up requests.
  bool _polling = false;

  Duration? _currentInterval;
  PositionFix? _latest;
  DateTime? _latestAt;

  /// One smoother per place, so each card's readout is filtered independently.
  final Map<String, DistanceSmoother> _smoothers = {};

  /// Localisations and unit preference, supplied by the screen that starts
  /// watching — the controller has no BuildContext of its own.
  L? _l;
  UnitSystem _units = UnitSystem.metric;
  String? _localeName;

  /// Raw (unsmoothed) distances. The geofence engine never reads these — they
  /// exist only to drive tier selection and the display pipeline.
  Map<String, PlaceDistance> _raw = {};

  List<String> _order = const [];
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _pendingEmit;

  /// How many screens currently want live distances.
  int _watchers = 0;

  LiveDistanceController(this._source, this._ref) : super(LiveDistances.empty) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Supplies the formatting context. Called by the watching screen on every
  /// build, so a locale or unit change is picked up immediately.
  ///
  /// The recompute is deferred to after the frame. This is called *from*
  /// `build`, and recomputing writes `state`, which Riverpod refuses mid-build
  /// with "Tried to modify a provider while the widget tree was building".
  /// It stayed hidden while formatting never changed after the first frame --
  /// the first call has nothing to recompute -- and surfaced the moment a
  /// setting could change it with places already on screen, which is true of
  /// both the language picker and the units toggle.
  void setFormatting({
    required L l,
    required UnitSystem units,
    String? localeName,
  }) {
    final changed = _units != units || _localeName != localeName || _l == null;
    _l = l;
    _units = units;
    _localeName = localeName;
    if (!changed) return;
    // Deferred to the event loop rather than a post-frame callback: a
    // post-frame callback only runs if a frame is actually scheduled, and the
    // recompute must happen even when nothing else marks the tree dirty.
    Future(() {
      if (mounted) _recompute();
    });
  }

  /// Called by a screen that wants live distances while it is visible.
  /// Exposed for tests: watcher bookkeeping has to stay balanced or the live
  /// stream stops for cards that are still on screen.
  @visibleForTesting
  int get debugWatchers => _watchers;

  /// Exposed for tests: [setFormatting] must record its inputs immediately even
  /// though it defers the recompute.
  @visibleForTesting
  UnitSystem get debugUnits => _units;

  /// Exposed for tests: counts recomputes so a caller can prove that
  /// [setFormatting] does not run one inline. Recomputing writes provider
  /// state, and setFormatting is called from build().
  @visibleForTesting
  int get debugRecomputes => _recomputes;
  int _recomputes = 0;

  void addWatcher() {
    _watchers++;
    if (_watchers == 1) _start();
  }

  void removeWatcher() {
    _watchers = (_watchers - 1).clamp(0, 1 << 30);
    if (_watchers == 0) _stop();
  }

  Future<void> _start() async {
    if (_sub != null || _watchers == 0) return;
    if (!await _source.isServiceEnabled()) {
      _markUnavailable();
      return;
    }
    // Never prompt from here: the list is a passive readout, not a place to
    // interrupt someone with a permission dialog.
    _subscribe(DistanceTrackingPolicy.nearInterval, highAccuracy: true);
  }

  void _subscribe(Duration interval, {required bool highAccuracy}) {
    _sub?.cancel();
    _idleTimer?.cancel();
    _idleTimer = null;
    _ticker?.cancel();
    _currentInterval = interval;

    _sub = _source
        .watch(interval: interval, highAccuracy: highAccuracy)
        .listen(_onFix, onError: (_) => _markUnavailable());

    // Poll at the same cadence, skipping the request whenever the stream has
    // already delivered something recent enough.
    _ticker = Timer.periodic(interval, (_) => _pollIfStale(interval, highAccuracy));
    _pollIfStale(interval, highAccuracy);
  }

  Future<void> _pollIfStale(Duration interval, bool highAccuracy) async {
    if (_polling || !mounted || _watchers == 0) return;

    final age = _latestAt == null
        ? null
        : DateTime.now().difference(_latestAt!);
    if (age != null && age < interval) return; // the stream is keeping up

    _polling = true;
    try {
      final fix = highAccuracy
          ? await _source.precise(timeout: interval * 4)
          : await _source.coarse(timeout: interval * 4);
      _onFix(fix);
    } catch (_) {
      // A missed poll is not worth surfacing; the next tick tries again.
    } finally {
      _polling = false;
    }
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
    _idleTimer?.cancel();
    _idleTimer = null;
    _pendingEmit?.cancel();
    _pendingEmit = null;
    _currentInterval = null;
  }

  void _markUnavailable() {
    _raw = {};
    _smoothers.clear();
    if (mounted) {
      state = LiveDistances(
        byPlace: {
          for (final p in _places())
            p.id: _display(PlaceDistance.unknown(p.id)),
        },
        order: _places().map((p) => p.id).toList(),
        positionUnavailable: true,
      );
    }
  }

  List<QuietPlace> _places() =>
      _ref.read(placesStreamProvider).valueOrNull ?? const [];

  void _onFix(PositionFix fix) {
    _latest = fix;
    _latestAt = DateTime.now();
    _recompute();
    _retierIfNeeded();
  }

  void _recompute() {
    _recomputes++;
    final fix = _latest;
    final places = _places();
    // Formatting context arrives from the screen; without it there is nothing
    // meaningful to render yet.
    if (fix == null || places.isEmpty || _l == null) return;

    final raw = <String, PlaceDistance>{};
    final display = <String, PlaceDistanceDisplay>{};

    for (final place in places) {
      final d = PlaceDistance.compute(
        place: place,
        fromLat: fix.latitude,
        fromLon: fix.longitude,
        accuracyMeters: fix.accuracyMeters,
      );
      raw[place.id] = d;
      final smoother = _smoothers.putIfAbsent(place.id, DistanceSmoother.new);
      display[place.id] = _display(smoother.smooth(d));
    }

    // Drop smoothers for places that no longer exist.
    _smoothers.removeWhere((id, _) => !raw.containsKey(id));

    _raw = raw;
    _order = orderWithHysteresis(previousOrder: _order, distances: raw);
    _emitThrottled(display);
  }

  PlaceDistanceDisplay _display(PlaceDistance d) => PlaceDistanceDisplay.from(
        d,
        l: _l!,
        units: _units,
        localeName: _localeName,
      );

  /// Coalesces updates to at most [DistanceTrackingPolicy.maxUiRefresh].
  void _emitThrottled(Map<String, PlaceDistanceDisplay> display) {
    final now = DateTime.now();
    final since = now.difference(_lastEmit);
    if (since >= DistanceTrackingPolicy.maxUiRefresh) {
      _lastEmit = now;
      _pendingEmit?.cancel();
      _pendingEmit = null;
      if (mounted) {
        state = LiveDistances(
          byPlace: display,
          order: List.unmodifiable(_order),
          positionUnavailable: false,
        );
      }
      return;
    }
    // Schedule the trailing edge so the final value is never dropped.
    _pendingEmit ??= Timer(
      DistanceTrackingPolicy.maxUiRefresh - since,
      () {
        _pendingEmit = null;
        _recompute();
      },
    );
  }

  /// Steps the stream up or down a tier as the nearest place changes distance.
  void _retierIfNeeded() {
    if (_raw.isEmpty) return;

    String? nearestId;
    double? nearestEdge;
    for (final entry in _raw.entries) {
      final edge = entry.value.signedEdgeMeters;
      if (edge == null) continue;
      if (nearestEdge == null || edge < nearestEdge) {
        nearestEdge = edge;
        nearestId = entry.key;
      }
    }
    if (nearestId == null) return;

    final radius = _places()
        .firstWhere((p) => p.id == nearestId,
            orElse: () => _places().first)
        .radiusMeters;

    final wanted = pollingIntervalFor(
      nearestEdgeMeters: nearestEdge,
      nearestRadiusMeters: radius,
    );

    if (wanted == null) {
      // Far from everything: stop the stream entirely and let OS geofencing do
      // its job, re-checking occasionally in case the user travels back.
      _sub?.cancel();
      _sub = null;
      _ticker?.cancel();
      _ticker = null;
      _currentInterval = null;
      // `??=` was wrong here: _subscribe cancels this timer without nulling it,
      // so a non-null cancelled timer meant the stream never came back.
      _idleTimer?.cancel();
      _idleTimer = Timer.periodic(
        DistanceTrackingPolicy.farInterval,
        (_) => _subscribe(DistanceTrackingPolicy.farInterval,
            highAccuracy: false),
      );
      return;
    }

    if (wanted != _currentInterval) {
      _subscribe(wanted,
          highAccuracy: wanted == DistanceTrackingPolicy.nearInterval);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_watchers > 0) _start();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Background behaviour is unchanged: geofence callbacks only.
        _stop();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }
}

final liveDistanceProvider =
    StateNotifierProvider<LiveDistanceController, LiveDistances>((ref) {
  return LiveDistanceController(ref.watch(positionSourceProvider), ref);
});

/// One place's display model. Cards watch this rather than the whole map, so a
/// card only rebuilds when its own visible text changes.
final placeDistanceProvider =
    Provider.family<PlaceDistanceDisplay?, String>((ref, placeId) {
  return ref.watch(
      liveDistanceProvider.select((state) => state.byPlace[placeId]));
});

/// Keeps the live stream running only while the widget using it is mounted.
mixin LiveDistanceWatcher<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Captured in [initState] rather than read in [dispose].
  ///
  /// dispose() runs inside `finalizeTree`, by which point Riverpod has already
  /// torn the element's `ref` down and throws "Cannot use ref after the widget
  /// was disposed". Holding the notifier is safe: [liveDistanceProvider] is not
  /// auto-disposed, so it outlives every card, and [removeWatcher] only cancels
  /// timers -- it never writes state.
  LiveDistanceController? _liveDistances;

  /// Whether [addWatcher] actually ran, so the two calls stay balanced.
  ///
  /// The add is deferred to after the first frame (it mutates provider state,
  /// which is illegal during build). A widget disposed before that frame --
  /// a card scrolled away instantly, or a route replaced under it -- would
  /// otherwise decrement a count it never incremented and stop the stream for
  /// every other card still on screen.
  bool _watching = false;

  @override
  void initState() {
    super.initState();
    _liveDistances = ref.read(liveDistanceProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _watching = true;
      _liveDistances?.addWatcher();
    });
  }

  @override
  void dispose() {
    if (_watching) _liveDistances?.removeWatcher();
    super.dispose();
  }
}
