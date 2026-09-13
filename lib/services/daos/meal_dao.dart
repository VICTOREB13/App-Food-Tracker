import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/interfaces/daos_interfaces.dart';
import '../../models/meal.dart';

/// Data Access Object for meals and constituent food items.
class MealDao implements IMealDao {
  final Future<Database> Function() _getDatabase;

  MealDao(this._getDatabase);

  @override
  Future<int> insertMeal(Meal meal) async => await upsertMeal(meal);

  @override
  Future<int> updateMeal(Meal meal) async => await upsertMeal(meal);

  @override
  Future<int> upsertMeal(Meal meal) async {
    final db = await _getDatabase();
    return await db.transaction((txn) async {
      final result = await txn.insert(
        'meals',
        meal.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final tableCheck = await txn.rawQuery(
        'SELECT name FROM sqlite_master WHERE type = \'table\' AND name = \'meal_items\';',
      );
      if (tableCheck.isNotEmpty) {
        await txn.delete('meal_items', where: 'meal_id = ?', whereArgs: [meal.id]);
        for (final item in meal.items) {
          await txn.insert(
            'meal_items',
            {
              'id': item.id,
              'meal_id': meal.id,
              'name': item.name,
              'calories': item.calories,
              'protein': item.protein,
              'carbs': item.carbs,
              'fat': item.fat,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      return result;
    });
  }

  @override
  Future<int> deleteMeal(String id) async {
    final db = await _getDatabase();
    return await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Meal?> getMealById(String id) async {
    final db = await _getDatabase();
    final results = await db.query(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Meal.fromSqliteMap(results.first);
  }

  @override
  Future<List<Meal>> getMealsForDay(DateTime day) async {
    final db = await _getDatabase();
    final startOfDay = DateTime(day.year, day.month, day.day).toIso8601String();
    final nextDay = DateTime(day.year, day.month, day.day + 1).toIso8601String();

    final results = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay, nextDay],
      orderBy: 'date ASC',
    );
    return results.map((m) => Meal.fromSqliteMap(m)).toList();
  }

  @override
  Future<List<Meal>> getAllMeals() async {
    final db = await _getDatabase();
    final results = await db.query('meals', orderBy: 'date DESC');
    return results.map((m) => Meal.fromSqliteMap(m)).toList();
  }

  @override
  Future<List<Meal>> getMealsByRange(DateTime start, DateTime end) async {
    final db = await _getDatabase();
    final startIso = DateTime(start.year, start.month, start.day).toIso8601String();
    final endExclusive =
        DateTime(end.year, end.month, end.day).add(const Duration(days: 1)).toIso8601String();

    final results = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [startIso, endExclusive],
      orderBy: 'date ASC',
    );
    return results.map((m) => Meal.fromSqliteMap(m)).toList();
  }

  @override
  Future<Meal?> getMealByImagePath(String imagePath) async {
    final db = await _getDatabase();
    final results = await db.query(
      'meals',
      where: 'image_path = ?',
      whereArgs: [imagePath],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Meal.fromSqliteMap(results.first);
  }

  @override
  Future<List<String>> getDistinctMealDates() async {
    final db = await _getDatabase();
    final results = await db.rawQuery(
      'SELECT DISTINCT substr(date, 1, 10) as meal_date FROM meals ORDER BY meal_date DESC',
    );
    return results
        .map((r) => r['meal_date'] as String?)
        .whereType<String>()
        .toList();
  }

  @override
  Future<int> clearMealImagePath(String mealId) async {
    final db = await _getDatabase();
    return await db.update(
      'meals',
      {'image_path': null},
      where: 'id = ?',
      whereArgs: [mealId],
    );
  }

  @override
  Future<List<Meal>> getMealsOlderThanWithImages(DateTime cutoffDate) async {
    final db = await _getDatabase();
    final results = await db.query(
      'meals',
      where: 'date < ? AND image_path IS NOT NULL',
      whereArgs: [cutoffDate.toIso8601String()],
      orderBy: 'date ASC',
    );
    return results.map((m) => Meal.fromSqliteMap(m)).toList();
  }

  // ==========================================
  // FUNCTIONAL RESULT APIS
  // ==========================================

  @override
  Future<Result<int, DatabaseFailure>> upsertMealResult(Meal meal) async {
    try {
      final id = await upsertMeal(meal);
      return Result.ok(id);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(message: 'Error al persistir comida: $e', cause: e, stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<Meal?, DatabaseFailure>> getMealByIdResult(String id) async {
    try {
      final meal = await getMealById(id);
      return Result.ok(meal);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(message: 'Error al consultar comida $id: $e', cause: e, stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<List<Meal>, DatabaseFailure>> getMealsForDayResult(DateTime day) async {
    try {
      final meals = await getMealsForDay(day);
      return Result.ok(meals);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(
          message: 'Error al consultar comidas del día: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<Meal>, DatabaseFailure>> getMealsByRangeResult(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final meals = await getMealsByRange(start, end);
      return Result.ok(meals);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(
          message: 'Error al consultar comidas por rango: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }
}
