import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/calibrated_dishware.dart';
import 'package:food_tracker/models/fasting_log.dart';
import 'package:food_tracker/models/food_item.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/models/meal_template.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
import 'package:food_tracker/services/daos/dishware_dao.dart';
import 'package:food_tracker/services/daos/fasting_dao.dart';
import 'package:food_tracker/services/daos/meal_dao.dart';
import 'package:food_tracker/services/daos/meal_template_dao.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late DishwareDao dishwareDao;
  late MealTemplateDao templateDao;
  late FastingDao fastingDao;
  late MealDao mealDao;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, v) => DatabaseSchema.createAllTables(db),
      ),
    );

    dishwareDao = DishwareDao(() async => db);
    templateDao = MealTemplateDao(() async => db);
    fastingDao = FastingDao(() async => db);
    mealDao = MealDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SQLite v3 DAOs & Migration Tests', () {
    test('DatabaseSchema.onUpgrade migrates from v2 to v3 safely', () async {
      final oldDb = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, v) async {
            await DatabaseSchema.createMealsTable(db);
            await DatabaseSchema.createMealItemsTable(db);
            await DatabaseSchema.createPantryTable(db);
            await DatabaseSchema.createWeightLogsTable(db);
            await DatabaseSchema.createUserProfileTable(db);
          },
        ),
      );

      // Upgrade to v3 and verify idempotency on second execution
      await DatabaseSchema.onUpgrade(oldDb, 2, 3);
      await DatabaseSchema.onUpgrade(oldDb, 2, 3);

      final mealCols = await oldDb.rawQuery('PRAGMA table_info(meals);');
      final colNames = mealCols.map((c) => c['name'] as String).toSet();
      expect(colNames.contains('fiber'), isTrue);
      expect(colNames.contains('sodium'), isTrue);
      expect(colNames.contains('sugar'), isTrue);

      final dishwareTableCheck = await oldDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'calibrated_dishware';",
      );
      expect(dishwareTableCheck.isNotEmpty, isTrue);

      await oldDb.close();
    });

    test('DishwareDao handles CRUD, default dishware toggle, and Result APIs', () async {
      final dish1 = CalibratedDishware(
        id: 'dish-1',
        name: 'Plato Hondo 24cm',
        diameterCm: 24.0,
        depthCm: 4.5,
        isDefault: false,
      );
      final dish2 = CalibratedDishware(
        id: 'dish-2',
        name: 'Plato Plano 28cm',
        diameterCm: 28.0,
        depthCm: 1.0,
        isDefault: true,
      );

      final insRes = await dishwareDao.insertDishwareResult(dish1);
      expect(insRes.isSuccess, isTrue);
      await dishwareDao.insertDishware(dish2);

      final allRes = await dishwareDao.getAllDishwareResult();
      expect(allRes.isSuccess, isTrue);
      expect(allRes.dataOrNull?.length, equals(2));

      var defaultDish = await dishwareDao.getDefaultDishwareResult();
      expect(defaultDish.dataOrNull?.id, equals('dish-2'));

      // Toggle default to dish-1
      await dishwareDao.setDefaultDishware('dish-1');
      defaultDish = await dishwareDao.getDefaultDishwareResult();
      expect(defaultDish.dataOrNull?.id, equals('dish-1'));

      final updated = dish1.copyWith(name: 'Plato Hondo Pro');
      await dishwareDao.updateDishware(updated);
      final fetched = await dishwareDao.getDishwareById('dish-1');
      expect(fetched?.name, equals('Plato Hondo Pro'));

      await dishwareDao.deleteDishware('dish-1');
      final afterDelete = await dishwareDao.getDishwareById('dish-1');
      expect(afterDelete, isNull);
    });

    test('MealTemplateDao handles CRUD, mealType filtering, and Result APIs', () async {
      final template = MealTemplate(
        id: 'tpl-1',
        name: 'Desayuno Clásico',
        mealType: 'Desayuno',
        calories: 450,
        protein: 30,
        carbs: 45,
        fat: 15,
        fiber: 6,
        sodium: 300,
        sugar: 4,
        items: [
          FoodItem(name: 'Huevos', calories: 150, protein: 12, carbs: 1, fat: 10),
          FoodItem(name: 'Pan', calories: 120, protein: 4, carbs: 24, fat: 1),
        ],
      );

      final insRes = await templateDao.insertTemplateResult(template);
      expect(insRes.isSuccess, isTrue);

      final fetched = await templateDao.getTemplateById('tpl-1');
      expect(fetched, isNotNull);
      expect(fetched?.name, equals('Desayuno Clásico'));
      expect(fetched?.fiber, equals(6.0));
      expect(fetched?.items.length, equals(2));

      final byType = await templateDao.getTemplatesByMealTypeResult('Desayuno');
      expect(byType.isSuccess, isTrue);
      expect(byType.dataOrNull?.length, equals(1));

      final emptyType = await templateDao.getTemplatesByMealTypeResult('Cena');
      expect(emptyType.dataOrNull?.isEmpty, isTrue);

      await templateDao.deleteTemplate('tpl-1');
      expect(await templateDao.getTemplateById('tpl-1'), isNull);
    });

    test('FastingDao handles CRUD, active fasting session, and Result APIs', () async {
      final now = DateTime.now();
      final session = FastingLog(
        id: 'fast-1',
        startTime: now.subtract(const Duration(hours: 14)),
        targetHours: 16.0,
        isActive: true,
        notes: 'Ayuno intermitente 16:8',
      );

      final insRes = await fastingDao.insertFastingLogResult(session);
      expect(insRes.isSuccess, isTrue);

      final active = await fastingDao.getActiveFastingLogResult();
      expect(active.isSuccess, isTrue);
      expect(active.dataOrNull?.id, equals('fast-1'));

      final completed = session.copyWith(
        isActive: false,
        endTime: now,
      );
      await fastingDao.updateFastingLog(completed);

      final activeAfter = await fastingDao.getActiveFastingLog();
      expect(activeAfter, isNull);

      final all = await fastingDao.getAllFastingLogsResult();
      expect(all.dataOrNull?.length, equals(1));

      await fastingDao.deleteFastingLog('fast-1');
      expect(await fastingDao.getFastingLogById('fast-1'), isNull);
    });

    test('MealDao stores and retrieves micronutrients (fiber, sodium, sugar)', () async {
      final meal = Meal(
        id: 'meal-micro-1',
        name: 'Bowl de Avena y Frutos Rojos',
        mealType: 'Desayuno',
        calories: 380,
        protein: 15,
        carbs: 60,
        fat: 8,
        fiber: 10.5,
        sodium: 150.0,
        sugar: 12.0,
        items: [
          FoodItem(
            name: 'Avena integral',
            calories: 250,
            protein: 10,
            carbs: 45,
            fat: 5,
            fiber: 8.0,
            sodium: 10.0,
            sugar: 2.0,
          ),
        ],
      );

      await mealDao.upsertMeal(meal);

      final retrieved = await mealDao.getMealById('meal-micro-1');
      expect(retrieved, isNotNull);
      expect(retrieved?.fiber, equals(10.5));
      expect(retrieved?.sodium, equals(150.0));
      expect(retrieved?.sugar, equals(12.0));

      final items = await db.query('meal_items', where: 'meal_id = ?', whereArgs: ['meal-micro-1']);
      expect(items.isNotEmpty, isTrue);
      expect(items.first['fiber'], equals(8.0));
      expect(items.first['sodium'], equals(10.0));
      expect(items.first['sugar'], equals(2.0));
    });

    test('DatabaseService provides access to all v3 DAOs', () {
      final dbService = DatabaseService.instance;
      expect(dbService.dishwareDao, isNotNull);
      expect(dbService.mealTemplateDao, isNotNull);
      expect(dbService.fastingDao, isNotNull);
    });
  });
}
