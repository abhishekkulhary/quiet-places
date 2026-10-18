import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/map/cached_tile_provider.dart';
import '../../data/map/tile_cache.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/usecases/geodesy.dart';
import '../../domain/usecases/validate_radius.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/press.dart';
import '../widgets/radius_dial.dart';
import '../../l10n/app_localizations.dart';

/// Interactive OSM map for editing a Quiet Place.
///
/// Only ever built when the user has opted into maps; the editor falls back to
/// the offline dial otherwise. Rotation is locked (a rotated map makes the
/// radius handle ambiguous and buys nothing here).
class PlaceMapEditor extends StatefulWidget {
  final LatLng centre;
  final double radiusMeters;

  /// Other saved places, drawn dimmed for context.
  final List<QuietPlace> otherPlaces;

  /// Live device position, if known.
  final LatLng? userPosition;
  final double? userAccuracyMeters;

  final ValueChanged<LatLng> onCentreChanged;

  /// Fired when a centre-moving gesture finishes, so the editor can snapshot
  /// one undo step and look up a name once.
  final VoidCallback onCentreSettled;

  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onRadiusSettled;

  /// False for the read-only overview pane on wide screens: the map still pans
  /// and zooms, but the pin and radius handle are not offered, so there is only
  /// ever one editing surface.
  final bool interactive;

  const PlaceMapEditor({
    super.key,
    required this.centre,
    required this.radiusMeters,
    required this.otherPlaces,
    required this.userPosition,
    required this.userAccuracyMeters,
    required this.onCentreChanged,
    required this.onCentreSettled,
    required this.onRadiusChanged,
    required this.onRadiusSettled,
    this.interactive = true,
  });

  @override
  State<PlaceMapEditor> createState() => _PlaceMapEditorState();
}

class _PlaceMapEditorState extends State<PlaceMapEditor> {
  final MapController _map = MapController();

  /// Used to convert a drag's global position into the map's own coordinate
  /// space before asking the camera to unproject it.
  final GlobalKey _mapKey = GlobalKey();
  final TileCache _cache = TileCache();
  late final CachedOsmTileProvider _tiles = CachedOsmTileProvider(
    cache: _cache,
    onNetworkFailure: () {
      if (mounted && !_offline) setState(() => _offline = true);
    },
  );

  /// True while the radius handle is being dragged, so map panning is
  /// suppressed and the gesture cannot fight the drag.
  bool _draggingHandle = false;

  /// Last radius at which a detent fired, so we click once per crossing.
  double? _lastRadius;

  /// Set once a tile fetch has failed, so we can say why the map looks sparse
  /// instead of leaving the user to guess.
  bool _offline = false;

  @override
  void dispose() {
    _tiles.dispose();
    _map.dispose();
    super.dispose();
  }

  /// The handle sits due east of the centre, on the circle.
  LatLng get _handlePosition {
    const metresPerDegLat = 111320.0;
    final metresPerDegLng = metresPerDegLat *
        math.cos(widget.centre.latitude * math.pi / 180).abs().clamp(0.01, 1);
    return LatLng(
      widget.centre.latitude,
      widget.centre.longitude + widget.radiusMeters / metresPerDegLng,
    );
  }

  void _onHandleDrag(LatLng point) {
    // Radius is the true geodesic distance from centre to wherever the finger
    // is, so dragging is accurate at any latitude.
    final radius = geodesicDistance(
      widget.centre.latitude,
      widget.centre.longitude,
      point.latitude,
      point.longitude,
    );
    final clamped = clampRadius(radius);

    // Haptic detents, once per crossing.
    final previous = _lastRadius ?? widget.radiusMeters;
    for (final detent in radiusDetents) {
      final crossed = (previous < detent && clamped >= detent) ||
          (previous > detent && clamped <= detent);
      if (crossed) {
        Haptics.fire(Hap.detent);
        break;
      }
    }
    _lastRadius = clamped;
    widget.onRadiusChanged(clamped);
  }

  void _recentreOnUser() {
    final me = widget.userPosition;
    if (me == null) return;
    Haptics.fire(Hap.toggle);
    _map.move(me, math.max(_map.camera.zoom, 16));
  }

  Future<void> _openAttribution() async {
    // OSM attribution is a licence requirement, and must actually work.
    final uri = Uri.parse('https://www.openstreetmap.org/copyright');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: Stack(
        children: [
          // A neutral grid sits under the tiles, so missing tiles read as
          // "not downloaded" rather than as an error.
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(colour: accents.grid)),
          ),
          FlutterMap(
            key: _mapKey,
            mapController: _map,
            options: MapOptions(
              initialCenter: widget.centre,
              initialZoom: 16,
              minZoom: 3,
              maxZoom: 18,
              // Rotation locked deliberately; everything else stays available.
              interactionOptions: InteractionOptions(
                flags: _draggingHandle
                    ? InteractiveFlag.none
                    : InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onLongPress: widget.interactive
                  ? (_, point) {
                      Haptics.fire(Hap.commit);
                      widget.onCentreChanged(point);
                      widget.onCentreSettled();
                    }
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: osmTileUrlTemplate,
                tileProvider: _tiles,
                userAgentPackageName: 'app.phonesilent',
                maxNativeZoom: 19,
                // Explicitly no prefetch: only what is on screen is requested.
                panBuffer: 0,
              ),
              // Other saved places, dimmed for context.
              CircleLayer(
                circles: [
                  for (final other in widget.otherPlaces)
                    CircleMarker(
                      point: LatLng(other.latitude, other.longitude),
                      radius: other.radiusMeters,
                      useRadiusInMeter: true,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.08),
                      borderColor:
                          scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderStrokeWidth: Strokes.hairline,
                    ),
                ],
              ),
              // Device position: accuracy halo, visually distinct from the
              // Quiet Place circle (filled, cool, no hard border).
              if (widget.userPosition != null)
                CircleLayer(
                  circles: [
                    if (widget.userAccuracyMeters != null)
                      CircleMarker(
                        point: widget.userPosition!,
                        radius: widget.userAccuracyMeters!,
                        useRadiusInMeter: true,
                        color: scheme.secondary.withValues(alpha: 0.15),
                        borderColor: scheme.secondary.withValues(alpha: 0.4),
                        borderStrokeWidth: Strokes.hairline,
                      ),
                  ],
                ),
              // The Quiet Place being edited.
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.centre,
                    radius: widget.radiusMeters,
                    useRadiusInMeter: true,
                    color: accents.ring.withValues(alpha: 0.12),
                    borderColor: accents.ring,
                    borderStrokeWidth: Strokes.ring,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (widget.userPosition != null)
                    Marker(
                      point: widget.userPosition!,
                      width: 18,
                      height: 18,
                      child: _UserDot(colour: scheme.secondary),
                    ),
                  // Centre pin — draggable when editing.
                  if (widget.interactive)
                    Marker(
                    point: widget.centre,
                    width: Hit.min,
                    height: Hit.min,
                    child: _CentrePin(
                      colour: accents.ring,
                      onDrag: _movePin,
                      onDragEnd: widget.onCentreSettled,
                    ),
                  ),
                  // Radius handle — editing only.
                  if (widget.interactive)
                    Marker(
                    point: _handlePosition,
                    width: Hit.min,
                    height: Hit.min,
                    child: _RadiusHandle(
                      colour: accents.ring,
                      onStart: () => setState(() => _draggingHandle = true),
                      onEnd: () {
                        setState(() {
                          _draggingHandle = false;
                          _lastRadius = null;
                        });
                        widget.onRadiusSettled();
                      },
                      onDrag: (global) {
                        final point = _latLngFromGlobal(global);
                        if (point != null) _onHandleDrag(point);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Recentre control.
          Positioned(
            right: Space.xs,
            bottom: Space.xl,
            child: _MapButton(
              icon: Icons.my_location,
              tooltip: l.mapRecentre,
              onPressed: widget.userPosition == null ? null : _recentreOnUser,
            ),
          ),
          if (_offline)
            Positioned(
              left: Space.xs,
              top: Space.xs,
              right: Space.xs,
              child: _OfflineChip(
                label: l.stateOfflineTitle,
                detail: l.stateOfflineBody,
              ),
            ),
          // OSM attribution — a licence requirement, so it is always visible
          // and always tappable.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _openAttribution,
              child: Container(
                color: scheme.surface.withValues(alpha: 0.72),
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.xs, vertical: 3),
                child: Semantics(
                  link: true,
                  child: Text(
                    l.mapAttribution,
                    textAlign: TextAlign.end,
                    style: AppType.micro.copyWith(
                      color: scheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _movePin(Offset global) {
    final point = _latLngFromGlobal(global);
    if (point != null) widget.onCentreChanged(point);
  }

  /// Global drag coordinates -> map-local -> LatLng.
  LatLng? _latLngFromGlobal(Offset global) {
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return _map.camera.screenOffsetToLatLng(box.globalToLocal(global));
  }
}

class _CentrePin extends StatelessWidget {
  final Color colour;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;
  const _CentrePin({
    required this.colour,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: L.of(context).mapCentreSemantic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => onDrag(d.globalPosition),
        onPanEnd: (_) => onDragEnd(),
        child: Center(
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colour,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Palette.mapMarkerStroke, width: Strokes.ring),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadiusHandle extends StatelessWidget {
  final Color colour;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const _RadiusHandle({
    required this.colour,
    required this.onDrag,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: L.of(context).mapHandleSemantic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onStart(),
        onPanUpdate: (d) => onDrag(d.globalPosition),
        onPanEnd: (_) => onEnd(),
        onPanCancel: onEnd,
        child: Center(
          child: Container(
            width: Sizes.mapHandle,
            height: Sizes.mapHandle,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colour, width: Strokes.ring),
            ),
            child: Icon(Icons.drag_indicator, size: IconSize.xs, color: colour),
          ),
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  final Color colour;
  const _UserDot({required this.colour});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: colour,
            shape: BoxShape.circle,
            border: Border.all(
                color: Palette.mapMarkerStroke, width: Strokes.ring),
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: Hit.min,
            height: Hit.min,
            child: Icon(
              icon,
              size: IconSize.md,
              color: onPressed == null
                  ? scheme.onSurfaceVariant
                  : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Neutral grid painted beneath the tiles.
class _GridPainter extends CustomPainter {
  final Color colour;
  _GridPainter({required this.colour});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..strokeWidth = Strokes.hairline;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.colour != colour;
}

/// Explains a sparse map rather than leaving the user to wonder.
///
/// The map itself already degrades gracefully — cached tiles, then a neutral
/// grid — so this is information, not an error.
class _OfflineChip extends StatelessWidget {
  final String label;
  final String detail;
  const _OfflineChip({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: '$label. $detail',
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.sm, vertical: Space.xs),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: scheme.outline, width: Strokes.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: IconSize.sm, color: scheme.onSurface),
            const SizedBox(width: Space.xs),
            Flexible(
              child: Text('$label · $detail',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(color: scheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}
