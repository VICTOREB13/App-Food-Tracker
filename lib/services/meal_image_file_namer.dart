import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/meal_image_file_info.dart';

export '../models/meal_image_file_info.dart';

/// Helper handling file nomenclature, parsing, and directory querying for meal images.
class MealImageFileNamer {
  static final RegExp mealImageFileNamePattern = RegExp(
    r'^(\d{4})_(\d{2})_(\d{2})_([BLDSO])_(\d+)\.jpe?g$',
    caseSensitive: false,
  );

  static String getMealTypeCode(String? mealType) {
    if (mealType == null) return 'O';
    final n = mealType.trim().toLowerCase();
    if (n.isEmpty) return 'O';

    const direct = {'b': 'B', 'l': 'L', 'd': 'D', 's': 'S', 'o': 'O'};
    if (direct.containsKey(n)) return direct[n]!;

    if (n.contains('desayun') || n.contains('breakfast')) return 'B';
    if (n.contains('almuerz') || n.contains('lunch') || n.contains('lonche') || n == 'comida') {
      return 'L';
    }
    if (n.contains('cena') || n.contains('dinner') || n.contains('supper')) return 'D';
    const snackKeys = [
      'snack', 'snarck', 'merienda', 'colacion', 'colación', 'tentempie',
      'tentempié', 'botana', 'piqueo', 'onces', 'aperitivo',
    ];
    if (snackKeys.any((k) => n.contains(k))) return 'S';

    return 'O';
  }

  static String getMealTypeFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'B': return 'Desayuno';
      case 'L': return 'Almuerzo';
      case 'D': return 'Cena';
      case 'S': return 'Snack';
      case 'O':
      default: return 'Otro';
    }
  }

  static String inferMealTypeByTime([DateTime? time]) {
    final effectiveTime = time ?? DateTime.now();
    final hour = effectiveTime.hour;
    if (hour >= 5 && hour < 12) return 'Desayuno';
    if (hour >= 12 && hour < 17) return 'Almuerzo';
    if (hour >= 17 && hour < 20) return 'Snack';
    return 'Cena';
  }

  static String normalizeFilePath(String pathOrUri) {
    String normalized = pathOrUri.trim();
    if (normalized.startsWith('file:')) {
      try {
        final uri = Uri.tryParse(normalized);
        if (uri != null) normalized = uri.toFilePath();
      } catch (_) {}
    }
    return normalized;
  }

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

    if (year == null || month == null || day == null || index == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31 || index < 1) return null;

    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) return null;
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

  static bool isMealImageFileName(String pathOrFileName) =>
      parseMealImageFileName(pathOrFileName) != null;

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
              if (parsed != null && parsed > maxIndex) maxIndex = parsed;
            }
          }
        }
      }
    } catch (_) {}

    return maxIndex + 1;
  }

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
      return '${year}_${month}_${day}_${typeCode}_${explicitIndex.toString().padLeft(2, '0')}.jpg';
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

    return '${year}_${month}_${day}_${typeCode}_${nextIndex.toString().padLeft(2, '0')}.jpg';
  }

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

  static Future<List<MealImageFileInfo>> listMealImages({
    required Directory directory,
    DateTime? date,
    int? year,
    int? month,
    int? day,
    String? mealType,
  }) async {
    if (!await directory.exists()) return [];

    final filePaths = <String>[];
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File) filePaths.add(entity.path);
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
}
