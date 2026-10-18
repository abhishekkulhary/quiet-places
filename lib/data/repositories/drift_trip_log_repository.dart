import 'package:drift/drift.dart';

import '../../domain/entities/trip_log_entry.dart';
import '../../domain/repositories/trip_log_repository.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

class DriftTripLogRepository implements TripLogRepository {
  final AppDatabase db;
  DriftTripLogRepository(this.db);

  @override
  Stream<List<TripLogEntry>> watchRecent({int limit = 200}) {
    final query = db.select(db.tripLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.timestampMs)])
      ..limit(limit);
    return query.watch().map((rows) => rows.map(tripLogFrom).toList());
  }

  @override
  Future<void> add(TripLogEntry entry) =>
      db.into(db.tripLogs).insert(tripLogToCompanion(entry));

  @override
  Future<void> clear() => db.delete(db.tripLogs).go();
}
