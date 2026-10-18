import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/app_settings.dart';
import 'package:quiet_places/domain/entities/position_fix.dart';
import 'package:quiet_places/domain/entities/quiet_place.dart';
import 'package:quiet_places/domain/usecases/distance_tracking.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/presentation/providers/providers.dart';
import 'package:quiet_places/l10n/app_localizations.dart';
import 'package:quiet_places/domain/services/position_source.dart';
import 'package:quiet_places/presentation/providers/distance_providers.dart';
import 'package:quiet_places/presentation/providers/position_providers.dart';

/// A source that never produces anything, so the controller's own timers stay
/// out of the way and the test is only about watcher bookkeeping.
class SilentPositionSource implements PositionSource {
  /// When set, [watch] emits this immediately, so the controller has a fix and
  /// _recompute can actually reach the point where it writes state.
  PositionFix? emit;

  @override
  Future<PositionFix?> lastKnown() async => null;
  @override
  Future<PositionFix> coarse({required Duration timeout}) =>
      Future.error(StateError('none'));
  @override
  Future<PositionFix> precise({required Duration timeout}) =>
      Future.error(StateError('none'));
  @override
  Stream<PositionFix> warmUp() => const Stream.empty();
  @override
  Stream<PositionFix> watch({
    required Duration interval,
    required bool highAccuracy,
  }) =>
      emit == null ? const Stream.empty() : Stream.value(emit!);
  @override
  Future<bool> isServiceEnabled() async => true;
  @override
  Future<PositionFailure?> ensurePermission() async => null;
  @override
  Future<void> openAppSettings() async {}
  @override
  Future<void> openLocationSettings() async {}
}

/// Mirrors HomeScreen: pushes formatting into the controller from build().
class _Formatter extends ConsumerWidget {
  final UnitSystem units;
  final String localeName;
  const _Formatter({required this.units, required this.localeName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(liveDistanceProvider.notifier).setFormatting(
          l: L.of(context),
          units: units,
          localeName: localeName,
        );
    return const SizedBox.shrink();
  }
}

class _Card extends ConsumerStatefulWidget {
  const _Card();
  @override
  ConsumerState<_Card> createState() => _CardState();
}

class _CardState extends ConsumerState<_Card> with LiveDistanceWatcher {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  final source = SilentPositionSource()
    ..emit = PositionFix(
      latitude: 51.5,
      longitude: -0.12,
      accuracyMeters: 8,
      stage: FixStage.precise,
      timestamp: DateTime(2026, 8, 24),
    );
  final place = QuietPlace(
    id: 'p',
    name: 'Office',
    latitude: 51.5008,
    longitude: -0.12,
    radiusMeters: 150,
    behaviour: QuietPlaceBehaviour.silent,
    enabled: true,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget formatterHost({required UnitSystem units, required String localeName}) =>
      ProviderScope(
        overrides: [
          positionSourceProvider.overrideWithValue(source),
          placesStreamProvider.overrideWith((ref) => Stream.value([place])),
        ],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: Scaffold(
            body: Column(children: [
              const _Card(),
              _Formatter(units: units, localeName: localeName),
            ]),
          ),
        ),
      );

  Widget host(Widget child) => ProviderScope(
        overrides: [
          positionSourceProvider.overrideWithValue(SilentPositionSource()),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('setFormatting never writes state synchronously', (tester) async {
    // HomeScreen calls setFormatting from build(). It used to recompute --
    // and therefore write provider state -- inline, which Riverpod refuses
    // mid-build with "Tried to modify a provider while the widget tree was
    // building". It stayed hidden while nothing changed formatting after the
    // first frame, and appeared the moment a setting could: the language
    // picker, and equally the units toggle.
    await tester.pumpWidget(
        formatterHost(units: UnitSystem.metric, localeName: 'en'));
    await tester.pump(); // post-frame: the watcher registers
    await tester.pump(); // the fix arrives
    await tester.pump(DistanceTrackingPolicy.maxUiRefresh * 3);

    final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
        listen: false);
    final notifier = container.read(liveDistanceProvider.notifier);
    expect(container.read(liveDistanceProvider).byPlace, isNotEmpty,
        reason: 'the controller needs a fix and a place to recompute at all');

    final recomputesBefore = notifier.debugRecomputes;
    notifier.setFormatting(
      l: lookupL(const Locale('en')),
      units: UnitSystem.imperial,
      localeName: 'en',
    );

    // The inputs land at once, so whatever recomputes next uses them...
    expect(notifier.debugUnits, UnitSystem.imperial);
    // ...but the recompute itself must not run inline. Running it here is
    // precisely what wrote provider state mid-build.
    expect(notifier.debugRecomputes, recomputesBefore,
        reason: 'setFormatting is called from build(); recomputing there '
            'throws "Tried to modify a provider while the widget tree was '
            'building"');

    await tester.pump(Duration.zero);
    expect(notifier.debugRecomputes, greaterThan(recomputesBefore),
        reason: 'the deferred recompute must still happen');
  });

  testWidgets('replacing the whole route stack does not throw on dispose',
      (tester) async {
    // Tearing the stack down unmounts every card at once, and dispose() used
    // to call ref.read() during finalizeTree, which Riverpod refuses. Found via
    // a since-removed settings action, but the hazard belongs to any teardown
    // of a screen full of cards, so the case is still worth holding.
    await tester.pumpWidget(host(const _Card()));
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('setup'))),
      (route) => false,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('setup'), findsOneWidget);
  });

  testWidgets('a card disposed before its first frame leaves the count at zero',
      (tester) async {
    // addWatcher is deferred to a post-frame callback; a card that never gets
    // that frame must not remove a watcher it never added, or the stream stops
    // for every card still on screen.
    late ProviderContainer container;
    await tester.pumpWidget(host(Builder(builder: (context) {
      container = ProviderScope.containerOf(context);
      return const _Card();
    })));
    // Dispose before pumping the frame that would have run the callback.
    await tester.pumpWidget(host(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(container.read(liveDistanceProvider.notifier).debugWatchers, 0);
  });

  testWidgets('a normal mount then unmount balances out', (tester) async {
    await tester.pumpWidget(host(const _Card()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
        listen: false);
    expect(container.read(liveDistanceProvider.notifier).debugWatchers, 1);

    await tester.pumpWidget(host(const SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(container.read(liveDistanceProvider.notifier).debugWatchers, 0);
  });
}
