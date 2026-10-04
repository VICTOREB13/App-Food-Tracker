import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/controllers/settings_controller.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
import 'package:food_tracker/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late SettingsController controller;

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
    SettingsController.resetInstance();
    controller = SettingsController.instance;
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
    SettingsController.resetInstance();
  });

  group('SettingsController File Backup Integration Tests', () {
    test('exportBackupToFile and importBackupFromFile execute end-to-end', () async {
      await DatabaseService.instance.insertMeal(
        Meal(id: 'm_ctrl', name: 'Meal Test File', calories: 400),
      );

      final file = await controller.exportBackupToFile();
      expect(await file.exists(), isTrue);
      expect(file.path.endsWith('.json'), isTrue);

      final backups = await controller.listBackups();
      expect(backups.any((f) => f.path == file.path), isTrue);

      final importRes = await controller.importBackupFromFile(file);
      expect(importRes['imported_meals'], equals(1));
    });
  });
}
