import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('v9 icon code points migrate to string keys', () async {
    final dir = Directory.systemTemp.createTempSync('genga_mig');
    final file = File('${dir.path}/db.sqlite');

    final fresh = AppDatabase.forTesting(NativeDatabase(file));
    await fresh.customSelect('SELECT 1').get();
    await fresh.close();

    final cart = AppIcons.legacyCodePoints.entries
        .firstWhere((e) => e.value == 'cart_fill')
        .key;
    final raw = sqlite3.open(file.path);
    raw.execute(
      "INSERT INTO accounts (name, icon_key, color) VALUES ('Cash', 'x', 0)",
    );
    for (final t in ['spaces', 'categories', 'accounts']) {
      raw.execute('ALTER TABLE $t DROP COLUMN icon_key');
      raw.execute(
          'ALTER TABLE $t ADD COLUMN icon_code_point INTEGER NOT NULL DEFAULT $cart');
    }
    raw.execute("UPDATE categories SET icon_code_point = 999999 WHERE name = 'Other'");
    raw.execute('PRAGMA user_version = 9');
    raw.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    final cats = await migrated.select(migrated.categories).get();
    final groceries = cats.firstWhere((c) => c.name == 'Groceries');
    final other = cats.firstWhere((c) => c.name == 'Other');
    expect(groceries.iconKey, 'cart_fill');
    expect(other.iconKey, AppIcons.fallbackKey);
    expect((await migrated.select(migrated.spaces).get()).first.iconKey,
        'cart_fill');
    expect((await migrated.select(migrated.accounts).get()).first.iconKey,
        'cart_fill');
    await migrated.close();
    dir.deleteSync(recursive: true);
  });
}
