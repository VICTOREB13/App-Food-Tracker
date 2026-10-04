import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/interfaces/meal_template_dao_interface.dart';
import '../../models/meal_template.dart';

/// Data Access Object for reusable meal templates.
class MealTemplateDao implements IMealTemplateDao {
  final Future<Database> Function() _getDatabase;

  MealTemplateDao(this._getDatabase);

  @override
  Future<int> insertTemplate(MealTemplate template) async {
    final db = await _getDatabase();
    return await db.insert(
      'meal_templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateTemplate(MealTemplate template) async {
    final db = await _getDatabase();
    return await db.update(
      'meal_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  @override
  Future<int> deleteTemplate(String id) async {
    final db = await _getDatabase();
    return await db.delete('meal_templates', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<MealTemplate?> getTemplateById(String id) async {
    final db = await _getDatabase();
    final results = await db.query(
      'meal_templates',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MealTemplate.fromMap(results.first);
  }

  @override
  Future<List<MealTemplate>> getAllTemplates() async {
    final db = await _getDatabase();
    final results = await db.query('meal_templates', orderBy: 'created_at DESC');
    return results.map((m) => MealTemplate.fromMap(m)).toList();
  }

  @override
  Future<List<MealTemplate>> getTemplatesByMealType(String mealType) async {
    final db = await _getDatabase();
    final results = await db.query(
      'meal_templates',
      where: 'meal_type = ?',
      whereArgs: [mealType],
      orderBy: 'name ASC',
    );
    return results.map((m) => MealTemplate.fromMap(m)).toList();
  }

  @override
  Future<Result<int, DatabaseFailure>> insertTemplateResult(MealTemplate template) async {
    try {
      final res = await insertTemplate(template);
      return Result.ok(res);
    } catch (e, stack) {
      return Result.err(DatabaseFailure(message: 'Error al persistir plantilla: $e', cause: e, stackTrace: stack));
    }
  }

  @override
  Future<Result<List<MealTemplate>, DatabaseFailure>> getAllTemplatesResult() async {
    try {
      final templates = await getAllTemplates();
      return Result.ok(templates);
    } catch (e, stack) {
      return Result.err(DatabaseFailure(message: 'Error al obtener plantillas: $e', cause: e, stackTrace: stack));
    }
  }

  @override
  Future<Result<List<MealTemplate>, DatabaseFailure>> getTemplatesByMealTypeResult(String mealType) async {
    try {
      final templates = await getTemplatesByMealType(mealType);
      return Result.ok(templates);
    } catch (e, stack) {
      return Result.err(DatabaseFailure(message: 'Error al obtener plantillas por tipo: $e', cause: e, stackTrace: stack));
    }
  }
}
