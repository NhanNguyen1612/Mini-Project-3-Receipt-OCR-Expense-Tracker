import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vku_expense_ocr/services/receipt_cropper.dart';

void main() {
  test('crops the same normalized frame shown in the camera preview', () {
    final original = img.Image(width: 100, height: 100);
    final cropped = ReceiptCropper.cropPixels(original);
    expect(cropped.width, 84);
    expect(cropped.height, 76);
  });
}
