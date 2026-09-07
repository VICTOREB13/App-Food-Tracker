import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/models/weight_log.dart';
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
        version: 2,
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

          await db.execute('''
            CREATE TABLE weight_logs (
              id TEXT PRIMARY KEY,
              date TEXT NOT NULL,
              weight REAL NOT NULL,
              notes TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE user_profile (
              id TEXT PRIMARY KEY,
              name TEXT,
              age INTEGER NOT NULL,
              gender TEXT NOT NULL,
              height REAL NOT NULL,
              weight REAL NOT NULL,
              activity_level TEXT NOT NULL,
              body_goal TEXT NOT NULL,
              estimated_steps INTEGER NOT NULL DEFAULT 8000,
              bmr REAL NOT NULL,
              tdee REAL NOT NULL,
              target_calories REAL NOT NULL,
              target_protein REAL NOT NULL,
              target_carbs REAL NOT NULL,
              target_fat REAL NOT NULL,
              master_prompt TEXT,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
        },
      ),
    );

    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('BackupService v2 Export & Import Tests', () {
    test('exportToJsonString genera JSON v2 completo con meals, pantry, weight_logs y user_profile', () async {
      final dbService = DatabaseService.instance;

      await dbService.insertMeal(Meal(id: 'm1', name: 'Almuerzo 1', calories: 500));
      await dbService.insertPantryItem(PantryItem(id: 'p1', name: 'Arroz', calories: 350));
      await dbService.insertWeightLog(WeightLog(id: 'w1', weight: 77.5, notes: 'Ayunas'));
      await dbService.saveUserProfile(
        UserProfile(
          name: 'Victor',
          age: 28,
          gender: 'male',
          height: 178.0,
          weight: 77.5,
          bmr: 1750.0,
          tdee: 2700.0,
          targetCalories: 2200.0,
          targetProtein: 155.0,
          targetCarbs: 240.0,
          targetFat: 60.0,
        ),
      );

      final jsonString = await BackupService.instance.exportToJsonString();
      final decoded = json.decode(jsonString) as Map<String, dynamic>;

      expect(decoded['app'], equals('Victor Engineer Food Tracker'));
      expect(decoded['version'], equals('2.0.0'));
      expect(decoded['schema_version'], equals(2));
      expect(decoded['meals_count'], equals(1));
      expect(decoded['pantry_count'], equals(1));
      expect(decoded['weight_logs_count'], equals(1));
      expect(decoded['has_user_profile'], isTrue);

      expect((decoded['meals'] as List).length, equals(1));
      expect((decoded['pantry_items'] as List).length, equals(1));
      expect((decoded['weight_logs'] as List).length, equals(1));
      expect(decoded['user_profile'], isNotNull);
      expect((decoded['user_profile'] as Map<String, dynamic>)['name'], equals('Victor'));
    });

    test('importFromJsonString restaura fielmente todas las entidades v2 en SQLite', () async {
      final backupJson = json.encode({
        'version': '2.0.0',
        'schema_version': 2,
        'meals': [
          {'id': 'm100', 'name': 'Desayuno V2', 'meal_type': 'Desayuno', 'date': '2026-09-07T08:00:00.000', 'calories': 400.0, 'protein': 25.0, 'carbs': 40.0, 'fat': 12.0}
        ],
        'pantry_items': [
          {'id': 'p100', 'name': 'Avena V2', 'calories': 380.0, 'protein': 14.0, 'carbs': 60.0, 'fat': 7.0, 'is_favorite': 1}
        ],
        'weight_logs': [
          {'id': 'w100', 'date': '2026-09-07T07:30:00.000', 'weight': 78.2, 'notes': 'Test Restore'}
        ],
        'user_profile': {
          'id': 'primary',
          'name': 'Victor Engineer',
          'age': 28,
          'gender': 'male',
          'height': 178.0,
          'weight': 78.2,
          'activity_level': 'moderate',
          'body_goal': 'fat_loss',
          'estimated_steps': 10000,
          'bmr': 1760.0,
          'tdee': 2728.0,
          'target_calories': 2228.0,
          'target_protein': 156.0,
          'target_carbs': 245.0,
          'target_fat': 62.0,
          'master_prompt': 'Master Prompt de prueba',
          'updated_at': '2026-09-07T12:00:00.000'
        }
      });

      final result = await BackupService.instance.importFromJsonString(backupJson);
      expect(result['imported_meals'], equals(1));
      expect(result['imported_pantry'], equals(1));
      expect(result['imported_weight_logs'], equals(1));
      expect(result['imported_user_profile'], equals(1));

      final restoredMeal = await DatabaseService.instance.getMealById('m100');
      expect(restoredMeal, isNotNull);
      expect(restoredMeal!.name, equals('Desayuno V2'));

      final restoredPantry = await DatabaseService.instance.getPantryItems();
      expect(restoredPantry.any((p) => p.id == 'p100'), isTrue);

      final restoredWeight = await DatabaseService.instance.getWeightLogById('w100');
      expect(restoredWeight, isNotNull);
      expect(restoredWeight!.weight, equals(78.2));

      final restoredProfile = await DatabaseService.instance.getUserProfile();
      expect(restoredProfile, isNotNull);
      expect(restoredProfile!.name, equals('Victor Engineer'));
      expect(restoredProfile.targetCalories, equals(2228.0));
    });

    test('Compatibilidad hacia atrás: importa exitosamente respaldos de Fase 1 sin romper', () async {
      final legacyPhase1Json = json.encode({
        'app': 'Victor Engineer Food Tracker',
        'version': '1.0.0',
        'export_date': '2026-09-06T12:00:00.000',
        'meals_count': 1,
        'pantry_count': 1,
        'meals': [
          {'id': 'm-legacy', 'name': 'Comida Antigua', 'meal_type': 'Cena', 'date': '2026-09-06T20:00:00.000', 'calories': 350.0, 'protein': 30.0, 'carbs': 20.0, 'fat': 10.0}
        ],
        'pantry_items': [
          {'id': 'p-legacy', 'name': 'Atún en Agua', 'calories': 120.0, 'protein': 26.0, 'carbs': 0.0, 'fat': 1.0, 'is_favorite': 0}
        ]
      });

      final result = await BackupService.instance.importFromJsonString(legacyPhase1Json);
      expect(result['imported_meals'], equals(1));
      expect(result['imported_pantry'], equals(1));
      expect(result['imported_weight_logs'], equals(0));
      expect(result['imported_user_profile'], equals(0));

      final meal = await DatabaseService.instance.getMealById('m-legacy');
      expect(meal, isNotNull);
      expect(meal!.name, equals('Comida Antigua'));

      // Weight and profile tables remain unpolluted
      expect(await DatabaseService.instance.getAllWeightLogs(), isEmpty);
      expect(await DatabaseService.instance.getUserProfile(), isNull);
    });

    test('Idempotencia: re-importar el mismo respaldo actualiza registros sin errores de clave única', () async {
      final jsonPayload = json.encode({
        'meals': [
          {'id': 'm-idemp', 'name': 'Pollo Asado', 'meal_type': 'Almuerzo', 'date': '2026-09-07T13:00:00.000', 'calories': 450.0, 'protein': 40.0, 'carbs': 10.0, 'fat': 12.0}
        ],
        'weight_logs': [
          {'id': 'w-idemp', 'date': '2026-09-07T08:00:00.000', 'weight': 76.0}
        ]
      });

      // First import
      await BackupService.instance.importFromJsonString(jsonPayload);
      // Second import with same IDs
      final result2 = await BackupService.instance.importFromJsonString(jsonPayload);

      expect(result2['imported_meals'], equals(1));
      expect(result2['imported_weight_logs'], equals(1));

      final allMeals = await DatabaseService.instance.getAllMeals();
      expect(allMeals.where((m) => m.id == 'm-idemp').length, equals(1));
    });

    test('importFromJsonString arroja FormatException si el JSON raíz no es un Map', () async {
      expect(
        () => BackupService.instance.importFromJsonString('["lista", "invalida"]'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
