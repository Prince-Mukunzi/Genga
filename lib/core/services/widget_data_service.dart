import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/shared/brands/account_brand.dart';
import 'package:flutter/painting.dart' show LinearGradient;

/// Keys used to store widget data in shared UserDefaults / SharedPreferences.
abstract final class WidgetDataKeys {
  static const totalBalance = 'total_balance';
  static const totalBalanceFormatted = 'total_balance_formatted';
  static const spentThisMonth = 'spent_this_month';
  static const spentThisMonthFormatted = 'spent_this_month_formatted';
  static const incomeThisMonth = 'income_this_month';
  static const incomeThisMonthFormatted = 'income_this_month_formatted';
  static const recentTransactions = 'recent_transactions';
  static const totalTransactionsCount = 'total_transactions_count';
  static const lastUpdated = 'last_updated';
  static const primaryName = 'primary_account_name';
  static const primaryBalance = 'primary_balance_formatted';
  static const primarySpent = 'primary_spent_formatted';
  static const primaryColors = 'primary_brand_colors';
}

/// Widget kind identifiers matching the Swift `Widget.kind` strings.
abstract final class WidgetNames {
  /// iOS WidgetKit widget kind identifiers.
  static const iOSSummary = 'GengaSummaryWidget';
  static const iOSQuickActions = 'GengaQuickActionsWidget';

  /// Android AppWidgetProvider class name (fully qualified).
  static const android = 'GengaWidgetProvider';
}

/// App Group ID used for iOS data sharing.
const _appGroupId = 'group.com.example.genga';

/// Service that pushes the latest financial summary to the home screen widgets.
class WidgetDataService {
  final AppDatabase _db;

  WidgetDataService(this._db);

  /// Computes the current financial snapshot and writes it to shared storage,
  /// then triggers a native widget reload for all widget kinds.
  Future<void> updateWidgetData() async {
    try {
      final activeSpace = await _db.getActiveSpace();
      final spaceId = activeSpace?.id;
      final accounts = await _db.getAllAccounts(
        spaceId: spaceId,
        filterBySpace: true,
      );
      final transactions = await _db.getAllTransactionsOnce(spaceId: spaceId);

      // ── Compute balances ──
      final totalBalance = _computeTotalBalance(accounts, transactions);
      final now = DateTime.now();
      final spentThisMonth = _computeMonthlyTotal(
        transactions,
        TransactionType.expense,
        now,
      );
      final incomeThisMonth = _computeMonthlyTotal(
        transactions,
        TransactionType.income,
        now,
      );

      // ── Format for display ──
      final formatter = NumberFormat.decimalPatternDigits(
        locale: 'en_US',
        decimalDigits: 0,
      );

      // ── Recent transactions (last 5 for the large widget) ──
      final recentTxnsWithCategory = await _db.getRecentTransactionsOnce(
        5,
        spaceId: spaceId,
      );
      final recentList = recentTxnsWithCategory.map((item) {
        final t = item.transaction;
        final cat = item.category;
        return {
          'amount': t.amount,
          'amountFormatted': 'R₣${formatter.format(t.amount)}',
          'type': t.type.name,
          'category': cat?.name ?? '',
          'note': t.note,
          'date': t.date.toIso8601String(),
        };
      }).toList();

      // ── Primary account for the wallet widget ──
      final primary =
          accounts.where((a) => a.isPrimary).firstOrNull ??
          accounts.firstOrNull;
      var primaryName = 'Genga';
      var primaryBalance = totalBalance;
      var primarySpent = spentThisMonth;
      var brandColors = <int>[0xFF3A3A42, 0xFF16161B];
      if (primary != null) {
        primaryName = primary.name;
        primaryBalance = _computeTotalBalance([primary], transactions);
        primarySpent = _computeMonthlyTotal(
          transactions.where((t) => t.accountId == primary.id).toList(),
          TransactionType.expense,
          now,
        );
        final gradient = brandFor(primary.accountType).layers.first;
        if (gradient is LinearGradient) {
          brandColors = gradient.colors.map((c) => c.toARGB32()).toList();
        }
      }

      // ── Save to shared storage ──
      await HomeWidget.setAppGroupId(_appGroupId);

      await Future.wait([
        HomeWidget.saveWidgetData<double>(
          WidgetDataKeys.totalBalance,
          totalBalance,
        ),
        HomeWidget.saveWidgetData<String>(
          WidgetDataKeys.totalBalanceFormatted,
          'RWF ${formatter.format(totalBalance)}',
        ),
        HomeWidget.saveWidgetData<double>(
          WidgetDataKeys.spentThisMonth,
          spentThisMonth,
        ),
        HomeWidget.saveWidgetData<String>(
          WidgetDataKeys.spentThisMonthFormatted,
          'RWF ${formatter.format(spentThisMonth)}',
        ),
        HomeWidget.saveWidgetData<double>(
          WidgetDataKeys.incomeThisMonth,
          incomeThisMonth,
        ),
        HomeWidget.saveWidgetData<String>(
          WidgetDataKeys.incomeThisMonthFormatted,
          'RWF ${formatter.format(incomeThisMonth)}',
        ),
        HomeWidget.saveWidgetData<String>(
          WidgetDataKeys.recentTransactions,
          jsonEncode(recentList),
        ),
        HomeWidget.saveWidgetData<int>(
          WidgetDataKeys.totalTransactionsCount,
          transactions.length,
        ),
        HomeWidget.saveWidgetData<String>(
          WidgetDataKeys.primaryName,
          primaryName,
        ),
        HomeWidget.saveWidgetData<String>(
          WidgetDataKeys.primaryBalance,
          'R₣${formatter.format(primaryBalance)}',
        ),
        HomeWidget.saveWidgetData<String>(
          WidgetDataKeys.primarySpent,
          formatter.format(primarySpent),
        ),
        HomeWidget.saveWidgetData<String>(
          WidgetDataKeys.primaryColors,
          jsonEncode(brandColors),
        ),
        HomeWidget.saveWidgetData<String>(
          WidgetDataKeys.lastUpdated,
          DateTime.now().toIso8601String(),
        ),
      ]);

      // ── Trigger native widget reload for all widget kinds ──
      await _reloadAllWidgets();
    } catch (_) {
      // Widget update is best-effort; never crash the main app.
    }
  }

  /// Reloads all registered widget kinds on both platforms.
  Future<void> _reloadAllWidgets() async {
    await Future.wait([
      HomeWidget.updateWidget(
        iOSName: WidgetNames.iOSSummary,
        androidName: WidgetNames.android,
      ),
      HomeWidget.updateWidget(
        iOSName: WidgetNames.iOSQuickActions,
        androidName: WidgetNames.android,
      ),
    ]);
  }

  double _computeTotalBalance(
    List<Account> accounts,
    List<TransactionEntry> transactions,
  ) {
    double total = 0;
    for (final account in accounts) {
      double balance = account.initialBalance;
      for (final txn in transactions) {
        final totalCost = txn.amount + txn.momoFee;
        if (txn.accountId == account.id) {
          if (txn.type == TransactionType.income) {
            balance += txn.amount;
          } else if (txn.type == TransactionType.expense) {
            balance -= totalCost;
          } else if (txn.type == TransactionType.transfer) {
            balance -= totalCost;
          }
        }
        if (txn.toAccountId == account.id &&
            txn.type == TransactionType.transfer) {
          balance += txn.amount;
        }
      }
      total += balance;
    }
    return total;
  }

  double _computeMonthlyTotal(
    List<TransactionEntry> transactions,
    TransactionType type,
    DateTime now,
  ) {
    return transactions
        .where(
          (t) =>
              t.type == type &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold<double>(
          0,
          (sum, t) =>
              sum +
              t.amount +
              (type == TransactionType.expense ? t.momoFee : 0),
        );
  }
}

/// Riverpod provider for the widget data service.
final widgetDataServiceProvider = Provider<WidgetDataService>((ref) {
  final db = ref.watch(databaseProvider);
  return WidgetDataService(db);
});
