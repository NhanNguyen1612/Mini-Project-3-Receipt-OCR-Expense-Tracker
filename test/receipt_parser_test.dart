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

  // ── Regression: Bách Hóa Xanh receipt with deferred e-bill notice ───────
  test('ignores masked card number (***4381) at bottom of receipt', () {
    // Simulates OCR output from the real Bách Hóa Xanh receipt where the
    // line "Hóa đơn tiện điện cho GPP ******4381 sau 24h" was wrongly chosen.
    final result = parser.parse('''
PHIEU THANH TOAN BACH HOA XANE
14/08/2026
SL  Gia ban(VAT)  Thanh tien
khan giay an softly goi 100 to
1   10.000 (VAT:8%)  10.000
mirinda cream soda 330ml
1   10.200 (VAT:10%)  10.200
nuoc ngot lon mirinda cam sleek
1   10.200 (VAT:10%)  10.200
nuoc xa vai comfort ban mai 20ml
2   18.500 (VAT:8%)  37.000
chuoi gia giong nam my
1.548  15.900 (VAT:5%)  24.613
Tong tien
92.013
Giam ao dung  13
92.000
Hoa don tien dien cho GPP ******4381 sau 24h
''');
    // Must pick 92013 (or 92000), NOT 4381
    expect(result.amount, greaterThan(10000));
    expect(result.amount, isNot(4381));
  });

  test('prefers largest unlabeled value when no total label is matched', () {
    // All lines are unlabeled; the largest number is the grand total.
    final result = parser.parse('''
SHOP ABC
Item A  10.000
Item B  25.000
Item C  15.000
92.000
Phone: 0901234567
''');
    expect(result.amount, 92000);
  });

  test('does not pick a discount line over the real total', () {
    final result = parser.parse('''
VKU CANTEEN
Mon an  45.000
Nuoc uong  12.000
Tong cong: 57.000
Giam: 7.000
Thanh toan: 50.000
''');
    // "Thanh toan" labeled line should win
    expect(result.amount, 50000);
  });

  test('parses full Bach Hoa Xanh receipt accurately', () {
    final result = parser.parse('''
PHIÊU THANH TOÁN BÁCH HÓA XANH
Số ct: OV134720609029082
16/09/2026 11:52 - YY:292407
SL Giá bán (VAT) Thành tiền
khăn giấy ăn softly gói 100 tờ - 1 lốc
(240 x 240mm)
1 10.000 (VAT:8%) 10.000
mirinda cream soda 330ml/320ml sleek lon
1 10.200 (VAT:10%) 10.200
nước ngọt lon mirinda cam sleek 330ml/320ml
1 10.200 (VAT:10%) 10.200
nước xả vải comfort ban mai 20ml dây 10 gói
2 21.000 18.500 (VAT:8%) 37.000
chuối già giống nam mỹ
1,548 15.900 (VAT:5%) 24.613
Tổng tiền: 92.013
Điểm sử dụng: 13
Chuyển khoản (Tiết kiệm: 5.013đ) 92.000
Khách mua tại siêu thị và thanh toán tiền mặt, số tiền là dưới
3000.000đ/lần tròn xuống: 323đ; 200đ lần tròn 14m
Quý khách in hóa đơn VAT tại báchhoaxanh.com hoặc qua zalo OA
HĐ VAT chỉ xuất trong ngày, góp ý: 19001908 (miễn phí)
Cảm ơn quý khách đã đồng ý chính sách đổi trả tại: www.bachhoaxanh.com
CẢM ƠN QUÝ KHÁCH ĐÃ CHỌN BÁCH HÓA XANH
MUA SẮM TIẾT KIỆM MỖI NGÀY!
Hóa đơn tích điểm cho GPP ******4381 sau 24h.
''');
    expect(result.merchant, 'BÁCH HÓA XANH');
    expect(result.amount, 92013);
    expect(result.date, DateTime(2026, 9, 16));
  });
}
