import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

/// Metadata extracted from a standardized meal image file name.
class MealImageFileInfo {
  final DateTime date;
  final String year;
  final String month;
  final String day;
  final String typeCode;
  final String mealType;
  final int index;
  final String fileName;
  final String? filePath;

  const MealImageFileInfo({
    required this.date,
    required this.year,
    required this.month,
    required this.day,
    required this.typeCode,
    required this.mealType,
    required this.index,
    required this.fileName,
    this.filePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealImageFileInfo &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          year == other.year &&
          month == other.month &&
          day == other.day &&
          typeCode == other.typeCode &&
          mealType == other.mealType &&
          index == other.index &&
          fileName == other.fileName &&
          filePath == other.filePath;

  @override
  int get hashCode => Object.hash(
        date,
        year,
        month,
        day,
        typeCode,
        mealType,
        index,
        fileName,
        filePath,
      );

  @override
  String toString() =>
      'MealImageFileInfo(date: ${year}_${month}_$day, type: $typeCode ($mealType), index: $index, file: $fileName, path: $filePath)';
}

class ImageProcessingService {
  static final ImageProcessingService instance = ImageProcessingService._();
  ImageProcessingService._();

  static const int maxDimension = 1024;
  static const int jpegQuality = 85;

  /// Public path on Android where meal photos are prioritized and visible to the user.
  static const String androidPublicPicturesPath = '/storage/emulated/0/Pictures/FoodTracker/images';

  /// Standardized RegExp pattern matching `YYYY_MM_DD_{TYPE}_{INDEX}.jpg`
  /// Group 1: Year (4 digits)
  /// Group 2: Month (2 digits)
  /// Group 3: Day (2 digits)
  /// Group 4: Meal Type Code (B, L, D, S, O)
  /// Group 5: Index (1+ digits)
  static final RegExp mealImageFileNamePattern = RegExp(
    r'^(\d{4})_(\d{2})_(\d{2})_([BLDSO])_(\d+)\.jpe?g$',
    caseSensitive: false,
  );

  /// Maps any meal type string (Spanish or English) to standard single-letter code:
  /// - Breakfast / Desayuno -> `B`
  /// - Lunch / Almuerzo -> `L`
  /// - Dinner / Cena -> `D`
  /// - Snack / Merienda -> `S`
  /// - Fallback / Other -> `O`
  static String getMealTypeCode(String? mealType) {
    if (mealType == null) return 'O';
    final normalized = mealType.trim().toLowerCase();
    if (normalized.isEmpty) return 'O';

    if (normalized == 'b' ||
        normalized == 'l' ||
        normalized == 'd' ||
        normalized == 's' ||
        normalized == 'o') {
      return normalized.toUpperCase();
    }

    if (normalized.contains('desayun') || normalized.contains('breakfast')) {
      return 'B';
    }

    if (normalized.contains('almuerz') ||
        normalized.contains('lunch') ||
        normalized.contains('lonche') ||
        normalized == 'comida') {
      return 'L';
    }

    if (normalized.contains('cena') ||
        normalized.contains('dinner') ||
        normalized.contains('supper')) {
      return 'D';
    }

    if (normalized.contains('snack') ||
        normalized.contains('snarck') ||
        normalized.contains('merienda') ||
        normalized.contains('colacion') ||
        normalized.contains('colación') ||
        normalized.contains('tentempie') ||
        normalized.contains('tentempié') ||
        normalized.contains('botana') ||
        normalized.contains('piqueo') ||
        normalized.contains('onces') ||
        normalized.contains('aperitivo')) {
      return 'S';
    }

    return 'O';
  }

  /// Converts single-letter code to canonical Spanish meal type name.
  static String getMealTypeFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'B':
        return 'Desayuno';
      case 'L':
        return 'Almuerzo';
      case 'D':
        return 'Cena';
      case 'S':
        return 'Snack';
      case 'O':
      default:
        return 'Otro';
    }
  }

  /// Infers meal type based on current time of day.
  /// - 05:00 - 11:59 -> Desayuno (Breakfast)
  /// - 12:00 - 16:59 -> Almuerzo (Lunch)
  /// - 17:00 - 19:59 -> Snack (Snack / Merienda)
  /// - 20:00 - 04:59 -> Cena (Dinner)
  static String inferMealTypeByTime([DateTime? time]) {
    final effectiveTime = time ?? DateTime.now();
    final hour = effectiveTime.hour;
    if (hour >= 5 && hour < 12) {
      return 'Desayuno';
    } else if (hour >= 12 && hour < 17) {
      return 'Almuerzo';
    } else if (hour >= 17 && hour < 20) {
      return 'Snack';
    } else {
      return 'Cena';
    }
  }

  /// Normalizes a path or `file://` URI into a clean absolute filesystem path.
  static String normalizeFilePath(String pathOrUri) {
    String normalized = pathOrUri.trim();
    if (normalized.startsWith('file:')) {
      try {
        final uri = Uri.tryParse(normalized);
        if (uri != null) {
          normalized = uri.toFilePath();
        }
      } catch (_) {}
    }
    return normalized;
  }

  /// Parses a file name or path against the `YYYY_MM_DD_{TYPE}_{INDEX}.jpg` nomenclature.
  /// Returns `null` if the filename doesn't match the pattern or if the date/calendar components are invalid.
  static MealImageFileInfo? parseMealImageFileName(String pathOrFileName) {
    final cleanPath = normalizeFilePath(pathOrFileName);
    final fileName = p.basename(cleanPath).trim();
    final match = mealImageFileNamePattern.firstMatch(fileName);
    if (match == null) return null;

    final yearStr = match.group(1)!;
    final monthStr = match.group(2)!;
    final dayStr = match.group(3)!;
    final typeCode = match.group(4)!.toUpperCase();
    final indexStr = match.group(5)!;

    final year = int.tryParse(yearStr);
    final month = int.tryParse(monthStr);
    final day = int.tryParse(dayStr);
    final index = int.tryParse(indexStr);

    if (year == null || month == null || day == null || index == null) {
      return null;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31 || index < 1) {
      return null;
    }

    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return MealImageFileInfo(
        date: date,
        year: yearStr,
        month: monthStr,
        day: dayStr,
        typeCode: typeCode,
        mealType: getMealTypeFromCode(typeCode),
        index: index,
        fileName: fileName,
        filePath: cleanPath != fileName ? cleanPath : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks if a file name or path complies with the meal image nomenclature.
  static bool isMealImageFileName(String pathOrFileName) {
    return parseMealImageFileName(pathOrFileName) != null;
  }

  /// Scans a directory to find the next sequential index for a given date and meal type code.
  static Future<int> getNextMealImageIndex({
    required Directory directory,
    required String year,
    required String month,
    required String day,
    required String typeCode,
  }) async {
    final paddedYear = year.trim().padLeft(4, '0');
    final paddedMonth = month.trim().padLeft(2, '0');
    final paddedDay = day.trim().padLeft(2, '0');
    final normalizedCode = getMealTypeCode(typeCode);

    final pattern = RegExp(
      '^${paddedYear}_${paddedMonth}_${paddedDay}_${normalizedCode}_([0-9]+)\\.jpe?g\$',
      caseSensitive: false,
    );

    int maxIndex = 0;
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list(followLinks: false)) {
          if (entity is File) {
            final fileName = p.basename(entity.path);
            final match = pattern.firstMatch(fileName);
            if (match != null) {
              final parsed = int.tryParse(match.group(1) ?? '');
              if (parsed != null && parsed > maxIndex) {
                maxIndex = parsed;
              }
            }
          }
        }
      }
    } catch (_) {
      // Graceful fallback to 1 if listing directory encounters permission or IO errors
    }

    return maxIndex + 1;
  }

  /// Generates the standardized meal image filename: `YYYY_MM_DD_{TYPE}_{INDEX}.jpg`
  static Future<String> generateMealImageFileName({
    DateTime? date,
    String? mealType,
    Directory? directory,
    int? explicitIndex,
  }) async {
    final effectiveDate = date ?? DateTime.now();
    final year = effectiveDate.year.toString().padLeft(4, '0');
    final month = effectiveDate.month.toString().padLeft(2, '0');
    final day = effectiveDate.day.toString().padLeft(2, '0');
    final effectiveMealType = mealType ?? inferMealTypeByTime(effectiveDate);
    final typeCode = getMealTypeCode(effectiveMealType);

    if (explicitIndex != null && explicitIndex > 0) {
      final indexStr = explicitIndex.toString().padLeft(2, '0');
      return '${year}_${month}_${day}_${typeCode}_$indexStr.jpg';
    }

    int nextIndex = 1;
    if (directory != null && await directory.exists()) {
      nextIndex = await getNextMealImageIndex(
        directory: directory,
        year: year,
        month: month,
        day: day,
        typeCode: typeCode,
      );
    }

    final indexStr = nextIndex.toString().padLeft(2, '0');
    return '${year}_${month}_${day}_${typeCode}_$indexStr.jpg';
  }

  /// Filters a list of file paths by date components and/or meal type.
  static List<MealImageFileInfo> filterMealImages(
    List<String> filePaths, {
    DateTime? date,
    int? year,
    int? month,
    int? day,
    String? mealType,
  }) {
    final filterYear = date?.year ?? year;
    final filterMonth = date?.month ?? month;
    final filterDay = date?.day ?? day;
    final targetTypeCode = mealType != null ? getMealTypeCode(mealType) : null;
    final results = <MealImageFileInfo>[];

    for (final path in filePaths) {
      final info = parseMealImageFileName(path);
      if (info == null) continue;

      if (filterYear != null && info.date.year != filterYear) continue;
      if (filterMonth != null && info.date.month != filterMonth) continue;
      if (filterDay != null && info.date.day != filterDay) continue;
      if (targetTypeCode != null && info.typeCode != targetTypeCode) continue;

      results.add(info);
    }

    return results;
  }

  /// Scans a directory and returns all compliant meal image files filtered by criteria.
  static Future<List<MealImageFileInfo>> listMealImages({
    required Directory directory,
    DateTime? date,
    int? year,
    int? month,
    int? day,
    String? mealType,
  }) async {
    if (!await directory.exists()) {
      return [];
    }

    final filePaths = <String>[];
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File) {
          filePaths.add(entity.path);
        }
      }
    } catch (_) {}

    return filterMealImages(
      filePaths,
      date: date,
      year: year,
      month: month,
      day: day,
      mealType: mealType,
    );
  }

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

  /// Saves processed meal image bytes into an identifiable, user-friendly directory
  /// following the standardized nomenclature: `YYYY_MM_DD_{TYPE}_{INDEX}.jpg`
  ///
  /// Examples:
  /// - `2026_06_30_B_01.jpg` (First breakfast photo on June 30, 2026)
  /// - `2026_06_30_B_02.jpg` (Second breakfast photo on June 30, 2026)
  /// - `2026_06_30_L_01.jpg` (First lunch photo on June 30, 2026)
  ///
  /// On Android:
  /// 1. Prioritizes public, user-visible external storage: `/storage/emulated/0/Pictures/FoodTracker/images`
  /// 2. Falls back to app-specific external storage: `getExternalStorageDirectory()/Pictures/FoodTracker/images`
  /// 3. Falls back to external pictures directory: `getExternalStorageDirectories(type: StorageDirectory.pictures)/FoodTracker/images`
  /// 4. Falls back to application documents directory: `getApplicationDocumentsDirectory()/Pictures/FoodTracker/images`
  /// 5. Ultimate fallback: system temporary directory
  Future<String> saveMealImage(
    Uint8List imageBytes, {
    String? mealType,
    DateTime? date,
    String? mealId,
    int? index,
    Directory? customDirectory,
  }) async {
    final effectiveDate = date ?? DateTime.now();
    final year = effectiveDate.year.toString().padLeft(4, '0');
    final month = effectiveDate.month.toString().padLeft(2, '0');
    final day = effectiveDate.day.toString().padLeft(2, '0');
    final effectiveMealType =
        mealType ?? mealId ?? inferMealTypeByTime(effectiveDate);
    final typeCode = getMealTypeCode(effectiveMealType);

    final candidateDirs = <Directory>[];

    if (customDirectory != null) {
      candidateDirs.add(customDirectory);
    }

    if (Platform.isAndroid) {
      // 1. Primary: Public, user-visible Pictures folder in shared storage
      candidateDirs.add(Directory(androidPublicPicturesPath));

      // 2. Fallback: App-specific external storage (accessible without Scoped Storage restrictions)
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

    // 3. Fallback: Application documents directory (standard cross-platform)
    try {
      final appDir = await getApplicationDocumentsDirectory();
      candidateDirs.add(Directory(p.join(appDir.path, 'Pictures', 'FoodTracker', 'images')));
    } catch (_) {}

    // 4. Ultimate fallback: System temporary directory
    candidateDirs.add(Directory(p.join(Directory.systemTemp.path, 'Pictures', 'FoodTracker', 'images')));

    Object? lastError;
    for (final dir in candidateDirs) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        int targetIndex;
        if (index != null && index > 0) {
          targetIndex = index;
        } else {
          targetIndex = await getNextMealImageIndex(
            directory: dir,
            year: year,
            month: month,
            day: day,
            typeCode: typeCode,
          );
        }

        String candidateFileName =
            '${year}_${month}_${day}_${typeCode}_${targetIndex.toString().padLeft(2, '0')}.jpg';
        String filePath = p.join(dir.path, candidateFileName);

        // Anti-collision guard: if file already exists on disk (.jpg or .jpeg), advance index until unique
        while (await File(filePath).exists() ||
            await File(p.join(dir.path, '${year}_${month}_${day}_${typeCode}_${targetIndex.toString().padLeft(2, '0')}.jpeg')).exists()) {
          targetIndex++;
          candidateFileName =
              '${year}_${month}_${day}_${typeCode}_${targetIndex.toString().padLeft(2, '0')}.jpg';
          filePath = p.join(dir.path, candidateFileName);
        }

        final file = File(filePath);
        await file.writeAsBytes(imageBytes, flush: true);
        return filePath;
      } catch (e) {
        lastError = e;
        // Proceed to next fallback candidate
      }
    }

    throw StateError('No se pudo guardar la imagen de la comida en ninguna ubicación: $lastError');
  }

  /// Prunes photos older than retentionDays while preserving nutritional meal data in SQLite.
  /// Deletes photos regardless of storage path (public, external, or documents).
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
          final normalizedPath = normalizeFilePath(path);
          final file = File(normalizedPath);
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
      final normalizedPath = normalizeFilePath(filePath);
      final file = File(normalizedPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Renames an existing meal image file so that its filename dynamically reflects
  /// the updated [newMealType] and optional [date], adhering to the `YYYY_MM_DD_{TYPE}_{INDEX}.jpg` standard.
  ///
  /// For example, moving a photo from Lunch (L) to Breakfast (B) renames `2026_09_10_L_01.jpg`
  /// into `2026_09_10_B_01.jpg` (or the next available sequential index).
  Future<String> renameMealImage({
    required String currentPath,
    required String newMealType,
    DateTime? date,
  }) async {
    try {
      final cleanPath = normalizeFilePath(currentPath);
      final file = File(cleanPath);
      if (!await file.exists()) {
        return currentPath;
      }

      final info = parseMealImageFileName(cleanPath);
      final effectiveDate = date ?? info?.date ?? DateTime.now();
      final year = effectiveDate.year.toString().padLeft(4, '0');
      final month = effectiveDate.month.toString().padLeft(2, '0');
      final day = effectiveDate.day.toString().padLeft(2, '0');
      final targetTypeCode = getMealTypeCode(newMealType);

      // If the file already matches target date and meal type, no rename needed
      if (info != null &&
          info.year == year &&
          info.month == month &&
          info.day == day &&
          info.typeCode == targetTypeCode) {
        return currentPath;
      }

      final dir = file.parent;
      int targetIndex = await getNextMealImageIndex(
        directory: dir,
        year: year,
        month: month,
        day: day,
        typeCode: targetTypeCode,
      );

      String candidateFileName =
          '${year}_${month}_${day}_${targetTypeCode}_${targetIndex.toString().padLeft(2, '0')}.jpg';
      String newPath = p.join(dir.path, candidateFileName);

      while (await File(newPath).exists() ||
          await File(p.join(dir.path, '${year}_${month}_${day}_${targetTypeCode}_${targetIndex.toString().padLeft(2, '0')}.jpeg')).exists()) {
        targetIndex++;
        candidateFileName =
            '${year}_${month}_${day}_${targetTypeCode}_${targetIndex.toString().padLeft(2, '0')}.jpg';
        newPath = p.join(dir.path, candidateFileName);
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
