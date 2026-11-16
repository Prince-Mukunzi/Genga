import 'package:drift/drift.dart';
import 'package:genga/core/models/enums.dart';

class Spaces extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get color => integer()();
  TextColumn get iconKey => text()();
  TextColumn get type => text().withDefault(const Constant('personal'))();
  TextColumn get inviteCode => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SpaceMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get spaceId => integer().references(Spaces, #id)();
  TextColumn get displayName => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get role => text().withDefault(const Constant('member'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isCurrentUser =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();
}

class SpaceNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get spaceId => integer().references(Spaces, #id)();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get payload => text().withDefault(const Constant(''))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get iconKey => text()();
  IntColumn get color => integer()();
  TextColumn get groupName => text().withDefault(const Constant('Other'))();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  RealColumn get budgetLimit => real().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get iconKey => text()();
  IntColumn get color => integer()();
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('RWF'))();
  TextColumn get accountType => text().withDefault(const Constant('cash'))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  RealColumn get initialBalance => real().withDefault(const Constant(0))();
  IntColumn get spaceId => integer().nullable().references(Spaces, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TransactionEntry')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get type => intEnum<TransactionType>()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get recurrence => text().withDefault(const Constant('none'))();
  TextColumn get recipientName => text().withDefault(const Constant(''))();
  TextColumn get recipientPhone => text().withDefault(const Constant(''))();
  RealColumn get momoFee => real().withDefault(const Constant(0))();
  TextColumn get createdBy => text().withDefault(const Constant(''))();
  TextColumn get updatedBy => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
