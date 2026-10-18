import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/usecases/validate_radius.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'press.dart';
import '../../l10n/app_localizations.dart';

/// Detents where the dial "clicks". Chosen as the radii people actually reach
/// for: a room, a building, a block.
const List<double> radiusDetents = [100, 250, 500];

/// The hero of the Quiet Place editor: a concentric-ring instrument showing the
/// place circle over a metric grid, with the live GPS accuracy drawn as a halo
/// that visibly tightens as the fix improves.
///
/// Fully offline — this app ships no map tiles and holds no network permission,
/// so the "map" is drawn geometry plus a coordinate readout.
class RadiusDial extends StatelessWidget {
  final double radiusMeters;
  final double? accuracyMeters;
  final bool hasPosition;

  /// Non-null in manual mode: drag the canvas to move the pin.
  final void Function(double dxMeters, double dyMeters)? onDragMeters;

  /// Fired when a drag finishes, so the editor can snapshot one undo step.
  final VoidCallback? onDragEnd;

  const RadiusDial({
    super.key,
    required this.radiusMeters,
    required this.accuracyMeters,
    required this.hasPosition,
    this.onDragMeters,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;

    // The viewport always shows a little more than the radius, so the circle
    // scales within a stable frame rather than the frame jumping around.
    final span = radiusMeters * 1.7 + 40;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final metresToPx = (size.shortestSide / 2) / span;

        // Spring the drawn radius toward its target so dragging the slider
        // feels like turning a weighted dial rather than a jump-cut.
        Widget canvas = TweenAnimationBuilder<double>(
          tween: Tween(begin: radiusMeters, end: radiusMeters),
          duration: Motion.of(context, Motion.base),
          curve: Motion.spring,
          builder: (context, drawnRadius, _) {
            // The halo animates on its own clock: accuracy improves in discrete
            // jumps and the tightening is the point.
            return TweenAnimationBuilder<double>(
              tween: Tween(
                begin: accuracyMeters ?? 0,
                end: accuracyMeters ?? 0,
              ),
              duration: Motion.of(context, Motion.slow),
              curve: Motion.decelerate,
              builder: (context, drawnAccuracy, _) => CustomPaint(
                size: size,
                painter: _DialPainter(
                  radiusPx: drawnRadius * metresToPx,
                  accuracyPx: accuracyMeters == null
                      ? null
                      : drawnAccuracy * metresToPx,
                  hasPosition: hasPosition,
                  ring: accents.ring,
                  grid: accents.grid,
                  surface: scheme.onSurface,
                  label: '${radiusMeters.round()}',
                ),
              ),
            );
          },
        );

        if (onDragMeters != null) {
          canvas = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => onDragMeters!(
              d.delta.dx / metresToPx,
              -d.delta.dy / metresToPx, // screen y is down; north is up
            ),
            onPanEnd: (_) => onDragEnd?.call(),
            child: canvas,
          );
        }

        return Semantics(
          label: hasPosition
              ? l.mapPreviewSemantic(radiusMeters.round())
              : l.mapPreviewNoPosition,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: Container(color: scheme.surfaceContainer, child: canvas),
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  final double radiusPx;
  final double? accuracyPx;
  final bool hasPosition;
  final Color ring;
  final Color grid;
  final Color surface;
  final String label;

  _DialPainter({
    required this.radiusPx,
    required this.accuracyPx,
    required this.hasPosition,
    required this.ring,
    required this.grid,
    required this.surface,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    _paintGrid(canvas, size, center);

    // Accuracy halo, behind the place circle: a soft disc that shrinks as the
    // fix sharpens. This is the visible feedback for "improving accuracy".
    final acc = accuracyPx;
    if (hasPosition && acc != null && acc > 0) {
      final haloR = math.min(acc, maxR - 2);
      canvas.drawCircle(
          center, haloR, Paint()..color = ring.withValues(alpha: 0.10));
      canvas.drawCircle(
        center,
        haloR,
        Paint()
          ..color = ring.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = Strokes.hairline,
      );
    }

    // The place circle itself, with an inner echo ring for the concentric motif.
    final r = math.min(radiusPx, maxR - 8);
    canvas.drawCircle(
        center, r, Paint()..color = ring.withValues(alpha: 0.08));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.ring,
    );
    canvas.drawCircle(
      center,
      r * 0.55,
      Paint()
        ..color = ring.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.hairline,
    );

    // Cardinal ticks on the place circle — instrument detailing.
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (r - 6),
        center + dir * (r + 6),
        Paint()
          ..color = ring
          ..strokeWidth = Strokes.ring
          ..strokeCap = StrokeCap.round,
      );
    }

    if (!hasPosition) {
      _paintNoPosition(canvas, center);
      return;
    }

    // Centre pin.
    canvas.drawCircle(center, 5, Paint()..color = ring);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = ring.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.hairline,
    );
  }

  void _paintGrid(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = grid
      ..strokeWidth = Strokes.hairline;
    const step = 28.0;
    for (double x = center.dx % step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = center.dy % step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// Dashed crosshair standing in for the pin while we have no position.
  void _paintNoPosition(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = surface.withValues(alpha: 0.35)
      ..strokeWidth = Strokes.ring
      ..strokeCap = StrokeCap.round;
    const arm = 9.0;
    canvas.drawLine(
        center - const Offset(arm, 0), center + const Offset(arm, 0), paint);
    canvas.drawLine(
        center - const Offset(0, arm), center + const Offset(0, arm), paint);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.radiusPx != radiusPx ||
      old.accuracyPx != accuracyPx ||
      old.hasPosition != hasPosition ||
      old.ring != ring;
}

/// Radius control: an oversized numeral plus a slider that clicks at
/// [radiusDetents]. The numeral is the readout of a physical instrument, so it
/// uses the expanded display face with tabular figures (no width jitter while
/// dragging).
class RadiusControl extends StatefulWidget {
  final double radiusMeters;
  final ValueChanged<double> onChanged;

  const RadiusControl({
    super.key,
    required this.radiusMeters,
    required this.onChanged,
  });

  @override
  State<RadiusControl> createState() => _RadiusControlState();
}

class _RadiusControlState extends State<RadiusControl> {
  double? _lastValue;

  /// Fires a selection click whenever the value crosses one of the detents.
  void _handle(double next) {
    final prev = _lastValue ?? widget.radiusMeters;
    for (final detent in radiusDetents) {
      final crossed = (prev < detent && next >= detent) ||
          (prev > detent && next <= detent);
      if (crossed) {
        Haptics.fire(Hap.detent);
        break;
      }
    }
    _lastValue = next;
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;
    final validation = validateRadius(widget.radiusMeters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(l.editorFieldRadius,
                style: AppType.label.copyWith(color: scheme.onSurfaceVariant)),
            const Spacer(),
            // ExcludeSemantics: the slider below already announces the value,
            // so the numeral would be a duplicate announcement.
            ExcludeSemantics(
              child: Text(
                '${widget.radiusMeters.round()}',
                style: AppType.numeral.copyWith(
                  color: validation == RadiusValidation.unreliable
                      ? scheme.error
                      : accents.accentInk,
                ),
              ),
            ),
            const SizedBox(width: Space.xxs),
            Text(l.editorUnitMetresShort,
                style: AppType.label.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
        Slider(
          value: widget.radiusMeters,
          min: RadiusPolicy.minMeters,
          max: RadiusPolicy.maxMeters,
          divisions: 95,
          label: '${widget.radiusMeters.round()} m',
          semanticFormatterCallback: (v) => l.editorRadiusSemantic(v.round()),
          onChanged: _handle,
        ),
      ],
    );
  }
}
