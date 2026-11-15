import 'package:sqflite/sqflite.dart';
import 'package:food_tracker/features/food_entry/models/calibrated_dishware.dart';
import 'package:food_tracker/features/fasting_tracker/models/fasting_log.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';
import 'package:food_tracker/features/food_entry/models/meal_template.dart';
import 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';
import 'package:food_tracker/features/biometrics_weight/models/weight_log.dart';
import '../errors/failures.dart';
import '../errors/result.dart';
import '../interfaces/daos_interfaces.dart';
/// Hexagonal port defining local persistence, database lifecycle, and domain DAOs.
abstract interface class IDatabasePort {
  /// Raw database handle for transactional and low-level operations.
  Future<Database> get database;

  /// Initializes the storage engine, migrations, and WAL pragmas.
  Future<void> init();

  /// Executes database VACUUM optimization to reclaim storage space.
  Future<void> executeVacuum();

  /// Retrieves database storage statistics and integrity status.
  Future<Map<String, dynamic>> getDatabaseStats();

  // --- Sub-DAO Accessors ---
  IMealDao get mealDao;
  IWeightLogDao get weightLogDao;
  IUserProfileDao get userProfileDao;
  IPantryDao get pantryDao;
  IDishwareDao get dishwareDao;
  IMealTemplateDao get mealTemplateDao;
  IFastingDao get fastingDao;

  // --- Meals Persistence ---
  Future<int> insertMeal(Meal meal);
  Future<int> upsertMeal(Meal meal);
  Future<int> updateMeal(Meal meal);
  Future<int> deleteMeal(String id);
  Future<Meal?> getMealById(String id);
  Future<List<Meal>> getMealsForDay(DateTime day);
  Future<List<Meal>> getAllMeals();
  Future<List<Meal>> getMealsByRange(DateTime start, DateTime end);
  Future<Meal?> getMealByImagePath(String imagePath);
  Future<List<String>> getDistinctMealDates();
  Future<int> clearMealImagePath(String mealId);
  Future<List<Meal>> getMealsOlderThanWithImages(DateTime cutoffDate);

  // Functional Result pattern for Meals
  Future<Result<int, DatabaseFailure>> upsertMealResult(Meal meal);
  Future<Result<Meal?, DatabaseFailure>> getMealByIdResult(String id);
  Future<Result<List<Meal>, DatabaseFailure>> getMealsForDayResult(DateTime day);
  Future<Result<List<Meal>, DatabaseFailure>> getMealsByRangeResult(DateTime start, DateTime end);

  // --- Pantry Persistence ---
  Future<int> insertPantryItem(PantryItem item);
  Future<int> updatePantryItem(PantryItem item);
  Future<int> deletePantryItem(String id);
  Future<List<PantryItem>> getPantryItems({String? query, String? category, bool? onlyFavorites});
  Future<String> getPantryPromptContext();
  Future<Result<int, DatabaseFailure>> insertPantryItemResult(PantryItem item);
  Future<Result<List<PantryItem>, DatabaseFailure>> getPantryItemsResult({
    String? query,
    String? category,
    bool? onlyFavorites,
  });

  // --- Weight Logs Persistence ---
  Future<int> insertWeightLog(WeightLog log);
  Future<int> updateWeightLog(WeightLog log);
  Future<int> deleteWeightLog(String id);
  Future<WeightLog?> getWeightLogById(String id);
  Future<List<WeightLog>> getAllWeightLogs();
  Future<WeightLog?> getLatestWeightLog();
  Future<List<WeightLog>> getWeightLogsByRange(DateTime startDate, DateTime endDate);
  Future<List<WeightLog>> getWeightLogsLastDays(int days);
  Future<void> batchUpsertWeightLogs(List<WeightLog> logs);
  Future<Result<int, DatabaseFailure>> insertWeightLogResult(WeightLog log);
  Future<Result<WeightLog?, DatabaseFailure>> getLatestWeightLogResult();
  Future<Result<List<WeightLog>, DatabaseFailure>> getWeightLogsByRangeResult(
    DateTime startDate,
    DateTime endDate,
  );

  // --- User Profile Persistence ---
  Future<int> saveUserProfile(UserProfile profile);
  Future<UserProfile?> getUserProfile();
  Future<int> deleteUserProfile({String id = 'primary'});
  Future<Result<int, DatabaseFailure>> saveUserProfileResult(UserProfile profile);
  Future<Result<UserProfile?, DatabaseFailure>> getUserProfileResult();

  // --- Dishware Calibration Persistence ---
  Future<int> insertDishware(CalibratedDishware dishware);
  Future<List<CalibratedDishware>> getDishwareList();
  Future<CalibratedDishware?> getDefaultDishware();
  Future<int> setDefaultDishware(String id);
  Future<int> deleteDishware(String id);

  // --- Meal Templates Persistence ---
  Future<int> saveMealTemplate(MealTemplate template);
  Future<List<MealTemplate>> getMealTemplates({String? mealType});
  Future<int> deleteMealTemplate(String id);

  // --- Intermittent Fasting Logs ---
  Future<int> startFast(DateTime startTime, {int targetHours = 16});
  Future<int> stopActiveFast(DateTime endTime, {String? notes});
  Future<FastingLog?> getActiveFast();
  Future<List<FastingLog>> getFastingHistory({int limit = 50});
}
