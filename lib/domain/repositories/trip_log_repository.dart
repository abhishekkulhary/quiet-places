import '../entities/trip_log_entry.dart';

abstract interface class TripLogRepository {
  /// Recent entries, newest first, capped at [limit].
  Stream<List<TripLogEntry>> watchRecent({int limit = 200});

  Future<void> add(TripLogEntry entry);

  Future<void> clear();
}
