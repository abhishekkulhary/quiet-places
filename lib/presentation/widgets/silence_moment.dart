import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/quiet_place_behaviour.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'press.dart';
import '../../l10n/app_localizations.dart';
import '../l10n_extensions.dart';

/// The app's signature moment: the confirmation shown when Quiet Places actually
/// mutes the phone.
///
/// Rings collapse inward and settle — sound folding into quiet — then the place
/// name and the applied behaviour resolve. Under reduced motion the same
/// information appears immediately with no animation at all.
class SilenceMomentOverlay extends StatefulWidget {
  final String placeName;
  final QuietPlaceBehaviour behaviour;

  /// True when leaving a place (rings expand outward instead of collapsing).
  final bool restoring;
  final VoidCallback onDismiss;

  const SilenceMomentOverlay({
    super.key,
    required this.placeName,
    required this.behaviour,
    required this.onDismiss,
    this.restoring = false,
  });

  @override
  State<SilenceMomentOverlay> createState() => _SilenceMomentOverlayState();
}

class _SilenceMomentOverlayState extends State<SilenceMomentOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.moment,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _verb(L l) => widget.restoring ? l.momentRestored : l.momentSilenced;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;

    return Semantics(
      liveRegion: true,
      label: widget.restoring
          ? l.momentSemanticRestored(widget.placeName)
          : l.momentSemanticApplied(
              widget.placeName, widget.behaviour.labelOf(l)),
      child: PressableScale(
        onPressed: widget.onDismiss,
        haptic: null,
        pressedScale: 0.99,
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: accents.ring, width: Strokes.hairline),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) => CustomPaint(
                    painter: _CollapsePainter(
                      t: Motion.decelerate.transform(_c.value),
                      color: accents.ring,
                      outward: widget.restoring,
                    ),
                    child: child,
                  ),
                  child: Center(
                    child: Icon(
                      widget.restoring
                          ? Icons.volume_up_outlined
                          : widget.behaviour.icon,
                      size: IconSize.md,
                      color: accents.accentInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_verb(l)} · ${widget.behaviour.label.toUpperCase()}',
                        style:
                            AppType.label.copyWith(color: accents.accentInk)),
                    const SizedBox(height: Space.xxs),
                    Text(
                      widget.placeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.headlineSmall
                          .copyWith(color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l.actionDismiss,
                icon: const Icon(Icons.close, size: IconSize.md),
                onPressed: widget.onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Concentric rings collapsing inward (or expanding outward when restoring).
class _CollapsePainter extends CustomPainter {
  final double t;
  final Color color;
  final bool outward;

  _CollapsePainter({
    required this.t,
    required this.color,
    required this.outward,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    for (var i = 0; i < 3; i++) {
      // Stagger the rings so they arrive in sequence rather than together.
      final delay = i * 0.18;
      final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      final progress = outward ? local : 1 - local;
      final radius = maxR * (0.35 + 0.65 * progress);
      final alpha = (outward ? 1 - local : local).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.10 + 0.45 * alpha * (1 - i * 0.25))
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 0 ? Strokes.ring : Strokes.hairline,
      );
    }

    // Settled inner disc.
    canvas.drawCircle(
      center,
      maxR * 0.34,
      Paint()..color = color.withValues(alpha: 0.12 * t),
    );
  }

  @override
  bool shouldRepaint(_CollapsePainter old) => old.t != t;
}

/// Full-bleed variant used the first time a place fires, to make the payoff
/// unmistakable. Auto-dismisses; tapping anywhere closes it early.
class SilenceMomentSheet extends StatelessWidget {
  final String placeName;
  final QuietPlaceBehaviour behaviour;

  const SilenceMomentSheet({
    super.key,
    required this.placeName,
    required this.behaviour,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;

    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Motion.of(context, Motion.moment),
              curve: Motion.decelerate,
              builder: (context, t, _) => CustomPaint(
                painter: _CollapsePainter(
                    t: t, color: accents.ring, outward: false),
                child: Center(
                  child: Transform.rotate(
                    angle: (1 - t) * math.pi / 8,
                    child: Icon(behaviour.icon,
                        size: IconSize.hero, color: accents.accentInk),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          Text(l.momentNowBehaviour(behaviour.labelOf(l).toUpperCase()),
              style: AppType.label.copyWith(color: accents.accentInk)),
          const SizedBox(height: Space.xs),
          Text(placeName,
              textAlign: TextAlign.center,
              style:
                  AppType.displayMedium.copyWith(color: scheme.onSurface)),
          const SizedBox(height: Space.xs),
          Text(l.momentRestoreExplain,
              textAlign: TextAlign.center,
              style:
                  AppType.body.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
