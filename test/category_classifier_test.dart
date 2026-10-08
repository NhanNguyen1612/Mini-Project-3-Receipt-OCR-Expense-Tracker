import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/services/category_classifier.dart';

void main() {
  const classifier = CategoryClassifier();
  test('suggests categories from receipt text', () {
    expect(classifier.classify('Nhà sách ABC - Sách giáo trình'),
        ExpenseCategory.study);
    expect(classifier.classify('GRAB TAXI'), ExpenseCategory.travel);
    expect(classifier.classify('Tai nghe và phụ kiện'), ExpenseCategory.gear);
    expect(classifier.classify('Vé xem phim CINEMA'),
        ExpenseCategory.entertainment);
    expect(classifier.classify('Siêu thị Coopmart'), ExpenseCategory.food);
  });
}
