import '../entities/quiet_place.dart';

abstract interface class QuietPlaceRepository {
  /// All places, newest first. Streamed so the UI reacts to background writes.
  Stream<List<QuietPlace>> watchAll();

  /// One-shot read, used by the background isolate where streams aren't needed.
  Future<List<QuietPlace>> getAll();

  /// Only enabled places — what the geofence engine should monitor.
  Future<List<QuietPlace>> getEnabled();

  Future<QuietPlace?> getById(String id);

  Future<void> upsert(QuietPlace place);

  Future<void> setEnabled(String id, bool enabled);

  Future<void> delete(String id);
}
