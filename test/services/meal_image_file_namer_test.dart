import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/meal_image_file_namer.dart';

void main() {
  group('MealImageFileNamer Unit Tests', () {
    test('getMealTypeCode converts standard types and synonyms', () {
      expect(MealImageFileNamer.getMealTypeCode('Desayuno'), equals('B'));
      expect(MealImageFileNamer.getMealTypeCode('Breakfast'), equals('B'));
      expect(MealImageFileNamer.getMealTypeCode('Almuerzo'), equals('L'));
      expect(MealImageFileNamer.getMealTypeCode('Lunch'), equals('L'));
      expect(MealImageFileNamer.getMealTypeCode('Cena'), equals('D'));
      expect(MealImageFileNamer.getMealTypeCode('Dinner'), equals('D'));
      expect(MealImageFileNamer.getMealTypeCode('Snack'), equals('S'));
      expect(MealImageFileNamer.getMealTypeCode('Merienda'), equals('S'));
      expect(MealImageFileNamer.getMealTypeCode('Desconocido'), equals('O'));
      expect(MealImageFileNamer.getMealTypeCode(null), equals('O'));
    });

    test('getMealTypeFromCode maps codes to Spanish meal names', () {
      expect(MealImageFileNamer.getMealTypeFromCode('B'), equals('Desayuno'));
      expect(MealImageFileNamer.getMealTypeFromCode('L'), equals('Almuerzo'));
      expect(MealImageFileNamer.getMealTypeFromCode('D'), equals('Cena'));
      expect(MealImageFileNamer.getMealTypeFromCode('S'), equals('Snack'));
      expect(MealImageFileNamer.getMealTypeFromCode('O'), equals('Otro'));
    });

    test('parseMealImageFileName correctly decodes standard filename pattern', () {
      const fileName = '2026_09_13_B_01.jpg';
      final info = MealImageFileNamer.parseMealImageFileName(fileName);

      expect(info, isNotNull);
      expect(info!.year, equals('2026'));
      expect(info.month, equals('09'));
      expect(info.day, equals('13'));
      expect(info.typeCode, equals('B'));
      expect(info.mealType, equals('Desayuno'));
      expect(info.index, equals(1));
    });

    test('parseMealImageFileName returns null for non-compliant names', () {
      expect(MealImageFileNamer.parseMealImageFileName('random_photo.jpg'), isNull);
      expect(MealImageFileNamer.parseMealImageFileName('2026-09-13-B-01.png'), isNull);
      expect(MealImageFileNamer.parseMealImageFileName('2026_13_40_B_01.jpg'), isNull);
    });

    test('generateMealImageFileName creates properly formatted string', () async {
      final name = await MealImageFileNamer.generateMealImageFileName(
        date: DateTime(2026, 9, 13),
        mealType: 'Lunch',
        explicitIndex: 2,
      );

      expect(name, equals('2026_09_13_L_02.jpg'));
    });

    test('filterMealImages matches requested criteria', () {
      final paths = [
        'C:/photos/2026_09_13_B_01.jpg',
        'C:/photos/2026_09_13_L_01.jpg',
        'C:/photos/2026_09_14_D_01.jpg',
      ];

      final dayFiltered = MealImageFileNamer.filterMealImages(
        paths,
        date: DateTime(2026, 9, 13),
      );
      expect(dayFiltered.length, equals(2));

      final typeFiltered = MealImageFileNamer.filterMealImages(
        paths,
        mealType: 'Breakfast',
      );
      expect(typeFiltered.length, equals(1));
      expect(typeFiltered.first.mealType, equals('Desayuno'));
    });
  });
}
