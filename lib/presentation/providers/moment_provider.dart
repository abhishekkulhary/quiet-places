import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trip_log_entry.dart';
import 'providers.dart';

/// Surfaces the most recent silencing/restoring event so the home screen can
/// show the in-app confirmation.
///
/// The event itself is produced by the geofence **background isolate**, which
/// cannot push into this isolate's drift streams — so a moment that happened
/// while the app was closed appears on the next resume rather than instantly.
/// Events raised in the foreground (including the debug injector) appear
/// immediately.
///
/// Only events newer than when this notifier was created are shown, so opening
/// the app doesn't replay an ancient event as if it just happened.
class SilenceMoment extends StateNotifier<TripLogEntry?> {
  final DateTime _since;
  DateTime? _dismissedThrough;

  SilenceMoment({DateTime? since})
      : _since = since ?? DateTime.now(),
        super(null);

  static const _momentActions = {
    TripAction.applied,
    TripAction.restored,
    TripAction.reResolved,
  };

  /// Freshness window: an event older than this is history, not a moment.
  static const _maxAge = Duration(minutes: 5);

  void ingest(List<TripLogEntry> entries) {
    TripLogEntry? newest;
    for (final e in entries) {
      if (!_momentActions.contains(e.action)) continue;
      if (!e.timestamp.isAfter(_since)) continue;
      if (DateTime.now().difference(e.timestamp) > _maxAge) continue;
      if (_dismissedThrough != null &&
          !e.timestamp.isAfter(_dismissedThrough!)) {
        continue;
      }
      if (newest == null || e.timestamp.isAfter(newest.timestamp)) {
        newest = e;
      }
    }
    if (newest != null && newest.timestamp != state?.timestamp) {
      state = newest;
    }
  }

  void dismiss() {
    _dismissedThrough = state?.timestamp ?? DateTime.now();
    state = null;
  }
}

final silenceMomentProvider =
    StateNotifierProvider<SilenceMoment, TripLogEntry?>((ref) {
  final notifier = SilenceMoment();
  ref.listen(tripLogStreamProvider, (_, next) {
    final entries = next.valueOrNull;
    if (entries != null) notifier.ingest(entries);
  }, fireImmediately: true);
  return notifier;
});
