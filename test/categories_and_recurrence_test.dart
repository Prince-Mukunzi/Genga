import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/utils/recurrence.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('monthly recurrence on the 31st clamps instead of drifting', () {
    final start = DateTime(2026, 1, 31);
    expect(
      nextOccurrence(start, 'monthly', after: DateTime(2026, 2, 1)),
      DateTime(2026, 2, 28),
    );
    expect(
      nextOccurrence(start, 'monthly', after: DateTime(2026, 3, 1)),
      DateTime(2026, 3, 31),
    );
  });

  test('v11 categories merge into the Rwandan set, keeping transactions',
      () async {
    final dir = Directory.systemTemp.createTempSync('genga_cat');
    final file = File('${dir.path}/db.sqlite');

    final fresh = AppDatabase.forTesting(NativeDatabase(file));
    await fresh.customSelect('SELECT 1').get();
    await fresh.close();

    final raw = sqlite3.open(file.path);
    raw.execute(
      "INSERT INTO categories (name, icon_key, color, group_name, type, is_default, budget_limit) "
      "VALUES ('Moto taxi', 'motorbike', 0, 'Transport', 'expense', 1, 20000)",
    );
    raw.execute(
      "INSERT INTO accounts (name, icon_key, color, account_type, is_primary) "
      "VALUES ('Cash', 'money_dollar', 0, 'cash', 1)",
    );
    final motoId = raw.select("SELECT id FROM categories WHERE name = 'Moto taxi'").first['id'];
    final accountId = raw.select('SELECT id FROM accounts').first['id'];
    raw.execute(
      'INSERT INTO transactions (amount, type, category_id, account_id, date) '
      'VALUES (1500, ${TransactionType.expense.index}, $motoId, $accountId, 0)',
    );
    raw.execute('PRAGMA user_version = 11');
    raw.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    final cats = await db.select(db.categories).get();
    final names = cats.map((c) => c.name).toSet();
    expect(names.contains('Moto taxi'), isFalse);
    expect(cats.length, 21);

    final transport = cats.firstWhere((c) => c.name == 'Transport');
    expect(transport.budgetLimit, 20000);
    final txn = await db.select(db.transactions).getSingle();
    expect(txn.categoryId, transport.id);

    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('erasing everything leaves a fresh space with no accounts', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(name: 'MoMo', iconKey: 'x', color: 0),
        );
    await db.eraseEverything();
    expect(await db.select(db.accounts).get(), isEmpty);
    expect((await db.select(db.spaces).get()).single.isActive, isTrue);
    expect((await db.select(db.categories).get()).length, 21);
    await db.close();
  });
}
