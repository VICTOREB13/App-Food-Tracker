import 'package:flutter/foundation.dart';

/// Metadata extracted from a standardized meal image file name.
@immutable
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
