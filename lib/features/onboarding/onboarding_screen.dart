import 'package:flutter/cupertino.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/shared/widgets/genga_text_field.dart';
import 'package:genga/shared/widgets/genga_button.dart';

import 'package:genga/features/settings/add_account_flow.dart';
import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/services/analytics_service.dart';
import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:genga/shared/animations/springs.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0; // 0 = splash, 1 = name, 2 = account setup

  @override
  Widget build(BuildContext context) {
    return GengaScaffold(
      child: AnimatedSwitcher(
        duration: GengaSprings.medium,
        switchInCurve: GengaSprings.smooth,
        switchOutCurve: GengaSprings.exit,
        transitionBuilder: (child, anim) {
          // Shared-axis horizontal — old slides out left, new slides in right
          final isIncoming = child.key == ValueKey(_step);
          final slide = Tween<Offset>(
            begin: Offset(isIncoming ? 0.15 : -0.15, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: GengaSprings.smooth));
          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: anim, child: child),
          );
        },
        child: switch (_step) {
          0 => SafeArea(
            key: const ValueKey(0),
            child: _SplashStep(onGetStarted: () => setState(() => _step = 1)),
          ),
          1 => SafeArea(
            key: const ValueKey(1),
            child: _NameStep(
              onContinue: (name) async {
                await ref.read(databaseProvider).setUserName(name);
                if (mounted) setState(() => _step = 2);
              },
            ),
          ),
          _ => _AccountStep(
            key: const ValueKey(2),
            onDone: () {
              ref
                  .read(analyticsServiceProvider)
                  .trackEvent('onboarding_completed');
              context.go('/');
            },
          ),
        },
      ),
    );
  }
}

class _SplashStep extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _SplashStep({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          const _WalletMark(),
          const SizedBox(height: 24),
          // Title — fade + slide up
          EntranceAnimation.stagger(
            index: 1,
            child: Text(
              'Genga',
              style: GengaTypography.largeTitle.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle — fade + slide up with longer delay
          EntranceAnimation.stagger(
            index: 2,
            child: Text(
              'Track spending, manage multiple accounts, and stay on top of your money — all in one place.',
              textAlign: TextAlign.center,
              style: GengaTypography.body.copyWith(
                color: GengaColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const Spacer(flex: 2),
          // CTA button — scale from 0.9
          EntranceAnimation.stagger(
            index: 3,
            initialScale: 0.9,
            slideOffset: 12,
            child: GengaButton(label: 'Get Started', onTap: onGetStarted),
          ),
          const SizedBox(height: 16),
          // Privacy note
          EntranceAnimation.stagger(
            index: 4,
            child: Text(
              'Your data is stored on this device only.',
              textAlign: TextAlign.center,
              style: GengaTypography.caption1.copyWith(
                color: GengaColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _WalletMark extends StatelessWidget {
  const _WalletMark();

  @override
  Widget build(BuildContext context) {
    final accent = GengaColors.dynamicAccent(context);
    final colors = [
      accent.withValues(alpha: 0.45),
      accent.withValues(alpha: 0.7),
      accent,
    ];

    return SizedBox(
      width: 180,
      height: 130,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: GengaSprings.smooth,
        builder: (context, t, _) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (var i = 0; i < 3; i++)
              Positioned(
                top: 6 + i * 22.0 * t,
                child: Container(
                  width: 150 - (2 - i) * 20,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: colors[i],
                    border: Border.all(
                      color: GengaColors.onCardChip,
                      width: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NameStep extends StatefulWidget {
  final Future<void> Function(String name) onContinue;

  const _NameStep({required this.onContinue});

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    await widget.onContinue(name);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            'What should we call you?',
            style: GengaTypography.title1.copyWith(
              color: GengaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your first space is named after you.',
            style: GengaTypography.subhead,
          ),
          const SizedBox(height: 28),
          GengaTextField(
            controller: _controller,
            placeholder: 'Your name',
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _go(),
          ),
          const Spacer(flex: 3),
          GengaButton(
            label: 'Continue',
            loading: _busy,
            onTap: ready ? _go : null,
          ),
        ],
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  final VoidCallback onDone;

  const _AccountStep({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) => AddAccountFlow(onDone: onDone);
}

/// Needed for color.transparent since cupertino doesn't expose Colors.
class Colors {
  static const Color transparent = Color(0x00000000);
}
