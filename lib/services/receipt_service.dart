import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'receipt_parser.dart';
import '../core/receipt_photo_paths.dart';

class ReceiptScan {
  const ReceiptScan({required this.image, required this.parsed});
  final XFile image;
  final ParsedReceipt parsed;
}

class ReceiptService {
  final _picker = ImagePicker();
  final _parser = ReceiptParser();

  Future<ReceiptScan?> scan(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (image == null) return null;
    return recognize(image);
  }

  Future<ReceiptScan> recognize(XFile image) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(image.path));
      return ReceiptScan(image: image, parsed: _parser.parse(result.text));
    } finally {
      await recognizer.close();
    }
  }

  Future<String> retainPhoto(XFile image) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'receipts'));
    await directory.create(recursive: true);
    final extension = p.extension(image.path).toLowerCase();
    final safeExtension = ['.jpg', '.jpeg', '.png', '.heic'].contains(extension)
        ? extension
        : '.jpg';
    final target = p.join(
      directory.path,
      'receipt_${DateTime.now().microsecondsSinceEpoch}$safeExtension',
    );
    await File(image.path).copy(target);
    try {
      await compute(_writeThumbnail, (target, receiptThumbnailPath(target)));
    } catch (_) {
      // The original remains available if this image format cannot be decoded.
    }
    return target;
  }

  Future<void> deletePhoto(String? path) async {
    if (path == null) return;
    for (final target in [path, receiptThumbnailPath(path)]) {
      final file = File(target);
      if (await file.exists()) await file.delete();
    }
  }
}

void _writeThumbnail((String, String) paths) {
  final image = img.decodeImage(File(paths.$1).readAsBytesSync());
  if (image == null) return;
  final oriented = img.bakeOrientation(image);
  final thumbnail = img.copyResize(oriented, width: 240);
  File(paths.$2).writeAsBytesSync(img.encodeJpg(thumbnail, quality: 75));
}
