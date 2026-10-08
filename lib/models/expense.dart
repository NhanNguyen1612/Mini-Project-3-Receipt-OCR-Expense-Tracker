enum ExpenseCategory { food, study, travel, gear, entertainment }

extension ExpenseCategoryLabel on ExpenseCategory {
  String get label => switch (this) {
        ExpenseCategory.food => 'Ăn uống',
        ExpenseCategory.study => 'Học tập',
        ExpenseCategory.travel => 'Di chuyển',
        ExpenseCategory.gear => 'Đồ dùng',
        ExpenseCategory.entertainment => 'Giải trí',
      };
}

class Expense {
  const Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.photoPath,
    this.rawText,
  });

  final int? id;
  final String merchant;
  final int amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? photoPath;
  final String? rawText;

  Expense copyWith({
    int? id,
    String? merchant,
    int? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? photoPath,
    String? rawText,
  }) =>
      Expense(
        id: id ?? this.id,
        merchant: merchant ?? this.merchant,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        category: category ?? this.category,
        photoPath: photoPath ?? this.photoPath,
        rawText: rawText ?? this.rawText,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'merchant': merchant,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category.name,
        'photo_path': photoPath,
        'raw_text': rawText,
      };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int,
        merchant: map['merchant'] as String,
        amount: map['amount'] as int,
        date: DateTime.parse(map['date'] as String),
        category: switch (map['category']) {
          'transport' => ExpenseCategory.travel,
          'shopping' => ExpenseCategory.gear,
          final String name => ExpenseCategory.values.firstWhere(
              (value) => value.name == name,
              orElse: () => ExpenseCategory.food,
            ),
          _ => ExpenseCategory.food,
        },
        photoPath: map['photo_path'] as String?,
        rawText: map['raw_text'] as String?,
      );
}
