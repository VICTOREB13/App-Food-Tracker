import 'package:sqflite/sqflite.dart';
import '../../models/meal.dart';
import '../../models/pantry_item.dart';
import '../../models/user_profile.dart';
import '../../models/weight_log.dart';
import 'daos_interfaces.dart';

/// Contract defining the Database Service connection orchestrator and DAOs provider.
abstract interface class IDatabaseService {
  Future<Database> get database;
  Future<void> init();
  Future<void> executeVacuum();
  Future<Map<String, dynamic>> getDatabaseStats();

  IMealDao get mealDao;
  IWeightLogDao get weightLogDao;
  IUserProfileDao get userProfileDao;
  IPantryDao get pantryDao;

  // Convenience delegations to DAOs
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

  Future<int> insertPantryItem(PantryItem item);
  Future<int> updatePantryItem(PantryItem item);
  Future<int> deletePantryItem(String id);
  Future<List<PantryItem>> getPantryItems({String? query, String? category, bool? onlyFavorites});

  Future<int> insertWeightLog(WeightLog log);
  Future<int> updateWeightLog(WeightLog log);
  Future<int> deleteWeightLog(String id);
  Future<WeightLog?> getWeightLogById(String id);
  Future<List<WeightLog>> getAllWeightLogs();
  Future<WeightLog?> getLatestWeightLog();
  Future<List<WeightLog>> getWeightLogsByRange(DateTime startDate, DateTime endDate);
  Future<List<WeightLog>> getWeightLogsLastDays(int days);
  Future<void> batchUpsertWeightLogs(List<WeightLog> logs);

  Future<int> saveUserProfile(UserProfile profile);
  Future<UserProfile?> getUserProfile();
  Future<int> deleteUserProfile({String id = 'primary'});
}
