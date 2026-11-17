import 'package:flutter/painting.dart' show VoidCallback;
import 'package:genga/core/database/database.dart';
import 'package:genga/shared/brands/account_brand.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> dialUssd(String code) async {
  final uri = Uri.parse('tel:${Uri.encodeComponent(code)}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

VoidCallback? balanceDialerFor(Account account) {
  final brand = brandFor(account.accountType);
  final code = brand.balanceUssd ?? brand.ussdMenu;
  if (brand.kind != BrandKind.mobileMoney || code == null) return null;
  return () => dialUssd(code);
}

VoidCallback? mtnBalanceDialer(List<Account> accounts) {
  final mtn = accounts.where((a) => brandFor(a.accountType).id == 'mtn_momo');
  if (mtn.isEmpty) return null;
  return balanceDialerFor(mtn.first);
}
