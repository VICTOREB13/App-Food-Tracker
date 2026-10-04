import '../../models/meal_template.dart';
import '../errors/failures.dart';
import '../errors/result.dart';

/// Contract for Meal Template Data Access Object.
abstract interface class IMealTemplateDao {
  Future<int> insertTemplate(MealTemplate template);
  Future<int> updateTemplate(MealTemplate template);
  Future<int> deleteTemplate(String id);
  Future<MealTemplate?> getTemplateById(String id);
  Future<List<MealTemplate>> getAllTemplates();
  Future<List<MealTemplate>> getTemplatesByMealType(String mealType);

  // Functional Result APIs
  Future<Result<int, DatabaseFailure>> insertTemplateResult(MealTemplate template);
  Future<Result<List<MealTemplate>, DatabaseFailure>> getAllTemplatesResult();
  Future<Result<List<MealTemplate>, DatabaseFailure>> getTemplatesByMealTypeResult(String mealType);
}
