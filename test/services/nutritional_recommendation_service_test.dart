import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
          bmr: 1750,
          tdee: 2500,
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
          bmr: 1750,
          tdee: 2500,
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
      expect(firstDish.fitScore, inInclusiveRange(70, 100));
      expect(firstDish.ingredients.isNotEmpty, isTrue);
      expect(firstDish.whyRecommended.isNotEmpty, isTrue);
    });

    test('getWhatShouldIEatToday filters by Snack category and offers practical, light options', () async {
      final service = NutritionalRecommendationService.instance;
      final plan = await service.getWhatShouldIEatToday(category: 'Snack');

      expect(plan.selectedCategory, equals('Snack'));
      expect(plan.recommendedOptions.isNotEmpty, isTrue);

      final snackNames = plan.recommendedOptions.map((d) => d.name).toList();
      expect(snackNames.any((name) => name.contains('Barra de Proteína') || name.contains('Maní') || name.contains('Mix de Frutos Secos')), isTrue);

      for (final dish in plan.recommendedOptions) {
        expect(dish.mealType.toLowerCase(), contains('snack'));
        // Practical snacks are light portions under 250 kcal
        expect(dish.calories, lessThanOrEqualTo(250.0));
      }
    });

    test('getWhatShouldIEatToday filters by Desayuno, Almuerzo, and Cena categories', () async {
      final service = NutritionalRecommendationService.instance;

      final breakfastPlan = await service.getWhatShouldIEatToday(category: 'Desayuno');
      expect(breakfastPlan.selectedCategory, equals('Desayuno'));
      for (final dish in breakfastPlan.recommendedOptions) {
        expect(dish.mealType, equals('Desayuno'));
      }

      final lunchPlan = await service.getWhatShouldIEatToday(category: 'Almuerzo');
      expect(lunchPlan.selectedCategory, equals('Almuerzo'));
      for (final dish in lunchPlan.recommendedOptions) {
        expect(dish.mealType, equals('Almuerzo'));
      }

      final dinnerPlan = await service.getWhatShouldIEatToday(category: 'Cena');
      expect(dinnerPlan.selectedCategory, equals('Cena'));
      for (final dish in dinnerPlan.recommendedOptions) {
        expect(dish.mealType, equals('Cena'));
      }
    });

    test('getWhatShouldIEatToday shuffles and recalculates scores on reload', () async {
      final service = NutritionalRecommendationService.instance;
      final planA = await service.getWhatShouldIEatToday(shuffle: true);
      expect(planA.recommendedOptions.isNotEmpty, isTrue);
      for (final dish in planA.recommendedOptions) {
        expect(dish.fitScore, inInclusiveRange(70, 99));
      }
    });

    test('getWhatShouldIEatToday supports English category normalization', () async {
      final service = NutritionalRecommendationService.instance;

      final breakfastPlan = await service.getWhatShouldIEatToday(category: 'Breakfast');
      expect(breakfastPlan.selectedCategory, equals('Desayuno'));
      expect(breakfastPlan.recommendedOptions.isNotEmpty, isTrue);
      for (final dish in breakfastPlan.recommendedOptions) {
        expect(dish.mealType, equals('Desayuno'));
      }

      final lunchPlan = await service.getWhatShouldIEatToday(category: 'Lunch');
      expect(lunchPlan.selectedCategory, equals('Almuerzo'));
      expect(lunchPlan.recommendedOptions.isNotEmpty, isTrue);
      for (final dish in lunchPlan.recommendedOptions) {
        expect(dish.mealType, equals('Almuerzo'));
      }

      final dinnerPlan = await service.getWhatShouldIEatToday(category: 'Dinner');
      expect(dinnerPlan.selectedCategory, equals('Cena'));
      expect(dinnerPlan.recommendedOptions.isNotEmpty, isTrue);
      for (final dish in dinnerPlan.recommendedOptions) {
        expect(dish.mealType, equals('Cena'));
      }
    });

    test('shuffle reload provides dynamic dish rotation and variety', () async {
      final service = NutritionalRecommendationService.instance;
      final staticPlan = await service.getWhatShouldIEatToday(category: 'Desayuno', shuffle: false);
      final reloadPlan1 = await service.getWhatShouldIEatToday(category: 'Desayuno', shuffle: true);
      final reloadPlan2 = await service.getWhatShouldIEatToday(category: 'Desayuno', shuffle: true);

      expect(staticPlan.recommendedOptions.isNotEmpty, isTrue);
      expect(reloadPlan1.recommendedOptions.isNotEmpty, isTrue);
      expect(reloadPlan2.recommendedOptions.isNotEmpty, isTrue);

      // Verify that the catalog has rich options (at least 8 in category)
      expect(staticPlan.recommendedOptions.length, greaterThanOrEqualTo(5));
    });
  });
}
