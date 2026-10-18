import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../dev/perf_probe.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/entities/quiet_place_behaviour.dart';
import '../../domain/services/position_source.dart';
import '../../domain/usecases/validate_radius.dart';
import '../providers/position_providers.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/press.dart';
import '../../data/map/nominatim_service.dart';
import '../../domain/usecases/detect_overlap.dart';
import '../widgets/place_map_editor.dart';
import '../widgets/radius_dial.dart';
import 'map_consent_screen.dart';
import '../../l10n/app_localizations.dart';
import '../l10n_extensions.dart';

/// Add or edit a place.
///
/// **Opens immediately.** The device position is state that arrives later, never
/// a precondition for showing the sheet: the screen subscribes to a staged
/// resolution and re-renders as better fixes land, with the accuracy halo
/// visibly tightening. Saving is possible from the first approximate fix;
/// `QuietPlaceRefiner` quietly corrects the record if a better one arrives shortly
/// after.
class QuietPlaceEditorScreen extends ConsumerStatefulWidget {
  final QuietPlace? existing;

  /// Manual placement: no auto-resolution, the user drags the pin.
  final bool manual;
  final String suggestedName;

  const QuietPlaceEditorScreen({
    super.key,
    this.existing,
    this.manual = false,
    this.suggestedName = '',
  });

  @override
  ConsumerState<QuietPlaceEditorScreen> createState() => _QuietPlaceEditorScreenState();
}

/// One undoable state of the thing being edited.
@immutable
class _Draft {
  final double? latitude;
  final double? longitude;
  final double radius;
  final String name;
  final QuietPlaceBehaviour behaviour;

  const _Draft({
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.name,
    required this.behaviour,
  });

  _Draft copyWith({
    double? latitude,
    double? longitude,
    double? radius,
    String? name,
    QuietPlaceBehaviour? behaviour,
  }) =>
      _Draft(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radius: radius ?? this.radius,
        name: name ?? this.name,
        behaviour: behaviour ?? this.behaviour,
      );

  @override
  bool operator ==(Object other) =>
      other is _Draft &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.radius == radius &&
      other.name == name &&
      other.behaviour == behaviour;

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, radius, name, behaviour);
}

class _QuietPlaceEditorScreenState extends ConsumerState<QuietPlaceEditorScreen> {
  /// Undo/redo within this editing session. Snapshots are pushed on discrete
  /// commits (a drag ending, a behaviour tap) rather than on every frame, so
  /// one undo steps back one intention rather than one pixel.
  final List<_Draft> _history = [];
  int _historyIndex = -1;

  final NominatimService _geocoder = NominatimService();
  final TextEditingController _search = TextEditingController();
  List<PlaceSearchResult> _searchResults = const [];
  bool _searching = false;
  bool _searchOpen = false;

  /// Set once the user edits the name themselves, so a reverse-geocoded
  /// suggestion never overwrites their own words.
  bool _nameOwnedByUser = false;
  int _reverseToken = 0;
  late final TextEditingController _name;
  late final TextEditingController _radiusField;

  double? _lat;
  double? _lng;
  late double _radius;
  late QuietPlaceBehaviour _behaviour;

  PositionResolution _resolution = const PositionResolution();
  StreamSubscription<PositionResolution>? _sub;

  /// Once the user drags the pin, incoming fixes must stop moving it.
  bool _pinOwnedByUser = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? widget.suggestedName);
    _radius = e?.radiusMeters ?? RadiusPolicy.defaultMeters;
    _behaviour = e?.behaviour ?? QuietPlaceBehaviour.silent;
    _radiusField = TextEditingController(text: _radius.round().toString());

    if (e != null) {
      _lat = e.latitude;
      _lng = e.longitude;
      _pinOwnedByUser = true;
    } else {
      final seed = ref.read(gpsWarmupProvider.notifier).seed;
      if (seed != null) {
        _lat = seed.latitude;
        _lng = seed.longitude;
        _resolution = PositionResolution(fix: seed, resolving: !widget.manual);
      }
      if (widget.manual) {
        _pinOwnedByUser = true;
        _lat ??= 0;
        _lng ??= 0;
      } else {
        _startResolving();
      }
    }
    _pushHistory(initial: true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => PerfProbe.markSheetFirstFrame());
  }

  // --- undo / redo --------------------------------------------------------

  _Draft get _currentDraft => _Draft(
        latitude: _lat,
        longitude: _lng,
        radius: _radius,
        name: _name.text,
        behaviour: _behaviour,
      );

  bool get _canUndo => _historyIndex > 0;
  bool get _canRedo => _historyIndex < _history.length - 1;

  /// Records a snapshot. Called on commits, not on every intermediate frame.
  void _pushHistory({bool initial = false}) {
    final draft = _currentDraft;
    if (!initial && _history.isNotEmpty && _history[_historyIndex] == draft) {
      return; // nothing actually changed
    }
    // A new edit after undoing discards the redo tail, as users expect.
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(draft);
    _historyIndex = _history.length - 1;
  }

  void _applyDraft(_Draft d) {
    setState(() {
      _lat = d.latitude;
      _lng = d.longitude;
      _radius = d.radius;
      _behaviour = d.behaviour;
      if (_name.text != d.name) _name.text = d.name;
      _radiusField.text = d.radius.round().toString();
    });
  }

  void _undo() {
    if (!_canUndo) return;
    Haptics.fire(Hap.toggle);
    _historyIndex--;
    _applyDraft(_history[_historyIndex]);
  }

  void _redo() {
    if (!_canRedo) return;
    Haptics.fire(Hap.toggle);
    _historyIndex++;
    _applyDraft(_history[_historyIndex]);
  }

  /// True when there is anything to lose by backing out.
  bool get _hasUnsavedChanges =>
      _history.isNotEmpty && _currentDraft != _history.first;

  // --- naming -------------------------------------------------------------

  /// Looks up a name for the pin's new position, once the user has let go.
  ///
  /// Never called continuously while dragging: Nominatim's policy forbids
  /// autocomplete-style querying, and systematic reverse lookups are a
  /// bannable pattern.
  Future<void> _suggestNameForPin() async {
    if (_nameOwnedByUser) return;
    final lat = _lat, lng = _lng;
    if (lat == null || lng == null) return;
    if (!(ref.read(settingsStreamProvider).valueOrNull?.mapsEnabled ?? false)) {
      return; // offline mode: no lookups at all
    }

    final token = ++_reverseToken;
    final name = await _geocoder.reverseName(lat, lng);
    if (!mounted || token != _reverseToken || name == null) return;
    if (_nameOwnedByUser) return;
    setState(() => _name.text = name);
    _pushHistory();
  }

  // --- search -------------------------------------------------------------

  /// Runs only on explicit submit — see [NominatimService.search].
  Future<void> _runSearch() async {
    final query = _search.text.trim();
    if (query.isEmpty) return;
    setState(() => _searching = true);
    final results = await _geocoder.search(query);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _searchResults = results;
    });
  }

  void _selectResult(PlaceSearchResult result) {
    Haptics.fire(Hap.commit);
    setState(() {
      _pinOwnedByUser = true;
      _lat = result.latitude;
      _lng = result.longitude;
      _searchResults = const [];
      _searchOpen = false;
      _search.clear();
      if (!_nameOwnedByUser) _name.text = result.primary;
    });
    _pushHistory();
  }

  void _startResolving() {
    _sub?.cancel();
    setState(() =>
        _resolution = _resolution.copyWith(resolving: true, clearFailure: true));
    final seed = ref.read(gpsWarmupProvider.notifier).seed;
    _sub = ref.read(resolvePositionProvider).call(seed: seed).listen((r) {
      if (!mounted) return;
      setState(() {
        _resolution = r;
        final fix = r.fix;
        if (fix != null && !_pinOwnedByUser) {
          _lat = fix.latitude;
          _lng = fix.longitude;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _geocoder.dispose();
    _search.dispose();
    _name.dispose();
    _radiusField.dispose();
    super.dispose();
  }

  void _setRadius(double meters) {
    setState(() {
      _radius = clampRadius(meters);
      final text = _radius.round().toString();
      if (_radiusField.text != text) _radiusField.text = text;
    });
  }

  /// Called when a continuous gesture finishes, so one undo steps back one
  /// intention rather than one frame of a drag.
  void _commitEdit() => setState(_pushHistory);

  void _onDragMeters(double dxMeters, double dyMeters) {
    const metresPerDegLat = 111320.0;
    final lat = _lat ?? 0;
    final metresPerDegLng =
        111320.0 * math.cos(lat * math.pi / 180).abs().clamp(0.01, 1);
    setState(() {
      _pinOwnedByUser = true;
      _lat = (lat + dyMeters / metresPerDegLat).clamp(-90, 90).toDouble();
      _lng =
          ((_lng ?? 0) + dxMeters / metresPerDegLng).clamp(-180, 180).toDouble();
    });
  }

  void _switchToManual() {
    _sub?.cancel();
    setState(() {
      _pinOwnedByUser = true;
      _lat ??= 0;
      _lng ??= 0;
      _resolution = const PositionResolution();
    });
  }

  /// Fallback used when the user leaves the name blank.
  String get _fallbackName => L.of(context).editorDefaultName;

  bool get _canSave =>
      _lat != null && _lng != null && validateRadius(_radius).isAccepted;

  Future<void> _save() async {
    if (!_canSave) return;
    final name =
        _name.text.trim().isEmpty ? _fallbackName : _name.text.trim();
    final place = QuietPlace(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: name,
      latitude: _lat!,
      longitude: _lng!,
      radiusMeters: _radius,
      behaviour: _behaviour,
      enabled: widget.existing?.enabled ?? true,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    await ref.read(coordinatorProvider).savePlace(place);

    final fix = _resolution.fix;
    if (!_isEditing && !_pinOwnedByUser && fix != null && !fix.isGoodEnough) {
      unawaited(ref
          .read(quietPlaceRefinerProvider)
          .refine(placeId: place.id, savedWith: fix));
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final validation = validateRadius(_radius);
    final mapsEnabled =
        ref.watch(settingsStreamProvider).valueOrNull?.mapsEnabled ?? false;

    final overlaps = (_lat == null || _lng == null)
        ? const <PlaceOverlap>[]
        : detectOverlaps(
            latitude: _lat!,
            longitude: _lng!,
            radiusMeters: _radius,
            behaviour: _behaviour,
            editingId: widget.existing?.id,
            others: ref.watch(placesStreamProvider).valueOrNull ?? const [],
          );

    return PopScope(
      // Cancel truly reverts: nothing is written until Save, so backing out
      // discards by definition — but we confirm first so it is never an
      // accidental loss.
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscard();
        if (discard && mounted) navigator.pop();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l.editorTitleEdit : l.editorTitleNew),
        titleTextStyle: AppType.screenTitle.copyWith(color: scheme.onSurface),
        actions: [
          IconButton(
            tooltip: l.actionUndo,
            icon: const Icon(Icons.undo, size: IconSize.md),
            onPressed: _canUndo ? _undo : null,
          ),
          IconButton(
            tooltip: l.actionRedo,
            icon: const Icon(Icons.redo, size: IconSize.md),
            onPressed: _canRedo ? _redo : null,
          ),
          if (mapsEnabled)
            IconButton(
              tooltip: l.editorSearchSemantic,
              icon: const Icon(Icons.search, size: IconSize.md),
              onPressed: () => setState(() => _searchOpen = !_searchOpen),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.gutter, 0, Space.gutter, Space.xxl),
        children: [
          if (_searchOpen && mapsEnabled) ...[
            _SearchBar(
              controller: _search,
              searching: _searching,
              results: _searchResults,
              onSubmit: _runSearch,
              onSelect: _selectResult,
            ),
            const SizedBox(height: Space.sm),
          ],
          SizedBox(
            height: editorMapHeight(
              availableWidth:
                  MediaQuery.sizeOf(context).width - Space.gutter * 2,
              viewport: MediaQuery.sizeOf(context),
            ),
            child: _MapOrDial(
              latitude: _lat,
              longitude: _lng,
              radiusMeters: _radius,
              accuracyMeters: _resolution.fix?.accuracyMeters,
              editingId: widget.existing?.id,
              onCentreChanged: (lat, lng) => setState(() {
                _pinOwnedByUser = true;
                _lat = lat;
                _lng = lng;
              }),
              onCentreSettled: () {
                _pushHistory();
                unawaited(_suggestNameForPin());
              },
              onRadiusChanged: _setRadius,
              onRadiusSettled: _commitEdit,
              onDragMeters: _pinOwnedByUser ? _onDragMeters : null,
            ),
          ),
          const SizedBox(height: Space.xs),
          _EditorHint(mapsEnabled: mapsEnabled),
          const SizedBox(height: Space.xs),
          _PositionStatus(
            resolution: _resolution,
            pinOwnedByUser: _pinOwnedByUser,
            latitude: _lat,
            longitude: _lng,
            onRetry: _startResolving,
            onManual: _switchToManual,
            onOpenAppSettings: () =>
                ref.read(positionSourceProvider).openAppSettings(),
            onOpenLocationSettings: () =>
                ref.read(positionSourceProvider).openLocationSettings(),
          ),
          const SizedBox(height: Space.lg),
          _FieldLabel(l.editorFieldName),
          const SizedBox(height: Space.xs),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            style: AppType.title.copyWith(color: scheme.onSurface),
            decoration: const InputDecoration(isDense: true),
            // Once the user types their own name, a reverse-geocoded
            // suggestion must never overwrite it.
            onChanged: (_) => _nameOwnedByUser = true,
            onEditingComplete: _commitEdit,
          ),
          const SizedBox(height: Space.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: RadiusControl(
                  radiusMeters: _radius,
                  onChanged: _setRadius,
                ),
              ),
              const SizedBox(width: Space.sm),
              SizedBox(
                width: 76,
                child: TextField(
                  controller: _radiusField,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppType.title.copyWith(color: scheme.onSurface),
                  decoration: const InputDecoration(isDense: true),
                  onSubmitted: (v) {
                    _setRadius(double.tryParse(v) ?? _radius);
                    _commitEdit();
                  },
                  onEditingComplete: () {
                    _setRadius(double.tryParse(_radiusField.text) ?? _radius);
                    _commitEdit();
                  },
                ),
              ),
            ],
          ),
          if (validation == RadiusValidation.unreliable) ...[
            const SizedBox(height: Space.xs),
            _Notice(
              icon: Icons.warning_amber_rounded,
              tone: _NoticeTone.warning,
              child: Text(
                l.editorRadiusUnreliable(
                    RadiusPolicy.reliableThresholdMeters.round()),
                style: AppType.bodySmall.copyWith(color: scheme.onErrorContainer),
              ),
            ),
          ],
          const SizedBox(height: Space.lg),
          _FieldLabel(l.editorFieldWhenInside),
          const SizedBox(height: Space.xs),
          _BehaviourPicker(
            value: _behaviour,
            onChanged: (b) {
              Haptics.fire(Hap.toggle);
              setState(() => _behaviour = b);
              _pushHistory();
            },
          ),
          if (overlaps.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            _OverlapNotice(overlaps: overlaps, behaviour: _behaviour),
          ],
          const SizedBox(height: Space.xl),
          PressableScale(
            onPressed: _canSave ? _save : null,
            semanticLabel: _isEditing ? l.editorSaveChanges : l.editorSaveNew,
            child: Opacity(
              opacity: _canSave ? 1 : 0.4,
              child: Container(
                height: Sizes.button,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Text(
                  _isEditing ? l.editorSaveChanges : l.editorSaveNew,
                  style: AppType.buttonLabel.copyWith(color: scheme.onPrimaryContainer),
                ),
              ),
            ),
          ),
          if (!_canSave && _lat == null) ...[
            const SizedBox(height: Space.xs),
            Text(
              l.editorWaitingForPosition,
              textAlign: TextAlign.center,
              style: AppType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L.of(context).editorDiscardTitle),
        content: Text(L.of(context).editorDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(L.of(context).editorDiscardKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(L.of(context).editorDiscardConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppType.label
            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

/// Segmented behaviour picker drawn from tokens rather than Material defaults,
/// so it matches the instrument aesthetic and keeps 48dp targets.
class _BehaviourPicker extends StatelessWidget {
  final QuietPlaceBehaviour value;
  final ValueChanged<QuietPlaceBehaviour> onChanged;

  const _BehaviourPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final b in QuietPlaceBehaviour.values) ...[
          Expanded(
            child: Semantics(
              selected: b == value,
              button: true,
              label: b.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(b),
                child: AnimatedContainer(
                  duration: Motion.of(context, Motion.fast),
                  curve: Motion.decelerate,
                  height: Hit.min,
                  decoration: BoxDecoration(
                    color: b == value
                        ? scheme.primaryContainer
                        : scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: Border.all(
                      color: b == value ? scheme.primary : scheme.outline,
                      width: Strokes.hairline,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      b.shortLabelOf(l).toUpperCase(),
                      style: AppType.label.copyWith(
                        color: b == value
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (b != QuietPlaceBehaviour.values.last) const SizedBox(width: Space.xs),
        ],
      ],
    );
  }
}

/// Live accuracy chip, coordinates, and inline recoverable failures. Never a
/// blocking spinner — every state offers a way forward.
class _PositionStatus extends StatelessWidget {
  final PositionResolution resolution;
  final bool pinOwnedByUser;
  final double? latitude;
  final double? longitude;
  final VoidCallback onRetry;
  final VoidCallback onManual;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;

  const _PositionStatus({
    required this.resolution,
    required this.pinOwnedByUser,
    required this.latitude,
    required this.longitude,
    required this.onRetry,
    required this.onManual,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;
    final fix = resolution.fix;
    final failure = resolution.failure;

    final coords = (latitude != null && longitude != null)
        ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (fix != null) ...[
              AnimatedContainer(
                duration: Motion.of(context, Motion.base),
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.xs, vertical: Space.xxs),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(
                    color: fix.isGoodEnough ? accents.ring : scheme.outline,
                    width: Strokes.hairline,
                  ),
                ),
                child: Text(
                  '±${fix.accuracyMeters.round()} M',
                  style: AppType.label.copyWith(
                    color: fix.isGoodEnough
                        ? accents.accentInk
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: Space.xs),
            ],
            Expanded(
              child: Text(
                pinOwnedByUser && failure == null
                    ? '${l.editorPlacedManually} · $coords'
                    : resolution.resolving
                        ? (fix == null ? l.editorLocating : l.editorImproving)
                        : failure == null && fix != null
                            ? coords
                            : coords,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppType.label.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        if (failure != null) ...[
          const SizedBox(height: Space.xs),
          _FailureNotice(
            failure: failure,
            hasFallbackFix: fix != null,
            onRetry: onRetry,
            onManual: onManual,
            onOpenAppSettings: onOpenAppSettings,
            onOpenLocationSettings: onOpenLocationSettings,
          ),
        ],
      ],
    );
  }
}

class _FailureNotice extends StatelessWidget {
  final PositionFailure failure;
  final bool hasFallbackFix;
  final VoidCallback onRetry;
  final VoidCallback onManual;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;

  const _FailureNotice({
    required this.failure,
    required this.hasFallbackFix,
    required this.onRetry,
    required this.onManual,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (message, actionLabel, action) = switch (failure) {
      PositionFailure.serviceDisabled => (
          l.positionServicesOff,
          l.actionOpenSettings,
          onOpenLocationSettings,
        ),
      PositionFailure.permissionDenied => (
          l.positionPermissionNeeded,
          l.actionRetry,
          onRetry,
        ),
      PositionFailure.permissionDeniedForever => (
          l.positionPermissionForever,
          l.actionAppSettings,
          onOpenAppSettings,
        ),
      PositionFailure.timeout => (
          hasFallbackFix
              ? l.positionTimeoutWithFix
              : l.positionTimeoutNoFix,
          l.actionRetry,
          onRetry,
        ),
      PositionFailure.unknown => (
          l.positionUnknownFailure,
          l.actionRetry,
          onRetry,
        ),
    };

    return _Notice(
      icon: Icons.info_outline,
      tone: _NoticeTone.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message,
              style: AppType.bodySmall
                  .copyWith(color: scheme.onSecondaryContainer)),
          const SizedBox(height: Space.xxs),
          Row(
            children: [
              TextButton(onPressed: action, child: Text(actionLabel)),
              const SizedBox(width: Space.xxs),
              TextButton(
                  onPressed: onManual, child: Text(l.actionEnterManually)),
            ],
          ),
        ],
      ),
    );
  }
}

enum _NoticeTone { info, warning }

class _Notice extends StatelessWidget {
  final IconData icon;
  final _NoticeTone tone;
  final Widget child;

  const _Notice({
    required this.icon,
    required this.tone,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = tone == _NoticeTone.warning
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final fg = tone == _NoticeTone.warning
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: IconSize.md, color: fg),
          const SizedBox(width: Space.xs),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Shows the real map when the user has opted in, and the offline dial
/// otherwise. Both edit the same state, so the feature is genuinely optional
/// rather than the map being load-bearing.
class _MapOrDial extends ConsumerWidget {
  final double? latitude;
  final double? longitude;
  final double radiusMeters;
  final double? accuracyMeters;
  final String? editingId;
  final void Function(double lat, double lng) onCentreChanged;
  final VoidCallback onCentreSettled;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onRadiusSettled;
  final void Function(double dxMeters, double dyMeters)? onDragMeters;

  const _MapOrDial({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.accuracyMeters,
    required this.editingId,
    required this.onCentreChanged,
    required this.onCentreSettled,
    required this.onRadiusChanged,
    required this.onRadiusSettled,
    required this.onDragMeters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsEnabled =
        ref.watch(settingsStreamProvider).valueOrNull?.mapsEnabled ?? false;

    if (!mapsEnabled || latitude == null || longitude == null) {
      return Stack(
        children: [
          Positioned.fill(
            child: RadiusDial(
              radiusMeters: radiusMeters,
              accuracyMeters: accuracyMeters,
              hasPosition: latitude != null,
              onDragMeters: onDragMeters,
              onDragEnd: onCentreSettled,
            ),
          ),
          if (!mapsEnabled)
            Positioned(
              right: Space.xs,
              top: Space.xs,
              child: _ShowMapChip(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MapConsentScreen())),
              ),
            ),
        ],
      );
    }

    final here = ref.watch(gpsWarmupProvider);
    final others = (ref.watch(placesStreamProvider).valueOrNull ?? const [])
        .where((p) => p.id != editingId)
        .toList();

    return PlaceMapEditor(
      centre: LatLng(latitude!, longitude!),
      radiusMeters: radiusMeters,
      otherPlaces: others,
      userPosition: here == null ? null : LatLng(here.latitude, here.longitude),
      userAccuracyMeters: here?.accuracyMeters,
      onCentreChanged: (p) => onCentreChanged(p.latitude, p.longitude),
      onCentreSettled: onCentreSettled,
      onRadiusChanged: onRadiusChanged,
      onRadiusSettled: onRadiusSettled,
    );
  }
}

class _ShowMapChip extends StatelessWidget {
  final VoidCallback onTap;
  const _ShowMapChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onPressed: onTap,
      semanticLabel: L.of(context).editorShowMapSemantic,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.sm, vertical: Space.xs),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: scheme.outline, width: Strokes.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: IconSize.sm, color: scheme.onSurface),
            const SizedBox(width: Space.xxs),
            Text(L.of(context).editorShowMap,
                style: AppType.label.copyWith(color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

/// Address search.
///
/// Submit-driven by design: Nominatim's usage policy forbids implementing
/// as-you-type search against the public API, so there is no query-on-keystroke
/// path here and adding one would get the app blocked.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final List<PlaceSearchResult> results;
  final VoidCallback onSubmit;
  final ValueChanged<PlaceSearchResult> onSelect;

  const _SearchBar({
    required this.controller,
    required this.searching,
    required this.results,
    required this.onSubmit,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSubmit(),
          style: AppType.body.copyWith(color: scheme.onSurface),
          decoration: InputDecoration(
            isDense: true,
            hintText: L.of(context).editorSearchHint,
            prefixIcon: const Icon(Icons.search, size: IconSize.md),
            suffixIcon: searching
                ? const Padding(
                    padding: EdgeInsets.all(Space.sm),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: L.of(context).actionSearch,
                    icon: const Icon(Icons.arrow_forward, size: IconSize.md),
                    onPressed: onSubmit,
                  ),
          ),
        ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: Space.xs),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: Radii.cardShape,
              border: Border.all(color: scheme.outline, width: Strokes.hairline),
            ),
            child: Column(
              children: [
                for (final r in results)
                  ListTile(
                    dense: true,
                    title: Text(r.primary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.title.copyWith(color: scheme.onSurface)),
                    subtitle: Text(r.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.bodySmall
                            .copyWith(color: scheme.onSurfaceVariant)),
                    onTap: () => onSelect(r),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Warns that this Quiet Place shares ground with another, and says which
/// setting actually wins there — resolved with the same rule the engine uses,
/// so the warning can never contradict the device's behaviour.
class _OverlapNotice extends StatelessWidget {
  final List<PlaceOverlap> overlaps;
  final QuietPlaceBehaviour behaviour;

  const _OverlapNotice({required this.overlaps, required this.behaviour});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final overridden = overlaps.where((o) => o.otherWins).toList();

    final String message;
    if (overridden.isNotEmpty) {
      final names = overridden.map((o) => o.other.name).join(', ');
      message = l.overlapStricterWins(
          names, overridden.first.winner.labelOf(l));
    } else {
      final names = overlaps.map((o) => o.other.name).join(', ');
      message = l.overlapThisWins(names, behaviour.labelOf(l));
    }

    return _Notice(
      icon: Icons.join_inner,
      tone: _NoticeTone.info,
      child: Text(
        message,
        style: AppType.bodySmall.copyWith(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

/// Says how to move the place.
///
/// Added because it was not discoverable: the map looks like a picture until
/// you happen to try dragging the pin. The wording differs by mode, since the
/// offline dial and the map are moved in different ways.
class _EditorHint extends StatelessWidget {
  final bool mapsEnabled;
  const _EditorHint({required this.mapsEnabled});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.touch_app_outlined,
            size: IconSize.sm, color: scheme.onSurfaceVariant),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Text(
            mapsEnabled ? l.editorHintMap : l.editorHintDial,
            style: AppType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
