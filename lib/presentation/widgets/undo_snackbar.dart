import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'press.dart';
import '../../l10n/app_localizations.dart';

/// Snackbar with a visible countdown ring, used in place of a confirmation
/// dialog: the destructive action already happened and the user can take it
/// back while the ring drains.
///
/// Under reduced motion the ring is replaced by a plain seconds counter, so the
/// remaining time is still legible without animation.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  Duration duration = Motion.undoWindow,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      content: Row(
        children: [
          _UndoCountdown(duration: duration),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(message, style: AppType.body)),
          TextButton(
            onPressed: () {
              Haptics.fire(Hap.toggle);
              messenger.hideCurrentSnackBar();
              onUndo();
            },
            child: Text(L.of(context).undoLabel),
          ),
        ],
      ),
    ),
  );
}

class _UndoCountdown extends StatefulWidget {
  final Duration duration;
  const _UndoCountdown({required this.duration});

  @override
  State<_UndoCountdown> createState() => _UndoCountdownState();
}

class _UndoCountdownState extends State<_UndoCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_c.isAnimating && _c.value == 0) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final accents = context.accents;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final remaining =
            (widget.duration.inSeconds * (1 - _c.value)).ceil().clamp(0, 99);
        if (Motion.reduced(context)) {
          return SizedBox(
            width: 24,
            child: Text('${remaining}s',
                style: AppType.label.copyWith(color: scheme.onSurface)),
          );
        }
        return SizedBox(
          width: 24,
          height: 24,
          child: Semantics(
            label: l.undoSecondsRemaining(remaining),
            child: CustomPaint(
              painter: _RingPainter(
                progress: 1 - _c.value,
                color: accents.accentInk,
                track: scheme.outline,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2 - Strokes.ring / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.ring,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // 12 o'clock
      6.28318 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.ring
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
