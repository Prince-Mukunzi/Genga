import 'package:flutter/cupertino.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';

enum BrandKind { mobileMoney, bank, other }

enum LogoTone { original, white, whiteFromDark }

class AccountBrand {
  final String id;
  final String name;
  final BrandKind kind;
  final String? logoAsset;
  final LogoTone tone;
  final List<Gradient> layers;
  final bool light;
  final Color base;
  final Color onCard;
  final HugeIconData icon;
  final String? ussdMenu;
  final String? balanceUssd;
  final bool automatedMomoPay;
  final double logoScale;

  const AccountBrand({
    required this.id,
    required this.name,
    required this.kind,
    required this.layers,
    this.light = false,
    required this.base,
    required this.onCard,
    required this.icon,
    this.logoAsset,
    this.tone = LogoTone.original,
    this.ussdMenu,
    this.balanceUssd,
    this.automatedMomoPay = false,
    this.logoScale = 1,
  });

  Color get onCardMuted => onCard.withValues(alpha: 0.7);
  bool get isLightCard => light;
}

const _white = Color(0xFFFFFFFF);

List<Gradient> _mesh(int a, int b, int c, int glow, int shade) => [
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(a), Color(b), Color(c)],
    stops: const [0, 0.55, 1],
  ),
  RadialGradient(
    center: const Alignment(1.05, -1.15),
    radius: 0.95,
    colors: [Color(glow).withAlpha(140), Color(glow).withAlpha(0)],
  ),
  RadialGradient(
    center: const Alignment(-1.1, 1.25),
    radius: 1.05,
    colors: [Color(shade).withAlpha(120), Color(shade).withAlpha(0)],
  ),
];

final kBrands = <AccountBrand>[
  AccountBrand(
    id: 'mtn_momo',
    name: 'MTN MoMo',
    kind: BrandKind.mobileMoney,
    logoAsset: 'assets/brands/momo.png',
    base: Color(0xFFFFCC00),
    layers: _mesh(0xFFFFE867, 0xFFFFC800, 0xFFF09400, 0xFFFFF6B8, 0xFFB85F00),
    onCard: Color(0xFF00334A),
    icon: AppIcons.creditcardFill,
    ussdMenu: '*182#',
    balanceUssd: '*182*6*1#',
    automatedMomoPay: true,
    logoScale: 1.35,
  ),
  AccountBrand(
    id: 'airtel_money',
    name: 'Airtel Money',
    kind: BrandKind.mobileMoney,
    logoAsset: 'assets/brands/airtel.png',
    tone: LogoTone.white,
    base: Color(0xFFED1C24),
    layers: _mesh(0xFFFF5A63, 0xFFE1202A, 0xFF9A0E18, 0xFFFF9A9F, 0xFF4F0309),
    onCard: _white,
    icon: AppIcons.creditcardFill,
    ussdMenu: '*182#',
  ),
  AccountBrand(
    id: 'bk',
    name: 'Bank of Kigali',
    kind: BrandKind.bank,
    logoAsset: 'assets/brands/bk.png',
    base: Color(0xFF0A5BBE),
    layers: _mesh(0xFF3FA2FF, 0xFF0F66D6, 0xFF06307A, 0xFF8BE0FF, 0xFF021846),
    onCard: _white,
    icon: AppIcons.building2Fill,
    ussdMenu: '*334#',
    logoScale: 1.45,
  ),
  AccountBrand(
    id: 'equity',
    name: 'Equity Bank',
    kind: BrandKind.bank,
    logoAsset: 'assets/brands/equity.png',
    tone: LogoTone.white,
    base: Color(0xFFA32A29),
    layers: _mesh(0xFFDD5550, 0xFFA32A29, 0xFF561010, 0xFFFF9A84, 0xFF260404),
    onCard: _white,
    icon: AppIcons.building2Fill,
    ussdMenu: '*555#',
    logoScale: 1.3,
  ),
  AccountBrand(
    id: 'im',
    name: 'I&M Bank',
    kind: BrandKind.bank,
    logoAsset: 'assets/brands/im.png',
    tone: LogoTone.white,
    base: Color(0xFF2B7FA8),
    layers: _mesh(0xFF2D5CB8, 0xFF2A8BA8, 0xFF33C2AC, 0xFF8CF5E0, 0xFF0C1B4A),
    onCard: _white,
    icon: AppIcons.building2Fill,
    ussdMenu: '*227#',
    logoScale: 1.2,
  ),
  AccountBrand(
    id: 'access',
    name: 'Access Bank',
    kind: BrandKind.bank,
    logoAsset: 'assets/brands/access.png',
    tone: LogoTone.white,
    base: Color(0xFFF08A24),
    layers: _mesh(0xFFFFC078, 0xFFF08A24, 0xFFCC5A08, 0xFFFFE6B8, 0xFF1F3A73),
    onCard: _white,
    icon: AppIcons.building2Fill,
    ussdMenu: '*903#',
  ),
  AccountBrand(
    id: 'ncba',
    name: 'NCBA',
    kind: BrandKind.bank,
    logoAsset: 'assets/brands/ncba.png',
    base: Color(0xFF3A3436),
    layers: _mesh(0xFF625A5C, 0xFF2E292A, 0xFF111011, 0xFFB3A7AA, 0xFF000000),
    onCard: _white,
    icon: AppIcons.building2Fill,
    ussdMenu: '*650#',
  ),
  AccountBrand(
    id: 'cash',
    name: 'Cash',
    kind: BrandKind.other,
    logoAsset: 'assets/images/app_logo.png',
    tone: LogoTone.white,
    logoScale: 0.95,
    base: Color(0xFF3A3A42),
    layers: _mesh(0xFF50505A, 0xFF27272D, 0xFF111114, 0xFF8A8A99, 0xFF000000),
    onCard: _white,
    icon: AppIcons.moneyDollarCircleFill,
  ),
  AccountBrand(
    id: 'credit_card',
    name: 'Credit card',
    kind: BrandKind.other,
    base: Color(0xFF4A4F86),
    layers: _mesh(0xFF7479C4, 0xFF3C4080, 0xFF13152D, 0xFFB3A6FF, 0xFF05060F),
    onCard: _white,
    icon: AppIcons.creditcardFill,
  ),
];

const _generic = AccountBrand(
  id: 'other',
  name: 'Account',
  kind: BrandKind.other,
  base: Color(0xFF3A3A42),
  layers: [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A3A42), Color(0xFF16161B)],
    ),
  ],
  onCard: _white,
  icon: AppIcons.creditcardFill,
);

AccountBrand brandFor(String accountType) {
  for (final b in kBrands) {
    if (b.id == accountType) return b;
  }
  return _generic;
}

class BrandLogo extends StatelessWidget {
  final AccountBrand brand;
  final double height;

  const BrandLogo({super.key, required this.brand, required this.height});

  static const _keyFromDark = ColorFilter.matrix(<double>[
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    1.7,
    0,
    0,
    0,
    -110,
  ]);

  @override
  Widget build(BuildContext context) {
    final asset = brand.logoAsset;
    if (asset == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(brand.icon, size: height * 0.8, color: brand.onCard),
          SizedBox(width: height * 0.3),
          Text(
            brand.name,
            style: TextStyle(
              fontSize: height * 0.62,
              fontWeight: FontWeight.w600,
              color: brand.onCard,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      );
    }

    final image = Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );

    return switch (brand.tone) {
      LogoTone.original => image,
      LogoTone.white => ColorFiltered(
        colorFilter: const ColorFilter.mode(_white, BlendMode.srcIn),
        child: image,
      ),
      LogoTone.whiteFromDark => ColorFiltered(
        colorFilter: _keyFromDark,
        child: image,
      ),
    };
  }
}

class BrandBackground extends StatelessWidget {
  final AccountBrand brand;
  final Widget? child;

  const BrandBackground({super.key, required this.brand, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        for (final g in brand.layers)
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: g)),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -0.6),
                end: const Alignment(1, 0.6),
                colors: [
                  const Color(0x00FFFFFF),
                  Color(brand.isLightCard ? 0x30FFFFFF : 0x1AFFFFFF),
                  const Color(0x00FFFFFF),
                ],
                stops: const [0.25, 0.42, 0.62],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _RingsPainter(
              Color(brand.isLightCard ? 0x26FFFFFF : 0x14FFFFFF),
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  final Color color;

  const _RingsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final center = Offset(size.width * 1.02, size.height * 1.05);
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, 34.0 * i + 20, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.color != color;
}
