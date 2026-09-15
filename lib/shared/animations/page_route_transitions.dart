import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'springs.dart';

/// Cupertino slide — standard iOS horizontal slide with swipe-back support.
CupertinoPage<T> cupertinoSlide<T>({
  required Widget child,
  bool fullscreenDialog = false,
  LocalKey? key,
}) {
  return CupertinoPage<T>(
    key: key,
    child: child,
    fullscreenDialog: fullscreenDialog,
  );
}

/// Fade-through transition — for modal screens (settings, analytics, add).
CustomTransitionPage<T> fadeThrough<T>({
  required Widget child,
  bool fullscreenDialog = false,
  LocalKey? key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: GengaSprings.medium,
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      );
      final fadeOut = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      );
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: GengaSprings.smooth));
      final scale = Tween<double>(
        begin: 0.96,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: GengaSprings.smooth));

      final secondaryFade = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut),
      );

      return FadeTransition(
        opacity: secondaryFade,
        child: FadeTransition(
          opacity: animation.status == AnimationStatus.reverse
              ? fadeOut
              : fadeIn,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: child),
          ),
        ),
      );
    },
  );
}

/// Cross-fade with a faint scale — switching between pill tabs.
CustomTransitionPage<T> tabFade<T>({required Widget child, LocalKey? key}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: GengaSprings.medium,
    reverseTransitionDuration: GengaSprings.quick,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Fade only, so a Hero flight is the star of the transition.
CustomTransitionPage<T> heroFade<T>({required Widget child, LocalKey? key}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: GengaSprings.slow,
    reverseTransitionDuration: GengaSprings.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.4, curve: Curves.easeOut),
            reverseCurve: const Interval(0.5, 1, curve: Curves.easeIn),
          ),
          child: child,
        ),
  );
}
