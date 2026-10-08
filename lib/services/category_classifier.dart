import '../models/expense.dart';

/// Suggests a category from OCR text; the user can always change it on review.
class CategoryClassifier {
  const CategoryClassifier();

  ExpenseCategory classify(String text) {
    final value = text.toLowerCase();
    if (_contains(value, [
      'học phí',
      'sách',
      'văn phòng phẩm',
      'bút',
      'photocopy',
      'tuition',
      'bookstore',
      'stationery',
    ])) {
      return ExpenseCategory.study;
    }
    if (_contains(value, [
      'rạp phim',
      'cinema',
      'movie',
      'karaoke',
      'game',
      'vé xem phim',
      'giải trí',
    ])) {
      return ExpenseCategory.entertainment;
    }
    if (_contains(value, [
      'grab',
      'be bike',
      'taxi',
      'xăng',
      'petrol',
      'vé xe',
      'bến xe',
      'parking',
      'gửi xe',
    ])) {
      return ExpenseCategory.travel;
    }
    if (_contains(value, [
      'điện thoại',
      'laptop',
      'máy tính',
      'tai nghe',
      'phụ kiện',
      'electronics',
      'gear',
      'thiết bị',
    ])) {
      return ExpenseCategory.gear;
    }
    return ExpenseCategory.food;
  }

  bool _contains(String text, List<String> words) =>
      words.any((word) => text.contains(word));
}
