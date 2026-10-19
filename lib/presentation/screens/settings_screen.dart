import 'package:flutter/material.dart';

import '../../data/map/tile_cache.dart';
import '../../domain/entities/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../../data/ringer/platform_locale.dart';
import '../theme/tokens.dart';
import '../widgets/press.dart';
import '../widgets/radar_backdrop.dart';
import 'quiet_place_editor_screen.dart';
import 'map_consent_screen.dart';
import 'onboarding_screen.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final coordinator = ref.read(coordinatorProvider);
    final supported = ref.watch(ringerSupportedProvider);
    final scheme = Theme.of(context).colorScheme;
    final snoozeUntil = settings?.snoozeUntil;
    final snoozeActive =
        snoozeUntil != null && snoozeUntil.isAfter(DateTime.now());

    return QuietScaffold(
      appBar: AppBar(
        title: Text(l.navSettings),
        titleTextStyle: AppType.screenTitle.copyWith(color: scheme.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.gutter, 0, Space.gutter, Space.xxl),
        children: [
          _Section(l.settingsSectionWhen),
          _SettingCard(
            children: [
              _SwitchRow(
                title: l.settingsPauseTitle,
                subtitle: l.settingsPauseBody,
                value: settings?.globalPaused ?? false,
                onChanged: coordinator.setGlobalPause,
              ),
              const _HairlineDivider(),
              _ActionRow(
                title: snoozeActive ? l.settingsSnoozedTitle : l.settingsSnoozeTitle,
                subtitle: snoozeActive
                    ? l.settingsSnoozeUntil(_hhmm(snoozeUntil))
                    : l.settingsSnoozeBody,
                actionLabel: snoozeActive ? l.settingsCancel : l.settingsSnoozeAction,
                onAction: snoozeActive
                    ? coordinator.clearSnooze
                    : coordinator.snoozeForOneHour,
              ),
            ],
          ),
          _Section(l.settingsSectionLocation),
          _SettingCard(
            children: [
              _SwitchRow(
                title: l.settingsWarmTitle,
                subtitle: l.settingsWarmBody,
                value: settings?.gpsWarmupEnabled ?? true,
                onChanged: coordinator.setGpsWarmup,
              ),
              const _HairlineDivider(),
              _ActionRow(
                title: l.settingsManualTitle,
                subtitle: l.settingsManualBody,
                actionLabel: l.settingsOpen,
                onAction: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const QuietPlaceEditorScreen(
                      suggestedName: 'Location', manual: true),
                )),
              ),
            ],
          ),
          _Section(l.settingsSectionMaps),
          _SettingCard(
            children: [
              _SwitchRow(
                title: l.settingsMapsTitle,
                subtitle: (settings?.mapsEnabled ?? false)
                    ? l.settingsMapsOn
                    : l.settingsMapsOff,
                value: settings?.mapsEnabled ?? false,
                onChanged: (v) async {
                  if (!v) {
                    await coordinator.setMapsEnabled(false);
                    return;
                  }
                  // Turning on always goes through the consent screen.
                  if (!context.mounted) return;
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MapConsentScreen()));
                },
              ),
              const _HairlineDivider(),
              const _MapCacheRow(),
            ],
          ),
          _Section(l.settingsSectionUnits),
          _SettingCard(
            children: [
              _ChoiceRow(
                title: l.settingsUnitsTitle,
                options: [
                  (UnitSystem.metric, l.settingsUnitsMetric),
                  (UnitSystem.imperial, l.settingsUnitsImperial),
                ],
                selected: settings?.units ?? UnitSystem.metric,
                onChanged: coordinator.setUnits,
              ),
            ],
          ),
          _Section(l.settingsSectionLanguage),
          _SettingCard(
            children: [
              _ChoiceRow<String?>(
                title: l.settingsLanguageTitle,
                options: [
                  (null, l.settingsLanguageSystem),
                  // Each language is named in itself, never translated: a
                  // reader looking for their own language recognises it by its
                  // own name, not by what the current language calls it.
                  for (final lang in supportedLanguages)
                    (lang.code, lang.name),
                ],
                selected: settings?.localeCode,
                onChanged: coordinator.setLocale,
              ),
            ],
          ),
          _Section(l.settingsSectionDevice),
          _SettingCard(
            children: [
              _InfoRow(
                title: supported
                    ? l.settingsRingerAvailable
                    : l.settingsRingerUnavailable,
                subtitle: supported
                    ? l.settingsRingerAvailableBody
                    : ref.watch(ringerUnsupportedReasonProvider),
                good: supported,
              ),
              const _HairlineDivider(),
              _ActionRow(
                title: l.settingsPermissionsTitle,
                subtitle: l.settingsPermissionsBody,
                actionLabel: l.settingsReview,
                onAction: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(returnToApp: true))),
              ),
            ],
          ),
          _Section(l.settingsSectionHistory),
          _SettingCard(
            children: [
              _ActionRow(
                title: l.settingsClearLogTitle,
                subtitle: l.settingsClearLogBody,
                actionLabel: l.settingsClear,
                destructive: true,
                onAction: () async {
                  await ref.read(tripLogRepositoryProvider).clear();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.settingsHistoryCleared)));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
      child: Text(label,
          style: AppType.label.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Elevation.surfaceFor(scheme, Elevation.raised),
        borderRadius: Radii.cardShape,
        border: Border.all(
            color: context.accents.glassEdge, width: Strokes.hairline),
        boxShadow: Elevation.shadowFor(scheme, Elevation.raised),
      ),
      child: Column(children: children),
    );
  }
}

class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider();
  @override
  Widget build(BuildContext context) => Divider(
        height: Strokes.hairline,
        thickness: Strokes.hairline,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppType.title.copyWith(color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppType.bodySmall
                        .copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Semantics(
            label: title,
            child: Switch(
              value: value,
              onChanged: (v) {
                Haptics.fire(Hap.toggle);
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final bool destructive;

  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Space.md, Space.md, Space.xs, Space.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppType.title.copyWith(color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppType.bodySmall
                        .copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          TextButton(
            onPressed: () {
              Haptics.fire(Hap.commit);
              onAction();
            },
            style: destructive
                ? TextButton.styleFrom(foregroundColor: scheme.error)
                : null,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool good;

  const _InfoRow({
    required this.title,
    required this.subtitle,
    required this.good,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(good ? Icons.check_circle_outline : Icons.info_outline,
              size: IconSize.md,
              color: good ? accents.accentInk : scheme.onSurfaceVariant),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppType.title.copyWith(color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppType.bodySmall
                        .copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows how much disk the tile cache is using and lets the user clear it.
///
/// Required counterpart to caching: tiles accumulate silently, so there has to
/// be a visible number and a way to reclaim the space.
class _MapCacheRow extends StatefulWidget {
  const _MapCacheRow();

  @override
  State<_MapCacheRow> createState() => _MapCacheRowState();
}

class _MapCacheRowState extends State<_MapCacheRow> {
  final TileCache _cache = TileCache();
  int? _bytes;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final size = await _cache.sizeInBytes();
    if (mounted) setState(() => _bytes = size);
  }

  String get _readable {
    final b = _bytes;
    if (b == null) return L.of(context).settingsCacheChecking;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _ActionRow(
      title: l.settingsCacheTitle,
      subtitle: l.settingsCacheBody(_readable),
      actionLabel: l.settingsClear,
      onAction: () async {
        // Captured before the await: the context may be gone afterwards.
        final messenger = ScaffoldMessenger.of(context);
        final cleared = L.of(context).settingsCacheCleared;
        await _cache.clear();
        await _refresh();
        messenger.showSnackBar(SnackBar(content: Text(cleared)));
      },
    );
  }
}

/// A small set of mutually exclusive options, shown inline rather than behind a
/// dialog — with only two choices, a picker would be more taps for no gain.
class _ChoiceRow<T> extends StatelessWidget {
  final String title;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _ChoiceRow({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppType.title.copyWith(color: scheme.onSurface)),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              for (final (value, label) in options) ...[
                Expanded(
                  child: Semantics(
                    selected: value == selected,
                    button: true,
                    label: label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Haptics.fire(Hap.toggle);
                        onChanged(value);
                      },
                      child: AnimatedContainer(
                        duration: Motion.of(context, Motion.fast),
                        curve: Motion.decelerate,
                        height: Hit.min,
                        decoration: BoxDecoration(
                          color: value == selected
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(Radii.sm),
                          border: Border.all(
                            color: value == selected
                                ? scheme.primary
                                : scheme.outline,
                            width: Strokes.hairline,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySmall.copyWith(
                              color: value == selected
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (value != options.last.$1) const SizedBox(width: Space.xs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
