import '../../domain/entities/app_settings.dart';
import '../../domain/entities/engagement.dart';
import '../../domain/repositories/settings_repository.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

class DriftSettingsRepository implements SettingsRepository {
  final AppDatabase db;
  DriftSettingsRepository(this.db);

  @override
  Stream<AppSettings> watch() {
    return (db.select(db.settingsRows)..where((t) => t.id.equals(0)))
        .watchSingleOrNull()
        .map((row) => row == null ? AppSettings.defaults : settingsFrom(row));
  }

  @override
  Future<AppSettings> get() async {
    final row = await (db.select(db.settingsRows)..where((t) => t.id.equals(0)))
        .getSingleOrNull();
    return row == null ? AppSettings.defaults : settingsFrom(row);
  }

  @override
  Future<void> save(AppSettings settings) => db
      .into(db.settingsRows)
      .insertOnConflictUpdate(settingsToCompanion(settings));
}

class DriftEngagementRepository implements EngagementRepository {
  final AppDatabase db;
  DriftEngagementRepository(this.db);

  @override
  Future<Engagement?> get() async {
    final row =
        await (db.select(db.engagementRows)..where((t) => t.id.equals(0)))
            .getSingleOrNull();
    return row == null ? null : engagementFrom(row);
  }

  @override
  Future<void> save(Engagement engagement) => db
      .into(db.engagementRows)
      .insertOnConflictUpdate(engagementToCompanion(engagement));

  @override
  Future<void> clear() =>
      (db.delete(db.engagementRows)..where((t) => t.id.equals(0))).go();
}
