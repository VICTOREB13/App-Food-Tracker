import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/models/weight_log.dart';
import 'package:food_tracker/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  Future<Database> createV2Database() async {
    return await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
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

          await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON meals(meal_type);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date_type ON meals(date, meal_type);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_name ON pantry_items(name COLLATE NOCASE);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_category ON pantry_items(category);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_favorite ON pantry_items(is_favorite);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
        },
      ),
    );
  }

  setUp(() async {
    db = await createV2Database();
    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('DatabaseService v2 Schema & Persistence Tests', () {
    test('Verifica la creación del índice B-Tree idx_weight_logs_date en SQLite', () async {
      final indexRes = await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'index';");
      final indexNames = indexRes.map((r) => r['name'] as String).toList();

      expect(indexNames, contains('idx_weight_logs_date'));
    });

    test('Migración atómica v1 -> v2 preserva datos existentes de meals y crea tablas v2', () async {
      await DatabaseService.instance.closeForTesting();
      final tempDbPath = p.join(
        Directory.systemTemp.path,
        'migration_test_${DateTime.now().microsecondsSinceEpoch}.db',
      );

      // Open database as version 1
      var migrationDb = await databaseFactoryFfi.openDatabase(
        tempDbPath,
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

      // Insert data into v1 database
      await migrationDb.insert('meals', {
        'id': 'v1-meal-1',
        'name': 'Comida Histórica',
        'meal_type': 'Almuerzo',
        'date': '2026-09-01T12:00:00.000',
        'calories': 600.0,
        'protein': 35.0,
        'carbs': 70.0,
        'fat': 18.0,
      });

      // Upgrade to version 2 with onUpgrade
      await migrationDb.close();
      migrationDb = await databaseFactoryFfi.openDatabase(
        tempDbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute('''
                CREATE TABLE IF NOT EXISTS weight_logs (
                  id TEXT PRIMARY KEY,
                  date TEXT NOT NULL,
                  weight REAL NOT NULL,
                  notes TEXT
                )
              ''');
              await db.execute('''
                CREATE TABLE IF NOT EXISTS user_profile (
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
            }
          },
        ),
      );

      DatabaseService.instance.setDatabaseForTesting(migrationDb);

      // Verify v1 data is still intact
      final existingMeal = await DatabaseService.instance.getMealById('v1-meal-1');
      expect(existingMeal, isNotNull);
      expect(existingMeal!.name, equals('Comida Histórica'));

      // Verify v2 tables exist and accept inserts
      await DatabaseService.instance.insertWeightLog(
        WeightLog(id: 'migrated-w1', weight: 75.0, notes: 'Post-migración'),
      );
      final fetchedLog = await DatabaseService.instance.getWeightLogById('migrated-w1');
      expect(fetchedLog, isNotNull);
      expect(fetchedLog!.weight, equals(75.0));

      await migrationDb.close();
      final tempFile = File(tempDbPath);
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }
    });

    test('Operaciones CRUD completas de WeightLog', () async {
      final service = DatabaseService.instance;
      final log = WeightLog(
        id: 'w-100',
        date: DateTime(2026, 9, 7, 8, 0),
        weight: 79.5,
        notes: 'En ayunas',
      );

      // 1. Insert
      await service.insertWeightLog(log);
      var fetched = await service.getWeightLogById('w-100');
      expect(fetched, isNotNull);
      expect(fetched!.weight, equals(79.5));
      expect(fetched.notes, equals('En ayunas'));

      // 2. Update
      final updatedLog = log.copyWith(weight: 79.1, notes: 'Actualizado');
      await service.updateWeightLog(updatedLog);
      fetched = await service.getWeightLogById('w-100');
      expect(fetched!.weight, equals(79.1));
      expect(fetched.notes, equals('Actualizado'));

      // 3. Delete
      await service.deleteWeightLog('w-100');
      fetched = await service.getWeightLogById('w-100');
      expect(fetched, isNull);
    });

    test('getLatestWeightLog retorna O(1) el registro más reciente o null si está vacía', () async {
      final service = DatabaseService.instance;

      expect(await service.getLatestWeightLog(), isNull);

      final logOld = WeightLog(id: 'w-old', date: DateTime(2026, 9, 1, 8, 0), weight: 81.0);
      final logMid = WeightLog(id: 'w-mid', date: DateTime(2026, 9, 5, 8, 0), weight: 80.0);
      final logNew = WeightLog(id: 'w-new', date: DateTime(2026, 9, 7, 8, 0), weight: 79.0);

      await service.insertWeightLog(logOld);
      await service.insertWeightLog(logMid);
      await service.insertWeightLog(logNew);

      final latest = await service.getLatestWeightLog();
      expect(latest, isNotNull);
      expect(latest!.id, equals('w-new'));
      expect(latest.weight, equals(79.0));
    });

    test('getWeightLogsByRange filtra exactamente por límites y ordena ascendentemente', () async {
      final service = DatabaseService.instance;

      final log1 = WeightLog(id: 'w-1', date: DateTime(2026, 9, 2, 8, 0), weight: 80.5);
      final log2 = WeightLog(id: 'w-2', date: DateTime(2026, 9, 4, 8, 0), weight: 80.0);
      final log3 = WeightLog(id: 'w-3', date: DateTime(2026, 9, 6, 8, 0), weight: 79.5);
      final logBefore = WeightLog(id: 'w-before', date: DateTime(2026, 8, 30, 8, 0), weight: 81.5);
      final logAfter = WeightLog(id: 'w-after', date: DateTime(2026, 9, 10, 8, 0), weight: 78.5);

      // Insert in unordered sequence
      await service.insertWeightLog(log3);
      await service.insertWeightLog(logBefore);
      await service.insertWeightLog(log1);
      await service.insertWeightLog(logAfter);
      await service.insertWeightLog(log2);

      final rangeLogs = await service.getWeightLogsByRange(
        DateTime(2026, 9, 1, 0, 0),
        DateTime(2026, 9, 7, 23, 59),
      );

      expect(rangeLogs.length, equals(3));
      expect(rangeLogs[0].id, equals('w-1'));
      expect(rangeLogs[1].id, equals('w-2'));
      expect(rangeLogs[2].id, equals('w-3'));
    });

    test('getWeightLogsLastDays recupera el número correcto de días relativos', () async {
      final service = DatabaseService.instance;
      final now = DateTime.now();

      final logToday = WeightLog(id: 'wt-0', date: now, weight: 75.0);
      final log5DaysAgo = WeightLog(id: 'wt-5', date: now.subtract(const Duration(days: 5)), weight: 75.5);
      final log20DaysAgo = WeightLog(id: 'wt-20', date: now.subtract(const Duration(days: 20)), weight: 76.0);
      final log50DaysAgo = WeightLog(id: 'wt-50', date: now.subtract(const Duration(days: 50)), weight: 77.0);

      await service.insertWeightLog(logToday);
      await service.insertWeightLog(log5DaysAgo);
      await service.insertWeightLog(log20DaysAgo);
      await service.insertWeightLog(log50DaysAgo);

      final last7Days = await service.getWeightLogsLastDays(7);
      expect(last7Days.length, equals(2));
      expect(last7Days.map((l) => l.id), containsAll(['wt-0', 'wt-5']));

      final last30Days = await service.getWeightLogsLastDays(30);
      expect(last30Days.length, equals(3));
      expect(last30Days.map((l) => l.id), containsAll(['wt-0', 'wt-5', 'wt-20']));

      final last90Days = await service.getWeightLogsLastDays(90);
      expect(last90Days.length, equals(4));
    });

    test('batchUpsertWeightLogs inserta y reemplaza múltiples registros de forma atómica', () async {
      final service = DatabaseService.instance;
      final batchLogs = [
        WeightLog(id: 'b-1', weight: 80.0),
        WeightLog(id: 'b-2', weight: 79.5),
        WeightLog(id: 'b-3', weight: 79.0),
      ];

      await service.batchUpsertWeightLogs(batchLogs);

      final all = await service.getAllWeightLogs();
      expect(all.length, equals(3));

      // Re-insert b-2 with updated weight
      final updatedLogs = [
        WeightLog(id: 'b-2', weight: 78.5),
        WeightLog(id: 'b-4', weight: 78.0),
      ];
      await service.batchUpsertWeightLogs(updatedLogs);

      final updatedAll = await service.getAllWeightLogs();
      expect(updatedAll.length, equals(4));

      final logB2 = await service.getWeightLogById('b-2');
      expect(logB2!.weight, equals(78.5));
    });

    test('UserProfile CRUD y singleton de perfil en SQLite', () async {
      final service = DatabaseService.instance;

      expect(await service.getUserProfile(), isNull);

      final profile = UserProfile(
        name: 'Victor',
        age: 29,
        gender: 'male',
        height: 177.0,
        weight: 75.0,
        activityLevel: 'moderate',
        bodyGoal: 'fat_loss',
        estimatedSteps: 10000,
        bmr: 1720.0,
        tdee: 2666.0,
        targetCalories: 2166.0,
        targetProtein: 150.0,
        targetCarbs: 240.0,
        targetFat: 60.0,
        masterPrompt: 'Prompt inicial',
      );

      await service.saveUserProfile(profile);

      var fetched = await service.getUserProfile();
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Victor'));
      expect(fetched.tdee, equals(2666.0));

      // Overwrite with updated profile
      final updatedProfile = profile.copyWith(weight: 74.5, targetCalories: 2150.0);
      await service.saveUserProfile(updatedProfile);

      fetched = await service.getUserProfile();
      expect(fetched!.weight, equals(74.5));
      expect(fetched.targetCalories, equals(2150.0));

      // Delete profile
      await service.deleteUserProfile();
      expect(await service.getUserProfile(), isNull);
    });

    test('getDatabaseStats incluye weight_logs_count y has_user_profile', () async {
      final service = DatabaseService.instance;

      var stats = await service.getDatabaseStats();
      expect(stats['weight_logs_count'], equals(0));
      expect(stats['has_user_profile'], isFalse);

      await service.insertWeightLog(WeightLog(id: 's-w1', weight: 70.0));
      await service.saveUserProfile(
        UserProfile(
          age: 25,
          height: 170.0,
          weight: 70.0,
          bmr: 1600.0,
          tdee: 2200.0,
          targetCalories: 2000.0,
          targetProtein: 140.0,
          targetCarbs: 220.0,
          targetFat: 65.0,
        ),
      );

      stats = await service.getDatabaseStats();
      expect(stats['weight_logs_count'], equals(1));
      expect(stats['has_user_profile'], isTrue);
    });
  });
}
