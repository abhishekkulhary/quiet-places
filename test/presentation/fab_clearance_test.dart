import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/presentation/theme/tokens.dart';

/// The floating action button overlays the list rather than occupying a row, so
/// the list must carry enough bottom inset for its last card to be scrolled
/// clear of it. Without that the button sits on top of the final card and the
/// switch under it cannot be reached.
void main() {
  test('the scroll inset clears the button and its margins', () {
    // Button height plus a gutter above and below it.
    expect(Sizes.fabScrollInset, greaterThanOrEqualTo(Sizes.fab + Space.gutter));
    expect(Sizes.fabScrollInset, Sizes.fab + Space.gutter * 2);
  });

  test('the button is a comfortable, accessible target', () {
    expect(Sizes.fab, greaterThanOrEqualTo(Hit.min));
    // Small enough to read as a floating action rather than a bar.
    expect(Sizes.fab, lessThan(Sizes.buttonHero + Space.xs));
  });

  testWidgets('a list bottom-inset by fabScrollInset scrolls its last item '
      'above the button', (tester) async {
    const itemHeight = 84.0;
    const items = 12;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  Space.gutter, Space.xs, Space.gutter, Sizes.fabScrollInset),
              itemCount: items,
              itemBuilder: (_, i) => SizedBox(
                height: itemHeight,
                child: Text('item $i', key: ValueKey('item$i')),
              ),
            ),
            const Positioned(
              right: Space.gutter,
              bottom: Space.gutter,
              child: SizedBox(
                  width: Sizes.fab, height: Sizes.fab, key: Key('fab')),
            ),
          ],
        ),
      ),
    ));

    // Scroll to the very bottom.
    await tester.fling(find.byType(ListView), const Offset(0, -4000), 1000);
    await tester.pumpAndSettle();

    final viewport = tester.getSize(find.byType(ListView));
    final lastItemBottom =
        tester.getBottomLeft(find.byKey(const ValueKey('item${items - 1}'))).dy;
    final fabTop = viewport.height - Space.gutter - Sizes.fab;

    expect(lastItemBottom, lessThanOrEqualTo(fabTop),
        reason: 'the last item must come to rest above the floating button');
  });
}
