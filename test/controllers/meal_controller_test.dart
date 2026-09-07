import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/controllers/meal_controller.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/services/database_service.dart';

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
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE meals (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              meal_type TEXT NOT NULL,
              date TEXT NOT NULL,
              image_path TEXT,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL,
              notes TEXT,
              ai_breakdown_json TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE pantry_items (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              brand TEXT,
              category TEXT,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL,
              is_favorite INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      ),
    );
    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await db.close();
    await DatabaseService.instance.closeForTesting();
  });

  group('MealController State & Calculation Tests', () {
    test('Agrupa comidas correctamente por tipo de comida en mealsByType', () async {
      final controller = MealController.instance;
      final today = DateTime.now();
      await controller.setSelectedDate(today);

      final breakfast = Meal(name: 'Huevos', mealType: 'Desayuno', date: today, calories: 250);
      final lunch = Meal(name: 'Pollo y Arroz', mealType: 'Almuerzo', date: today, calories: 600);
      final dinner = Meal(name: 'Ensalada', mealType: 'Cena', date: today, calories: 200);
      final snack = Meal(name: 'Almendras', mealType: 'Snack', date: today, calories: 150);

      await controller.saveMeal(breakfast);
      await controller.saveMeal(lunch);
      await controller.saveMeal(dinner);
      await controller.saveMeal(snack);

      final byType = controller.mealsByType;
      expect(byType['Desayuno']!.length, equals(1));
      expect(byType['Almuerzo']!.length, equals(1));
      expect(byType['Cena']!.length, equals(1));
      expect(byType['Snack']!.length, equals(1));

      expect(controller.totalCalories, equals(1200.0));
    });

    test('Calcula porcentajes de progreso nutricional acotados entre 0.0 y 1.0', () async {
      final controller = MealController.instance;
      final today = DateTime.now();
      await controller.setSelectedDate(today);

      // Add a heavy meal
      final heavyMeal = Meal(
        name: 'Banquete',
        calories: 3000,
        protein: 200,
        carbs: 400,
        fat: 100,
        date: today,
      );
      await controller.saveMeal(heavyMeal);

      // Daily goals default: 2000 cal, 140 prot, 220 carbs, 65 fat
      expect(controller.calorieProgress, equals(1.0)); // Clamped to 1.0
      expect(controller.proteinProgress, equals(1.0));
      expect(controller.carbsProgress, equals(1.0));
      expect(controller.fatProgress, equals(1.0));
    });

    test('Navegación entre días (goToPreviousDay, goToNextDay, goToToday) actualiza fecha seleccionada', () async {
      final controller = MealController.instance;
      final baseDate = DateTime(2026, 9, 6);
      await controller.setSelectedDate(baseDate);

      expect(controller.selectedDate.day, equals(6));

      await controller.goToPreviousDay();
      expect(controller.selectedDate.day, equals(5));

      await controller.goToNextDay();
      expect(controller.selectedDate.day, equals(6));

      await controller.goToToday();
      final now = DateTime.now();
      expect(controller.selectedDate.day, equals(now.day));
      expect(controller.selectedDate.month, equals(now.month));
      expect(controller.selectedDate.year, equals(now.year));
    });
  });
}
