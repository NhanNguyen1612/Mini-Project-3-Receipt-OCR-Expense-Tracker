import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

void main() {
  final parser = ReceiptParser();

  test('extracts Vietnamese receipt fields and prioritizes total', () {
    final result = parser.parse('''
HIGHLANDS COFFEE
Địa chỉ: Đà Nẵng
Ngày: 22/10/2026
Cà phê 35.000 đ
Bánh 20.000 đ
TỔNG CỘNG 55.000 đ
''');
    expect(result.merchant, 'HIGHLANDS COFFEE');
    expect(result.amount, 55000);
    expect(result.date, DateTime(2026, 10, 22));
  });

  test('reads total on next line and ISO date', () {
    final result = parser.parse('''
VKU BOOK STORE
2026-09-30
Total
125,000 VND
''');
    expect(result.merchant, 'VKU BOOK STORE');
    expect(result.amount, 125000);
    expect(result.date, DateTime(2026, 9, 30));
  });

  test('returns null when OCR has no reliable fields', () {
    final result = parser.parse('HÓA ĐƠN\nMã số thuế: 123456789');
    expect(result.merchant, isNull);
    expect(result.amount, isNull);
    expect(result.date, isNull);
  });

  test('rejects invalid dates', () {
    final result = parser.parse('Cửa hàng A\n31/02/2026\nTổng 50.000 đ');
    expect(result.date, isNull);
  });

  test('accepts OCR text without Vietnamese accents', () {
    final result = parser.parse('HOA DON\nCUA HANG VKU\nTong tien: 150000 VNĐ');
    expect(result.merchant, 'CUA HANG VKU');
    expect(result.amount, 150000);
  });

  test('uses the last amount on a total line', () {
    final result = parser.parse('VKU STORE\nTong tien: 2 x 35.000 = 70.000');
    expect(result.amount, 70000);
  });
}
