import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/place_distance.dart';
import '../../domain/entities/quiet_place.dart';
import '../../domain/entities/quiet_place_behaviour.dart';
import '../distance_format.dart';
import '../l10n_extensions.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'press.dart';
import '../../l10n/app_localizations.dart';

/// A place in the list.
///
/// The card carries its state visually: a breathing lime ring when you're
/// currently inside it, a distance readout when you're near, and a desaturated
/// treatment when disabled. The place name is the largest thing on the card.
class QuietPlaceCard extends StatelessWidget {
  final QuietPlace place;

  /// Live distance readout. Null while the first fix is still arriving.
  final PlaceDistanceDisplay? distance;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const QuietPlaceCard({
    super.key,
    required this.place,
    required this.distance,
    required this.onToggle,
    required this.onTap,
    this.onLongPress,
  });

  bool get _inside =>
      distance?.side == BoundarySide.inside && place.enabled;

  bool get _uncertain =>
      distance?.confidence == DistanceConfidence.uncertain;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;
    final dim = !place.enabled;


    return Semantics(
      container: true,
      label: [
        l.placeCardSemantic(
          place.name,
          place.behaviour.labelOf(l),
          place.radiusMeters.round(),
        ),
        if (distance != null) distance!.detail,
        if (_uncertain) l.semanticPositionUncertain,
        if (!place.enabled) l.semanticDisabled,
      ].join(', '),
      child: PressableScale(
        onPressed: onTap,
        pressedScale: 0.985,
        haptic: Hap.toggle,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.base),
            curve: Motion.decelerate,
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: Elevation.surfaceFor(scheme, Elevation.raised),
              borderRadius: Radii.cardShape,
              border: Border.all(
                color: _inside ? accents.ring : accents.glassEdge,
                width: _inside ? Strokes.ring : Strokes.hairline,
              ),
              // Inside a place the card lights up; otherwise it rests. The glow
              // is always the bright lime fill colour — the olive text accent
              // would read as a smudge through the glass in light mode.
              boxShadow: _inside
                  ? Elevation.glowFor(Palette.lime, strength: 0.8)
                  : Elevation.shadowFor(scheme, Elevation.raised),
            ),
            child: Row(
              children: [
                _ProximityDial(
                  behaviour: place.behaviour,
                  inside: _inside,
                  dim: dim,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.headline.copyWith(
                          color: dim ? scheme.onSurfaceVariant : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: Space.xxs),
                      _DistanceLine(
                        place: place,
                        distance: distance,
                        inside: _inside,
                        uncertain: _uncertain,
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: l.placeEnabledSemantic(place.name),
                  child: Switch(
                    value: place.enabled,
                    onChanged: (v) {
                      Haptics.fire(Hap.toggle);
                      onToggle(v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Concentric-ring badge: the app's core motif, doubling as the behaviour icon
/// and the "you are inside" indicator.
class _ProximityDial extends StatefulWidget {
  final QuietPlaceBehaviour behaviour;
  final bool inside;
  final bool dim;

  const _ProximityDial({
    required this.behaviour,
    required this.inside,
    required this.dim,
  });

  @override
  State<_ProximityDial> createState() => _ProximityDialState();
}

class _ProximityDialState extends State<_ProximityDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _ProximityDial old) {
    super.didUpdateWidget(old);
    if (old.inside != widget.inside) _sync();
  }

  /// The breathing pulse only runs while inside, and never under reduced
  /// motion — where the ring is simply drawn at full strength instead.
  void _sync() {
    if (widget.inside && !Motion.reduced(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  IconData get _icon => widget.behaviour.icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;
    final color = widget.dim
        ? scheme.onSurfaceVariant
        : (widget.inside ? accents.ring : scheme.onSurface);

    return ExcludeSemantics(
      child: SizedBox(
        width: Sizes.dial,
        height: Sizes.dial,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => CustomPaint(
            painter: _DialPainter(
              color: color,
              glow: widget.inside ? accents.glow : null,
              pulse: _c.value,
            ),
            child: child,
          ),
          child: Center(child: Icon(_icon, size: IconSize.md, color: color)),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final Color color;
  final Color? glow;
  final double pulse;

  _DialPainter({required this.color, required this.glow, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    // Outer breathing halo, only when inside.
    final g = glow;
    if (g != null) {
      final t = 0.35 + 0.65 * pulse;
      canvas.drawCircle(
        center,
        maxR * (0.82 + 0.18 * t),
        Paint()..color = g.withValues(alpha: 0.10 * t),
      );
    }

    // Two concentric rings — the motif.
    canvas.drawCircle(
      center,
      maxR - 1,
      Paint()
        ..color = color.withValues(alpha: glow != null ? 0.9 : 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow != null ? Strokes.ring : Strokes.hairline,
    );
    canvas.drawCircle(
      center,
      maxR * 0.62,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.hairline,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.color != color || old.glow != glow || old.pulse != pulse;
}

/// Empty-state illustration: concentric rings with a pin at the centre, drawn
/// rather than shipped as an image so it themes correctly and costs nothing.
class EmptyPlacesArt extends StatelessWidget {
  const EmptyPlacesArt({super.key});

  @override
  Widget build(BuildContext context) {
    final accents = context.accents;
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        width: 180,
        height: 180,
        child: CustomPaint(
          painter: _EmptyArtPainter(
            ring: accents.ring,
            grid: accents.grid,
            pin: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _EmptyArtPainter extends CustomPainter {
  final Color ring;
  final Color grid;
  final Color pin;

  _EmptyArtPainter({required this.ring, required this.grid, required this.pin});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    for (var i = 4; i >= 1; i--) {
      final t = i / 4;
      canvas.drawCircle(
        center,
        maxR * t,
        Paint()
          ..color = ring.withValues(alpha: 0.10 + 0.16 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 2 ? Strokes.ring : Strokes.hairline,
      );
    }

    // Dashed cross-hair through the middle.
    final dash = Paint()
      ..color = grid
      ..strokeWidth = Strokes.hairline;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(
          Offset(x, center.dy), Offset(x + 4, center.dy), dash);
    }
    for (double y = 0; y < size.height; y += 10) {
      canvas.drawLine(
          Offset(center.dx, y), Offset(center.dx, y + 4), dash);
    }

    // Centre marker.
    canvas.drawCircle(center, 7, Paint()..color = ring);
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..color = ring.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.ring,
    );
    // Tick marks at the cardinal points.
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (maxR - 10);
      final p2 = center + Offset(math.cos(a), math.sin(a)) * maxR;
      canvas.drawLine(
          p1, p2, Paint()..color = ring..strokeWidth = Strokes.ring);
    }
  }

  @override
  bool shouldRepaint(_EmptyArtPainter old) => old.ring != ring;
}

/// The distance readout: two related facts on one legible line.
///
/// The primary number is distance to the centre; the secondary clause says
/// which side of the boundary you are on and by how much. When GPS accuracy is
/// larger than the distance to the edge the whole line is rendered in the
/// uncertain treatment — dimmed, with a "~" prefix and the ± figure — because
/// a precise-looking number we cannot back up is worse than an honest hedge.
class _DistanceLine extends StatelessWidget {
  final QuietPlace place;
  final PlaceDistanceDisplay? distance;
  final bool inside;
  final bool uncertain;

  const _DistanceLine({
    required this.place,
    required this.distance,
    required this.inside,
    required this.uncertain,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;
    final d = distance;

    // First fix still pending: show the place's own settings, not a fake zero.
    if (d == null) {
      return Text(
        '${place.behaviour.labelOf(L.of(context)).toUpperCase()}'
        '  ·  ${place.radiusMeters.round()} ${L.of(context).editorUnitMetresShort}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppType.label.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    if (d.confidence == DistanceConfidence.unknown) {
      return Text(
        d.detail.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppType.label.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    final emphasis = uncertain
        ? scheme.onSurfaceVariant
        : (inside ? accents.accentInk : scheme.onSurface);

    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: uncertain ? '~${d.centre}' : d.centre,
          style: AppType.label.copyWith(color: emphasis),
        ),
        TextSpan(
          text: '  ·  ${d.detail}',
          style: AppType.label.copyWith(
            color: inside && !uncertain
                ? accents.accentInk
                : scheme.onSurfaceVariant,
          ),
        ),
        if (uncertain && d.accuracy != null)
          TextSpan(
            text: '  ${d.accuracy}',
            style: AppType.label.copyWith(color: scheme.onSurfaceVariant),
          ),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
