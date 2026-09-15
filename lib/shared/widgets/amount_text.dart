import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/core/models/enums.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final TransactionType type;
  final TextStyle? style;
  final String currency;
  final bool showSign;

  const AmountText({
    super.key,
    required this.amount,
    required this.type,
    this.style,
    this.currency = 'RWF',
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      TransactionType.expense => GengaColors.expense,
      TransactionType.income => GengaColors.income,
      TransactionType.transfer => GengaColors.transfer,
    };

    final sign = switch (type) {
      TransactionType.expense => '- ',
      TransactionType.income => '+ ',
      TransactionType.transfer => '',
    };

    final formatted = _formatAmount(amount, currency);
    final text = showSign ? '$sign$formatted' : formatted;

    return Text(
      text,
      style:
          (style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
              .copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static String _formatAmount(double amount, String currency) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'en_US',
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    );
    return '$currency ${formatter.format(amount)}';
  }

  static const _symbols = {
    'RWF': 'R₣',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'KES': 'KSh',
    'UGX': 'USh',
    'TZS': 'TSh',
    'BIF': 'FBu',
    'ZAR': 'R',
  };

  static String symbol(String code) => _symbols[code] ?? code;

  static String withSymbol(double amount, String code) {
    final sym = symbol(code);
    final gap = sym.length > 2 ? ' ' : '';
    return '$sym$gap${plain(amount)}';
  }

  static String plain(double amount) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'en_US',
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    );
    return formatter.format(amount);
  }

  static String format(double amount, {String currency = 'RWF'}) {
    return _formatAmount(amount, currency);
  }
}
