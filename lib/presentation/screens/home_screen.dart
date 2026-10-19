import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../dev/perf_probe.dart';
import '../../domain/entities/boundary_transition.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/services/position_source.dart';
import '../../l10n/app_localizations.dart';
import '../providers/distance_providers.dart';
import '../providers/position_providers.dart';
import '../../domain/entities/trip_log_entry.dart';
import '../../domain/entities/quiet_place_behaviour.dart';
import '../providers/moment_provider.dart';
import '../providers/providers.dart';
import '../theme/tokens.dart';
import '../widgets/place_map_editor.dart';
import '../widgets/press.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/state_views.dart';
import '../widgets/silence_moment.dart';
import '../widgets/undo_snackbar.dart';
import '../widgets/quiet_place_card.dart';
import '../widgets/radar_backdrop.dart';
import 'quiet_place_editor_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// [LiveDistanceWatcher] keeps the location stream running only while this
/// screen is mounted and foregrounded; background behaviour is untouched.
class _HomeScreenState extends ConsumerState<HomeScreen>
    with LiveDistanceWatcher {
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final places = ref.watch(placesStreamProvider);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final supported = ref.watch(ringerSupportedProvider);

    final paused = settings?.isPausedAt(DateTime.now()) ?? false;

    // Formatting context flows from here: the controller has no BuildContext,
    // and a unit or locale change must take effect immediately.
    ref.read(liveDistanceProvider.notifier).setFormatting(
          l: l,
          units: settings?.units ?? UnitSystem.metric,
          localeName: Localizations.localeOf(context).toString(),
        );

    return QuietScaffold(
      body: SafeArea(
        child: AdaptivePanes(
          // On a wide screen the map sits beside the list rather than being a
          // separate trip into the editor.
          detail: (context) => const _WidePreviewPane(),
          primary: Stack(
            children: [
              Column(
          children: [
            const _Header(),
            if (!supported) const _Banner.unsupported(),
            if (paused) const _Banner.paused(),
            const _PositionBlockedBanner(),
            const _MomentSlot(),
            Expanded(
              child: places.when(
                loading: () =>
                    StateViews.loadingList(bottomInset: Sizes.fabScrollInset),
                error: (e, _) => StateViews.error(
                  message: l.homeLoadFailed,
                  detail: '$e',
                ),
                data: (list) => list.isEmpty
                    ? StateViews.empty(
                        art: const EmptyPlacesArt(),
                        title: l.homeEmptyTitle,
                        body: l.homeEmptyBody,
                        bottomInset: Sizes.fabScrollInset,
                      )
                    : _QuietPlaceList(places: list),
              ),
            ),
          ],
              ),
              // Floats over the list rather than occupying a row of its own.
              // The list carries a matching bottom inset so its last card can
              // still be scrolled clear of this button.
              Positioned(
                right: Space.gutter,
                bottom: Space.gutter,
                child: _AddFab(
                    onPressed: () => _addCurrentLocation(context, ref)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the sheet on the very next frame. The position is resolved *inside*
  /// the sheet, so this path never awaits GPS — the original implementation
  /// awaited a high-accuracy fix here, measured at ~9.6 s on a cold device.
  void _addCurrentLocation(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    PerfProbe.markAddTapped();
    final count = ref.read(placesStreamProvider).valueOrNull?.length ?? 0;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          QuietPlaceEditorScreen(suggestedName: l.editorSuggestedName(count + 1)),
    ));
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.gutter, Space.md, Space.xs, Space.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appName.toUpperCase(),
                    style: AppType.label
                        .copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: Space.xxs),
                Text(l.homeTitle,
                    style: AppType.displayMedium
                        .copyWith(color: scheme.onSurface)),
              ],
            ),
          ),
          IconButton(
            tooltip: l.navHistory,
            icon: const Icon(Icons.history),
            iconSize: IconSize.lg,
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            tooltip: l.navSettings,
            icon: const Icon(Icons.settings_outlined),
            iconSize: IconSize.lg,
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}

/// Slot for the signature moment. Animates in when the engine changes the
/// ringer and collapses away when dismissed; occupies no space otherwise.
class _MomentSlot extends ConsumerWidget {
  const _MomentSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(silenceMomentProvider);
    return AnimatedSize(
      duration: Motion.of(context, Motion.base),
      curve: Motion.decelerate,
      alignment: Alignment.topCenter,
      child: entry == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.gutter, Space.xs, Space.gutter, 0),
              child: SilenceMomentOverlay(
                key: ValueKey(entry.timestamp),
                placeName: entry.placeName,
                behaviour: behaviourOfLogEntry(entry),
                restoring: entry.action == TripAction.restored,
                onDismiss: () =>
                    ref.read(silenceMomentProvider.notifier).dismiss(),
              ),
            ),
    );
  }

}

/// Entries written from schema v7 onward carry the applied behaviour.
///
/// Older rows only describe it in prose, and that prose names *two*
/// behaviours on a step-down ("Do Not Disturb → Vibrate"), so the legacy path
/// reads only the side after the arrow -- the one actually in force. Scanning
/// the whole string is what made a step-down to Vibrate announce itself as
/// Do Not Disturb.
QuietPlaceBehaviour behaviourOfLogEntry(TripLogEntry e) {
  final recorded = e.behaviour;
  if (recorded != null) return recorded;

  var d = (e.detail ?? '').toLowerCase();
  if (d.contains('→')) d = d.split('→').last;
  if (d.contains('do not disturb')) return QuietPlaceBehaviour.dnd;
  if (d.contains('vibrate')) return QuietPlaceBehaviour.vibrate;
  return QuietPlaceBehaviour.silent;
}

class _QuietPlaceList extends ConsumerWidget {
  final List<QuietPlace> places;
  const _QuietPlaceList({required this.places});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ordering comes from the live controller, which applies hysteresis so
    // cards cannot swap places on GPS noise.
    final order = ref.watch(liveDistanceProvider.select((s) => s.order));
    final ordered = _applyOrder(places, order);

    return ListView.separated(
      // Bottom inset so the last card clears the floating action button.
      padding: const EdgeInsets.fromLTRB(
          Space.gutter, Space.xs, Space.gutter, Sizes.fabScrollInset),
      itemCount: ordered.length,
      separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
      itemBuilder: (context, i) {
        final place = ordered[i];
        return Dismissible(
          key: ValueKey(place.id),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          onDismissed: (_) => _deleteWithUndo(context, ref, place),
          child: _LiveQuietPlaceCard(
            place: place,
            onToggle: (v) =>
                ref.read(coordinatorProvider).setEnabled(place.id, v),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => QuietPlaceEditorScreen(existing: place, manual: true),
            )),
            onLongPress: () => _debugMenu(context, ref, place),
          ),
        );
      },
    );
  }

  /// Applies the controller's hysteresis order, keeping any place the
  /// controller has not seen yet (e.g. just created) in its original position.
  List<QuietPlace> _applyOrder(List<QuietPlace> places, List<String> order) {
    if (order.isEmpty) return places;
    final byId = {for (final p in places) p.id: p};
    final result = <QuietPlace>[];
    for (final id in order) {
      final p = byId.remove(id);
      if (p != null) result.add(p);
    }
    result.addAll(byId.values);
    return result;
  }

  /// Delete is optimistic with a timed undo, never a confirmation dialog.
  Future<void> _deleteWithUndo(
      BuildContext context, WidgetRef ref, QuietPlace place) async {
    final l = L.of(context);
    final coordinator = ref.read(coordinatorProvider);
    Haptics.fire(Hap.commit);
    await coordinator.deletePlace(place.id);
    if (!context.mounted) return;
    showUndoSnackBar(
      context,
      message: l.placeDeleted(place.name),
      onUndo: () => coordinator.savePlace(place),
    );
  }

  Future<void> _debugMenu(
      BuildContext context, WidgetRef ref, QuietPlace place) async {
    final l = L.of(context);
    final coordinator = ref.read(coordinatorProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Text(l.debugSimulate(place.name.toUpperCase()),
                  style: AppType.label),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: Text(l.debugSimulateEnter),
              onTap: () {
                coordinator.debugInject(place.id, BoundaryTransition.enter);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l.debugSimulateExit),
              onTap: () {
                coordinator.debugInject(place.id, BoundaryTransition.exit);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: Space.lg),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: Radii.cardShape,
      ),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }
}

/// The primary action: large, thumb-reachable, with real press physics.
/// The primary action, as a floating circular button.
///
/// Was a full-width bar, which gave a secondary-frequency action more weight
/// than it earns and pushed the list up. Floating it frees the row; the list's
/// bottom inset keeps the last card reachable underneath.
class _AddFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onPressed: onPressed,
      semanticLabel: l.homeAddCurrentSemantic,
      child: Tooltip(
        message: l.homeAddCurrent,
        child: Container(
          width: Sizes.fab,
          height: Sizes.fab,
          decoration: BoxDecoration(
            gradient: AppAccents.fill,
            shape: BoxShape.circle,
            // The glow is the lift in both themes; the ring separates the
            // button from any card scrolling underneath it.
            boxShadow: [
              ...Elevation.shadowFor(scheme, Elevation.floating),
              ...Elevation.glowFor(Palette.cyan, strength: 1.2),
            ],
            border: Border.all(
              color: scheme.surface,
              width: Strokes.ring,
            ),
          ),
          child: Icon(Icons.add,
              color: scheme.onPrimaryContainer, size: IconSize.lg),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final bool _unsupported;
  const _Banner.unsupported() : _unsupported = true;
  const _Banner.paused() : _unsupported = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer(
      builder: (context, ref, _) {
        final text = _unsupported
            ? ref.watch(ringerUnsupportedReasonProvider)
            : L.of(context).homePaused;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
              Space.gutter, Space.xs, Space.gutter, 0),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Row(
            children: [
              Icon(
                _unsupported ? Icons.info_outline : Icons.pause_circle_outline,
                size: IconSize.md,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(text,
                    style: AppType.bodySmall
                        .copyWith(color: scheme.onSecondaryContainer)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Subscribes to one place's distance only.
///
/// Watching `placeDistanceProvider(id)` rather than the whole map means a card
/// rebuilds only when its own displayed text changes — the list does not
/// repaint wholesale on every position sample.
class _LiveQuietPlaceCard extends ConsumerWidget {
  final QuietPlace place;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _LiveQuietPlaceCard({
    required this.place,
    required this.onToggle,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = ref.watch(placeDistanceProvider(place.id));
    return QuietPlaceCard(
      place: place,
      distance: distance,
      onToggle: onToggle,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// Surfaces a blocking location condition with the action that fixes it.
///
/// Shown when we have no usable position at all — the list still renders, with
/// each card reading "Distance unavailable", so the app stays usable rather
/// than becoming a wall.
class _PositionBlockedBanner extends ConsumerStatefulWidget {
  const _PositionBlockedBanner();

  @override
  ConsumerState<_PositionBlockedBanner> createState() =>
      _PositionBlockedBannerState();
}

class _PositionBlockedBannerState
    extends ConsumerState<_PositionBlockedBanner> {
  PositionFailure? _reason;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final source = ref.read(positionSourceProvider);
    PositionFailure? reason;
    if (!await source.isServiceEnabled()) {
      reason = PositionFailure.serviceDisabled;
    }
    if (!mounted) return;
    setState(() => _reason = reason);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final unavailable =
        ref.watch(liveDistanceProvider.select((s) => s.positionUnavailable));
    final places = ref.watch(placesStreamProvider).valueOrNull ?? const [];

    // Nothing to be blocked about if there is nothing to measure to.
    if (!unavailable || places.isEmpty) return const SizedBox.shrink();

    final servicesOff = _reason == PositionFailure.serviceDisabled;
    return StateBanner(
      icon: Icons.location_disabled,
      title: servicesOff ? l.stateServicesTitle : l.statePermissionTitle,
      body: servicesOff ? l.stateServicesBody : l.statePermissionBody,
      actionLabel:
          servicesOff ? l.stateServicesAction : l.statePermissionAction,
      onAction: () async {
        final source = ref.read(positionSourceProvider);
        if (servicesOff) {
          await source.openLocationSettings();
        } else {
          await source.ensurePermission();
        }
        await _check();
      },
    );
  }
}

/// The second pane on wide screens: a read-only map of every Quiet Place.
///
/// Deliberately read-only — editing still happens in the editor, so there is
/// one place where changes are made and one undo history, rather than two
/// divergent editing surfaces.
class _WidePreviewPane extends ConsumerWidget {
  const _WidePreviewPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final mapsEnabled =
        ref.watch(settingsStreamProvider).valueOrNull?.mapsEnabled ?? false;
    final places = ref.watch(placesStreamProvider).valueOrNull ?? const [];
    final here = ref.watch(gpsWarmupProvider);

    if (!mapsEnabled || places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined,
                  size: IconSize.hero, color: scheme.onSurfaceVariant),
              const SizedBox(height: Space.md),
              Text(
                mapsEnabled ? l.homeEmptyBody : l.consentFallback,
                textAlign: TextAlign.center,
                style: AppType.bodySmall
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final focus = places.first;
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: PlaceMapEditor(
        centre: LatLng(focus.latitude, focus.longitude),
        radiusMeters: focus.radiusMeters,
        otherPlaces: places.skip(1).toList(),
        userPosition:
            here == null ? null : LatLng(here.latitude, here.longitude),
        userAccuracyMeters: here?.accuracyMeters,
        onCentreChanged: (_) {},
        onCentreSettled: () {},
        onRadiusChanged: (_) {},
        onRadiusSettled: () {},
        interactive: false,
      ),
    );
  }
}
