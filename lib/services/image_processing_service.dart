import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

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
    Directory? targetDir;

    // On Android or platforms supporting external pictures storage
    try {
      if (Platform.isAndroid) {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.pictures);
        if (extDirs != null && extDirs.isNotEmpty) {
          targetDir = Directory(p.join(extDirs.first.path, 'FoodTrackerMeals'));
        }
      }
    } catch (_) {}

    // Fallback cleanly to getApplicationDocumentsDirectory()/Pictures/FoodTrackerMeals
    if (targetDir == null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        targetDir = Directory(p.join(appDir.path, 'Pictures', 'FoodTrackerMeals'));
      } catch (_) {
        targetDir = Directory(p.join(Directory.systemTemp.path, 'FoodTrackerMeals'));
      }
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final filePath = p.join(
      targetDir.path,
      'meal_${mealId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final file = File(filePath);
    await file.writeAsBytes(imageBytes, flush: true);
    return filePath;
  }

  /// Prunes photos older than retentionDays while preserving nutritional meal data in SQLite
  Future<int> pruneOldMealPhotos({required int retentionDays}) async {
    if (retentionDays <= 0) {
      return 0;
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    final meals = await DatabaseService.instance.getMealsOlderThanWithImages(cutoffDate);

    int deletedCount = 0;
    for (final meal in meals) {
      final path = meal.imagePath;
      if (path != null && path.trim().isNotEmpty) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            deletedCount++;
          }
        } catch (_) {}
      }
      await DatabaseService.instance.clearMealImagePath(meal.id);
    }

    return deletedCount;
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
