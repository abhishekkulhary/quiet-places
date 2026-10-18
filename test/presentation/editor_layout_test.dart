import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/presentation/theme/tokens.dart';

/// Regression: in landscape the editor's map filled the whole viewport, and
/// because a map consumes vertical drag gestures the page could not be scrolled
/// at all — everything below the map became unreachable. Reported from real use.
void main() {
  // Nothing Phone A059 logical size, portrait and landscape.
  const portrait = Size(411, 910);
  const landscape = Size(910, 411);

  double heightFor(Size viewport) => editorMapHeight(
        availableWidth: viewport.width - Space.gutter * 2,
        viewport: viewport,
      );

  test('portrait: the map is a comfortable slice, not the whole screen', () {
    final h = heightFor(portrait);
    expect(h, lessThan(portrait.height * 0.5));
    expect(h, greaterThan(160));
  });

  test('landscape: the map cannot fill the viewport', () {
    final h = heightFor(landscape);
    // The bug: 910 - 40 = 870 wide / 1.45 = 600px, well over the 411px screen.
    expect(870 / 1.45, greaterThan(landscape.height),
        reason: 'the unclamped aspect ratio really would overflow');
    expect(h, lessThanOrEqualTo(landscape.height * 0.55));
  });

  test('landscape: room remains below the map to scroll to', () {
    final remaining = landscape.height - heightFor(landscape);
    expect(remaining, greaterThan(landscape.height * 0.4));
  });

  test('never collapses to nothing on a very short viewport', () {
    expect(heightFor(const Size(900, 200)), greaterThanOrEqualTo(160));
  });

  test('scales with width on a tablet', () {
    final phone = heightFor(portrait);
    final tablet = heightFor(const Size(1024, 1366));
    expect(tablet, greaterThan(phone));
  });
}
