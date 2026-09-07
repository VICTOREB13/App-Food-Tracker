import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/meal.dart';
import '../models/pantry_item.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  Future<String> exportToJsonString() async {
    final dbService = DatabaseService.instance;
    final meals = await dbService.getAllMeals();
    final pantry = await dbService.getPantryItems();

    final exportData = {
      'app': 'Victor Engineer Food Tracker',
      'version': '1.0.0',
      'export_date': DateTime.now().toIso8601String(),
      'meals_count': meals.length,
      'pantry_count': pantry.length,
      'meals': meals.map((m) => m.toJson()).toList(),
      'pantry_items': pantry.map((p) => p.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  Future<Map<String, int>> importFromJsonString(String jsonContent) async {
    final dynamic decoded = json.decode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El archivo de respaldo no tiene el formato JSON esperado.');
    }

    final db = await DatabaseService.instance.database;
    int importedMeals = 0;
    int importedPantry = 0;

    await db.transaction((txn) async {
      if (decoded['meals'] is List) {
        for (final item in decoded['meals']) {
          if (item is Map<String, dynamic>) {
            final meal = Meal.fromJson(item);
            await txn.insert(
              'meals',
              meal.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            importedMeals++;
          }
        }
      }

      if (decoded['pantry_items'] is List) {
        for (final item in decoded['pantry_items']) {
          if (item is Map<String, dynamic>) {
            final pantryItem = PantryItem.fromJson(item);
            await txn.insert(
              'pantry_items',
              pantryItem.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            importedPantry++;
          }
        }
      }
    });

    return {
      'imported_meals': importedMeals,
      'imported_pantry': importedPantry,
    };
  }
}
