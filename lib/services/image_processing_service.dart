import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  static final ImageProcessingService instance = ImageProcessingService._();
  ImageProcessingService._();

  static const int maxDimension = 1024;
  static const int jpegQuality = 85;

  Uint8List compressAndResize(
    Uint8List rawBytes, {
    int targetMaxDimension = maxDimension,
    int quality = jpegQuality,
  }) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      return rawBytes;
    }

    img.Image processed = decoded;
    if (decoded.width > targetMaxDimension || decoded.height > targetMaxDimension) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(
          decoded,
          width: targetMaxDimension,
          interpolation: img.Interpolation.linear,
        );
      } else {
        processed = img.copyResize(
          decoded,
          height: targetMaxDimension,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    final compressed = img.encodeJpg(processed, quality: quality);
    return Uint8List.fromList(compressed);
  }

  Future<String> saveMealImage(Uint8List imageBytes, String mealId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mealsDir = Directory(p.join(appDir.path, 'meals'));
    if (!await mealsDir.exists()) {
      await mealsDir.create(recursive: true);
    }

    final filePath = p.join(mealsDir.path, 'meal_${mealId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final file = File(filePath);
    await file.writeAsBytes(imageBytes, flush: true);
    return filePath;
  }

  Future<void> deleteMealImage(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
