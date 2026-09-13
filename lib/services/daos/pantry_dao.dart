import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/interfaces/daos_interfaces.dart';
import '../../models/pantry_item.dart';

/// Data Access Object for pantry catalog and favorites.
class PantryDao implements IPantryDao {
  final Future<Database> Function() _getDatabase;

  PantryDao(this._getDatabase);

  @override
  Future<int> insertPantryItem(PantryItem item) async {
    final db = await _getDatabase();
    return await db.insert(
      'pantry_items',
      item.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updatePantryItem(PantryItem item) async {
    final db = await _getDatabase();
    return await db.update(
      'pantry_items',
      item.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<int> deletePantryItem(String id) async {
    final db = await _getDatabase();
    return await db.delete('pantry_items', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<PantryItem>> getPantryItems({
    String? query,
    String? category,
    bool? onlyFavorites,
  }) async {
    final db = await _getDatabase();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR brand LIKE ?)');
      whereArgs.add('%${query.trim()}%');
      whereArgs.add('%${query.trim()}%');
    }

    if (category != null && category.trim().isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category.trim());
    }

    if (onlyFavorites == true) {
      whereClauses.add('is_favorite = 1');
    }

    final whereString = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final results = await db.query(
      'pantry_items',
      where: whereString,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'is_favorite DESC, name ASC',
    );

    return results.map((p) => PantryItem.fromSqliteMap(p)).toList();
  }

  // ==========================================
  // FUNCTIONAL RESULT APIS
  // ==========================================

  @override
  Future<Result<int, DatabaseFailure>> insertPantryItemResult(PantryItem item) async {
    try {
      final id = await insertPantryItem(item);
      return Result.ok(id);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(
          message: 'Error al persistir artículo de despensa: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<PantryItem>, DatabaseFailure>> getPantryItemsResult({
    String? query,
    String? category,
    bool? onlyFavorites,
  }) async {
    try {
      final items = await getPantryItems(
        query: query,
        category: category,
        onlyFavorites: onlyFavorites,
      );
      return Result.ok(items);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(
          message: 'Error al consultar despensa: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }
}
