import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/boundary_transition.dart';
import 'package:quiet_places/domain/entities/quiet_place_behaviour.dart';
import 'package:quiet_places/domain/entities/trip_log_entry.dart';
import 'package:quiet_places/presentation/screens/home_screen.dart';

TripLogEntry entry({QuietPlaceBehaviour? behaviour, String? detail}) =>
    TripLogEntry(
      placeId: 'p',
      placeName: 'Nordring',
      transition: BoundaryTransition.enter,
      action: TripAction.applied,
      behaviour: behaviour,
      detail: detail,
      timestamp: DateTime(2026, 8, 24),
    );

void main() {
  test('a recorded behaviour is used as-is', () {
    expect(
      behaviourOfLogEntry(entry(
          behaviour: QuietPlaceBehaviour.vibrate,
          // Prose that disagrees must not win.
          detail: 'Do Not Disturb → Vibrate')),
      QuietPlaceBehaviour.vibrate,
    );
  });

  group('legacy rows with no recorded behaviour', () {
    test('a step-down reports the behaviour now in force, not the old one', () {
      // The reported bug: standing in Vibrate, the moment announced Do Not
      // Disturb, because the scan found the name on the left of the arrow.
      expect(
        behaviourOfLogEntry(entry(detail: 'Do Not Disturb → Vibrate')),
        QuietPlaceBehaviour.vibrate,
      );
    });

    test('a step-up reports the stricter behaviour', () {
      expect(
        behaviourOfLogEntry(entry(detail: 'Vibrate → Do Not Disturb')),
        QuietPlaceBehaviour.dnd,
      );
    });

    test('a first application reads the target side', () {
      expect(behaviourOfLogEntry(entry(detail: 'normal → Do Not Disturb')),
          QuietPlaceBehaviour.dnd);
      expect(behaviourOfLogEntry(entry(detail: 'normal → Vibrate')),
          QuietPlaceBehaviour.vibrate);
      expect(behaviourOfLogEntry(entry(detail: 'normal → Silent')),
          QuietPlaceBehaviour.silent);
    });

    test('a no-change entry names a single behaviour', () {
      expect(behaviourOfLogEntry(entry(detail: 'no change (Do Not Disturb)')),
          QuietPlaceBehaviour.dnd);
      expect(behaviourOfLogEntry(entry(detail: 'no change (Vibrate)')),
          QuietPlaceBehaviour.vibrate);
    });

    test('a restore names the behaviour being undone', () {
      // "Do Not Disturb → silent" is a restore *to* the ringer mode silent;
      // the behaviour that was in force is Do Not Disturb. The target-side rule
      // cannot know that, which is exactly why v7 records it instead.
      expect(behaviourOfLogEntry(entry(detail: 'Vibrate → normal')),
          QuietPlaceBehaviour.silent);
      expect(
        behaviourOfLogEntry(entry(
            behaviour: QuietPlaceBehaviour.vibrate, detail: 'Vibrate → normal')),
        QuietPlaceBehaviour.vibrate,
      );
    });

    test('missing detail falls back rather than throwing', () {
      expect(behaviourOfLogEntry(entry()), QuietPlaceBehaviour.silent);
    });
  });
}
