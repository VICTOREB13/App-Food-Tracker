import 'package:sqflite/sqflite.dart';
import 'package:food_tracker/features/food_entry/models/calibrated_dishware.dart';
import 'package:food_tracker/features/fasting_tracker/models/fasting_log.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';
import 'package:food_tracker/features/food_entry/models/meal_template.dart';
import 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';
import 'package:food_tracker/features/biometrics_weight/models/weight_log.dart';
import 'package:food_tracker/core/database/database_service.dart';
import '../errors/failures.dart';
import '../errors/result.dart';
import '../interfaces/daos_interfaces.dart';
import '../interfaces/dishware_dao_interface.dart';
import '../interfaces/fasting_dao_interface.dart';
import '../interfaces/meal_template_dao_interface.dart';
import '../ports/database_port.dart';

/// Sqflite implementation adapter for the [IDatabasePort] hexagonal contract.
class SqfliteDatabaseAdapter implements IDatabasePort {
  final DatabaseService _dbService;

  SqfliteDatabaseAdapter({DatabaseService? databaseService})
      : _dbService = databaseService ?? DatabaseService.instance;

  @override
  Future<Database> get database => _dbService.database;
  @override
  Future<void> init() => _dbService.init();
  @override
  Future<void> executeVacuum() => _dbService.executeVacuum();
  @override
  Future<Map<String, dynamic>> getDatabaseStats() => _dbService.getDatabaseStats();

  // --- Sub-DAOs Accessors ---
  @override
  IMealDao get mealDao => _dbService.mealDao;
  @override
  IWeightLogDao get weightLogDao => _dbService.weightLogDao;
  @override
  IUserProfileDao get userProfileDao => _dbService.userProfileDao;
  @override
  IPantryDao get pantryDao => _dbService.pantryDao;
  @override
  IDishwareDao get dishwareDao => _dbService.dishwareDao;
  @override
  IMealTemplateDao get mealTemplateDao => _dbService.mealTemplateDao;
  @override
  IFastingDao get fastingDao => _dbService.fastingDao;

  // --- Meals Persistence ---
  @override
  Future<int> insertMeal(Meal meal) => _dbService.insertMeal(meal);
  @override
  Future<int> upsertMeal(Meal meal) => _dbService.upsertMeal(meal);
  @override
  Future<int> updateMeal(Meal meal) => _dbService.updateMeal(meal);
  @override
  Future<int> deleteMeal(String id) => _dbService.deleteMeal(id);
  @override
  Future<Meal?> getMealById(String id) => _dbService.getMealById(id);
  @override
  Future<List<Meal>> getMealsForDay(DateTime day) => _dbService.getMealsForDay(day);
  @override
  Future<List<Meal>> getAllMeals() => _dbService.getAllMeals();
  @override
  Future<List<Meal>> getMealsByRange(DateTime s, DateTime e) => _dbService.getMealsByRange(s, e);
  @override
  Future<Meal?> getMealByImagePath(String imagePath) => _dbService.getMealByImagePath(imagePath);
  @override
  Future<List<String>> getDistinctMealDates() => _dbService.getDistinctMealDates();
  @override
  Future<int> clearMealImagePath(String mealId) => _dbService.clearMealImagePath(mealId);
  @override
  Future<List<Meal>> getMealsOlderThanWithImages(DateTime cutoff) => _dbService.getMealsOlderThanWithImages(cutoff);

  // --- Functional Result APIs for Meals ---
  @override
  Future<Result<int, DatabaseFailure>> upsertMealResult(Meal meal) => _dbService.upsertMealResult(meal);
  @override
  Future<Result<Meal?, DatabaseFailure>> getMealByIdResult(String id) => _dbService.getMealByIdResult(id);
  @override
  Future<Result<List<Meal>, DatabaseFailure>> getMealsForDayResult(DateTime day) => _dbService.getMealsForDayResult(day);
  @override
  Future<Result<List<Meal>, DatabaseFailure>> getMealsByRangeResult(DateTime s, DateTime e) => _dbService.getMealsByRangeResult(s, e);

  // --- Pantry Persistence ---
  @override
  Future<int> insertPantryItem(PantryItem item) => _dbService.insertPantryItem(item);
  @override
  Future<int> updatePantryItem(PantryItem item) => _dbService.updatePantryItem(item);
  @override
  Future<int> deletePantryItem(String id) => _dbService.deletePantryItem(id);
  @override
  Future<List<PantryItem>> getPantryItems({String? query, String? category, bool? onlyFavorites}) =>
      _dbService.getPantryItems(query: query, category: category, onlyFavorites: onlyFavorites);
  @override
  Future<String> getPantryPromptContext() => _dbService.getPantryPromptContext();
  @override
  Future<Result<int, DatabaseFailure>> insertPantryItemResult(PantryItem item) => _dbService.insertPantryItemResult(item);
  @override
  Future<Result<List<PantryItem>, DatabaseFailure>> getPantryItemsResult({String? query, String? category, bool? onlyFavorites}) =>
      _dbService.getPantryItemsResult(query: query, category: category, onlyFavorites: onlyFavorites);

  // --- Weight Logs Persistence ---
  @override
  Future<int> insertWeightLog(WeightLog log) => _dbService.insertWeightLog(log);
  @override
  Future<int> updateWeightLog(WeightLog log) => _dbService.updateWeightLog(log);
  @override
  Future<int> deleteWeightLog(String id) => _dbService.deleteWeightLog(id);
  @override
  Future<WeightLog?> getWeightLogById(String id) => _dbService.getWeightLogById(id);
  @override
  Future<List<WeightLog>> getAllWeightLogs() => _dbService.getAllWeightLogs();
  @override
  Future<WeightLog?> getLatestWeightLog() => _dbService.getLatestWeightLog();
  @override
  Future<List<WeightLog>> getWeightLogsByRange(DateTime s, DateTime e) => _dbService.getWeightLogsByRange(s, e);
  @override
  Future<List<WeightLog>> getWeightLogsLastDays(int days) => _dbService.getWeightLogsLastDays(days);
  @override
  Future<void> batchUpsertWeightLogs(List<WeightLog> logs) => _dbService.batchUpsertWeightLogs(logs);
  @override
  Future<Result<int, DatabaseFailure>> insertWeightLogResult(WeightLog log) => _dbService.insertWeightLogResult(log);
  @override
  Future<Result<WeightLog?, DatabaseFailure>> getLatestWeightLogResult() => _dbService.getLatestWeightLogResult();
  @override
  Future<Result<List<WeightLog>, DatabaseFailure>> getWeightLogsByRangeResult(DateTime s, DateTime e) => _dbService.getWeightLogsByRangeResult(s, e);

  // --- User Profile Persistence ---
  @override
  Future<int> saveUserProfile(UserProfile profile) => _dbService.saveUserProfile(profile);
  @override
  Future<UserProfile?> getUserProfile() => _dbService.getUserProfile();
  @override
  Future<int> deleteUserProfile({String id = 'primary'}) => _dbService.deleteUserProfile(id: id);
  @override
  Future<Result<int, DatabaseFailure>> saveUserProfileResult(UserProfile profile) => _dbService.saveUserProfileResult(profile);
  @override
  Future<Result<UserProfile?, DatabaseFailure>> getUserProfileResult() => _dbService.getUserProfileResult();

  // --- Dishware Calibration Persistence ---
  @override
  Future<int> insertDishware(CalibratedDishware dishware) => _dbService.dishwareDao.insertDishware(dishware);
  @override
  Future<List<CalibratedDishware>> getDishwareList() => _dbService.dishwareDao.getAllDishware();
  @override
  Future<CalibratedDishware?> getDefaultDishware() => _dbService.dishwareDao.getDefaultDishware();
  @override
  Future<int> setDefaultDishware(String id) async {
    await _dbService.dishwareDao.setDefaultDishware(id);
    return 1;
  }
  @override
  Future<int> deleteDishware(String id) => _dbService.dishwareDao.deleteDishware(id);

  // --- Meal Templates Persistence ---
  @override
  Future<int> saveMealTemplate(MealTemplate template) => _dbService.mealTemplateDao.insertTemplate(template);
  @override
  Future<List<MealTemplate>> getMealTemplates({String? mealType}) =>
      mealType != null ? _dbService.mealTemplateDao.getTemplatesByMealType(mealType) : _dbService.mealTemplateDao.getAllTemplates();
  @override
  Future<int> deleteMealTemplate(String id) => _dbService.mealTemplateDao.deleteTemplate(id);

  // --- Intermittent Fasting Logs ---
  @override
  Future<int> startFast(DateTime startTime, {int targetHours = 16}) =>
      _dbService.fastingDao.insertFastingLog(FastingLog(startTime: startTime, targetHours: targetHours.toDouble(), isActive: true));
  @override
  Future<int> stopActiveFast(DateTime endTime, {String? notes}) async {
    final active = await _dbService.fastingDao.getActiveFastingLog();
    if (active == null) return 0;
    final updated = active.copyWith(endTime: endTime, isActive: false, notes: notes ?? active.notes);
    return await _dbService.fastingDao.updateFastingLog(updated);
  }
  @override
  Future<FastingLog?> getActiveFast() => _dbService.fastingDao.getActiveFastingLog();
  @override
  Future<List<FastingLog>> getFastingHistory({int limit = 50}) => _dbService.fastingDao.getRecentFastingLogs(limit: limit);
}
