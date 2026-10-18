import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/boundary_transition.dart';
import 'package:quiet_places/domain/entities/trip_log_entry.dart';
import 'package:quiet_places/l10n/app_localizations.dart';
import 'package:quiet_places/presentation/screens/history_screen.dart';
import 'package:quiet_places/presentation/theme/app_theme.dart';

/// Day headers must replace one another, not accumulate.
///
/// A plain pinned SliverPersistentHeader stacks: scroll into YESTERDAY and you
/// read its rows underneath a pile of TODAY + YESTERDAY labels. Grouping each
/// day in a SliverMainAxisGroup bounds the header to its own section, so the
/// incoming day pushes the previous label off and exactly one is ever shown.
void main() {
  /// A pinned header is 44 tall with its label vertically centred, so the text
  /// of a header sitting at the top of the viewport is around y=15, never 0.
  /// Anything within this band counts as pinned.
  const pinnedBand = 24.0;

  TripLogEntry entry(DateTime at, String name) => TripLogEntry(
        placeId: 'p',
        placeName: name,
        transition: BoundaryTransition.enter,
        action: TripAction.applied,
        detail: 'normal to Silent',
        timestamp: at,
      );

  /// Newest first, as the repository returns them.
  List<TripLogEntry> entriesAcrossDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    return [
      for (var i = 0; i < 8; i++)
        entry(today.subtract(Duration(minutes: i)), 'Today $i'),
      for (var i = 0; i < 8; i++)
        entry(yesterday.subtract(Duration(minutes: i)), 'Yesterday $i'),
      for (var i = 0; i < 8; i++)
        entry(twoDaysAgo.subtract(Duration(minutes: i)), 'Older $i'),
    ];
  }

  Widget host(List<TripLogEntry> entries) => MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(body: HistoryTimeline(entries: entries)),
      );

  testWidgets('at the top, only TODAY is shown', (tester) async {
    await tester.pumpWidget(host(entriesAcrossDays()));
    await tester.pumpAndSettle();

    expect(find.text('TODAY'), findsOneWidget);
    // Later days exist further down, but their labels are not at the top.
    final todayY = tester.getTopLeft(find.text('TODAY')).dy;
    expect(todayY, lessThan(pinnedBand));
  });

  /// Scrolls in small steps until [label] is pinned at the top, so the test
  /// does not depend on row heights. Returns false if it never gets there.
  Future<bool> scrollUntilPinned(WidgetTester tester, String label) async {
    for (var step = 0; step < 40; step++) {
      final finder = find.text(label);
      if (finder.evaluate().isNotEmpty &&
          tester.getTopLeft(finder).dy < pinnedBand) {
        return true;
      }
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
      await tester.pumpAndSettle();
    }
    return false;
  }

  testWidgets('scrolling into YESTERDAY hides TODAY rather than stacking',
      (tester) async {
    await tester.pumpWidget(host(entriesAcrossDays()));
    await tester.pumpAndSettle();

    expect(await scrollUntilPinned(tester, 'YESTERDAY'), isTrue,
        reason: 'YESTERDAY should reach the top as you scroll');

    // The key assertion: TODAY is gone, not sitting above YESTERDAY.
    expect(find.text('TODAY'), findsNothing);
  });

  testWidgets('never shows two day headers at once', (tester) async {
    await tester.pumpWidget(host(entriesAcrossDays()));
    await tester.pumpAndSettle();

    final scrollable = find.byType(CustomScrollView);
    // Walk down the whole list in small steps; at no point may two headers be
    // pinned to the top of the viewport simultaneously.
    for (var step = 0; step < 14; step++) {
      await tester.drag(scrollable, const Offset(0, -120));
      await tester.pumpAndSettle();

      final pinnedAtTop = <String>[];
      for (final label in ['TODAY', 'YESTERDAY']) {
        final finder = find.text(label);
        if (finder.evaluate().isEmpty) continue;
        if (tester.getTopLeft(finder).dy < pinnedBand) pinnedAtTop.add(label);
      }
      expect(pinnedAtTop.length, lessThanOrEqualTo(1),
          reason: 'two headers were pinned together at step $step');
    }
  });

  testWidgets('scrolling back up restores the earlier day header',
      (tester) async {
    await tester.pumpWidget(host(entriesAcrossDays()));
    await tester.pumpAndSettle();

    expect(await scrollUntilPinned(tester, 'YESTERDAY'), isTrue);
    expect(find.text('TODAY'), findsNothing);

    await tester.fling(
        find.byType(CustomScrollView), const Offset(0, 3000), 1500);
    await tester.pumpAndSettle();
    expect(find.text('TODAY'), findsOneWidget);
  });
}
