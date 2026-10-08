import 'package:path/path.dart' as p;

String receiptThumbnailPath(String originalPath) => p.join(
      p.dirname(originalPath),
      'thumb_${p.basenameWithoutExtension(originalPath)}.jpg',
    );
