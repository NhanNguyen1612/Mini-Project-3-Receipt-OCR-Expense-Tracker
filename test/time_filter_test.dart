import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/time_filter.dart';

void main() {
  final exp1 = Expense(
    id: 1,
    merchant: 'Ăn trưa',
    amount: 50000,
    date: DateTime(2026, 10, 9, 12, 0),
    category: ExpenseCategory.food,
  );

  final exp2 = Expense(
    id: 2,
    merchant: 'Tiệm sách',
    amount: 120000,
    date: DateTime(2026, 10, 5, 8, 30),
    category: ExpenseCategory.study,
  );

  final exp3 = Expense(
    id: 3,
    merchant: 'Hóa đơn cũ',
    amount: 9150000,
    date: DateTime(2022, 6, 29),
    category: ExpenseCategory.entertainment,
  );

  final exp4 = Expense(
    id: 4,
    merchant: 'Hóa đơn tương lai',
    amount: 92013,
    date: DateTime(2036, 8, 16),
    category: ExpenseCategory.food,
  );

  final allExpenses = [exp1, exp2, exp3, exp4];

  test('Filter by Day matches only that date', () {
    final filter = TimeFilterState(
      mode: TimeFilterMode.day,
      anchorDate: DateTime(2026, 10, 9),
    );
    final results = filter.filter(allExpenses);
    expect(results.length, 1);
    expect(results.first.amount, 50000);
    expect(filter.total(allExpenses), 50000);
  });

  test('Filter by Week matches all days in that week', () {
    // 2026-10-09 is Friday; 2026-10-05 is Monday of the same week
    final filter = TimeFilterState(
      mode: TimeFilterMode.week,
      anchorDate: DateTime(2026, 10, 9),
    );
    final results = filter.filter(allExpenses);
    expect(results.length, 2);
    expect(filter.total(allExpenses), 170000);
  });

  test('Filter by Month matches month', () {
    final filter = TimeFilterState(
      mode: TimeFilterMode.month,
      anchorDate: DateTime(2026, 10, 1),
    );
    final results = filter.filter(allExpenses);
    expect(results.length, 2);
    expect(filter.total(allExpenses), 170000);
  });

  test('Filter by Month matches past year month', () {
    final filter = TimeFilterState(
      mode: TimeFilterMode.month,
      anchorDate: DateTime(2022, 6, 1),
    );
    final results = filter.filter(allExpenses);
    expect(results.length, 1);
    expect(results.first.amount, 9150000);
  });

  test('Filter by Year matches all expenses in that year', () {
    final filter = TimeFilterState(
      mode: TimeFilterMode.year,
      anchorDate: DateTime(2036, 1, 1),
    );
    final results = filter.filter(allExpenses);
    expect(results.length, 1);
    expect(results.first.amount, 92013);
  });

  test('Filter by All returns everything', () {
    final filter = TimeFilterState(
      mode: TimeFilterMode.all,
      anchorDate: DateTime(2026, 10, 9),
    );
    final results = filter.filter(allExpenses);
    expect(results.length, 4);
    expect(filter.total(allExpenses), 50000 + 120000 + 9150000 + 92013);
  });

  test('Previous and Next navigation work properly', () {
    var filter = TimeFilterState(
      mode: TimeFilterMode.month,
      anchorDate: DateTime(2026, 10, 1),
    );
    filter = filter.previous();
    expect(filter.anchorDate.month, 9);
    expect(filter.anchorDate.year, 2026);

    filter = filter.next();
    expect(filter.anchorDate.month, 10);
  });
}
