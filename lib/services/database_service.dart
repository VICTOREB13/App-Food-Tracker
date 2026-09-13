import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../core/errors/failures.dart';
import '../core/errors/result.dart';
import '../core/interfaces/daos_interfaces.dart';
import '../core/interfaces/database_service_interface.dart';
import '../models/meal.dart';
import '../models/pantry_item.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import 'daos/database_connection_factory.dart';
import 'daos/meal_dao.dart';
import 'daos/pantry_dao.dart';
import 'daos/user_profile_dao.dart';
import 'daos/weight_log_dao.dart';

/// Central database orchestrator managing SQLite lifecycle, WAL configuration, and DAOs.
class DatabaseService implements IDatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static Future<Database>? _initFuture;

  late final IMealDao _mealDao;
  late final IWeightLogDao _weightLogDao;
  late final IUserProfileDao _userProfileDao;
  late final IPantryDao _pantryDao;

  DatabaseService._() {
    _mealDao = MealDao(() => database);
    _weightLogDao = WeightLogDao(() => database);
    _userProfileDao = UserProfileDao(() => database);
    _pantryDao = PantryDao(() => database);
  }

  /// Optional constructor allowing dependency injection of custom DAOs.
  DatabaseService({
    IMealDao? mealDao,
    IWeightLogDao? weightLogDao,
    IUserProfileDao? userProfileDao,
    IPantryDao? pantryDao,
  }) {
    _mealDao = mealDao ?? MealDao(() => database);
    _weightLogDao = weightLogDao ?? WeightLogDao(() => database);
    _userProfileDao = userProfileDao ?? UserProfileDao(() => database);
    _pantryDao = pantryDao ?? PantryDao(() => database);
  }

  /// Global accessor maintaining backwards compatibility while allowing DI overrides.
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  @visibleForTesting
  static void setMockInstance(DatabaseService mock) => _instance = mock;

  @visibleForTesting
  static void resetInstance() => _instance = null;

  @override
  IMealDao get mealDao => _mealDao;

  @override
  IWeightLogDao get weightLogDao => _weightLogDao;

  @override
  IUserProfileDao get userProfileDao => _userProfileDao;

  @override
  IPantryDao get pantryDao => _pantryDao;

  @visibleForTesting
  void setDatabaseForTesting(Database db) {
    _database = db;
    _initFuture = Future.value(db);
  }

  @visibleForTesting
  Future<void> closeForTesting() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
    _initFuture = null;
  }

  @override
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    if (_initFuture != null) return await _initFuture!;

    _initFuture = DatabaseConnectionFactory.openFoodTrackerDatabase();
    try {
      _database = await _initFuture!;
      return _database!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  @override
  Future<void> init() async => await database;

  // Delegations to specialized DAOs
  @override
  Future<int> insertMeal(Meal meal) => _mealDao.insertMeal(meal);
  @override
  Future<int> upsertMeal(Meal meal) => _mealDao.upsertMeal(meal);
  @override
  Future<int> updateMeal(Meal meal) => _mealDao.updateMeal(meal);
  @override
  Future<int> deleteMeal(String id) => _mealDao.deleteMeal(id);
  @override
  Future<Meal?> getMealById(String id) => _mealDao.getMealById(id);
  @override
  Future<List<Meal>> getMealsForDay(DateTime day) => _mealDao.getMealsForDay(day);
  @override
  Future<List<Meal>> getAllMeals() => _mealDao.getAllMeals();
  @override
  Future<List<Meal>> getMealsByRange(DateTime s, DateTime e) => _mealDao.getMealsByRange(s, e);
  @override
  Future<Meal?> getMealByImagePath(String p) => _mealDao.getMealByImagePath(p);
  @override
  Future<List<String>> getDistinctMealDates() => _mealDao.getDistinctMealDates();
  @override
  Future<int> clearMealImagePath(String mealId) => _mealDao.clearMealImagePath(mealId);
  @override
  Future<List<Meal>> getMealsOlderThanWithImages(DateTime c) =>
      _mealDao.getMealsOlderThanWithImages(c);

  @override
  Future<int> insertPantryItem(PantryItem item) => _pantryDao.insertPantryItem(item);
  @override
  Future<int> updatePantryItem(PantryItem item) => _pantryDao.updatePantryItem(item);
  @override
  Future<int> deletePantryItem(String id) => _pantryDao.deletePantryItem(id);
  @override
  Future<List<PantryItem>> getPantryItems({String? query, String? category, bool? onlyFavorites}) =>
      _pantryDao.getPantryItems(query: query, category: category, onlyFavorites: onlyFavorites);

  @override
  Future<int> insertWeightLog(WeightLog log) => _weightLogDao.insertWeightLog(log);
  @override
  Future<int> updateWeightLog(WeightLog log) => _weightLogDao.updateWeightLog(log);
  @override
  Future<int> deleteWeightLog(String id) => _weightLogDao.deleteWeightLog(id);
  @override
  Future<WeightLog?> getWeightLogById(String id) => _weightLogDao.getWeightLogById(id);
  @override
  Future<List<WeightLog>> getAllWeightLogs() => _weightLogDao.getAllWeightLogs();
  @override
  Future<WeightLog?> getLatestWeightLog() => _weightLogDao.getLatestWeightLog();
  @override
  Future<List<WeightLog>> getWeightLogsByRange(DateTime s, DateTime e) =>
      _weightLogDao.getWeightLogsByRange(s, e);
  @override
  Future<List<WeightLog>> getWeightLogsLastDays(int days) =>
      _weightLogDao.getWeightLogsLastDays(days);
  @override
  Future<void> batchUpsertWeightLogs(List<WeightLog> logs) =>
      _weightLogDao.batchUpsertWeightLogs(logs);

  @override
  Future<int> saveUserProfile(UserProfile profile) => _userProfileDao.saveUserProfile(profile);
  @override
  Future<UserProfile?> getUserProfile() => _userProfileDao.getUserProfile();
  @override
  Future<int> deleteUserProfile({String id = 'primary'}) =>
      _userProfileDao.deleteUserProfile(id: id);

  @override
  Future<Result<int, DatabaseFailure>> upsertMealResult(Meal meal) =>
      _mealDao.upsertMealResult(meal);
  @override
  Future<Result<Meal?, DatabaseFailure>> getMealByIdResult(String id) =>
      _mealDao.getMealByIdResult(id);
  @override
  Future<Result<List<Meal>, DatabaseFailure>> getMealsForDayResult(DateTime day) =>
      _mealDao.getMealsForDayResult(day);
  @override
  Future<Result<List<Meal>, DatabaseFailure>> getMealsByRangeResult(DateTime s, DateTime e) =>
      _mealDao.getMealsByRangeResult(s, e);

  @override
  Future<Result<int, DatabaseFailure>> insertWeightLogResult(WeightLog log) =>
      _weightLogDao.insertWeightLogResult(log);
  @override
  Future<Result<WeightLog?, DatabaseFailure>> getLatestWeightLogResult() =>
      _weightLogDao.getLatestWeightLogResult();
  @override
  Future<Result<List<WeightLog>, DatabaseFailure>> getWeightLogsByRangeResult(
    DateTime s,
    DateTime e,
  ) =>
      _weightLogDao.getWeightLogsByRangeResult(s, e);

  @override
  Future<Result<int, DatabaseFailure>> saveUserProfileResult(UserProfile profile) =>
      _userProfileDao.saveUserProfileResult(profile);
  @override
  Future<Result<UserProfile?, DatabaseFailure>> getUserProfileResult() =>
      _userProfileDao.getUserProfileResult();

  @override
  Future<Result<int, DatabaseFailure>> insertPantryItemResult(PantryItem item) =>
      _pantryDao.insertPantryItemResult(item);
  @override
  Future<Result<List<PantryItem>, DatabaseFailure>> getPantryItemsResult({
    String? query,
    String? category,
    bool? onlyFavorites,
  }) =>
      _pantryDao.getPantryItemsResult(query: query, category: category, onlyFavorites: onlyFavorites);

  @override
  Future<void> executeVacuum() async {
    final db = await database;
    await db.execute('VACUUM;');
  }

  @override
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    final mealsCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM meals;');
    final mealsCount = Sqflite.firstIntValue(mealsCountRes) ?? 0;

    final pantryCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM pantry_items;');
    final pantryCount = Sqflite.firstIntValue(pantryCountRes) ?? 0;

    int weightCount = 0;
    try {
      final weightCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM weight_logs;');
      weightCount = Sqflite.firstIntValue(weightCountRes) ?? 0;
    } catch (_) {}

    int profileCount = 0;
    try {
      final profileCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM user_profile;');
      profileCount = Sqflite.firstIntValue(profileCountRes) ?? 0;
    } catch (_) {}

    int fileSizeBytes = 0;
    try {
      final dbPath = await DatabaseConnectionFactory.getDatabasePath();
      final file = File(dbPath);
      if (await file.exists()) {
        fileSizeBytes = await file.length();
      }
    } catch (_) {}

    return {
      'meals_count': mealsCount,
      'pantry_count': pantryCount,
      'weight_logs_count': weightCount,
      'has_user_profile': profileCount > 0,
      'file_size_bytes': fileSizeBytes,
      'file_size_kb': (fileSizeBytes / 1024).toStringAsFixed(1),
    };
  }
}
