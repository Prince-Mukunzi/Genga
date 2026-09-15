import 'package:genga/core/database/database.dart';

class TransactionWithCategory {
  final TransactionEntry transaction;
  final Category? category;
  final Account? account;
  final Account? toAccount;

  const TransactionWithCategory({
    required this.transaction,
    this.category,
    this.account,
    this.toAccount,
  });
}
