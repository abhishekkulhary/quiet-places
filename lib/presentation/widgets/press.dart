import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Weight of haptic feedback, mapped to intent rather than to a platform API.
enum Hap {
  /// Passing a detent while dragging.
  detent,

  /// Toggling something.
  toggle,

  /// Committing: save, delete.
  commit,

  /// The signature moment — the phone actually going quiet.
  event,
}

/// Central haptics so weight stays consistent and is easy to audit.
abstract final class Haptics {
  static void fire(Hap kind) {
    switch (kind) {
      case Hap.detent:
        HapticFeedback.selectionClick();
      case Hap.toggle:
        HapticFeedback.lightImpact();
      case Hap.commit:
        HapticFeedback.mediumImpact();
      case Hap.event:
        HapticFeedback.heavyImpact();
    }
  }
}

/// Wraps a child with a springy press-scale.
///
/// The scale is driven by a real [AnimationController] with a spring-ish curve
/// rather than an implicit tween, so press and release feel physical and the
/// release can overshoot slightly. Collapses to a plain tap target when the
/// user has asked for reduced motion.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double pressedScale;
  final Hap? haptic;

  /// Semantic label for screen readers. Required for interactive elements.
  final String? semanticLabel;

  const PressableScale({
    super.key,
    required this.child,
    this.onPressed,
    this.pressedScale = 0.96,
    this.haptic = Hap.commit,
    this.semanticLabel,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.fast,
    reverseDuration: Motion.base,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null;

  void _down(_) {
    if (!_enabled || Motion.reduced(context)) return;
    _c.forward();
  }

  void _up([_]) {
    if (!_enabled || Motion.reduced(context)) return;
    _c.reverse();
  }

  void _tap() {
    if (!_enabled) return;
    if (widget.haptic != null) Haptics.fire(widget.haptic!);
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _up,
        onTap: _tap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            // easeOutBack on release gives a small, satisfying overshoot.
            final t = Motion.spring.transform(_c.value.clamp(0.0, 1.0));
            final scale = 1 - (1 - widget.pressedScale) * t;
            return Transform.scale(scale: scale, child: child);
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Shimmering placeholder used instead of spinners.
class Skeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius radius;

  const Skeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = const BorderRadius.all(Radius.circular(Radii.sm)),
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A looping shimmer is decorative — drop it entirely under reduced motion
    // rather than merely speeding it up.
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Motion.reduced(context) ? 0.5 : _c.value;
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: widget.radius,
              color: Color.lerp(
                scheme.surfaceContainer,
                scheme.surfaceContainerHighest,
                t,
              ),
            ),
          );
        },
      ),
    );
  }
}
