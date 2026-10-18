import 'dart:async';

import '../entities/position_fix.dart';
import '../services/position_source.dart';

/// Drives the three-stage position ladder, emitting a [PositionResolution] at
/// every improvement so the UI can render progressively.
///
/// The contract that makes the sheet feel instant: **this never blocks the
/// caller**. It emits [PositionResolution.initial] synchronously-ish and then
/// upgrades. The sheet opens on tap and subscribes; it is never awaited.
///
/// Stage 0 (last known, ~40 ms) → Stage 1 (coarse) → Stage 2 (precise).
/// A pre-warmed fix supplied via [seed] short-circuits stage 0 entirely, which
/// on a cold device is the difference between instant and ~10 s.
class ResolvePosition {
  final PositionSource source;

  /// Bound for the coarse attempt.
  final Duration coarseTimeout;

  /// Bound for the precise attempt. Exceeding it is a [PositionFailure.timeout],
  /// not a hang.
  final Duration preciseTimeout;

  ResolvePosition(
    this.source, {
    this.coarseTimeout = const Duration(seconds: 8),
    this.preciseTimeout = const Duration(seconds: 20),
  });

  /// Emits successive resolutions, best-effort, never throwing.
  Stream<PositionResolution> call({PositionFix? seed}) async* {
    var current = PositionResolution(fix: seed, resolving: true);
    yield current;

    // Preconditions. A failure here is terminal for automatic resolution, but we
    // still keep any seed fix on screen so the user can save or edit manually.
    if (!await source.isServiceEnabled()) {
      yield current.copyWith(
          resolving: false, failure: PositionFailure.serviceDisabled);
      return;
    }
    final permissionFailure = await source.ensurePermission();
    if (permissionFailure != null) {
      yield current.copyWith(resolving: false, failure: permissionFailure);
      return;
    }

    // Stage 0 — cached. Skipped when a warmed seed already beats it.
    if (seed == null) {
      try {
        final last = await source.lastKnown();
        if (last != null && shouldSupersede(current.fix, last)) {
          current = current.copyWith(fix: last);
          yield current;
        }
      } catch (_) {
        // A missing cache is normal, not an error.
      }
    }

    // Stage 1 — coarse. Only worth waiting for while we have nothing better.
    if ((current.fix?.stage.index ?? -1) < FixStage.coarse.index) {
      try {
        final coarse = await source.coarse(timeout: coarseTimeout);
        if (shouldSupersede(current.fix, coarse)) {
          current = current.copyWith(fix: coarse, clearFailure: true);
          yield current;
        }
      } catch (_) {
        // Fall through to the precise attempt; coarse failing alone isn't fatal.
      }
    }

    // Stage 2 — precise.
    try {
      final precise = await source.precise(timeout: preciseTimeout);
      if (shouldSupersede(current.fix, precise)) {
        current = current.copyWith(fix: precise, clearFailure: true);
      }
      yield current.copyWith(resolving: false, clearFailure: true);
    } on TimeoutException {
      yield current.copyWith(
          resolving: false, failure: PositionFailure.timeout);
    } catch (_) {
      yield current.copyWith(
        resolving: false,
        failure: current.fix == null ? PositionFailure.unknown : null,
      );
    }
  }
}
