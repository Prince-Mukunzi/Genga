import 'package:flutter_riverpod/flutter_riverpod.dart';

// HTTP import disabled — API calls commented out for offline use.
// import 'dart:convert';
// import 'package:http/http.dart' as http;

class CurrencyRate {
  final String code;
  final String name;
  final String flag;
  final double rateFromRwf;

  const CurrencyRate({
    required this.code,
    required this.name,
    required this.flag,
    required this.rateFromRwf,
  });
}

const _currencyMeta = <String, (String, String)>{
  'RWF': ('Rwandan Franc', '\u{1F1F7}\u{1F1FC}'),
  'USD': ('US Dollar', '\u{1F1FA}\u{1F1F8}'),
  'EUR': ('Euro', '\u{1F1EA}\u{1F1FA}'),
  'GBP': ('British Pound', '\u{1F1EC}\u{1F1E7}'),
  'KES': ('Kenyan Shilling', '\u{1F1F0}\u{1F1EA}'),
  'UGX': ('Ugandan Shilling', '\u{1F1FA}\u{1F1EC}'),
  'TZS': ('Tanzanian Shilling', '\u{1F1F9}\u{1F1FF}'),
  'BIF': ('Burundian Franc', '\u{1F1E7}\u{1F1EE}'),
  'ZAR': ('South African Rand', '\u{1F1FF}\u{1F1E6}'),
  'NGN': ('Nigerian Naira', '\u{1F1F3}\u{1F1EC}'),
  'CAD': ('Canadian Dollar', '\u{1F1E8}\u{1F1E6}'),
  'JPY': ('Japanese Yen', '\u{1F1EF}\u{1F1F5}'),
  'CNY': ('Chinese Yuan', '\u{1F1E8}\u{1F1F3}'),
  'INR': ('Indian Rupee', '\u{1F1EE}\u{1F1F3}'),
};

// Approximate rates: 1 USD = X of each currency (fallbacks).
const _usdApproxRates = <String, double>{
  'RWF': 1370.0,
  'EUR': 0.92,
  'GBP': 0.79,
  'KES': 129.0,
  'UGX': 3750.0,
  'TZS': 2510.0,
  'BIF': 2860.0,
  'ZAR': 18.2,
  'NGN': 1550.0,
  'CAD': 1.36,
  'JPY': 149.0,
  'CNY': 7.24,
  'INR': 83.5,
};

final currencyRatesProvider = FutureProvider.autoDispose<List<CurrencyRate>>((
  ref,
) async {
  // API call disabled — using offline fallback rates only.
  // To re-enable: uncomment the HTTP block below and the http import.
  //
  // final symbols = ['EUR', 'GBP', 'ZAR', 'CAD', 'JPY', 'CNY', 'INR'].join(',');
  // final url = Uri.parse(
  //     'https://api.frankfurter.dev/v1/latest?base=USD&symbols=$symbols');
  //
  // try {
  //   final response = await http.get(url).timeout(const Duration(seconds: 8));
  //   if (response.statusCode == 200) {
  //     final json = jsonDecode(response.body) as Map<String, dynamic>;
  //     final rates = json['rates'] as Map<String, dynamic>?;
  //     if (rates != null) {
  //       for (final e in rates.entries) {
  //         usdRates[e.key] = (e.value as num).toDouble();
  //       }
  //     }
  //   }
  // } catch (_) {
  //   // Use fallback rates
  // }

  Map<String, double> usdRates = {'USD': 1.0, ...Map.from(_usdApproxRates)};

  final rwfPerUsd = usdRates['RWF'] ?? 1370.0;

  final result = <CurrencyRate>[
    const CurrencyRate(
      code: 'RWF',
      name: 'Rwandan Franc',
      flag: '\u{1F1F7}\u{1F1FC}',
      rateFromRwf: 1.0,
    ),
  ];

  for (final entry in _currencyMeta.entries) {
    if (entry.key == 'RWF') continue;
    final meta = entry.value;
    final usdRate = usdRates[entry.key];
    double rateFromRwf;
    if (usdRate != null && rwfPerUsd > 0) {
      // 1 RWF = (1 / rwfPerUsd) USD = (usdRate / rwfPerUsd) target
      rateFromRwf = usdRate / rwfPerUsd;
    } else {
      rateFromRwf = 0;
    }
    result.add(
      CurrencyRate(
        code: entry.key,
        name: meta.$1,
        flag: meta.$2,
        rateFromRwf: rateFromRwf,
      ),
    );
  }

  return result;
});

String currencyFlag(String code) {
  return _currencyMeta[code]?.$2 ?? '';
}

String currencyFlagForCode(String code) {
  return _currencyMeta[code]?.$2 ?? '\u{1F1F7}\u{1F1FC}';
}

String currencyName(String code) {
  return _currencyMeta[code]?.$1 ?? code;
}
