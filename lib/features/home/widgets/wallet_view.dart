import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/immersive_provider.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/pressable.dart';

import 'account_card_face.dart';

const double walletHeight = 262;
const double _kPocketTop = 108;
const double _kCardHeight = 132;
const double _kCardTop = 30;
const int _kMaxBehind = 3;

class WalletView extends ConsumerStatefulWidget {
  final List<Account> accounts;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final Future<void> Function(int) onOpen;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final String currency;
  final double rate;

  const WalletView({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
    required this.onOpen,
    required this.hidden,
    required this.onToggleHidden,
    required this.currency,
    required this.rate,
  });

  @override
  ConsumerState<WalletView> createState() => _WalletViewState();
}

class _CardPose {
  final double top;
  final double inset;
  final double scale;
  final double turn;
  final double opacity;

  const _CardPose({
    required this.top,
    required this.inset,
    this.scale = 1,
    this.turn = 0,
    required this.opacity,
  });

  factory _CardPose.atDepth(int depth) {
    final shown = depth.clamp(0, _kMaxBehind);
    return _CardPose(
      top: _kCardTop - shown * 14.0,
      inset: 14 + shown * 12.0,
      opacity: depth <= _kMaxBehind ? 1 - shown * 0.18 : 0,
    );
  }

  static _CardPose lerp(_CardPose a, _CardPose b, double t) => _CardPose(
    top: ui.lerpDouble(a.top, b.top, t)!,
    inset: ui.lerpDouble(a.inset, b.inset, t)!,
    scale: ui.lerpDouble(a.scale, b.scale, t)!,
    turn: ui.lerpDouble(a.turn, b.turn, t)!,
    opacity: ui.lerpDouble(a.opacity, b.opacity, t)!.clamp(0, 1),
  );
}

const _kApexTop = -34.0;
const _kSunkTop = _kPocketTop + 24;
const _kHandoff = 0.42;

class _WalletViewState extends ConsumerState<WalletView>
    with TickerProviderStateMixin {
  late final AnimationController _switch = AnimationController(
    vsync: this,
    value: 1,
  );
  late final AnimationController _openCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 460),
  );

  bool _opening = false;
  bool _scrubbing = false;
  int _scrubBase = 0;
  int _scrubLast = 0;

  Map<int, _CardPose> _from = const {};
  Map<int, int> _fromDepth = const {};
  Map<int, _CardPose> _lastPoses = {};
  int? _incoming;
  int? _outgoing;
  bool _plainSwitch = false;

  List<Account> get _ordered {
    final selected = widget.accounts
        .where((a) => a.id == widget.selectedId)
        .firstOrNull;
    if (selected == null) return widget.accounts;
    return [selected, ...widget.accounts.where((a) => a.id != selected.id)];
  }

  @override
  void didUpdateWidget(covariant WalletView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId == widget.selectedId) return;
    if (oldWidget.selectedId == null || GengaMotion.reduced(context)) return;

    final oldOrder = [
      ...oldWidget.accounts.where((a) => a.id == oldWidget.selectedId),
      ...oldWidget.accounts.where((a) => a.id != oldWidget.selectedId),
    ];
    _fromDepth = {
      for (var i = 0; i < oldOrder.length; i++) oldOrder[i].id: i,
    };
    _from = Map.of(_lastPoses);
    _incoming = widget.selectedId;
    _outgoing = oldWidget.selectedId;
    _plainSwitch = _scrubbing;
    _switch.duration = Duration(milliseconds: _plainSwitch ? 280 : 640);
    _switch.forward(from: 0);
  }

  void _step(int delta) {
    if (widget.accounts.length < 2 || _opening) return;
    final ordered = _ordered;
    final next = delta > 0 ? ordered[1] : ordered.last;
    HapticFeedback.selectionClick();
    widget.onSelect(next.id);
  }

  void _scrubStart() {
    if (widget.accounts.length < 2 || _opening) return;
    HapticFeedback.mediumImpact();
    _scrubBase = widget.accounts
        .indexWhere((a) => a.id == widget.selectedId)
        .clamp(0, widget.accounts.length - 1);
    _scrubLast = _scrubBase;
    setState(() => _scrubbing = true);
    ref.read(immersiveProvider.notifier).state = true;
  }

  void _scrubMove(Offset travel) {
    if (!_scrubbing) return;
    final along = travel.dx.abs() >= travel.dy.abs() ? travel.dx : travel.dy;
    final steps = (-along / 64).round();
    final idx = (_scrubBase + steps).clamp(0, widget.accounts.length - 1);
    if (idx == _scrubLast) return;
    _scrubLast = idx;
    HapticFeedback.selectionClick();
    widget.onSelect(widget.accounts[idx].id);
  }

  void _scrubEnd() {
    if (!_scrubbing) return;
    setState(() => _scrubbing = false);
    ref.read(immersiveProvider.notifier).state = false;
  }

  @override
  void dispose() {
    if (_scrubbing) {
      Future.microtask(
        () => ref.read(immersiveProvider.notifier).state = false,
      );
    }
    _switch.dispose();
    _openCtrl.dispose();
    super.dispose();
  }

  Future<void> _open(int id) async {
    if (_opening) return;
    HapticFeedback.lightImpact();
    setState(() => _opening = true);
    if (GengaMotion.reduced(context)) {
      _openCtrl.value = 1;
    } else {
      await _openCtrl.forward(from: 0).orCancel.catchError((_) {});
    }
    if (!mounted) return;
    await widget.onOpen(id);
    if (!mounted) return;
    setState(() => _opening = false);
    await _openCtrl.reverse().orCancel.catchError((_) {});
  }

  _CardPose _switchPose(int id, int depth, double t) {
    final target = _CardPose.atDepth(depth);
    final from = _from[id] ?? _CardPose.atDepth(_fromDepth[id] ?? depth);
    if (t >= 1) return target;

    if (_plainSwitch) {
      return _CardPose.lerp(from, target, Curves.easeOutCubic.transform(t));
    }

    if (id == _incoming) {
      if (t < _kHandoff) {
        final u = Curves.easeOutCubic.transform(t / _kHandoff);
        return _CardPose.lerp(
          from,
          const _CardPose(
            top: _kApexTop,
            inset: 14,
            scale: 1.04,
            turn: -0.035,
            opacity: 1,
          ),
          u,
        );
      }
      final v = (t - _kHandoff) / (1 - _kHandoff);
      return _CardPose(
        top: ui.lerpDouble(_kApexTop, target.top, GengaSprings.smooth.transform(v))!,
        inset: 14,
        scale: ui.lerpDouble(1.04, 1, Curves.easeOutCubic.transform(v))!,
        turn: ui.lerpDouble(-0.035, 0, Curves.easeOutBack.transform(v))!,
        opacity: 1,
      );
    }

    if (id == _outgoing) {
      if (t < _kHandoff) {
        final u = Curves.easeInCubic.transform(t / _kHandoff);
        return _CardPose.lerp(
          from,
          _CardPose(
            top: _kSunkTop,
            inset: from.inset,
            turn: 0.02,
            opacity: from.opacity,
          ),
          u,
        );
      }
      final v = Curves.easeOutCubic.transform(
        (t - _kHandoff) / (1 - _kHandoff),
      );
      return _CardPose.lerp(
        _CardPose(top: _kSunkTop, inset: target.inset, opacity: target.opacity),
        target,
        v,
      );
    }

    return _CardPose.lerp(from, target, GengaSprings.smooth.transform(t));
  }

  _CardPose _withOpen(_CardPose pose, int depth, double o) {
    if (o == 0) return pose;
    if (depth == 0) {
      final lift = Curves.easeOutBack.transform(o);
      return _CardPose(
        top: pose.top - 26 * lift,
        inset: pose.inset,
        scale: pose.scale + 0.03 * lift,
        turn: pose.turn,
        opacity: pose.opacity,
      );
    }
    final sink = Curves.easeInCubic.transform(o);
    return _CardPose(
      top: pose.top + 90 * sink,
      inset: pose.inset,
      scale: pose.scale,
      turn: pose.turn,
      opacity: pose.opacity * (1 - sink),
    );
  }

  List<Widget> _cards(List<Account> ordered) {
    final t = _switch.value;
    final o = _openCtrl.value;
    final handoff = _plainSwitch ? 0.5 : _kHandoff;
    final useOldOrder = t < handoff && _fromDepth.isNotEmpty;

    final poses = <int, _CardPose>{};
    for (var depth = 0; depth < ordered.length; depth++) {
      final id = ordered[depth].id;
      poses[id] = _withOpen(_switchPose(id, depth, t), depth, o);
    }
    _lastPoses = poses;

    int paintDepth(int depth) {
      final id = ordered[depth].id;
      return useOldOrder ? (_fromDepth[id] ?? depth) : depth;
    }

    final indices = List.generate(ordered.length, (i) => i)
      ..sort((a, b) => paintDepth(b).compareTo(paintDepth(a)));

    return [
      for (final depth in indices)
        _peekCard(ordered[depth], depth, poses[ordered[depth].id]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered;
    final front = ordered.firstOrNull;
    final balance = front == null
        ? 0.0
        : ref.watch(accountBalanceProvider(front.id)) * widget.rate;
    final spent = front == null
        ? 0.0
        : ref.watch(accountSpentThisMonthProvider(front.id)) * widget.rate;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (_) => _scrubStart(),
          onLongPressMoveUpdate: (d) => _scrubMove(d.offsetFromOrigin),
          onLongPressEnd: (_) => _scrubEnd(),
          onLongPressCancel: _scrubEnd,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -250) _step(1);
            if (v > 250) _step(-1);
          },
          child: AnimatedScale(
            duration: GengaSprings.medium,
            curve: GengaSprings.smooth,
            scale: _scrubbing ? 1.05 : 1,
            child: SizedBox(
              height: walletHeight,
              child: AnimatedBuilder(
                animation: Listenable.merge([_switch, _openCtrl]),
                builder: (context, _) {
                  final drop = Curves.easeInCubic.transform(_openCtrl.value);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ..._cards(ordered),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: _kPocketTop,
                        bottom: 0,
                        child: Transform.translate(
                          offset: Offset(0, 70 * drop),
                          child: Opacity(
                            opacity: 1 - drop,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: front == null
                                  ? null
                                  : () => _open(front.id),
                              child: CustomPaint(
                                painter: const _PocketPainter(),
                                child: _pocketContent(front, balance, spent),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pocketContent(Account? front, double balance, double spent) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: front == null
          ? const SizedBox.shrink()
          : _PocketContent(
              key: ValueKey(front.id),
              account: front,
              balanceText: widget.hidden
                  ? '••••'
                  : AmountText.withSymbol(balance, widget.currency),
              spentText: widget.hidden ? '••' : AmountText.plain(spent),
              hidden: widget.hidden,
              onToggleHidden: widget.onToggleHidden,
              onOpen: () => _open(front.id),
            ),
    );
  }

  Widget _peekCard(Account account, int depth, _CardPose pose) {
    return Positioned(
      key: ValueKey(account.id),
      left: pose.inset,
      right: pose.inset,
      top: pose.top,
      height: _kCardHeight,
      child: Opacity(
        opacity: pose.opacity,
        child: Transform.rotate(
          angle: pose.turn,
          child: Transform.scale(
            scale: pose.scale,
            child: Pressable(
              scale: 0.98,
              haptic: true,
              onTap: depth == 0
                  ? () => _open(account.id)
                  : () => widget.onSelect(account.id),
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 168,
                maxHeight: 168,
                child: SizedBox(
                  height: 168,
                  child: AccountCardFace(
                    account: account,
                    large: true,
                    balanceText: '',
                    heroTag: depth == 0 ? accountHeroTag(account.id) : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PocketContent extends StatelessWidget {
  final Account account;
  final String balanceText;
  final String spentText;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onOpen;

  const _PocketContent({
    super.key,
    required this.account,
    required this.balanceText,
    required this.spentText,
    required this.hidden,
    required this.onToggleHidden,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xB3EDEAE4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Pressable(
              scale: 0.98,
              onTap: onOpen,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: muted,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      balanceText,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: Color(0xFFEDEAE4),
                        decoration: TextDecoration.none,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Spent $spentText this month',
                    style: const TextStyle(
                      fontSize: 12,
                      color: muted,
                      decoration: TextDecoration.none,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Pressable(
            scale: 0.85,
            haptic: true,
            onTap: onToggleHidden,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AppIcon(
                hidden ? AppIcons.eyeOff : AppIcons.eye,
                size: 22,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Path walletPocketPath(Size size, {double inset = 0}) {
  const r = 34.0;
  const scoop = 20.0;
  const half = 64.0;
  final l = inset;
  final t = inset;
  final rt = size.width - inset;
  final b = size.height - inset;
  final cx = size.width / 2;
  return Path()
    ..moveTo(l, t + r)
    ..quadraticBezierTo(l, t, l + r, t)
    ..lineTo(cx - half, t)
    ..cubicTo(cx - half * 0.45, t, cx - half * 0.55, t + scoop, cx, t + scoop)
    ..cubicTo(cx + half * 0.55, t + scoop, cx + half * 0.45, t, cx + half, t)
    ..lineTo(rt - r, t)
    ..quadraticBezierTo(rt, t, rt, t + r)
    ..lineTo(rt, b - r)
    ..quadraticBezierTo(rt, b, rt - r, b)
    ..lineTo(l + r, b)
    ..quadraticBezierTo(l, b, l, b - r)
    ..close();
}

class _PocketPainter extends CustomPainter {
  const _PocketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = walletPocketPath(size);

    canvas.drawShadow(path, const Color(0xFF000000), 10, true);

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2B2B2F), Color(0xFF18181B)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fill);

    final sheen = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.6, -1.0),
        radius: 1.0,
        colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, sheen);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0x24FFFFFF),
    );

    final stitch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x4DEDEAE4);
    final inner = walletPocketPath(size, inset: 10);
    for (final metric in inner.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = (d + 5).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(d, end), stitch);
        d += 10;
      }
    }

    for (final dx in [22.0, size.width - 22.0]) {
      final c = Offset(dx, 22);
      canvas.drawCircle(c, 4.2, Paint()..color = const Color(0xFF0E0E10));
      canvas.drawCircle(
        c,
        3.4,
        Paint()
          ..shader = ui.Gradient.radial(c.translate(-1, -1), 4, const [
            Color(0xFF8A8A90),
            Color(0xFF3A3A3F),
          ]),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
