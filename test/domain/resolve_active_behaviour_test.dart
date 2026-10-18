import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/domain/usecases/resolve_active_behaviour.dart';

import 'fakes.dart';

void main() {
  group('resolveActiveBehaviour (overlap = most restrictive wins)', () {
    test('empty set resolves to null', () {
      expect(resolveActiveBehaviour([]), isNull);
    });

    test('single place resolves to its own behaviour', () {
      expect(
        resolveActiveBehaviour([place('a', behaviour: QuietPlaceBehaviour.vibrate)]),
        QuietPlaceBehaviour.vibrate,
      );
    });

    test('DND beats silent beats vibrate regardless of order', () {
      final z = [
        place('a', behaviour: QuietPlaceBehaviour.vibrate),
        place('b', behaviour: QuietPlaceBehaviour.dnd),
        place('c', behaviour: QuietPlaceBehaviour.silent),
      ];
      expect(resolveActiveBehaviour(z), QuietPlaceBehaviour.dnd);
      expect(resolveActiveBehaviour(z.reversed), QuietPlaceBehaviour.dnd);
    });

    test('silent wins over vibrate', () {
      expect(
        resolveActiveBehaviour([
          place('a', behaviour: QuietPlaceBehaviour.silent),
          place('b', behaviour: QuietPlaceBehaviour.vibrate),
        ]),
        QuietPlaceBehaviour.silent,
      );
    });

    test('disabled places are ignored', () {
      expect(
        resolveActiveBehaviour([
          place('a', behaviour: QuietPlaceBehaviour.dnd, enabled: false),
          place('b', behaviour: QuietPlaceBehaviour.vibrate),
        ]),
        QuietPlaceBehaviour.vibrate,
      );
    });

    test('all-disabled resolves to null', () {
      expect(
        resolveActiveBehaviour([
          place('a', behaviour: QuietPlaceBehaviour.dnd, enabled: false),
        ]),
        isNull,
      );
    });
  });
}
