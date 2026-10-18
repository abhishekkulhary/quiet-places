import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/app_settings.dart';
import 'package:quiet_places/domain/entities/place_distance.dart';
import 'package:quiet_places/domain/entities/quiet_place.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/l10n/app_localizations.dart';
import 'package:quiet_places/presentation/distance_format.dart';
import 'package:quiet_places/presentation/theme/app_theme.dart';
import 'package:quiet_places/presentation/widgets/quiet_place_card.dart';
import 'package:quiet_places/presentation/widgets/silence_moment.dart';
import 'package:quiet_places/presentation/widgets/state_views.dart';

/// The brief asks for layouts that stay "legible and unbroken up to 200% system
/// font size". An overflowing RenderFlex throws in tests, so asserting no
/// exception at each scale is a real check rather than a claim — this is the
/// same class of bug the accessibility pass already caught once.
void main() {
  late L en;

  setUpAll(() async => en = await L.delegate.load(const Locale('en')));

  /// Narrow-phone widths as well as scale: the two together are what actually
  /// breaks layouts.
  const scales = [1.0, 1.3, 1.6, 2.0];
  const widths = [320.0, 360.0, 411.0];

  Widget host(Widget child, double scale, double width) => MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: Center(child: SizedBox(width: width, child: child)),
          ),
        ),
      );

  QuietPlace place({
    String name = 'The Everyman Cinema on Baker Street',
    QuietPlaceBehaviour behaviour = QuietPlaceBehaviour.dnd,
    bool enabled = true,
  }) =>
      QuietPlace(
        id: 'z1',
        name: name,
        latitude: 51.5,
        longitude: -0.12,
        radiusMeters: 150,
        behaviour: behaviour,
        enabled: enabled,
        createdAt: DateTime(2026, 1, 1),
      );

  PlaceDistanceDisplay distance(double? signedEdge, {double? accuracy = 8}) {
    final raw = signedEdge == null
        ? const PlaceDistance.unknown('z1')
        : PlaceDistance(
            placeId: 'z1',
            centreMeters: signedEdge + 150,
            signedEdgeMeters: signedEdge,
            accuracyMeters: accuracy,
          );
    return PlaceDistanceDisplay.from(raw,
        l: en, units: UnitSystem.metric, localeName: 'en');
  }

  for (final scale in scales) {
    for (final width in widths) {
      testWidgets('place card survives ${scale}x at ${width.round()}px',
          (tester) async {
        await tester.pumpWidget(host(
          QuietPlaceCard(
            place: place(),
            distance: distance(-40),
            onToggle: (_) {},
            onTap: () {},
          ),
          scale,
          width,
        ));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('uncertain distance line survives ${scale}x', (tester) async {
      // The longest variant: "~1.4 km · inside by 1.2 km  ±120 m".
      await tester.pumpWidget(host(
        QuietPlaceCard(
          place: place(),
          distance: distance(-1200, accuracy: 1400),
          onToggle: (_) {},
          onTap: () {},
        ),
        scale,
        320,
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('distance-unavailable card survives ${scale}x', (tester) async {
      await tester.pumpWidget(host(
        QuietPlaceCard(
          place: place(enabled: false),
          distance: distance(null),
          onToggle: (_) {},
          onTap: () {},
        ),
        scale,
        320,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('state banner survives ${scale}x', (tester) async {
      await tester.pumpWidget(host(
        StateBanner(
          icon: Icons.location_disabled,
          title: en.statePermissionTitle,
          body: en.statePermissionBody,
          actionLabel: en.statePermissionAction,
          onAction: () {},
        ),
        scale,
        320,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state survives ${scale}x', (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          height: 720,
          child: StateViews.empty(
            art: const EmptyPlacesArt(),
            title: en.homeEmptyTitle,
            body: en.homeEmptyBody,
          ),
        ),
        scale,
        320,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('silencing moment survives ${scale}x', (tester) async {
      await tester.pumpWidget(host(
        SilenceMomentOverlay(
          placeName: 'The Everyman Cinema on Baker Street',
          behaviour: QuietPlaceBehaviour.dnd,
          onDismiss: () {},
        ),
        scale,
        320,
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('error state survives ${scale}x', (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          height: 720,
          child: StateViews.error(
            message: en.homeLoadFailed,
            detail: 'DatabaseException: disk I/O error',
            onRetry: () {},
          ),
        ),
        scale,
        320,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
