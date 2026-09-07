import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/models/pantry_item.dart';
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
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('PRAGMA foreign_keys = ON;');
        },
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

          await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON meals(meal_type);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date_type ON meals(date, meal_type);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_name ON pantry_items(name COLLATE NOCASE);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_category ON pantry_items(category);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_favorite ON pantry_items(is_favorite);');
        },
      ),
    );

    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('DatabaseService Tests', () {
    test('Condiciones de carrera: 50 llamadas asíncronas devuelven la misma instancia', () async {
      final futures = List.generate(50, (_) => DatabaseService.instance.database);
      final results = await Future.wait(futures);

      for (final instance in results) {
        expect(identical(instance, results.first), isTrue);
        expect(instance.isOpen, isTrue);
      }
    });

    test('Integridad PRAGMAs e índices creados correctamente', () async {
      final fkRes = await db.rawQuery('PRAGMA foreign_keys;');
      expect(Sqflite.firstIntValue(fkRes), equals(1));

      final indexRes = await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'index';");
      final indexNames = indexRes.map((r) => r['name'] as String).toList();

      expect(indexNames, contains('idx_meals_date'));
      expect(indexNames, contains('idx_meals_meal_type'));
      expect(indexNames, contains('idx_meals_date_type'));
      expect(indexNames, contains('idx_pantry_name'));
    });

    test('Operaciones CRUD completas de Meals en SQLite', () async {
      final service = DatabaseService.instance;
      final meal = Meal(
        id: 'meal-001',
        name: 'Desayuno Andino',
        mealType: 'Desayuno',
        date: DateTime(2026, 9, 6, 8, 0),
        calories: 450.0,
        protein: 20.0,
        carbs: 55.0,
        fat: 15.0,
        notes: 'Huevos pericos y arepa con queso',
      );

      // Insert
      await service.insertMeal(meal);
      var fetched = await service.getMealById('meal-001');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Desayuno Andino'));
      expect(fetched.calories, equals(450.0));

      // Update
      final updatedMeal = meal.copyWith(name: 'Desayuno Campesino', calories: 500.0);
      await service.updateMeal(updatedMeal);
      fetched = await service.getMealById('meal-001');
      expect(fetched!.name, equals('Desayuno Campesino'));
      expect(fetched.calories, equals(500.0));

      // Delete
      await service.deleteMeal('meal-001');
      fetched = await service.getMealById('meal-001');
      expect(fetched, isNull);
    });

    test('getMealsForDay filtra con precisión comidas por fecha incluyendo microsegundos límite', () async {
      final service = DatabaseService.instance;
      final day = DateTime(2026, 9, 6);

      final mealToday1 = Meal(id: 'm-t1', name: 'Desayuno', date: DateTime(2026, 9, 6, 8, 30));
      final mealToday2 = Meal(id: 'm-t2', name: 'Almuerzo', date: DateTime(2026, 9, 6, 13, 0));
      final mealEndOfDay = Meal(id: 'm-end', name: 'Snack Medianoche', date: DateTime(2026, 9, 6, 23, 59, 59, 999, 999));
      final mealYesterday = Meal(id: 'm-y1', name: 'Cena Ayer', date: DateTime(2026, 9, 5, 20, 0));
      final mealTomorrow = Meal(id: 'm-tm1', name: 'Snack Mañana', date: DateTime(2026, 9, 7, 10, 0));

      await service.insertMeal(mealToday1);
      await service.insertMeal(mealToday2);
      await service.insertMeal(mealEndOfDay);
      await service.insertMeal(mealYesterday);
      await service.insertMeal(mealTomorrow);

      final mealsForToday = await service.getMealsForDay(day);
      expect(mealsForToday.length, equals(3));
      expect(mealsForToday.map((m) => m.id), containsAll(['m-t1', 'm-t2', 'm-end']));
      expect(mealsForToday.map((m) => m.id), isNot(contains('m-y1')));
      expect(mealsForToday.map((m) => m.id), isNot(contains('m-tm1')));
    });

    test('Pantry Items CRUD y filtros de búsqueda', () async {
      final service = DatabaseService.instance;
      final item1 = PantryItem(id: 'p1', name: 'Arroz Diana', brand: 'Diana', category: 'Granos', calories: 350, protein: 7, carbs: 78, fat: 0.5, isFavorite: true);
      final item2 = PantryItem(id: 'p2', name: 'Lentejas Pardinas', brand: 'El Grano', category: 'Legumbres', calories: 320, protein: 24, carbs: 55, fat: 1.0, isFavorite: false);

      await service.insertPantryItem(item1);
      await service.insertPantryItem(item2);

      // Search by query
      final searchRes = await service.getPantryItems(query: 'diana');
      expect(searchRes.length, equals(1));
      expect(searchRes.first.name, equals('Arroz Diana'));

      // Filter by favorites
      final favsRes = await service.getPantryItems(onlyFavorites: true);
      expect(favsRes.length, equals(1));
      expect(favsRes.first.id, equals('p1'));

      // Filter by category
      final catRes = await service.getPantryItems(category: 'Legumbres');
      expect(catRes.length, equals(1));
      expect(catRes.first.name, equals('Lentejas Pardinas'));
    });

    test('executeVacuum y getDatabaseStats se ejecutan sin errores', () async {
      final service = DatabaseService.instance;
      await service.insertMeal(Meal(name: 'Comida Test'));
      await service.insertPantryItem(PantryItem(name: 'Item Test'));

      await service.executeVacuum();

      final stats = await service.getDatabaseStats();
      expect(stats['meals_count'], equals(1));
      expect(stats['pantry_count'], equals(1));
    });
  });
}
