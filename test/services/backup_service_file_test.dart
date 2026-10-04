import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/models/weight_log.dart';
import 'package:food_tracker/services/backup_service.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
import 'package:food_tracker/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('food_tracker_backup_test_');

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
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupService Physical File Export & Import Tests', () {
    test('exportToJsonFile writes real physical JSON file and inspectBackupFile returns metadata', () async {
      final dbService = DatabaseService.instance;
      await dbService.insertMeal(Meal(id: 'm1', name: 'Almuerzo File', calories: 550, protein: 40));
      await dbService.insertPantryItem(PantryItem(id: 'p1', name: 'Arroz Integral', calories: 340));
      await dbService.insertWeightLog(WeightLog(id: 'w1', weight: 75.0, notes: 'Semana 1'));
      await dbService.saveUserProfile(
        UserProfile(
          name: 'Victor',
          age: 29,
          gender: 'male',
          height: 178,
          weight: 75,
          bmr: 1700,
          tdee: 2400,
          targetCalories: 2000,
          targetProtein: 150,
          targetCarbs: 220,
          targetFat: 60,
        ),
      );

      final file = await BackupService.instance.exportToJsonFile(customDirectoryPath: tempDir.path);

      expect(await file.exists(), isTrue);
      expect(file.path.endsWith('.json'), isTrue);
      expect(await file.length(), greaterThan(100));

      final metadata = await BackupService.instance.inspectBackupFile(file);
      expect(metadata['meals_count'], equals(1));
      expect(metadata['pantry_count'], equals(1));
      expect(metadata['weight_logs_count'], equals(1));
      expect(metadata['has_user_profile'], isTrue);
      expect(metadata['filename'], contains('food_tracker_backup_'));
    });

    test('importFromFile restores entities into SQLite database', () async {
      final backupFile = File('${tempDir.path}/test_manual_backup.json');
      const jsonContent = '''
{
  "app": "Victor Engineer Food Tracker",
  "version": "2.0.0",
  "schema_version": 2,
  "export_date": "2026-10-04T12:00:00.000",
  "meals": [
    {
      "id": "file_m1",
      "name": "Pollo al Limon",
      "meal_type": "Almuerzo",
      "date": "2026-10-04T13:00:00.000",
      "calories": 450.0,
      "protein": 42.0,
      "carbs": 20.0,
      "fat": 8.0
    }
  ],
  "pantry_items": [
    {
      "id": "file_p1",
      "name": "Aceite de Oliva",
      "calories": 880.0,
      "protein": 0.0,
      "carbs": 0.0,
      "fat": 100.0,
      "is_favorite": 1
    }
  ],
  "weight_logs": [
    {
      "id": "file_w1",
      "date": "2026-10-04T08:00:00.000",
      "weight": 76.5,
      "notes": "Post entrenamiento"
    }
  ],
  "user_profile": {
    "name": "Victor Engineer",
    "age": 29,
    "gender": "male",
    "height": 178.0,
    "weight": 76.5,
    "target_calories": 2100.0,
    "target_protein": 160.0,
    "target_carbs": 220.0,
    "target_fat": 55.0
  }
}
''';
      await backupFile.writeAsString(jsonContent);

      final result = await BackupService.instance.importFromFile(backupFile);
      expect(result['imported_meals'], equals(1));
      expect(result['imported_pantry'], equals(1));
      expect(result['imported_weight_logs'], equals(1));
      expect(result['imported_user_profile'], equals(1));

      final restoredMeal = await DatabaseService.instance.getMealById('file_m1');
      expect(restoredMeal, isNotNull);
      expect(restoredMeal!.name, equals('Pollo al Limon'));
      expect(restoredMeal.protein, equals(42.0));

      final restoredProfile = await DatabaseService.instance.getUserProfile();
      expect(restoredProfile, isNotNull);
      expect(restoredProfile!.name, equals('Victor Engineer'));
      expect(restoredProfile.targetProtein, equals(160.0));
    });
  });
}
