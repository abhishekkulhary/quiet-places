import 'package:drift/drift.dart';

import '../../domain/entities/quiet_place.dart';
import '../../domain/repositories/quiet_place_repository.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

class DriftQuietPlaceRepository implements QuietPlaceRepository {
  final AppDatabase db;
  DriftQuietPlaceRepository(this.db);

  @override
  Stream<List<QuietPlace>> watchAll() {
    final query = db.select(db.quietPlaces)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)]);
    return query.watch().map((rows) => rows.map(quietPlaceFrom).toList());
  }

  @override
  Future<List<QuietPlace>> getAll() async {
    final rows = await db.select(db.quietPlaces).get();
    return rows.map(quietPlaceFrom).toList();
  }

  @override
  Future<List<QuietPlace>> getEnabled() async {
    final rows = await (db.select(db.quietPlaces)
          ..where((t) => t.enabled.equals(true)))
        .get();
    return rows.map(quietPlaceFrom).toList();
  }

  @override
  Future<QuietPlace?> getById(String id) async {
    final row = await (db.select(db.quietPlaces)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : quietPlaceFrom(row);
  }

  @override
  Future<void> upsert(QuietPlace place) =>
      db.into(db.quietPlaces).insertOnConflictUpdate(place.toCompanion());

  @override
  Future<void> setEnabled(String id, bool enabled) {
    return (db.update(db.quietPlaces)..where((t) => t.id.equals(id)))
        .write(QuietPlacesCompanion(enabled: Value(enabled)));
  }

  @override
  Future<void> delete(String id) =>
      (db.delete(db.quietPlaces)..where((t) => t.id.equals(id))).go();
}
