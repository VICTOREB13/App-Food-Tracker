import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/controllers/meal_controller.dart';
import 'package:food_tracker/models/weight_log.dart';
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
    await db.close();
    await DatabaseService.instance.closeForTesting();
  });

  group('MealController Weight Tracking State & Reactivity Tests', () {
    test('Estado inicial de weightLogs está vacío y selectedWeightDays es 30 por defecto', () async {
      final controller = MealController.instance;
      await controller.loadWeightLogs();

      expect(controller.weightLogs, isEmpty);
      expect(controller.latestWeightLog, isNull);
      expect(controller.currentWeight, isNull);
      expect(controller.selectedWeightDays, equals(30));
    });

    test('recordWeight persiste registro, actualiza latestWeightLog y notifica a listeners', () async {
      final controller = MealController.instance;
      int notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      await controller.recordWeight(78.5, notes: 'Ayuno matutino');

      expect(controller.weightLogs.length, equals(1));
      expect(controller.latestWeightLog, isNotNull);
      expect(controller.latestWeightLog!.weight, equals(78.5));
      expect(controller.latestWeightLog!.notes, equals('Ayuno matutino'));
      expect(controller.currentWeight, equals(78.5));
      expect(notificationCount, greaterThan(0));

      // Check record persisted in SQLite
      final inDb = await DatabaseService.instance.getLatestWeightLog();
      expect(inDb, isNotNull);
      expect(inDb!.weight, equals(78.5));
    });

    test('deleteWeight elimina registro por ID y actualiza el estado', () async {
      final controller = MealController.instance;

      await controller.recordWeight(80.0, notes: 'Log 1');
      final firstLogId = controller.latestWeightLog!.id;

      await controller.recordWeight(79.5, notes: 'Log 2');
      expect(controller.weightLogs.length, equals(2));

      await controller.deleteWeight(firstLogId);

      expect(controller.weightLogs.length, equals(1));
      expect(controller.weightLogs.any((l) => l.id == firstLogId), isFalse);
    });

    test('Encapsulación: weightLogs retorna una lista inmutable (UnmodifiableListView)', () {
      final controller = MealController.instance;
      expect(
        () => controller.weightLogs.add(WeightLog(weight: 70.0)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('loadWeightLogs con parámetro days actualiza selectedWeightDays y filtra rango', () async {
      final controller = MealController.instance;
      final now = DateTime.now();

      // Insert directly into SQLite: 1 log today, 1 log 15 days ago, 1 log 45 days ago
      final service = DatabaseService.instance;
      await service.insertWeightLog(WeightLog(id: 'd-today', date: now, weight: 75.0));
      await service.insertWeightLog(WeightLog(id: 'd-15', date: now.subtract(const Duration(days: 15)), weight: 75.8));
      await service.insertWeightLog(WeightLog(id: 'd-45', date: now.subtract(const Duration(days: 45)), weight: 76.5));

      // 1. Load last 7 days (should return only 1 log)
      await controller.loadWeightLogs(days: 7);
      expect(controller.selectedWeightDays, equals(7));
      expect(controller.weightLogs.length, equals(1));
      expect(controller.weightLogs.first.id, equals('d-today'));

      // 2. Load last 30 days (should return 2 logs)
      await controller.loadWeightLogs(days: 30);
      expect(controller.selectedWeightDays, equals(30));
      expect(controller.weightLogs.length, equals(2));

      // 3. Load last 90 days (should return all 3 logs)
      await controller.loadWeightLogs(days: 90);
      expect(controller.selectedWeightDays, equals(90));
      expect(controller.weightLogs.length, equals(3));

      // 4. Load days <= 0 (historical all records via getAllWeightLogs)
      await controller.loadWeightLogs(days: 0);
      expect(controller.selectedWeightDays, equals(0));
      expect(controller.weightLogs.length, equals(3));
    });

    test('loadWeightLogs maneja errores de BD limpiando estado sin propagar excepción a la UI', () async {
      final controller = MealController.instance;

      // Close the underlying database to induce an exception
      await db.close();

      // Should not throw
      await controller.loadWeightLogs();
      expect(controller.weightLogs, isEmpty);
      expect(controller.latestWeightLog, isNull);
    });
  });
}
