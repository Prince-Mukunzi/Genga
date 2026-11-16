import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart' hide Column, Table;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:genga/app/theme/colors.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/models/transaction_with_category.dart';
import 'package:genga/shared/icons/app_icons.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Spaces,
    SpaceMembers,
    Categories,
    Accounts,
    Transactions,
    SpaceNotifications,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultSpace();
      await _seedCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 6) {
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
        await _seedDefaultSpace();
        await _seedCategories();
        await _seedDefaultAccount();
      }
      if (from < 7) {
        await _addColumnIfMissing(m, transactions, transactions.momoFee);
      }
      if (from < 8) {
        await _addColumnIfMissing(m, spaceMembers, spaceMembers.phone);
        await _addColumnIfMissing(m, spaceMembers, spaceMembers.status);
        try {
          await m.createTable(spaceNotifications);
        } catch (_) {}
      }
      if (from < 9) {
        await _addColumnIfMissing(m, transactions, transactions.createdBy);
        await _addColumnIfMissing(m, transactions, transactions.updatedBy);
        await _addColumnIfMissing(m, transactions, transactions.recipientName);
        await _addColumnIfMissing(m, transactions, transactions.recipientPhone);
        await _addColumnIfMissing(m, categories, categories.budgetLimit);
        await _addColumnIfMissing(m, accounts, accounts.initialBalance);
      }
      if (from < 10) {
        await _migrateIconKeys(m);
      }
      if (from < 12) {
        await _consolidateCategories();
      }
    },
  );

  Future<void> _migrateIconKeys(Migrator m) async {
    final whens = AppIcons.legacyCodePoints.entries
        .map((e) => "WHEN ${e.key} THEN '${e.value}'")
        .join(' ');
    final expr = CustomExpression<String>(
      "CASE icon_code_point $whens ELSE '${AppIcons.fallbackKey}' END",
    );
    await m.alterTable(
      TableMigration(
        spaces,
        newColumns: [spaces.iconKey],
        columnTransformer: {spaces.iconKey: expr},
      ),
    );
    await m.alterTable(
      TableMigration(
        categories,
        newColumns: [categories.iconKey],
        columnTransformer: {categories.iconKey: expr},
      ),
    );
    await m.alterTable(
      TableMigration(
        accounts,
        newColumns: [accounts.iconKey],
        columnTransformer: {accounts.iconKey: expr},
      ),
    );
  }

  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    try {
      await m.addColumn(table, column);
    } catch (_) {
      // Column already exists — safe to ignore.
    }
  }

  // ════════════════════════════════════════════════════════════
  // Seed data
  // ════════════════════════════════════════════════════════════

  Future<void> _seedDefaultSpace() async {
    final spaceId = await into(spaces).insert(
      SpacesCompanion.insert(
        name: 'Personal',
        color: const Color(0xFF6366F1).toARGB32(),
        iconKey: 'person_fill',
        isActive: const Value(true),
        type: const Value('personal'),
      ),
    );
    await into(spaceMembers).insert(
      SpaceMembersCompanion.insert(
        spaceId: spaceId,
        displayName: 'You',
        role: const Value('admin'),
        isCurrentUser: const Value(true),
      ),
    );
  }

  static List<CategoriesCompanion> _defaultCategories() => [
    _cat('Groceries', 'cart_fill', 3, 'Essentials'),
    _cat('Transport', 'motorbike', 1, 'Essentials'),
    _cat('Rent', 'house_fill', 0, 'Essentials'),
    _cat('Utilities', 'plug', 6, 'Essentials'),
    _cat('Airtime & data', 'smartphone', 4, 'Essentials'),
    _cat('Health', 'stethoscope', 5, 'Essentials'),
    _cat('Education', 'school', 2, 'Essentials'),
    _cat('Family & giving', 'user_group', 8, 'Essentials'),
    _cat('Eating out', 'restaurant', 0, 'Lifestyle'),
    _cat('Shopping', 'bag_fill', 4, 'Lifestyle'),
    _cat('Beauty & care', 'scissor', 8, 'Lifestyle'),
    _cat('Going out', 'sparkles', 7, 'Lifestyle'),
    _cat('Subscriptions', 'arrow_2_circlepath', 9, 'Lifestyle'),
    _cat('Savings', 'coins', 3, 'Money'),
    _cat('Loans', 'wallet', 5, 'Money'),
    _cat('Fees', 'building_2_fill', 6, 'Money'),
    _catIncome('Salary', 'money_dollar', 3, 'Income'),
    _catIncome('Business', 'store', 1, 'Income'),
    _catIncome('Freelance', 'briefcase_fill', 10, 'Income'),
    _catIncome('Gift received', 'gift_fill', 5, 'Income'),
    _cat('Other', 'ellipsis', 11, 'Other'),
  ];

  // Every default name Genga has ever shipped, mapped onto the current set.
  static const _legacyCategoryTargets = {
    'Market': 'Groceries',
    'Restaurants': 'Eating out',
    'Brochettes & snacks': 'Eating out',
    'Coffee & tea': 'Eating out',
    'Coffee': 'Eating out',
    'Food delivery': 'Eating out',
    'Bike': 'Transport',
    'Public transport': 'Transport',
    'Moto taxi': 'Transport',
    'Bus': 'Transport',
    'Taxi & ride-hailing': 'Transport',
    'Taxi & Ride-hailing': 'Transport',
    'Fuel': 'Transport',
    'Car maintenance': 'Transport',
    'Parking': 'Transport',
    'Electricity': 'Utilities',
    'Water': 'Utilities',
    'Internet': 'Airtime & data',
    'Phone': 'Airtime & data',
    'Home supplies': 'Shopping',
    'Netflix': 'Subscriptions',
    'Spotify': 'Subscriptions',
    'Canal+ & TV': 'Subscriptions',
    'Other subscriptions': 'Subscriptions',
    'Claude': 'Subscriptions',
    'ChatGPT': 'Subscriptions',
    'Higgsfield': 'Subscriptions',
    'Cursor': 'Subscriptions',
    'Gemini': 'Subscriptions',
    'Other AI tools': 'Subscriptions',
    'Clothes': 'Shopping',
    'Electronics': 'Shopping',
    'Home decor': 'Shopping',
    'Salon & beauty': 'Beauty & care',
    'Beauty': 'Beauty & care',
    'Mutuelle de santé': 'Health',
    'Insurance': 'Health',
    'Pharmacy': 'Health',
    'Hospital & doctor': 'Health',
    'Doctor': 'Health',
    'Gym & sports': 'Going out',
    'Gym': 'Going out',
    'Movies': 'Going out',
    'Games': 'Going out',
    'Activities': 'Going out',
    'Trips & activities': 'Going out',
    'Hotels': 'Going out',
    'Flights': 'Transport',
    'Mobile money fees': 'Fees',
    'Bank fees': 'Fees',
    'Taxes': 'Fees',
    'Ejo Heza savings': 'Savings',
    'School fees': 'Education',
    'Tuition': 'Education',
    'Books & supplies': 'Education',
    'Books': 'Education',
    'Courses': 'Education',
    'Church & tithe': 'Family & giving',
    'Family support': 'Family & giving',
    'Weddings & events': 'Family & giving',
    'Gifts': 'Family & giving',
    'Charity': 'Family & giving',
    'Rental income': 'Business',
    'Interest': 'Business',
  };

  Future<void> _seedCategories() async {
    await batch((b) => b.insertAll(categories, _defaultCategories()));
  }

  Future<void> _consolidateCategories() async {
    await transaction(() async {
      final wanted = _defaultCategories();
      final existing = await select(categories).get();
      final names = existing.map((c) => c.name).toSet();
      final missing = wanted
          .where((c) => !names.contains(c.name.value))
          .toList();
      if (missing.isNotEmpty) {
        await batch((b) => b.insertAll(categories, missing));
      }

      final all = await select(categories).get();
      final byName = {for (final c in all) c.name: c};
      final keep = wanted.map((c) => c.name.value).toSet();

      for (final old in all.where(
        (c) => c.isDefault && !keep.contains(c.name),
      )) {
        final targetName =
            _legacyCategoryTargets[old.name] ??
            (old.type == 'income' ? 'Business' : 'Other');
        final target = byName[targetName];
        if (target == null) continue;

        await (update(transactions)..where((t) => t.categoryId.equals(old.id)))
            .write(TransactionsCompanion(categoryId: Value(target.id)));

        final oldBudget = old.budgetLimit;
        if (oldBudget != null && oldBudget > 0) {
          final fresh = await (select(
            categories,
          )..where((c) => c.id.equals(target.id))).getSingle();
          await (update(
            categories,
          )..where((c) => c.id.equals(target.id))).write(
            CategoriesCompanion(
              budgetLimit: Value((fresh.budgetLimit ?? 0) + oldBudget),
            ),
          );
        }

        await (delete(categories)..where((c) => c.id.equals(old.id))).go();
      }
    });
  }

  static CategoriesCompanion _cat(
    String name,
    String icon,
    int colorIdx,
    String group,
  ) {
    final color = GengaColors
        .categoryPalette[colorIdx % GengaColors.categoryPalette.length]
        .toARGB32();
    return CategoriesCompanion.insert(
      name: name,
      iconKey: icon,
      color: color,
      groupName: Value(group),
      type: const Value('expense'),
      isDefault: const Value(true),
    );
  }

  static CategoriesCompanion _catIncome(
    String name,
    String icon,
    int colorIdx,
    String group,
  ) {
    final color = GengaColors
        .categoryPalette[colorIdx % GengaColors.categoryPalette.length]
        .toARGB32();
    return CategoriesCompanion.insert(
      name: name,
      iconKey: icon,
      color: color,
      groupName: Value(group),
      type: const Value('income'),
      isDefault: const Value(true),
    );
  }

  Future<void> _seedDefaultAccount() async {
    final activeSpace = await getActiveSpace();
    final spaceId = activeSpace?.id;
    await into(accounts).insert(
      AccountsCompanion.insert(
        name: 'Cash',
        iconKey: 'money_dollar',
        color: const Color(0xFF3478F6).toARGB32(),
        accountType: const Value('cash'),
        isPrimary: const Value(true),
        spaceId: Value(spaceId),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Spaces
  // ════════════════════════════════════════════════════════════

  Future<List<Space>> getAllSpaces() => select(spaces).get();

  Stream<List<Space>> watchAllSpaces() => select(spaces).watch();

  Future<Space?> getActiveSpace() async {
    final query = select(spaces)
      ..where((s) => s.isActive.equals(true))
      ..limit(1);
    final result = await query.get();
    return result.isNotEmpty ? result.first : null;
  }

  Stream<Space?> watchActiveSpace() {
    final query = select(spaces)
      ..where((s) => s.isActive.equals(true))
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<int> insertSpace(SpacesCompanion entry) async {
    final spaceId = await into(spaces).insert(entry);
    await into(accounts).insert(
      AccountsCompanion.insert(
        name: 'Cash',
        iconKey: 'money_dollar',
        color: const Color(0xFF3478F6).toARGB32(),
        accountType: const Value('cash'),
        isPrimary: const Value(true),
        spaceId: Value(spaceId),
      ),
    );
    return spaceId;
  }

  Future<int> insertSpaceFromInvite(SpacesCompanion entry) async {
    return into(spaces).insert(entry);
  }

  Future<Space?> getSpaceById(int id) async {
    final query = select(spaces)
      ..where((s) => s.id.equals(id))
      ..limit(1);
    final result = await query.get();
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> joinSpace(
    int spaceId, {
    required String displayName,
    required String phone,
  }) async {
    await into(spaceMembers).insert(
      SpaceMembersCompanion.insert(
        spaceId: spaceId,
        displayName: displayName,
        role: const Value('member'),
        status: const Value('pending'),
        isCurrentUser: const Value(true),
        phone: Value(phone),
      ),
    );
    final hasExisting = await (select(
      accounts,
    )..where((a) => a.spaceId.equals(spaceId))).get();
    if (hasExisting.isEmpty) {
      await into(accounts).insert(
        AccountsCompanion.insert(
          name: 'Cash',
          iconKey: 'money_dollar',
          color: const Color(0xFF3478F6).toARGB32(),
          accountType: const Value('cash'),
          isPrimary: const Value(true),
          spaceId: Value(spaceId),
        ),
      );
    }
    await setActiveSpace(spaceId);
  }

  Future<void> addPendingMember(
    int spaceId, {
    required String displayName,
    required String phone,
  }) async {
    final existing =
        await (select(spaceMembers)
              ..where(
                (m) =>
                    m.spaceId.equals(spaceId) &
                    m.displayName.equals(displayName) &
                    m.phone.equals(phone),
              )
              ..limit(1))
            .get();
    if (existing.isNotEmpty) return;

    await into(spaceMembers).insert(
      SpaceMembersCompanion.insert(
        spaceId: spaceId,
        displayName: displayName,
        role: const Value('member'),
        status: const Value('pending'),
        phone: Value(phone),
      ),
    );
  }

  Future<void> approveMember(int memberId) async {
    await (update(spaceMembers)..where((m) => m.id.equals(memberId))).write(
      const SpaceMembersCompanion(status: Value('active')),
    );
  }

  Future<void> rejectMember(int memberId) async {
    await (delete(spaceMembers)..where((m) => m.id.equals(memberId))).go();
  }

  Stream<List<SpaceMember>> watchPendingMembers(int spaceId) {
    final query = select(spaceMembers)
      ..where(
        (m) =>
            m.spaceId.equals(spaceId) &
            m.status.equals('pending') &
            m.isCurrentUser.equals(false),
      )
      ..orderBy([(m) => OrderingTerm.desc(m.joinedAt)]);
    return query.watch();
  }

  Stream<int> watchPendingMemberCount(int spaceId) {
    final count = spaceMembers.id.count();
    final query = selectOnly(spaceMembers)
      ..addColumns([count])
      ..where(
        spaceMembers.spaceId.equals(spaceId) &
            spaceMembers.status.equals('pending') &
            spaceMembers.isCurrentUser.equals(false),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<bool> updateSpace(Space entry) => update(spaces).replace(entry);

  Future<void> setActiveSpace(int spaceId) async {
    await (update(spaces)..where((s) => s.isActive.equals(true))).write(
      const SpacesCompanion(isActive: Value(false)),
    );
    await (update(spaces)..where((s) => s.id.equals(spaceId))).write(
      const SpacesCompanion(isActive: Value(true)),
    );
  }

  Future<void> deleteSpace(int id) => transaction(() async {
    final ids = (await getAllAccounts(spaceId: id)).map((a) => a.id).toList();
    if (ids.isNotEmpty) {
      await (delete(
        transactions,
      )..where((t) => t.accountId.isIn(ids) | t.toAccountId.isIn(ids))).go();
      await (delete(accounts)..where((a) => a.id.isIn(ids))).go();
    }
    await (delete(spaceMembers)..where((m) => m.spaceId.equals(id))).go();
    await (delete(spaceNotifications)..where((n) => n.spaceId.equals(id))).go();
    await (delete(spaces)..where((s) => s.id.equals(id))).go();

    final active = await (select(
      spaces,
    )..where((s) => s.isActive.equals(true))).get();
    if (active.isEmpty) {
      final fallback = await (select(spaces)..limit(1)).getSingleOrNull();
      if (fallback != null) await setActiveSpace(fallback.id);
    }
  });

  Future<void> eraseEverything() => transaction(() async {
    for (final TableInfo table in [
      transactions,
      accounts,
      spaceNotifications,
      spaceMembers,
      categories,
      spaces,
    ]) {
      await delete(table).go();
    }
    await _seedDefaultSpace();
    await _seedCategories();
  });

  Future<void> deleteTransactionsForSpace(int spaceId) async {
    final spaceAccounts = await getAllAccounts(spaceId: spaceId);
    final ids = spaceAccounts.map((a) => a.id).toList();
    if (ids.isEmpty) return;
    await (delete(transactions)..where((t) => t.accountId.isIn(ids))).go();
  }

  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<Space?> getSpaceByInviteCode(String code) async {
    final query = select(spaces)
      ..where((s) => s.inviteCode.equals(code))
      ..limit(1);
    final result = await query.get();
    return result.isNotEmpty ? result.first : null;
  }

  // ════════════════════════════════════════════════════════════
  // Space Members
  // ════════════════════════════════════════════════════════════

  Stream<List<SpaceMember>> watchSpaceMembers(int spaceId) {
    final query = select(spaceMembers)
      ..where((m) => m.spaceId.equals(spaceId))
      ..orderBy([(m) => OrderingTerm.asc(m.joinedAt)]);
    return query.watch();
  }

  Future<List<SpaceMember>> getSpaceMembers(int spaceId) {
    final query = select(spaceMembers)..where((m) => m.spaceId.equals(spaceId));
    return query.get();
  }

  Future<SpaceMember?> getCurrentUserMember(int spaceId) async {
    final query = select(spaceMembers)
      ..where((m) => m.spaceId.equals(spaceId) & m.isCurrentUser.equals(true))
      ..limit(1);
    final result = await query.get();
    return result.isNotEmpty ? result.first : null;
  }

  Future<String> currentUserName() async {
    final rows =
        await (select(spaceMembers)
              ..where((m) => m.isCurrentUser.equals(true))
              ..orderBy([(m) => OrderingTerm.asc(m.id)])
              ..limit(1))
            .get();
    return rows.firstOrNull?.displayName ?? 'You';
  }

  Future<void> setUserName(String name) async {
    await customStatement(
      'UPDATE space_members SET display_name = ? WHERE is_current_user = 1',
      [name],
    );
    final first = name.trim().split(RegExp(r'\s+')).first;
    await customStatement(
      "UPDATE spaces SET name = ? WHERE type = 'personal'",
      [first],
    );
  }

  Future<int> insertSpaceMember(SpaceMembersCompanion entry) =>
      into(spaceMembers).insert(entry);

  Future<bool> updateSpaceMember(SpaceMember entry) =>
      update(spaceMembers).replace(entry);

  Future<int> deleteSpaceMember(int id) =>
      (delete(spaceMembers)..where((m) => m.id.equals(id))).go();

  Future<int> memberCount(int spaceId) async {
    final count =
        await (selectOnly(spaceMembers)
              ..addColumns([spaceMembers.id.count()])
              ..where(spaceMembers.spaceId.equals(spaceId)))
            .map((row) => row.read(spaceMembers.id.count()))
            .getSingle();
    return count ?? 0;
  }

  // ════════════════════════════════════════════════════════════
  // Notifications
  // ════════════════════════════════════════════════════════════

  Future<int> insertNotification(SpaceNotificationsCompanion entry) =>
      into(spaceNotifications).insert(entry);

  Stream<List<SpaceNotification>> watchUnreadNotifications(int spaceId) {
    final query = select(spaceNotifications)
      ..where((n) => n.spaceId.equals(spaceId) & n.isRead.equals(false))
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
    return query.watch();
  }

  Stream<List<SpaceNotification>> watchAllNotifications(int spaceId) {
    final query = select(spaceNotifications)
      ..where((n) => n.spaceId.equals(spaceId))
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
      ..limit(50);
    return query.watch();
  }

  Stream<int> watchUnreadNotificationCount(int spaceId) {
    final count = spaceNotifications.id.count();
    final query = selectOnly(spaceNotifications)
      ..addColumns([count])
      ..where(
        spaceNotifications.spaceId.equals(spaceId) &
            spaceNotifications.isRead.equals(false),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<void> markNotificationRead(int notificationId) async {
    await (update(spaceNotifications)
          ..where((n) => n.id.equals(notificationId)))
        .write(const SpaceNotificationsCompanion(isRead: Value(true)));
  }

  Future<void> markAllNotificationsRead(int spaceId) async {
    await (update(spaceNotifications)
          ..where((n) => n.spaceId.equals(spaceId) & n.isRead.equals(false)))
        .write(const SpaceNotificationsCompanion(isRead: Value(true)));
  }

  // ════════════════════════════════════════════════════════════
  // Categories
  // ════════════════════════════════════════════════════════════

  Future<List<Category>> getAllCategories() => select(categories).get();

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(Category entry) =>
      update(categories).replace(entry);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  // ════════════════════════════════════════════════════════════
  // Accounts
  // ════════════════════════════════════════════════════════════

  Future<List<Account>> getAllAccounts({
    int? spaceId,
    bool filterBySpace = false,
  }) {
    if (!filterBySpace) return select(accounts).get();
    final query = select(accounts);
    if (spaceId != null) {
      query.where((a) => a.spaceId.equals(spaceId));
    } else {
      query.where((a) => a.spaceId.isNull());
    }
    return query.get();
  }

  Stream<List<Account>> watchAllAccounts() => select(accounts).watch();

  Stream<List<Account>> watchAccountsBySpace(int? spaceId) {
    final query = select(accounts)
      ..where(
        (a) => spaceId != null ? a.spaceId.equals(spaceId) : a.spaceId.isNull(),
      );
    return query.watch();
  }

  Future<int> insertAccount(AccountsCompanion entry) =>
      into(accounts).insert(entry);

  Future<bool> updateAccount(Account entry) => update(accounts).replace(entry);

  Future<int> deleteAccount(int id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();

  Future<Account?> getPrimaryAccount() async {
    final query = select(accounts)
      ..where((a) => a.isPrimary.equals(true))
      ..limit(1);
    final result = await query.get();
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> setPrimaryAccount(int accountId) async {
    await (update(accounts)..where((a) => a.isPrimary.equals(true))).write(
      const AccountsCompanion(isPrimary: Value(false)),
    );
    await (update(accounts)..where((a) => a.id.equals(accountId))).write(
      const AccountsCompanion(isPrimary: Value(true)),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Transactions
  // ════════════════════════════════════════════════════════════

  late final _toAccounts = alias(accounts, 'to_acct');

  JoinedSelectStatement<HasResultSet, dynamic> _txnBaseQuery({
    int? spaceId,
    bool filterBySpace = false,
  }) {
    final query = select(transactions).join([
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      leftOuterJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(
        _toAccounts,
        _toAccounts.id.equalsExp(transactions.toAccountId),
      ),
    ]);
    if (filterBySpace) {
      if (spaceId != null) {
        query.where(accounts.spaceId.equals(spaceId));
      } else {
        query.where(accounts.spaceId.isNull());
      }
    }
    return query;
  }

  Stream<List<TransactionWithCategory>> watchAllTransactions({int? spaceId}) {
    final query = _txnBaseQuery(spaceId: spaceId, filterBySpace: true);
    query.orderBy([OrderingTerm.desc(transactions.date)]);
    return query.watch().map((rows) => rows.map(_rowToTxn).toList());
  }

  Future<List<TransactionEntry>> getAllTransactionsOnce({int? spaceId}) {
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ]);
    if (spaceId != null) {
      query.where(accounts.spaceId.equals(spaceId));
    } else {
      query.where(accounts.spaceId.isNull());
    }
    return query.map((row) => row.readTable(transactions)).get();
  }

  Stream<List<TransactionWithCategory>> watchRecentTransactions(
    int limit, {
    int? spaceId,
  }) {
    final query = _txnBaseQuery(spaceId: spaceId, filterBySpace: true);
    query
      ..orderBy([OrderingTerm.desc(transactions.date)])
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_rowToTxn).toList());
  }

  Future<List<TransactionWithCategory>> getRecentTransactionsOnce(
    int limit, {
    int? spaceId,
  }) async {
    final query = _txnBaseQuery(spaceId: spaceId, filterBySpace: true);
    query
      ..orderBy([OrderingTerm.desc(transactions.date)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map(_rowToTxn).toList();
  }

  Future<List<TransactionWithCategory>> getAllRecurringOnce() async {
    final query = _txnBaseQuery()
      ..where(transactions.recurrence.isNotIn(['none', '']));
    final rows = await query.get();
    return rows.map(_rowToTxn).toList();
  }

  Stream<List<TransactionWithCategory>> watchRecurringTransactions({
    int? spaceId,
  }) {
    final query = _txnBaseQuery(spaceId: spaceId, filterBySpace: true);
    query
      ..where(transactions.recurrence.isNotIn(['none', '']))
      ..orderBy([OrderingTerm.desc(transactions.date)]);
    return query.watch().map((rows) => rows.map(_rowToTxn).toList());
  }

  Stream<double> watchTotalSpent({
    required DateTime from,
    required DateTime to,
    int? spaceId,
  }) {
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ]);
    query.where(
      transactions.type.equals(TransactionType.expense.index) &
          transactions.date.isBetweenValues(from, to),
    );
    if (spaceId != null) {
      query.where(accounts.spaceId.equals(spaceId));
    } else {
      query.where(accounts.spaceId.isNull());
    }
    return query.watch().map(
      (rows) => rows.fold<double>(
        0,
        (sum, r) => sum + r.readTable(transactions).amount,
      ),
    );
  }

  Stream<double> watchTotalIncome({
    required DateTime from,
    required DateTime to,
    int? spaceId,
  }) {
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ]);
    query.where(
      transactions.type.equals(TransactionType.income.index) &
          transactions.date.isBetweenValues(from, to),
    );
    if (spaceId != null) {
      query.where(accounts.spaceId.equals(spaceId));
    } else {
      query.where(accounts.spaceId.isNull());
    }
    return query.watch().map(
      (rows) => rows.fold<double>(
        0,
        (sum, r) => sum + r.readTable(transactions).amount,
      ),
    );
  }

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> updateTransaction(TransactionEntry entry) =>
      update(transactions).replace(entry);

  Future<int> setTransactionNote(int id, String note) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(note: Value(note)),
      );

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Stream<List<TransactionWithCategory>> watchTransactionsByDateRange({
    required DateTime from,
    required DateTime to,
    int? spaceId,
  }) {
    final query = _txnBaseQuery(spaceId: spaceId, filterBySpace: true);
    query
      ..where(transactions.date.isBetweenValues(from, to))
      ..orderBy([OrderingTerm.desc(transactions.date)]);
    return query.watch().map((rows) => rows.map(_rowToTxn).toList());
  }

  Future<bool> hasAccounts({int? spaceId}) async {
    final query = select(accounts);
    if (spaceId != null) {
      query.where((a) => a.spaceId.equals(spaceId));
    } else {
      query.where((a) => a.spaceId.isNull());
    }
    final results = await query.get();
    return results.isNotEmpty;
  }

  TransactionWithCategory _rowToTxn(TypedResult row) {
    return TransactionWithCategory(
      transaction: row.readTable(transactions),
      category: row.readTableOrNull(categories),
      account: row.readTableOrNull(accounts),
      toAccount: row.readTableOrNull(_toAccounts),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'genga.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
