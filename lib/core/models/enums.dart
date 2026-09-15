enum TransactionType {
  expense,
  income,
  transfer;

  String get label => switch (this) {
    expense => 'Expense',
    income => 'Income',
    transfer => 'Transfer',
  };
}

enum SpaceType {
  personal,
  family,
  organization;

  String get label => switch (this) {
    personal => 'Personal',
    family => 'Family',
    organization => 'Organization',
  };
}

enum SpaceRole {
  admin,
  member,
  viewer;

  String get label => switch (this) {
    admin => 'Admin',
    member => 'Member',
    viewer => 'Viewer',
  };
}
