import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dander/core/motion/dander_motion.dart';

/// Transition builder for tab switches — crossfade over 200ms.
Widget crossfadeTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

/// Transition builder for push navigation — slide in from right over 250ms.
Widget slideRightTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}

/// Creates a crossfade tab-switch page (200ms).
///
/// Returns [NoTransitionPage] when reduced motion is enabled.
Page<void> danderCrossfadePage(BuildContext context, Widget child) {
  if (DanderMotion.isReduced(context)) {
    return NoTransitionPage<void>(child: child);
  }
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: crossfadeTransitionBuilder,
  );
}

/// Creates a slide-from-right push navigation page (250ms).
///
/// Returns [NoTransitionPage] when reduced motion is enabled.
Page<void> danderSlideRightPage(BuildContext context, Widget child) {
  if (DanderMotion.isReduced(context)) {
    return NoTransitionPage<void>(child: child);
  }
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: slideRightTransitionBuilder,
  );
}
