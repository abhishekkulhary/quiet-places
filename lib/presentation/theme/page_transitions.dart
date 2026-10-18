import 'package:flutter/material.dart';

import 'tokens.dart';

/// One route transition for the whole app.
///
/// Without this, every push uses Material's per-platform default — a different
/// motion language from the one the widgets use, which is the "per-screen
/// invention" the design brief warns against. This makes navigation obey the
/// same durations and curves as everything else:
///
///  * enter: fade up over [Motion.base] with [Motion.decelerate];
///  * exit: fade back down, slightly shorter, so returning feels lighter than
///    going forward;
///  * reduced motion: no movement and no fade at all — the destination is
///    simply there.
class QuietPageTransitions extends PageTransitionsBuilder {
  const QuietPageTransitions();

  /// How far the incoming page rises, as a fraction of its height. Small on
  /// purpose: the fade carries the transition, the slide only gives direction.
  static const double _rise = 0.035;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return child;

    final enter = CurvedAnimation(
      parent: animation,
      curve: Motion.decelerate,
      reverseCurve: Motion.decelerate.flipped,
    );

    // The outgoing page recedes slightly rather than sliding away, so the two
    // screens read as stacked depth rather than a carousel.
    final recede = Tween<double>(begin: 1, end: 0.985).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Motion.standard),
    );

    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, _rise),
          end: Offset.zero,
        ).animate(enter),
        child: ScaleTransition(scale: recede, child: child),
      ),
    );
  }
}

/// Applied to every platform so the app feels like itself rather than like the
/// OS it happens to be running on.
const PageTransitionsTheme quietPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: QuietPageTransitions(),
    TargetPlatform.iOS: QuietPageTransitions(),
    TargetPlatform.macOS: QuietPageTransitions(),
    TargetPlatform.windows: QuietPageTransitions(),
    TargetPlatform.linux: QuietPageTransitions(),
    TargetPlatform.fuchsia: QuietPageTransitions(),
  },
);
