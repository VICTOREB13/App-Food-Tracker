import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/models/weight_log.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
import 'package:food_tracker/services/daos/meal_dao.dart';
import 'package:food_tracker/services/daos/pantry_dao.dart';
import 'package:food_tracker/services/daos/user_profile_dao.dart';
import 'package:food_tracker/services/daos/weight_log_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late MealDao mealDao;
  late WeightLogDao weightLogDao;
  late UserProfileDao userProfileDao;
  late PantryDao pantryDao;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, v) => DatabaseSchema.createAllTables(db),
      ),
    );

    mealDao = MealDao(() async => db);
    weightLogDao = WeightLogDao(() async => db);
    userProfileDao = UserProfileDao(() async => db);
    pantryDao = PantryDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Specialized DAOs Tests', () {
    test('MealDao performs CRUD and Result operations', () async {
      final meal = Meal(
        id: 'meal-101',
        name: 'Huevos con tostadas',
        mealType: 'Desayuno',
        date: DateTime(2026, 9, 13, 8, 30),
        calories: 380,
        protein: 24,
        carbs: 32,
        fat: 16,
      );

      final insertRes = await mealDao.upsertMealResult(meal);
      expect(insertRes.isSuccess, isTrue);

      final fetchRes = await mealDao.getMealByIdResult('meal-101');
      expect(fetchRes.isSuccess, isTrue);
      expect(fetchRes.dataOrNull?.name, equals('Huevos con tostadas'));
      expect(fetchRes.dataOrNull?.calories, equals(380.0));

      final dayMeals = await mealDao.getMealsForDay(DateTime(2026, 9, 13));
      expect(dayMeals.length, equals(1));
    });

    test('WeightLogDao records time-series and queries ranges', () async {
      final log = WeightLog(
        id: 'wl-1',
        weight: 78.5,
        date: DateTime(2026, 9, 13),
        notes: 'Ayuno matutino',
      );

      final res = await weightLogDao.insertWeightLogResult(log);
      expect(res.isSuccess, isTrue);

      final latest = await weightLogDao.getLatestWeightLogResult();
      expect(latest.isSuccess, isTrue);
      expect(latest.dataOrNull?.weight, equals(78.5));
    });

    test('UserProfileDao persists biometrics and calculates goals', () async {
      final profile = UserProfile(
        id: 'primary',
        name: 'Victor',
        age: 26,
        gender: 'male',
        height: 178,
        weight: 78.5,
        activityLevel: 'moderate',
        bodyGoal: 'deficit',
        estimatedSteps: 10000,
        bmr: 1750,
        tdee: 2450,
        targetCalories: 2000,
        targetProtein: 160,
        targetCarbs: 200,
        targetFat: 60,
        updatedAt: DateTime(2026, 9, 13),
      );

      final saveRes = await userProfileDao.saveUserProfileResult(profile);
      expect(saveRes.isSuccess, isTrue);

      final fetched = await userProfileDao.getUserProfileResult();
      expect(fetched.isSuccess, isTrue);
      expect(fetched.dataOrNull?.name, equals('Victor'));
      expect(fetched.dataOrNull?.targetCalories, equals(2000));
    });

    test('PantryDao manages items, favorites, and filters', () async {
      final item = PantryItem(
        id: 'p-1',
        name: 'Avena en hojuelas',
        brand: 'Quaker',
        category: 'Granos',
        calories: 150,
        protein: 5,
        carbs: 27,
        fat: 3,
        isFavorite: true,
      );

      final insertRes = await pantryDao.insertPantryItemResult(item);
      expect(insertRes.isSuccess, isTrue);

      final items = await pantryDao.getPantryItems(onlyFavorites: true);
      expect(items.length, equals(1));
      expect(items.first.name, equals('Avena en hojuelas'));
    });
  });
}
