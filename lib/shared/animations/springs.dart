import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart';

/// A [Curve] driven by a real spring simulation, normalized so the
/// animation always ends exactly at 1.0 after [settleSeconds].
class SpringCurve extends Curve {
  final SpringDescription spring;
  final double settleSeconds;

  const SpringCurve(this.spring, {this.settleSeconds = 0.6});

  @override
  double transformInternal(double t) {
    if (t >= 1) return 1;
    return SpringSimulation(spring, 0, 1, 0).x(t * settleSeconds);
  }
}

abstract final class GengaMotion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Central animation configuration for the entire Genga app.
///
/// All spring configs, durations, and curves are defined here so motion
/// feels consistent across every screen and widget.
abstract final class GengaSprings {
  // ── Spring Curves (approximated as Cubic for Implicit animations) ──

  /// Snappy spring with overshoot — buttons, toggles, small elements.
  static const Curve snappy = SpringCurve(
    SpringDescription(mass: 1.0, stiffness: 600, damping: 30),
    settleSeconds: 0.45,
  );

  /// Smooth spring with slight overshoot — page elements, cards.
  static const Curve smooth = SpringCurve(
    SpringDescription(mass: 1.0, stiffness: 300, damping: 24),
    settleSeconds: 0.7,
  );

  /// Gentle spring with no overshoot — large surfaces, backgrounds.
  static const Curve gentle = Cubic(0.4, 0.0, 0.2, 1);

  /// Default entrance curve — fade + slide elements appearing on screen.
  static const Curve entrance = Cubic(0.0, 0.0, 0.2, 1);

  /// Exit curve — elements leaving the screen.
  static const Curve exit = Cubic(0.4, 0.0, 1.0, 1);

  // ── Spring Descriptions (for physics-based AnimationControllers) ──

  /// Snappy spring simulation — quick settle, moderate bounce.
  static SpringDescription get snappySpring =>
      const SpringDescription(mass: 1.0, stiffness: 600, damping: 30);

  /// Smooth spring — slower settle, gentle bounce.
  static SpringDescription get smoothSpring =>
      const SpringDescription(mass: 1.0, stiffness: 300, damping: 22);

  /// Bouncy spring — for playful, attention-grabbing motion.
  static SpringDescription get bouncySpring =>
      const SpringDescription(mass: 1.0, stiffness: 400, damping: 15);

  // ── Standard Durations ──

  /// Ultra-fast — press feedback, toggle states.
  static const Duration pressDuration = Duration(milliseconds: 60);

  /// Fast release — button release, chip toggle.
  static const Duration releaseDuration = Duration(milliseconds: 150);

  /// Quick — micro-interactions, color changes.
  static const Duration quick = Duration(milliseconds: 200);

  /// Medium — element entrances, state transitions.
  static const Duration medium = Duration(milliseconds: 350);

  /// Slow — page transitions, large surface changes.
  static const Duration slow = Duration(milliseconds: 500);

  /// Orchestration — total duration for staggered group entrances.
  static const Duration orchestration = Duration(milliseconds: 600);

  // ── Stagger Helpers ──

  /// Delay between each element in a staggered entrance group.
  static const Duration staggerInterval = Duration(milliseconds: 50);

  /// Calculate the delay for element at [index] in a stagger sequence.
  static Duration staggerDelay(int index) =>
      Duration(milliseconds: index * staggerInterval.inMilliseconds);

  // ── Legacy aliases (keep backward compat) ──
  static const Curve spring = snappy;
}
