import 'package:flutter/material.dart';

import 'dirassty_tokens.dart';

/// Pushed screens slide in from the end edge in 280 ms (DESIGN_SPEC §6
/// "Transitions") — from the right in French, from the left in Arabic —
/// while the screen underneath drifts a quarter-width the other way.
/// No motion at all when the OS asks for reduced motion.
///
/// Android only: iOS keeps Cupertino's transition, which already slides
/// from the end edge and carries the interactive swipe-back gesture.
class DirasstyPageTransitionsBuilder extends PageTransitionsBuilder {
  const DirasstyPageTransitionsBuilder();

  @override
  Duration get transitionDuration => DirasstyMotion.push;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final double dir = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(dir, 0), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: animation,
        curve: DirasstyMotion.curve,
        reverseCurve: Curves.easeInCubic,
      )),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset.zero, end: Offset(-dir * 0.25, 0))
            .animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: DirasstyMotion.curve,
          reverseCurve: Curves.easeInCubic,
        )),
        child: child,
      ),
    );
  }
}
