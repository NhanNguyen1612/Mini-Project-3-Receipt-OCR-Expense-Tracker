import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Normalized frame shown in the camera preview and applied to the saved photo.
class ReceiptFrame {
  static const left = 0.08;
  static const top = 0.12;
  static const width = 0.84;
  static const height = 0.76;
}

class ReceiptCropper {
  static img.Image cropPixels(img.Image source) {
    final oriented = img.bakeOrientation(source);
    final x = (oriented.width * ReceiptFrame.left).round();
    final y = (oriented.height * ReceiptFrame.top).round();
    final width = (oriented.width * ReceiptFrame.width).round();
    final height = (oriented.height * ReceiptFrame.height).round();
    return img.copyCrop(
      oriented,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  Future<XFile> crop(XFile source) async {
    final directory = await getTemporaryDirectory();
    final target = p.join(
      directory.path,
      'receipt_crop_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await compute(_cropFile, (source.path, target));
    return XFile(target);
  }
}

void _cropFile((String, String) paths) {
  final source = img.decodeImage(File(paths.$1).readAsBytesSync());
  if (source == null) throw const FormatException('Ảnh chụp không đọc được');
  final cropped = ReceiptCropper.cropPixels(source);
  File(paths.$2).writeAsBytesSync(img.encodeJpg(cropped, quality: 90));
}
