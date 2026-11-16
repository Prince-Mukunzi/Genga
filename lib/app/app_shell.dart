import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/core/providers/immersive_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/widgets/nav_pill.dart';

class AppShell extends ConsumerStatefulWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: GengaSprings.orchestration,
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  bool get _onTab => navPillDestinations.any((d) => d.path == widget.location);

  int get _index {
    final i = navPillDestinations.indexWhere((d) => d.path == widget.location);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _entrance,
      curve: GengaSprings.snappy,
    );

    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: AnimatedBuilder(
            animation: curved,
            builder: (context, child) => Opacity(
              opacity: curved.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - curved.value)),
                child: child,
              ),
            ),
            child: IgnorePointer(
              ignoring: !_onTab,
              child: AnimatedSlide(
                duration: GengaSprings.medium,
                curve: _onTab ? GengaSprings.snappy : GengaSprings.exit,
                offset: _onTab ? Offset.zero : const Offset(0, 1.8),
                child: AnimatedOpacity(
                  duration: GengaSprings.quick,
                  opacity: !_onTab
                      ? 0
                      : ref.watch(immersiveProvider)
                      ? 0.15
                      : 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NavPill(
                        index: _index,
                        onSelect: (i) =>
                            context.go(navPillDestinations[i].path),
                      ),
                      AnimatedScale(
                        scale: widget.location == '/' ? 1 : 0,
                        duration: GengaSprings.medium,
                        curve: GengaSprings.snappy,
                        child: _AddButton(onTap: () => context.push('/add')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = GengaColors.dynamicAccent(context);
    return Pressable(
      scale: 0.9,
      haptic: true,
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: AppIcon(AppIcons.add, size: 26, color: GengaColors.onOffWhite),
        ),
      ),
    );
  }
}
