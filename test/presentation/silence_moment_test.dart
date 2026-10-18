import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/l10n/app_localizations.dart';
import 'package:quiet_places/presentation/theme/app_theme.dart';
import 'package:quiet_places/presentation/widgets/silence_moment.dart';

/// The banner interpolated a *function tear-off* rather than calling it, so the
/// signature moment read "Closure: (L) => String from Function '_verb@...'"
/// on a real device. Dart is happy to interpolate any Object, so only rendering
/// it catches this.
void main() {
  Widget host({required bool restoring,
          QuietPlaceBehaviour behaviour = QuietPlaceBehaviour.vibrate}) =>
      MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SilenceMomentOverlay(
            placeName: 'Nordring',
            behaviour: behaviour,
            restoring: restoring,
            onDismiss: () {},
          ),
        ),
      );

  testWidgets('silencing reads as words, never a closure', (tester) async {
    await tester.pumpWidget(host(restoring: false));
    await tester.pumpAndSettle();

    expect(find.text('SILENCED · VIBRATE'), findsOneWidget);
    expect(find.text('Nordring'), findsOneWidget);
  });

  testWidgets('restoring uses the other verb', (tester) async {
    await tester.pumpWidget(host(restoring: true));
    await tester.pumpAndSettle();

    expect(find.text('RESTORED · VIBRATE'), findsOneWidget);
  });

  testWidgets('the icon follows the behaviour, not a fixed bell',
      (tester) async {
    // The moment drew Icons.notifications_off_outlined -- the *Silent* icon --
    // whatever behaviour had been applied, so entering a Do Not Disturb place
    // was announced with the wrong symbol.
    await tester.pumpWidget(host(restoring: false, behaviour: QuietPlaceBehaviour.dnd));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.do_not_disturb_on_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);

    await tester.pumpWidget(
        host(restoring: false, behaviour: QuietPlaceBehaviour.vibrate));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.vibration), findsOneWidget);

    await tester.pumpWidget(
        host(restoring: false, behaviour: QuietPlaceBehaviour.silent));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
  });

  testWidgets('restoring keeps its own icon regardless of behaviour',
      (tester) async {
    await tester.pumpWidget(
        host(restoring: true, behaviour: QuietPlaceBehaviour.dnd));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
  });

  testWidgets('no rendered text anywhere leaks a Dart object description',
      (tester) async {
    for (final restoring in [false, true]) {
      await tester.pumpWidget(host(restoring: restoring));
      await tester.pumpAndSettle();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(texts, isNotEmpty);
      for (final t in texts) {
        expect(t, isNot(contains('Closure:')));
        expect(t, isNot(contains('Instance of')));
        expect(t, isNot(contains('Function \'')));
      }
    }
  });
}
