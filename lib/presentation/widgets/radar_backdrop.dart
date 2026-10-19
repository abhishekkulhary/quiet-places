import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A [Scaffold] standing on the radar backdrop.
///
/// Every screen uses this instead of a bare [Scaffold], so the backdrop is one
/// decision rather than six. The backdrop is opaque and belongs to the route,
/// which keeps page transitions clean: the incoming page never shows the
/// outgoing page's content through a transparent ground.
class QuietScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;

  const QuietScaffold({super.key, this.appBar, this.body});

  @override
  Widget build(BuildContext context) {
    return RadarBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
      ),
    );
  }
}

/// The page ground: concentric radar rings sweeping in from the top-right
/// corner over a faint dot grid, lit by a soft glow at their origin.
///
/// Static by design — the app's motion budget belongs to the signature
/// silencing moment and the inside-place pulse, not to wallpaper.
class RadarBackdrop extends StatelessWidget {
  final Widget child;

  const RadarBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _RadarPainter(
              ground: scheme.surface,
              ring: accents.backdropRing,
              dot: accents.backdropDot,
              glow: accents.backdropGlow,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Color ground;
  final Color ring;
  final Color dot;
  final Color glow;

  _RadarPainter({
    required this.ground,
    required this.ring,
    required this.dot,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = ground);

    final origin = Backdrop.origin.alongSize(size);

    // Soft light where the rings originate.
    final glowRadius = size.width * Backdrop.glowRadius;
    canvas.drawCircle(
      origin,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [glow, glow.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: origin, radius: glowRadius)),
    );

    // Dot grid, fading out with distance from the origin so the bottom of the
    // screen — where the list lives — stays calm.
    final reach = math.sqrt(size.width * size.width + size.height * size.height);
    final dotPaint = Paint();
    for (var y = Backdrop.dotSpacing / 2; y < size.height; y += Backdrop.dotSpacing) {
      for (var x = Backdrop.dotSpacing / 2; x < size.width; x += Backdrop.dotSpacing) {
        final p = Offset(x, y);
        final fade = 1 - ((p - origin).distance / reach).clamp(0.0, 1.0);
        dotPaint.color = dot.withValues(alpha: dot.a * (0.25 + 0.75 * fade));
        canvas.drawCircle(p, Backdrop.dotRadius, dotPaint);
      }
    }

    // Radar rings: every third one slightly stronger, like range markers.
    for (var i = 1; i <= Backdrop.ringCount; i++) {
      final strong = i % 3 == 0;
      canvas.drawCircle(
        origin,
        Backdrop.ringSpacing * i,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strong ? Strokes.ring : Strokes.hairline
          ..color = ring.withValues(
            alpha: ring.a * (strong ? 1.0 : 0.7) * (1 - i / (Backdrop.ringCount + 2)),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.ground != ground || old.ring != ring || old.dot != dot || old.glow != glow;
}
