import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/providers/momo_setup_provider.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/genga_button.dart';
import 'package:genga/shared/widgets/genga_toast.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';

const _blue = CupertinoColors.systemBlue;
const _iosCard = Color(0xFF1C1C1E);
const _iosLine = Color(0xFF2C2C2E);

const _ease = Curves.easeInOutCubic;
const _glide = Duration(milliseconds: 400);

Future<void> showMomoCaptureSheet(BuildContext context) {
  return showGengaBottomSheet<void>(
    context: context,
    maxHeightFraction: 0.92,
    builder: (ctx) => const _MomoCaptureContent(),
  );
}

Future<void> _openShortcuts() =>
    launchUrl(Uri.parse('shortcuts://'), mode: LaunchMode.externalApplication);

class _MomoCaptureContent extends ConsumerStatefulWidget {
  const _MomoCaptureContent();

  @override
  ConsumerState<_MomoCaptureContent> createState() =>
      _MomoCaptureContentState();
}

enum _Flow { shortcut, automation }

class _MomoCaptureContentState extends ConsumerState<_MomoCaptureContent> {
  _Flow? _flow;

  void _show(_Flow? flow) {
    HapticFeedback.selectionClick();
    setState(() => _flow = flow);
  }

  Future<void> _finish(_Flow flow) async {
    final setup = ref.read(momoSetupProvider.notifier);
    await switch (flow) {
      _Flow.shortcut => setup.markShortcutAdded(),
      _Flow.automation => setup.markAutomationDone(),
    };
    HapticFeedback.mediumImpact();
    _show(null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _glide,
      curve: _ease,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: _glide,
        switchInCurve: _ease,
        switchOutCurve: _ease,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: Offset(
                child.key == const ValueKey('tracker') ? -0.04 : 0.04,
                0,
              ),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: switch (_flow) {
          null => _Tracker(
            key: const ValueKey('tracker'),
            onCreateShortcut: () => _show(_Flow.shortcut),
            onSetUp: () => _show(_Flow.automation),
          ),
          final flow => _Guide(
            key: ValueKey(flow),
            steps: flow == _Flow.shortcut ? _shortcutSteps : _automationSteps,
            onBack: () => _show(null),
            onDone: () => _finish(flow),
          ),
        },
      ),
    );
  }
}

class _Tracker extends ConsumerWidget {
  final VoidCallback onCreateShortcut;
  final VoidCallback onSetUp;

  const _Tracker({
    super.key,
    required this.onCreateShortcut,
    required this.onSetUp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(momoSetupProvider);
    final (label, action) = !setup.shortcutAdded
        ? ('Create the shortcut', onCreateShortcut)
        : !setup.automationDone
        ? ('Set up the automation', onSetUp)
        : ('Done', () => Navigator.of(context).pop());

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetTitle('Auto-capture MoMo'),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          child: Text(
            'When an MTN MoMo SMS arrives, Genga opens with the amount '
            'filled in. You pick a category and save.',
            style: GengaTypography.subhead,
          ),
        ),
        _Milestone(
          n: 1,
          title: 'Create the Genga shortcut',
          detail: setup.shortcutAdded
              ? 'Saved as Log MoMo SMS'
              : 'Four steps, with pictures',
          done: setup.shortcutAdded,
          action: setup.shortcutAdded ? 'Review' : 'Start',
          onAction: onCreateShortcut,
        ),
        _Milestone(
          n: 2,
          title: 'Set up the automation',
          detail: setup.automationDone
              ? 'Runs on every MoMo SMS'
              : 'Runs the shortcut on every MoMo SMS',
          done: setup.automationDone,
          action: setup.automationDone ? 'Review' : 'Start',
          onAction: onSetUp,
        ),
        _Milestone(
          n: 3,
          title: 'Catch your first MoMo SMS',
          detail: setup.captured
              ? 'Working'
              : 'Ticks off by itself when an SMS opens Genga',
          done: setup.captured,
          last: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: GengaButton(label: label, onTap: action),
        ),
      ],
    );
  }
}

class _Milestone extends StatelessWidget {
  final int n;
  final String title;
  final String detail;
  final bool done;
  final bool last;
  final String? action;
  final VoidCallback? onAction;

  const _Milestone({
    required this.n,
    required this.title,
    required this.detail,
    required this.done,
    this.last = false,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _StatusDot(n: n, done: done),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: done
                          ? GengaColors.income.withValues(alpha: 0.5)
                          : GengaColors.borderLight,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: last ? 0 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GengaTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(detail, style: GengaTypography.footnote),
                  ],
                ),
              ),
            ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 12),
                child: Row(
                  children: [
                    Text(
                      action!,
                      style: GengaTypography.body.copyWith(color: _blue),
                    ),
                    const AppIcon(
                      AppIcons.chevronRight,
                      size: 16,
                      color: _blue,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    if (onAction == null || action == null) return row;
    return Pressable(scale: 0.98, haptic: true, onTap: onAction, child: row);
  }
}

class _StatusDot extends StatelessWidget {
  final int n;
  final bool done;

  const _StatusDot({required this.n, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _glide,
      curve: _ease,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? GengaColors.income : const Color(0x00000000),
        border: Border.all(
          color: done ? GengaColors.income : GengaColors.textTertiary,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: done
          ? const AppIcon(
              AppIcons.checkmark,
              size: 15,
              color: GengaColors.onOffWhite,
            )
          : Text(
              '$n',
              style: GengaTypography.footnote.copyWith(
                color: GengaColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

const _shortcutSteps = [
  _GuideStep(
    title: 'Start a new shortcut',
    body:
        'In Shortcuts, stay on the [Shortcuts] tab and tap [+] at the '
        'top right.',
    replica: _NewShortcutReplica(),
  ),
  _GuideStep(
    title: 'Add the Genga action',
    body:
        'Tap [Search Actions], type {Genga} and tap [Log MoMo SMS] in '
        'the results.',
    replica: _SearchActionReplica(),
  ),
  _GuideStep(
    title: 'Pass the message in',
    body:
        'Tap the blue word [Message] in the action, tap [Select Variable], '
        'then tap [Shortcut Input].',
    replica: _ShortcutInputReplica(),
  ),
  _GuideStep(
    title: 'Save it',
    body:
        'Check the name at the top reads {Log MoMo SMS}. If not, tap it, '
        'tap [Rename] and paste. Then tap [Done].',
    replica: _SaveShortcutReplica(),
  ),
];

const _automationSteps = [
  _GuideStep(
    title: 'Open Automation',
    body:
        'In Shortcuts, tap [Automation] at the bottom, then [+] at the '
        'top right. No automations yet? Tap [New Automation] instead.',
    replica: _AutomationTabReplica(),
  ),
  _GuideStep(
    title: 'Choose Message',
    body: 'Scroll down the list and tap [Message].',
    replica: _TriggerListReplica(),
  ),
  _GuideStep(
    title: 'Set the trigger',
    body:
        'Tap [Choose] next to Message Contains, type {RWF} and tap '
        '[Done]. Pick [Run Immediately], then tap [Next].',
    replica: _MessageTriggerReplica(),
  ),
  _GuideStep(
    title: 'Pick the shortcut',
    body:
        'Under My Shortcuts, tap [Log MoMo SMS]. The automation saves '
        'right away.',
    replica: _PickShortcutReplica(),
  ),
];

class _Guide extends StatefulWidget {
  final List<_GuideStep> steps;
  final VoidCallback onBack;
  final VoidCallback onDone;

  const _Guide({
    super.key,
    required this.steps,
    required this.onBack,
    required this.onDone,
  });

  @override
  State<_Guide> createState() => _GuideState();
}

class _GuideState extends State<_Guide> {
  final _pages = PageController();
  int _index = 0;

  List<_GuideStep> get _steps => widget.steps;

  bool get _isLast => _index == _steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _back() {
    if (_index == 0) {
      widget.onBack();
      return;
    }
    _pages.previousPage(duration: _glide, curve: _ease);
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    HapticFeedback.selectionClick();
    _pages.nextPage(duration: _glide, curve: _ease);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 24, 4),
          child: Row(
            children: [
              Pressable(
                haptic: true,
                onTap: _back,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: AppIcon(
                    AppIcons.back,
                    size: 22,
                    color: GengaColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Step ${_index + 1} of ${_steps.length}',
                style: GengaTypography.subhead,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 376,
          child: PageView(
            controller: _pages,
            onPageChanged: (i) => setState(() => _index = i),
            children: [for (final step in _steps) _GuidePage(step)],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _steps.length; i++)
                AnimatedContainer(
                  duration: _glide,
                  curve: _ease,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == _index
                        ? GengaColors.textPrimary
                        : GengaColors.borderLight,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              GengaButton(label: _isLast ? 'Done' : 'Next', onTap: _next),
              const SizedBox(height: 10),
              GengaButton.secondary(
                label: 'Open Shortcuts',
                onTap: _openShortcuts,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideStep {
  final String title;
  final String body;
  final Widget replica;

  const _GuideStep({
    required this.title,
    required this.body,
    required this.replica,
  });
}

class _GuidePage extends StatelessWidget {
  final _GuideStep step;

  const _GuidePage(this.step);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.title, style: GengaTypography.title2),
          const SizedBox(height: 6),
          _StepBody(step.body),
          const SizedBox(height: 18),
          step.replica,
        ],
      ),
    );
  }
}

// Body markup: [Label] is something to tap in Shortcuts, {text} is something to type.
class _StepBody extends StatelessWidget {
  final String source;

  const _StepBody(this.source);

  static final _token = RegExp(r'\[([^\]]+)\]|\{([^}]+)\}');

  @override
  Widget build(BuildContext context) {
    final base = GengaTypography.subhead.copyWith(height: 1.4);
    final label = base.copyWith(color: _blue, fontWeight: FontWeight.w600);
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _token.allMatches(source)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, match.start)));
      }
      final tap = match.group(1);
      final typed = match.group(2);
      if (tap != null) {
        spans.add(TextSpan(text: tap, style: label));
      } else if (typed != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _CopyWord(text: typed, style: label),
          ),
        );
      }
      cursor = match.end;
    }
    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor)));
    }

    return Text.rich(TextSpan(style: base, children: spans));
  }
}

class _CopyWord extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _CopyWord({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        HapticFeedback.lightImpact();
        showGengaToast(context, 'Copied');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: style),
          const SizedBox(width: 3),
          const AppIcon(AppIcons.docOnClipboard, size: 14, color: _blue),
        ],
      ),
    );
  }
}

// Replicas of the Shortcuts screens, with the thing to tap ringed in blue.

class _Replica extends StatelessWidget {
  final List<Widget> children;

  const _Replica({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GengaColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final Widget child;
  final bool on;

  const _Ring({required this.child, this.on = true});

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    return Container(
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _blue, width: 1.5),
      ),
      child: child,
    );
  }
}

class _IosGroup extends StatelessWidget {
  final List<Widget> rows;

  const _IosGroup(this.rows);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _iosCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: SizedBox(
                  height: 0.5,
                  child: ColoredBox(color: _iosLine),
                ),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _IosRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool ringed;
  final bool chevron;
  final Widget? leading;
  final Color? labelColor;

  const _IosRow(
    this.label, {
    this.value,
    this.ringed = false,
    this.chevron = false,
    this.leading,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = GengaTypography.subhead.copyWith(
      color: labelColor ?? GengaColors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.all(4),
      child: _Ring(
        on: ringed,
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Expanded(child: Text(label, style: text)),
                if (value != null)
                  Text(
                    value!,
                    style: GengaTypography.subhead.copyWith(
                      color: GengaColors.textTertiary,
                    ),
                  ),
                if (chevron)
                  const AppIcon(
                    AppIcons.chevronRight,
                    size: 14,
                    color: GengaColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IosHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _IosHeader(this.title, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GengaTypography.headline.copyWith(
                color: GengaColors.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _AutomationTabReplica extends StatelessWidget {
  const _AutomationTabReplica();

  @override
  Widget build(BuildContext context) {
    return _Replica(
      children: [
        _IosHeader(
          'Automation',
          trailing: _Ring(
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: AppIcon(AppIcons.add, size: 20, color: _blue),
            ),
          ),
        ),
        _IosGroup([_IosRow('New Automation', labelColor: _blue)]),
        const SizedBox(height: 34),
        const _IosTabBar(selected: 'Automation'),
      ],
    );
  }
}

class _TriggerListReplica extends StatelessWidget {
  const _TriggerListReplica();

  @override
  Widget build(BuildContext context) {
    return const _Replica(
      children: [
        _IosHeader('New Automation'),
        _IosGroup([
          _IosRow('Time of Day', chevron: true),
          _IosRow('Alarm', chevron: true),
          _IosRow('Email', chevron: true),
          _IosRow('Message', chevron: true, ringed: true),
          _IosRow('Wallet', chevron: true),
        ]),
      ],
    );
  }
}

class _MessageTriggerReplica extends StatelessWidget {
  const _MessageTriggerReplica();

  @override
  Widget build(BuildContext context) {
    return _Replica(
      children: [
        _IosHeader(
          'Message',
          trailing: Text(
            'Next',
            style: GengaTypography.subhead.copyWith(
              color: _blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const _IosGroup([
          _IosRow('Sender', value: 'Any Sender'),
          _IosRow('Message Contains', value: 'RWF', ringed: true),
        ]),
        const SizedBox(height: 12),
        const _IosGroup([
          _IosRow('Run After Confirmation'),
          _IosRow(
            'Run Immediately',
            ringed: true,
            leading: AppIcon(AppIcons.checkmark, size: 16, color: _blue),
          ),
        ]),
      ],
    );
  }
}

class _PickShortcutReplica extends StatelessWidget {
  const _PickShortcutReplica();

  @override
  Widget build(BuildContext context) {
    return _Replica(
      children: [
        const _IosHeader('When I get a message containing RWF'),
        const _IosGroup([_IosRow('Create New Shortcut', labelColor: _blue)]),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 0, 6),
          child: Text(
            'My Shortcuts',
            style: GengaTypography.footnote.copyWith(
              color: GengaColors.textTertiary,
            ),
          ),
        ),
        _IosGroup([
          _IosRow('Log MoMo SMS', ringed: true, leading: const _GengaGlyph()),
        ]),
      ],
    );
  }
}

class _IosTabBar extends StatelessWidget {
  final String selected;

  const _IosTabBar({required this.selected});

  @override
  Widget build(BuildContext context) {
    final tab = GengaTypography.caption2.copyWith(
      color: GengaColors.textTertiary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final name in const ['Shortcuts', 'Automation', 'Gallery'])
          _Ring(
            on: name == selected,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                name,
                style: name == selected ? tab.copyWith(color: _blue) : tab,
              ),
            ),
          ),
      ],
    );
  }
}

class _GengaGlyph extends StatelessWidget {
  const _GengaGlyph();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset('assets/images/app_icon.png', width: 22, height: 22),
    );
  }
}

class _ActionBlock extends StatelessWidget {
  final String value;
  final bool ringed;

  const _ActionBlock({required this.value, this.ringed = false});

  @override
  Widget build(BuildContext context) {
    final text = GengaTypography.body.copyWith(color: GengaColors.textPrimary);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _iosCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          const _GengaGlyph(),
          Text('Log', style: text),
          _Ring(
            on: ringed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                value,
                style: text.copyWith(color: _blue, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Text('in Genga', style: text),
        ],
      ),
    );
  }
}

class _NewShortcutReplica extends StatelessWidget {
  const _NewShortcutReplica();

  @override
  Widget build(BuildContext context) {
    return _Replica(
      children: [
        _IosHeader(
          'All Shortcuts',
          trailing: _Ring(
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: AppIcon(AppIcons.add, size: 20, color: _blue),
            ),
          ),
        ),
        Row(
          children: [
            for (final color in const [Color(0xFF5E5CE6), Color(0xFFFF9F0A)])
              Expanded(
                child: Container(
                  height: 64,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 30),
        const _IosTabBar(selected: 'Shortcuts'),
      ],
    );
  }
}

class _SearchActionReplica extends StatelessWidget {
  const _SearchActionReplica();

  @override
  Widget build(BuildContext context) {
    return _Replica(
      children: [
        const _IosHeader('New Shortcut'),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _iosCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const AppIcon(
                AppIcons.search,
                size: 16,
                color: GengaColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Genga',
                style: GengaTypography.subhead.copyWith(
                  color: GengaColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 0, 6),
          child: Text(
            'Genga',
            style: GengaTypography.footnote.copyWith(
              color: GengaColors.textTertiary,
            ),
          ),
        ),
        const _IosGroup([
          _IosRow('Log MoMo SMS', ringed: true, leading: _GengaGlyph()),
        ]),
      ],
    );
  }
}

class _ShortcutInputReplica extends StatelessWidget {
  const _ShortcutInputReplica();

  @override
  Widget build(BuildContext context) {
    return _Replica(
      children: [
        const _ActionBlock(value: 'Message', ringed: true),
        const SizedBox(height: 12),
        Row(
          children: [
            _Ring(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Select Variable',
                  style: GengaTypography.subhead.copyWith(color: _blue),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Ask Each Time',
              style: GengaTypography.subhead.copyWith(color: _blue),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _IosGroup([
          _IosRow('Shortcut Input', ringed: true),
          _IosRow('Clipboard'),
          _IosRow('Current Date'),
        ]),
      ],
    );
  }
}

class _SaveShortcutReplica extends StatelessWidget {
  const _SaveShortcutReplica();

  @override
  Widget build(BuildContext context) {
    return _Replica(
      children: [
        _IosHeader(
          'Log MoMo SMS',
          trailing: _Ring(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Done',
                style: GengaTypography.subhead.copyWith(
                  color: _blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _iosCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Receive input from Nowhere',
            style: GengaTypography.subhead.copyWith(
              color: GengaColors.textTertiary,
            ),
          ),
        ),
        const _ActionBlock(value: 'Shortcut Input'),
      ],
    );
  }
}
