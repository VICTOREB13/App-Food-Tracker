import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/services/backup_service.dart';
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
    await DatabaseService.instance.closeForTesting();
  });

  group('BackupService Export & Import Tests', () {
    test('exportToJsonString genera un JSON válido con todas las comidas y despensa', () async {
      final dbService = DatabaseService.instance;
      await dbService.insertMeal(Meal(id: 'm1', name: 'Almuerzo 1', calories: 500));
      await dbService.insertPantryItem(PantryItem(id: 'p1', name: 'Arroz', calories: 350));

      final jsonString = await BackupService.instance.exportToJsonString();
      final decoded = json.decode(jsonString) as Map<String, dynamic>;

      expect(decoded['app'], equals('Victor Engineer Food Tracker'));
      expect(decoded['meals_count'], equals(1));
      expect(decoded['pantry_count'], equals(1));
      expect((decoded['meals'] as List).length, equals(1));
      expect((decoded['pantry_items'] as List).length, equals(1));
    });

    test('importFromJsonString restaura fielmente registros en SQLite', () async {
      final backupJson = json.encode({
        'meals': [
          {'id': 'm100', 'name': 'Desayuno Importado', 'meal_type': 'Desayuno', 'date': '2026-09-06T08:00:00.000', 'calories': 400.0, 'protein': 25.0, 'carbs': 40.0, 'fat': 12.0}
        ],
        'pantry_items': [
          {'id': 'p100', 'name': 'Avena Importada', 'calories': 380.0, 'protein': 14.0, 'carbs': 60.0, 'fat': 7.0, 'is_favorite': 1}
        ]
      });

      final result = await BackupService.instance.importFromJsonString(backupJson);
      expect(result['imported_meals'], equals(1));
      expect(result['imported_pantry'], equals(1));

      final restoredMeal = await DatabaseService.instance.getMealById('m100');
      expect(restoredMeal, isNotNull);
      expect(restoredMeal!.name, equals('Desayuno Importado'));

      final restoredPantry = await DatabaseService.instance.getPantryItems();
      expect(restoredPantry.any((p) => p.id == 'p100'), isTrue);
    });

    test('importFromJsonString arroja FormatException si el JSON es inválido', () async {
      expect(
        () => BackupService.instance.importFromJsonString('["no", "es", "un", "mapa"]'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
