import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/meal.dart';
import '../models/pantry_item.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import 'backup_normalizer.dart';
import 'database_service.dart';

/// Service orchestrating database backup export to physical JSON files and atomic JSON restores.
class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  /// Resolves the dedicated local directory for JSON backups.
  Future<Directory> getBackupDirectory() async {
    // 1. Attempt public Downloads on Android for effortless user visibility
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final foodTrackerDir = Directory(p.join(downloadDir.path, 'FoodTrackerBackups'));
          if (!await foodTrackerDir.exists()) {
            await foodTrackerDir.create(recursive: true);
          }
          return foodTrackerDir;
        }
      } catch (_) {}
    }

    // 2. Fallback to app documents backup folder
    final docs = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docs.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Exports full database snapshot to an indented JSON string.
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

  /// Exports full database snapshot directly into a physical `.json` file.
  Future<File> exportToJsonFile({String? customDirectoryPath}) async {
    final jsonContent = await exportToJsonString();
    final Directory directory;
    if (customDirectoryPath != null) {
      directory = Directory(customDirectoryPath);
    } else {
      directory = await getBackupDirectory();
    }
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = p.join(directory.path, 'food_tracker_backup_$dateStamp.json');
    final file = File(filePath);
    await file.writeAsString(jsonContent, flush: true);
    return file;
  }

  /// Lists all `.json` backup files discovered in the default backup locations, sorted newest first.
  Future<List<File>> listAvailableBackups({String? customDirectoryPath}) async {
    final results = <File>[];
    try {
      if (customDirectoryPath != null) {
        final customDir = Directory(customDirectoryPath);
        if (await customDir.exists()) {
          for (final e in customDir.listSync()) {
            if (e is File && e.path.toLowerCase().endsWith('.json')) {
              results.add(e);
            }
          }
        }
        return results;
      }

      final backupDir = await getBackupDirectory();
      if (await backupDir.exists()) {
        final entities = backupDir.listSync();
        for (final e in entities) {
          if (e is File && e.path.toLowerCase().endsWith('.json')) {
            results.add(e);
          }
        }
      }

      // Also scan documents directory
      final docs = await getApplicationDocumentsDirectory();
      if (await docs.exists()) {
        final entities = docs.listSync();
        for (final e in entities) {
          if (e is File && e.path.toLowerCase().endsWith('.json') && !results.any((r) => r.path == e.path)) {
            results.add(e);
          }
        }
      }
    } catch (_) {}

    // Sort newest first by last modified time
    results.sort((a, b) {
      try {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      } catch (_) {
        return 0;
      }
    });

    return results;
  }

  /// Inspects a backup file and returns metadata preview without executing changes.
  Future<Map<String, dynamic>> inspectBackupFile(File file) async {
    final content = await file.readAsString();
    final normalized = await Isolate.run(
      () => BackupNormalizer.decodeAndNormalize(content),
    );

    return {
      'path': file.path,
      'filename': p.basename(file.path),
      'size_bytes': await file.length(),
      'export_date': normalized['export_date'],
      'meals_count': (normalized['meals'] as List?)?.length ?? 0,
      'pantry_count': (normalized['pantry_items'] as List?)?.length ?? 0,
      'weight_logs_count': (normalized['weight_logs'] as List?)?.length ?? 0,
      'has_user_profile': normalized['user_profile'] != null,
    };
  }

  /// Restores database content directly from a physical `.json` file.
  Future<Map<String, int>> importFromFile(File file) async {
    final content = await file.readAsString();
    return await importFromJsonString(content);
  }

  /// Restores database content from raw JSON string with SQLite transaction guarantees.
  Future<Map<String, int>> importFromJsonString(String jsonContent) async {
    final normalized = await Isolate.run(
      () => BackupNormalizer.decodeAndNormalize(jsonContent),
    );

    final db = await DatabaseService.instance.database;
    int importedMeals = 0;
    int importedPantry = 0;
    int importedWeightLogs = 0;
    int importedUserProfile = 0;

    await db.transaction((txn) async {
      final batch = txn.batch();

      final meals = normalized['meals'];
      if (meals is List) {
        for (final item in meals) {
          if (item is Map) {
            final meal = Meal.fromJson(Map<String, dynamic>.from(item));
            batch.insert('meals', meal.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
            importedMeals++;
          }
        }
      }

      final pantry = normalized['pantry_items'];
      if (pantry is List) {
        for (final item in pantry) {
          if (item is Map) {
            final pItem = PantryItem.fromJson(Map<String, dynamic>.from(item));
            batch.insert('pantry_items', pItem.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
            importedPantry++;
          }
        }
      }

      final weightLogs = normalized['weight_logs'];
      if (weightLogs is List) {
        for (final item in weightLogs) {
          if (item is Map) {
            final wLog = WeightLog.fromJson(Map<String, dynamic>.from(item));
            batch.insert('weight_logs', wLog.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
            importedWeightLogs++;
          }
        }
      }

      final userProfile = normalized['user_profile'];
      if (userProfile is Map) {
        final profile = UserProfile.fromJson(Map<String, dynamic>.from(userProfile));
        batch.insert('user_profile', profile.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        importedUserProfile = 1;
      }

      await batch.commit(noResult: true);
    });

    return {
      'imported_meals': importedMeals,
      'imported_pantry': importedPantry,
      'imported_weight_logs': importedWeightLogs,
      'imported_user_profile': importedUserProfile,
    };
  }
}
