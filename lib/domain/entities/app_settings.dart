/// Which units distances are shown in.
enum UnitSystem { metric, imperial }

/// Global, user-facing app configuration (a single persisted record).
class AppSettings {
  /// Master switch. When true, no place ever fires.
  final bool globalPaused;

  /// If set and in the future, the engine is temporarily paused until this
  /// instant ("snooze for 1h").
  final DateTime? snoozeUntil;

  /// Whether the permission onboarding flow has been completed at least once.
  final bool onboardingComplete;

  /// Keep a low-power location listener running while the app is in the
  /// foreground, so "Add current location" already has a recent fix in hand.
  /// Costs a little battery; user-disableable.
  final bool gpsWarmupEnabled;

  /// Opt-in: show real map tiles in the Quiet Place editor.
  ///
  /// Off by default. While false the app makes **no network requests at all**;
  /// turning it on is the only thing that causes traffic to leave the device,
  /// and the user is told exactly what that means before it flips.
  final bool mapsEnabled;

  /// Metric or imperial for every distance shown in the UI.
  final UnitSystem units;

  /// Language override as a bare language code ("en", "de").
  ///
  /// Null means follow the device. Stored rather than derived because the
  /// choice has to outlive the process: the geofence background isolate posts
  /// notifications without ever building the UI, and has nothing but this to
  /// tell it which language the user reads.
  final String? localeCode;

  const AppSettings({
    required this.globalPaused,
    required this.snoozeUntil,
    required this.onboardingComplete,
    this.gpsWarmupEnabled = true,
    this.mapsEnabled = false,
    this.units = UnitSystem.metric,
    this.localeCode,
  });

  static const defaults = AppSettings(
    globalPaused: false,
    snoozeUntil: null,
    onboardingComplete: false,
    gpsWarmupEnabled: true,
    mapsEnabled: false,
    units: UnitSystem.metric,
    localeCode: null,
  );

  /// True when the engine should not act right now, for any reason.
  bool isPausedAt(DateTime now) {
    if (globalPaused) return true;
    final until = snoozeUntil;
    return until != null && until.isAfter(now);
  }

  AppSettings copyWith({
    bool? globalPaused,
    DateTime? Function()? snoozeUntil,
    bool? onboardingComplete,
    bool? gpsWarmupEnabled,
    bool? mapsEnabled,
    UnitSystem? units,
    String? Function()? localeCode,
  }) {
    return AppSettings(
      globalPaused: globalPaused ?? this.globalPaused,
      snoozeUntil: snoozeUntil != null ? snoozeUntil() : this.snoozeUntil,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      gpsWarmupEnabled: gpsWarmupEnabled ?? this.gpsWarmupEnabled,
      mapsEnabled: mapsEnabled ?? this.mapsEnabled,
      units: units ?? this.units,
      localeCode: localeCode != null ? localeCode() : this.localeCode,
    );
  }
}
