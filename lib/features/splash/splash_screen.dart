import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/haptics/launch_haptic.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showName = false;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _timers.add(
      Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showName = true);
      }),
    );
    _timers.add(Timer(const Duration(seconds: 3), _open));
  }

  Future<void> _open() async {
    if (!mounted) return;
    context.go('/');
    playLaunchHaptic();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GengaColors.background,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.7, -0.75),
                  radius: 1.15,
                  colors: [Color(0x558C93A6), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.86 + 0.14 * t,
                      child: child,
                    ),
                  ),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      GengaColors.offWhite,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 112,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                AnimatedSlide(
                  duration: GengaSprings.slow,
                  curve: GengaSprings.smooth,
                  offset: _showName ? Offset.zero : const Offset(0, 0.5),
                  child: AnimatedOpacity(
                    duration: GengaSprings.slow,
                    opacity: _showName ? 1 : 0,
                    child: Text(
                      'Genga',
                      style: GengaTypography.largeTitle.copyWith(
                        color: GengaColors.offWhite,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
