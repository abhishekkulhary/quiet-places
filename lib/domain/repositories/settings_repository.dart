import '../entities/app_settings.dart';
import '../entities/engagement.dart';

abstract interface class SettingsRepository {
  Stream<AppSettings> watch();

  Future<AppSettings> get();

  Future<void> save(AppSettings settings);
}

/// Persistence for the engine's active engagement (see [Engagement]). Kept
/// separate from user-facing settings because it is engine bookkeeping the user
/// never edits, written from the background isolate.
abstract interface class EngagementRepository {
  Future<Engagement?> get();

  Future<void> save(Engagement engagement);

  Future<void> clear();
}
