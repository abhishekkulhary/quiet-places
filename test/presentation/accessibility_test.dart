import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/quiet_place.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/domain/entities/app_settings.dart';
import 'package:quiet_places/domain/entities/place_distance.dart';
import 'package:quiet_places/l10n/app_localizations.dart';
import 'package:quiet_places/presentation/distance_format.dart';
import 'package:quiet_places/presentation/theme/app_theme.dart';
import 'package:quiet_places/presentation/theme/tokens.dart';
import 'package:quiet_places/presentation/widgets/press.dart';
import 'package:quiet_places/presentation/widgets/quiet_place_card.dart';

/// Accessibility guarantees, asserted rather than claimed.
///
/// Flutter ships matchers for exactly what the brief demands — contrast,
/// tap-target size and labelling — so these run in CI instead of relying on a
/// manual audit.
Widget _host(
  Widget child, {
  ThemeData? theme,
  bool disableAnimations = false,
  double textScale = 1.0,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.dark(),
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: disableAnimations,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

QuietPlace _place({
  QuietPlaceBehaviour behaviour = QuietPlaceBehaviour.silent,
  bool enabled = true,
}) =>
    QuietPlace(
      id: 'z1',
      name: 'Cinema',
      latitude: 51.5,
      longitude: -0.12,
      radiusMeters: 150,
      behaviour: behaviour,
      enabled: enabled,
      createdAt: DateTime(2026, 1, 1),
    );

/// Builds a card with a live distance readout.
/// [signedEdge] negative means inside; [accuracy] drives the confidence state.
Widget _card({
  QuietPlaceBehaviour behaviour = QuietPlaceBehaviour.silent,
  bool enabled = true,
  double? signedEdge = -40,
  double? accuracy = 8,
  double width = 380,
}) =>
    SizedBox(
      width: width,
      child: QuietPlaceCard(
        place: _place(behaviour: behaviour, enabled: enabled),
        distance: _distance(signedEdge, accuracy),
        onToggle: (_) {},
        onTap: () {},
      ),
    );

PlaceDistanceDisplay _distance(double? signedEdge, double? accuracy) {
  final raw = signedEdge == null
      ? const PlaceDistance.unknown('z1')
      : PlaceDistance(
          placeId: 'z1',
          centreMeters: signedEdge + 150,
          signedEdgeMeters: signedEdge,
          accuracyMeters: accuracy,
        );
  return PlaceDistanceDisplay.from(raw,
      l: _english, units: UnitSystem.metric, localeName: 'en');
}

/// Loaded once so the card helpers can build display models outside a widget.
late final L _english;

void main() {
  setUpAll(() async => _english = await L.delegate.load(const Locale('en')));

  group('guidelines', () {
    testWidgets('place card meets contrast and tap targets (dark)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_card()));
      // The inside-state pulse repeats forever by design, so pumpAndSettle
      // would never return; pump a fixed frame instead.
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('place card meets contrast in light theme', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(
        _card(behaviour: QuietPlaceBehaviour.dnd, signedEdge: 320),
        theme: AppTheme.light(),
      ));
      await tester.pumpAndSettle();

      // Guards the lime-on-white trap: the accent must never be text in light
      // mode — AppAccents.accentInk supplies the readable variant.
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('disabled place card still meets contrast', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(
        _card(enabled: false, signedEdge: null),
      ));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('large text', () {
    // A Row of two Texts here previously overflowed by 32px at default scale on
    // a narrow card; these lock the fix in at accessibility text sizes.
    for (final scale in [1.3, 2.0]) {
      testWidgets('place card does not overflow at ${scale}x text',
          (tester) async {
        await tester.pumpWidget(_host(_card(), textScale: scale));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });

      testWidgets('narrow place card does not overflow at ${scale}x text',
          (tester) async {
        await tester.pumpWidget(_host(
          _card(
              behaviour: QuietPlaceBehaviour.dnd,
              signedEdge: 1450,
              width: 300),
          textScale: scale,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('semantics', () {
    testWidgets('place card announces name, behaviour and inside state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_card()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.bySemanticsLabel(RegExp('Cinema.*Silent.*inside by')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('disabled state is announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(
        _card(enabled: false, signedEdge: null),
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('Cinema.*disabled')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('PressableScale exposes a labelled button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(
        PressableScale(
          semanticLabel: 'Add current location',
          onPressed: () {},
          child: const SizedBox(width: 200, height: Hit.min),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Add current location'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('decorative skeleton is hidden from screen readers',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const Skeleton(height: 40, width: 200)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.getSemantics(find.byType(Skeleton)).label, isEmpty);
      handle.dispose();
    });
  });

  group('page transitions', _pageTransitionTests);

  group('reduced motion', () {
    testWidgets('Motion.of returns zero under disableAnimations',
        (tester) async {
      late Duration resolved;
      late bool reduced;
      await tester.pumpWidget(_host(
        Builder(builder: (context) {
          resolved = Motion.of(context, Motion.base);
          reduced = Motion.reduced(context);
          return const SizedBox();
        }),
        disableAnimations: true,
      ));
      expect(resolved, Duration.zero);
      expect(reduced, isTrue);
    });

    testWidgets('Motion.of passes the duration through normally',
        (tester) async {
      late Duration resolved;
      await tester.pumpWidget(_host(
        Builder(builder: (context) {
          resolved = Motion.of(context, Motion.base);
          return const SizedBox();
        }),
      ));
      expect(resolved, Motion.base);
    });

    testWidgets('inside-place card settles when animations are disabled',
        (tester) async {
      // The breathing pulse must not leave a permanently pending frame, or
      // pumpAndSettle — and real reduced-motion users — would never reach a
      // stable UI.
      await tester.pumpWidget(_host(_card(), disableAnimations: true));
      await tester.pumpAndSettle();
      expect(find.text('Cinema'), findsOneWidget);
    });

    testWidgets('skeleton settles when animations are disabled',
        (tester) async {
      await tester.pumpWidget(
          _host(const Skeleton(height: 40, width: 200), disableAnimations: true));
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsOneWidget);
    });
  });
}

/// Route transitions must obey reduced motion too, or the setting is a lie:
/// widgets would stop moving while navigation kept sliding.
void _pageTransitionTests() {
  Widget app({required bool disableAnimations}) => MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('destination')),
                    ),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

  testWidgets('a normal push animates', (tester) async {
    await tester.pumpWidget(app(disableAnimations: false));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    // Mid-flight the destination exists but is not yet fully opaque.
    final opacity = tester.widgetList<FadeTransition>(find.byType(FadeTransition));
    expect(opacity, isNotEmpty);
    await tester.pumpAndSettle();
    expect(find.text('destination'), findsOneWidget);
  });

  testWidgets('with reduced motion the destination does not move',
      (tester) async {
    await tester.pumpWidget(app(disableAnimations: true));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();

    // The destination is present and already at its final position on the
    // first frame. Note the route's controller still ticks — MaterialPageRoute
    // owns the duration and the transitions builder cannot zero it — but the
    // builder returns the child untransformed, so nothing on screen moves,
    // which is what the setting actually promises.
    expect(find.text('destination'), findsOneWidget);
    final atStart = tester.getTopLeft(find.text('destination'));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('destination')), atStart);
  });
}
