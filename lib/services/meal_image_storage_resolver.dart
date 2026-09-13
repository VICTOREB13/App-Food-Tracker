import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'meal_image_file_namer.dart';

/// Resolves directories and executes atomic filesystem operations for meal photos.
class MealImageStorageResolver {
  static const String androidPublicPicturesPath = '/storage/emulated/0/Pictures/FoodTracker/images';

  static Future<List<Directory>> getCandidateDirectories({Directory? customDirectory}) async {
    final candidateDirs = <Directory>[];
    if (customDirectory != null) candidateDirs.add(customDirectory);

    if (Platform.isAndroid) {
      candidateDirs.add(Directory(androidPublicPicturesPath));
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          candidateDirs.add(Directory(p.join(extDir.path, 'Pictures', 'FoodTracker', 'images')));
        }
      } catch (_) {}
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.pictures);
        if (extDirs != null && extDirs.isNotEmpty) {
          candidateDirs.add(Directory(p.join(extDirs.first.path, 'FoodTracker', 'images')));
        }
      } catch (_) {}
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      candidateDirs.add(Directory(p.join(appDir.path, 'Pictures', 'FoodTracker', 'images')));
    } catch (_) {}

    candidateDirs.add(
      Directory(p.join(Directory.systemTemp.path, 'Pictures', 'FoodTracker', 'images')),
    );

    return candidateDirs;
  }

  static Future<String> writeImageWithAntiCollision({
    required List<int> imageBytes,
    required DateTime date,
    required String typeCode,
    int? explicitIndex,
    Directory? customDirectory,
  }) async {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    final candidateDirs = await getCandidateDirectories(customDirectory: customDirectory);
    Object? lastError;

    for (final dir in candidateDirs) {
      try {
        if (!await dir.exists()) await dir.create(recursive: true);

        int targetIndex = explicitIndex != null && explicitIndex > 0
            ? explicitIndex
            : await MealImageFileNamer.getNextMealImageIndex(
                directory: dir,
                year: year,
                month: month,
                day: day,
                typeCode: typeCode,
              );

        String fileName =
            '${year}_${month}_${day}_${typeCode}_${targetIndex.toString().padLeft(2, '0')}.jpg';
        String filePath = p.join(dir.path, fileName);

        while (await File(filePath).exists() ||
            await File(p.join(dir.path, '${year}_${month}_${day}_${typeCode}_${targetIndex.toString().padLeft(2, '0')}.jpeg')).exists()) {
          targetIndex++;
          fileName =
              '${year}_${month}_${day}_${typeCode}_${targetIndex.toString().padLeft(2, '0')}.jpg';
          filePath = p.join(dir.path, fileName);
        }

        await File(filePath).writeAsBytes(imageBytes, flush: true);
        return filePath;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('No se pudo guardar la imagen: $lastError');
  }

  static Future<String> renameImageFile({
    required String currentPath,
    required String newMealType,
    DateTime? date,
  }) async {
    try {
      final cleanPath = MealImageFileNamer.normalizeFilePath(currentPath);
      final file = File(cleanPath);
      if (!await file.exists()) return currentPath;

      final info = MealImageFileNamer.parseMealImageFileName(cleanPath);
      final effectiveDate = date ?? info?.date ?? DateTime.now();
      final year = effectiveDate.year.toString().padLeft(4, '0');
      final month = effectiveDate.month.toString().padLeft(2, '0');
      final day = effectiveDate.day.toString().padLeft(2, '0');
      final targetCode = MealImageFileNamer.getMealTypeCode(newMealType);

      if (info != null &&
          info.year == year &&
          info.month == month &&
          info.day == day &&
          info.typeCode == targetCode) {
        return currentPath;
      }

      final dir = file.parent;
      int targetIndex = await MealImageFileNamer.getNextMealImageIndex(
        directory: dir,
        year: year,
        month: month,
        day: day,
        typeCode: targetCode,
      );

      String candidateName =
          '${year}_${month}_${day}_${targetCode}_${targetIndex.toString().padLeft(2, '0')}.jpg';
      String newPath = p.join(dir.path, candidateName);

      while (await File(newPath).exists() ||
          await File(p.join(dir.path, '${year}_${month}_${day}_${targetCode}_${targetIndex.toString().padLeft(2, '0')}.jpeg')).exists()) {
        targetIndex++;
        candidateName =
            '${year}_${month}_${day}_${targetCode}_${targetIndex.toString().padLeft(2, '0')}.jpg';
        newPath = p.join(dir.path, candidateName);
      }

      try {
        final renamedFile = await file.rename(newPath);
        return renamedFile.path;
      } catch (_) {
        try {
          await file.copy(newPath);
          await file.delete();
          return newPath;
        } catch (_) {
          return currentPath;
        }
      }
    } catch (_) {
      return currentPath;
    }
  }
}
