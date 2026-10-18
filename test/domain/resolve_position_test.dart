import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/entities/position_fix.dart';
import 'package:quiet_places/domain/services/position_source.dart';
import 'package:quiet_places/domain/usecases/resolve_position.dart';

PositionFix fix(FixStage stage, double accuracy, {double lat = 1, double lng = 2}) =>
    PositionFix(
      latitude: lat,
      longitude: lng,
      accuracyMeters: accuracy,
      stage: stage,
      timestamp: DateTime(2026, 8, 23),
    );

/// Scriptable source: each stage either returns a fix, throws, or hangs.
class FakePositionSource implements PositionSource {
  PositionFix? lastKnownFix;
  PositionFix? coarseFix;
  PositionFix? preciseFix;
  Object? coarseError;
  Object? preciseError;
  bool serviceEnabled = true;
  PositionFailure? permissionFailure;
  final List<String> calls = [];

  @override
  Future<PositionFix?> lastKnown() async {
    calls.add('lastKnown');
    return lastKnownFix;
  }

  @override
  Future<PositionFix> coarse({required Duration timeout}) async {
    calls.add('coarse');
    if (coarseError != null) throw coarseError!;
    return coarseFix!;
  }

  @override
  Future<PositionFix> precise({required Duration timeout}) async {
    calls.add('precise');
    if (preciseError != null) throw preciseError!;
    return preciseFix!;
  }

  @override
  Stream<PositionFix> warmUp() => const Stream.empty();

  @override
  Stream<PositionFix> watch({
    required Duration interval,
    required bool highAccuracy,
  }) =>
      const Stream.empty();

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<PositionFailure?> ensurePermission() async => permissionFailure;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

void main() {
  group('shouldSupersede', () {
    test('anything beats nothing', () {
      expect(shouldSupersede(null, fix(FixStage.lastKnown, 500)), isTrue);
    });

    test('a later stage wins even with worse accuracy', () {
      // A stale cache can report a flatteringly small number; provenance wins.
      expect(
        shouldSupersede(fix(FixStage.lastKnown, 5), fix(FixStage.precise, 40)),
        isTrue,
      );
    });

    test('never regresses to an earlier stage', () {
      expect(
        shouldSupersede(fix(FixStage.precise, 40), fix(FixStage.lastKnown, 5)),
        isFalse,
      );
    });

    test('same stage requires a materially better reading', () {
      final current = fix(FixStage.precise, 100);
      expect(shouldSupersede(current, fix(FixStage.precise, 95)), isFalse);
      expect(shouldSupersede(current, fix(FixStage.precise, 50)), isTrue);
    });
  });

  group('ResolvePosition ladder', () {
    late FakePositionSource source;

    setUp(() {
      source = FakePositionSource()
        ..lastKnownFix = fix(FixStage.lastKnown, 80)
        ..coarseFix = fix(FixStage.coarse, 60)
        ..preciseFix = fix(FixStage.precise, 12);
    });

    test('emits progressively: initial → lastKnown → coarse → precise', () async {
      final states = await ResolvePosition(source).call().toList();

      expect(states.first.fix, isNull);
      expect(states.first.resolving, isTrue);

      final stages = states.map((s) => s.fix?.stage).toList();
      expect(stages, containsAllInOrder([
        null,
        FixStage.lastKnown,
        FixStage.coarse,
        FixStage.precise,
      ]));

      expect(states.last.resolving, isFalse);
      expect(states.last.failure, isNull);
      expect(states.last.fix!.accuracyMeters, 12);
    });

    test('a warmed seed skips the lastKnown lookup entirely', () async {
      final states = await ResolvePosition(source)
          .call(seed: fix(FixStage.coarse, 30))
          .toList();

      expect(source.calls, isNot(contains('lastKnown')));
      // Seed is coarse, so the coarse stage is skipped too — straight to precise.
      expect(source.calls, isNot(contains('coarse')));
      expect(states.first.fix!.stage, FixStage.coarse);
      expect(states.last.fix!.stage, FixStage.precise);
    });

    test('services disabled ends immediately with a recoverable failure',
        () async {
      source.serviceEnabled = false;
      final states = await ResolvePosition(source).call().toList();

      expect(states.last.failure, PositionFailure.serviceDisabled);
      expect(states.last.resolving, isFalse);
      expect(states.last.isDeadEnd, isTrue);
      expect(source.calls, isEmpty); // never even tried to locate
    });

    test('permanent permission denial surfaces as its own failure', () async {
      source.permissionFailure = PositionFailure.permissionDeniedForever;
      final states = await ResolvePosition(source).call().toList();
      expect(states.last.failure, PositionFailure.permissionDeniedForever);
      expect(states.last.resolving, isFalse);
    });

    test('precise timing out keeps the coarse fix and reports timeout',
        () async {
      source.preciseError = TimeoutException('no fix');
      final states = await ResolvePosition(source).call().toList();

      expect(states.last.failure, PositionFailure.timeout);
      expect(states.last.resolving, isFalse);
      // Crucially, we still have something usable to save.
      expect(states.last.fix!.stage, FixStage.coarse);
      expect(states.last.isDeadEnd, isFalse);
    });

    test('coarse failing does not abort the precise attempt', () async {
      source.coarseError = Exception('coarse unavailable');
      final states = await ResolvePosition(source).call().toList();

      expect(source.calls, contains('precise'));
      expect(states.last.fix!.stage, FixStage.precise);
      expect(states.last.failure, isNull);
    });

    test('total failure with no cache is a dead end (manual entry path)',
        () async {
      source
        ..lastKnownFix = null
        ..coarseError = Exception('nope')
        ..preciseError = Exception('nope');

      final states = await ResolvePosition(source).call().toList();
      expect(states.last.fix, isNull);
      expect(states.last.resolving, isFalse);
      expect(states.last.isDeadEnd, isTrue);
      expect(states.last.failure, PositionFailure.unknown);
    });
  });

  group('isMateriallyBetter (post-save upgrade rule)', () {
    test('a 20%+ tightening qualifies', () {
      expect(
          isMateriallyBetter(fix(FixStage.precise, 100), fix(FixStage.precise, 79)),
          isTrue);
      expect(
          isMateriallyBetter(fix(FixStage.precise, 100), fix(FixStage.precise, 81)),
          isFalse);
    });

    test('nonsense accuracy is never considered better', () {
      expect(
          isMateriallyBetter(fix(FixStage.precise, 50), fix(FixStage.precise, 0)),
          isFalse);
    });
  });
}
