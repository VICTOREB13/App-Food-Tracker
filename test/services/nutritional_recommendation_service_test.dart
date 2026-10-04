import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/models/daily_goals.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/services/nutritional_recommendation_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await DatabaseSchema.createAllTables(db);
        },
      ),
    );

    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('NutritionalRecommendationService Unit Tests', () {
    test('analyzeHistory detects fat excess and protein deficit with targeted diagnosis', () async {
      final dbService = DatabaseService.instance;
      final now = DateTime.now();

      // Configure user daily goals: 2000 kcal, 140g protein, 200g carbs, 60g fat
      await dbService.saveUserProfile(
        UserProfile(
          name: 'Victor Test',
          age: 28,
          gender: 'male',
          height: 178,
          weight: 78,
          targetCalories: 2000,
          targetProtein: 140,
          targetCarbs: 200,
          targetFat: 60,
        ),
      );

      // Log meals with high fat (85g) and low protein (80g)
      for (int i = 0; i < 3; i++) {
        final date = now.subtract(Duration(days: i));
        await dbService.insertMeal(
          Meal(
            id: 'm_$i',
            name: 'Comida Grasa $i',
            mealType: 'Almuerzo',
            date: date,
            calories: 2200,
            protein: 80, // deficit vs 140g
            carbs: 200,
            fat: 85, // excess vs 60g
          ),
        );
      }

      final service = NutritionalRecommendationService.instance;
      final report = await service.analyzeHistory(days: 7);

      expect(report.daysAnalyzed, equals(7));
      expect(report.mealsLogged, equals(3));
      expect(report.averageDailyFat, equals(85.0));
      expect(report.averageDailyProtein, equals(80.0));
      expect(report.fatDelta, equals(25.0));
      expect(report.proteinDelta, equals(-60.0));

      // Assert diagnostic text mentions excess fat and deficit protein
      expect(report.fatDiagnosis, contains('supera tu meta en +25.0g/día'));
      expect(report.proteinDiagnosis, contains('Déficit proteico de 60.0g/día'));
      expect(report.fatReductionSwaps.isNotEmpty, isTrue);
      expect(report.proteinIncreaseSuggestions.isNotEmpty, isTrue);
      expect(report.suggestedPlates.isNotEmpty, isTrue);
    });

    test('analyzeHistory handles 15 and 30 days periods cleanly', () async {
      final service = NutritionalRecommendationService.instance;
      final rep15 = await service.analyzeHistory(days: 15);
      expect(rep15.daysAnalyzed, equals(15));

      final rep30 = await service.analyzeHistory(days: 30);
      expect(rep30.daysAnalyzed, equals(30));
    });

    test('analyzeHistory handles empty database with graceful default diagnosis', () async {
      final service = NutritionalRecommendationService.instance;
      final report = await service.analyzeHistory(days: 7);

      expect(report.mealsLogged, equals(0));
      expect(report.averageDailyCalories, equals(0.0));
      expect(report.fatReductionSwaps.isNotEmpty, isTrue);
      expect(report.proteinIncreaseSuggestions.isNotEmpty, isTrue);
    });

    test('getWhatShouldIEatToday calculates remaining macros and suggests matching dishes', () async {
      final dbService = DatabaseService.instance;
      final now = DateTime.now();

      await dbService.saveUserProfile(
        UserProfile(
          name: 'Victor',
          age: 28,
          gender: 'male',
          height: 178,
          weight: 78,
          targetCalories: 2000,
          targetProtein: 150,
          targetCarbs: 220,
          targetFat: 60,
        ),
      );

      // Log breakfast today: 400 kcal, 20g protein, 50g carbs, 10g fat
      await dbService.insertMeal(
        Meal(
          id: 'breakfast_1',
          name: 'Desayuno Ligero',
          mealType: 'Desayuno',
          date: now,
          calories: 400,
          protein: 20,
          carbs: 50,
          fat: 10,
        ),
      );

      final service = NutritionalRecommendationService.instance;
      final plan = await service.getWhatShouldIEatToday(date: now);

      expect(plan.remainingCalories, equals(1600.0));
      expect(plan.remainingProtein, equals(130.0));
      expect(plan.remainingCarbs, equals(170.0));
      expect(plan.remainingFat, equals(50.0));
      expect(plan.recommendedOptions.isNotEmpty, isTrue);

      final firstDish = plan.recommendedOptions.first;
      expect(firstDish.name, isNotEmpty);
      expect(firstDish.calories, greaterThan(0));
      expect(firstDish.fitScore, inInclusiveRange(80, 100));
      expect(firstDish.ingredients.isNotEmpty, isTrue);
      expect(firstDish.whyRecommended.isNotEmpty, isTrue);
    });
  });
}
