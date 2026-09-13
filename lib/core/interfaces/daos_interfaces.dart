import '../../models/meal.dart';
import '../../models/pantry_item.dart';
import '../../models/user_profile.dart';
import '../../models/weight_log.dart';
import '../errors/failures.dart';
import '../errors/result.dart';

/// Contract for Meal Data Access Object.
abstract interface class IMealDao {
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

  // Functional Result APIs
  Future<Result<int, DatabaseFailure>> upsertMealResult(Meal meal);
  Future<Result<Meal?, DatabaseFailure>> getMealByIdResult(String id);
  Future<Result<List<Meal>, DatabaseFailure>> getMealsForDayResult(DateTime day);
  Future<Result<List<Meal>, DatabaseFailure>> getMealsByRangeResult(DateTime start, DateTime end);
}

/// Contract for Weight Log Data Access Object.
abstract interface class IWeightLogDao {
  Future<int> insertWeightLog(WeightLog log);
  Future<int> updateWeightLog(WeightLog log);
  Future<int> deleteWeightLog(String id);
  Future<WeightLog?> getWeightLogById(String id);
  Future<List<WeightLog>> getAllWeightLogs();
  Future<WeightLog?> getLatestWeightLog();
  Future<List<WeightLog>> getWeightLogsByRange(DateTime startDate, DateTime endDate);
  Future<List<WeightLog>> getWeightLogsLastDays(int days);
  Future<void> batchUpsertWeightLogs(List<WeightLog> logs);

  // Functional Result APIs
  Future<Result<int, DatabaseFailure>> insertWeightLogResult(WeightLog log);
  Future<Result<List<WeightLog>, DatabaseFailure>> getWeightLogsByRangeResult(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Result<WeightLog?, DatabaseFailure>> getLatestWeightLogResult();
}

/// Contract for User Profile Data Access Object.
abstract interface class IUserProfileDao {
  Future<int> saveUserProfile(UserProfile profile);
  Future<UserProfile?> getUserProfile();
  Future<int> deleteUserProfile({String id = 'primary'});

  // Functional Result APIs
  Future<Result<int, DatabaseFailure>> saveUserProfileResult(UserProfile profile);
  Future<Result<UserProfile?, DatabaseFailure>> getUserProfileResult();
}

/// Contract for Pantry Item Data Access Object.
abstract interface class IPantryDao {
  Future<int> insertPantryItem(PantryItem item);
  Future<int> updatePantryItem(PantryItem item);
  Future<int> deletePantryItem(String id);
  Future<List<PantryItem>> getPantryItems({
    String? query,
    String? category,
    bool? onlyFavorites,
  });

  // Functional Result APIs
  Future<Result<int, DatabaseFailure>> insertPantryItemResult(PantryItem item);
  Future<Result<List<PantryItem>, DatabaseFailure>> getPantryItemsResult({
    String? query,
    String? category,
    bool? onlyFavorites,
  });
}
