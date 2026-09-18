import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/models/transaction_with_category.dart';
import 'package:genga/core/providers/space_provider.dart';

import 'database_provider.dart';

final recentTransactionsProvider =
    StreamProvider<List<TransactionWithCategory>>((ref) {
      final spaceId = ref.watch(activeSpaceProvider).valueOrNull?.id;
      return ref
          .watch(databaseProvider)
          .watchRecentTransactions(5, spaceId: spaceId);
    });

final allTransactionsProvider = StreamProvider<List<TransactionWithCategory>>((
  ref,
) {
  final spaceId = ref.watch(activeSpaceProvider).valueOrNull?.id;
  return ref.watch(databaseProvider).watchAllTransactions(spaceId: spaceId);
});

final recurringTransactionsProvider =
    StreamProvider<List<TransactionWithCategory>>((ref) {
      final spaceId = ref.watch(activeSpaceProvider).valueOrNull?.id;
      return ref
          .watch(databaseProvider)
          .watchRecurringTransactions(spaceId: spaceId);
    });

final totalSpentThisMonthProvider = Provider<double>((ref) {
  final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return txns
      .where(
        (t) =>
            t.transaction.type == TransactionType.expense &&
            t.transaction.date.year == now.year &&
            t.transaction.date.month == now.month,
      )
      .fold<double>(
        0,
        (sum, t) => sum + t.transaction.amount + t.transaction.momoFee,
      );
});

final totalIncomeThisMonthProvider = Provider<double>((ref) {
  final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return txns
      .where(
        (t) =>
            t.transaction.type == TransactionType.income &&
            t.transaction.date.year == now.year &&
            t.transaction.date.month == now.month,
      )
      .fold<double>(0, (sum, t) => sum + t.transaction.amount);
});

/// Spent this month scoped to a single account.
final accountSpentThisMonthProvider = Provider.family<double, int>((
  ref,
  accountId,
) {
  final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return txns
      .where(
        (t) =>
            t.transaction.accountId == accountId &&
            t.transaction.type == TransactionType.expense &&
            t.transaction.date.year == now.year &&
            t.transaction.date.month == now.month,
      )
      .fold<double>(
        0,
        (sum, t) => sum + t.transaction.amount + t.transaction.momoFee,
      );
});

/// Income this month scoped to a single account.
final accountIncomeThisMonthProvider = Provider.family<double, int>((
  ref,
  accountId,
) {
  final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return txns
      .where(
        (t) =>
            t.transaction.accountId == accountId &&
            t.transaction.type == TransactionType.income &&
            t.transaction.date.year == now.year &&
            t.transaction.date.month == now.month,
      )
      .fold<double>(0, (sum, t) => sum + t.transaction.amount);
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).watchAllCategories();
});

final accountsProvider = StreamProvider<List<Account>>((ref) {
  final activeSpace = ref.watch(activeSpaceProvider).valueOrNull;
  return ref.watch(databaseProvider).watchAccountsBySpace(activeSpace?.id);
});

final accountBalanceProvider = Provider.family<double, int>((ref, accountId) {
  final txns = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  final account = ref
      .watch(accountsProvider)
      .valueOrNull
      ?.where((a) => a.id == accountId)
      .firstOrNull;
  final initialBalance = account?.initialBalance ?? 0;

  return txns.fold<double>(initialBalance, (sum, t) {
    final txn = t.transaction;
    final totalCost = txn.amount + txn.momoFee;
    if (txn.accountId == accountId) {
      if (txn.type == TransactionType.income) {
        return sum + txn.amount;
      } else if (txn.type == TransactionType.expense) {
        return sum - totalCost;
      } else if (txn.type == TransactionType.transfer) {
        return sum - totalCost;
      }
    }
    if (txn.toAccountId == accountId && txn.type == TransactionType.transfer) {
      return sum + txn.amount;
    }
    return sum;
  });
});
