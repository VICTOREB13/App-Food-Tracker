import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/meal.dart';
import '../models/pantry_item.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  Future<String> exportToJsonString() async {
    final dbService = DatabaseService.instance;
    final meals = await dbService.getAllMeals();
    final pantry = await dbService.getPantryItems();
    final weightLogs = await dbService.getAllWeightLogs();
    final userProfile = await dbService.getUserProfile();

    final exportData = {
      'app': 'Victor Engineer Food Tracker',
      'version': '2.0.0',
      'schema_version': 2,
      'export_date': DateTime.now().toIso8601String(),
      'meals_count': meals.length,
      'pantry_count': pantry.length,
      'weight_logs_count': weightLogs.length,
      'has_user_profile': userProfile != null,
      'meals': meals.map((m) => m.toJson()).toList(),
      'pantry_items': pantry.map((p) => p.toJson()).toList(),
      'weight_logs': weightLogs.map((w) => w.toJson()).toList(),
      'user_profile': userProfile?.toJson(),
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
    int importedWeightLogs = 0;
    int importedUserProfile = 0;

    await db.transaction((txn) async {
      // 1. Restore Meals
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

      // 2. Restore Pantry Items
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

      // 3. Restore Weight Logs (Phase 2)
      if (decoded['weight_logs'] is List) {
        for (final item in decoded['weight_logs']) {
          if (item is Map<String, dynamic>) {
            final weightLog = WeightLog.fromJson(item);
            await txn.insert(
              'weight_logs',
              weightLog.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            importedWeightLogs++;
          }
        }
      }

      // 4. Restore User Profile (Phase 2)
      if (decoded['user_profile'] is Map<String, dynamic>) {
        final profile = UserProfile.fromJson(decoded['user_profile'] as Map<String, dynamic>);
        await txn.insert(
          'user_profile',
          profile.toSqliteMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        importedUserProfile = 1;
      }
    });

    return {
      'imported_meals': importedMeals,
      'imported_pantry': importedPantry,
      'imported_weight_logs': importedWeightLogs,
      'imported_user_profile': importedUserProfile,
    };
  }
}
