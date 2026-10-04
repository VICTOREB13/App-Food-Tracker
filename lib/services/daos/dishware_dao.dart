import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/interfaces/dishware_dao_interface.dart';
import '../../models/calibrated_dishware.dart';

/// Data Access Object for calibrated dishware catalog and reference sizing.
class DishwareDao implements IDishwareDao {
  final Future<Database> Function() _getDatabase;

  DishwareDao(this._getDatabase);

  @override
  Future<int> insertDishware(CalibratedDishware dishware) async {
    final db = await _getDatabase();
    return await db.insert(
      'calibrated_dishware',
      dishware.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateDishware(CalibratedDishware dishware) async {
    final db = await _getDatabase();
    return await db.update(
      'calibrated_dishware',
      dishware.toMap(),
      where: 'id = ?',
      whereArgs: [dishware.id],
    );
  }

  @override
  Future<int> deleteDishware(String id) async {
    final db = await _getDatabase();
    return await db.delete('calibrated_dishware', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<CalibratedDishware?> getDishwareById(String id) async {
    final db = await _getDatabase();
    final results = await db.query(
      'calibrated_dishware',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CalibratedDishware.fromMap(results.first);
  }

  @override
  Future<List<CalibratedDishware>> getAllDishware() async {
    final db = await _getDatabase();
    final results = await db.query('calibrated_dishware', orderBy: 'is_default DESC, name ASC');
    return results.map((m) => CalibratedDishware.fromMap(m)).toList();
  }

  @override
  Future<CalibratedDishware?> getDefaultDishware() async {
    final db = await _getDatabase();
    final results = await db.query(
      'calibrated_dishware',
      where: 'is_default = 1',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CalibratedDishware.fromMap(results.first);
  }

  @override
  Future<void> setDefaultDishware(String id) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.update('calibrated_dishware', {'is_default': 0});
      await txn.update(
        'calibrated_dishware',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<Result<int, DatabaseFailure>> insertDishwareResult(CalibratedDishware dishware) async {
    try {
      final res = await insertDishware(dishware);
      return Result.ok(res);
    } catch (e, stack) {
      return Result.err(DatabaseFailure(message: 'Error al persistir vajilla: $e', cause: e, stackTrace: stack));
    }
  }

  @override
  Future<Result<List<CalibratedDishware>, DatabaseFailure>> getAllDishwareResult() async {
    try {
      final items = await getAllDishware();
      return Result.ok(items);
    } catch (e, stack) {
      return Result.err(DatabaseFailure(message: 'Error al obtener vajillas: $e', cause: e, stackTrace: stack));
    }
  }

  @override
  Future<Result<CalibratedDishware?, DatabaseFailure>> getDefaultDishwareResult() async {
    try {
      final item = await getDefaultDishware();
      return Result.ok(item);
    } catch (e, stack) {
      return Result.err(DatabaseFailure(message: 'Error al obtener vajilla por defecto: $e', cause: e, stackTrace: stack));
    }
  }
}
