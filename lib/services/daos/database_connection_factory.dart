import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_schema.dart';

/// Handles SQLite database path resolution, initialization, and pragma configuration.
class DatabaseConnectionFactory {
  static Future<String> getDatabasePath() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final directory = await getApplicationDocumentsDirectory();
      try {
        final dir = Directory(directory.path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } catch (_) {}
      return p.join(directory.path, 'app_food_tracker.db');
    } else {
      try {
        final databasesPath = await getDatabasesPath();
        try {
          final dir = Directory(databasesPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        } catch (_) {}
        return p.join(databasesPath, 'app_food_tracker.db');
      } catch (e) {
        debugPrint('Warning: getDatabasesPath failed ($e), falling back to documents');
        final directory = await getApplicationDocumentsDirectory();
        try {
          final dir = Directory(directory.path);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        } catch (_) {}
        return p.join(directory.path, 'app_food_tracker.db');
      }
    }
  }

  static Future<Database> openFoodTrackerDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasePath();

    return await openDatabase(
      dbPath,
      version: 2,
      onConfigure: configurePragmas,
      onCreate: (db, version) => DatabaseSchema.createAllTables(db),
      onUpgrade: DatabaseSchema.onUpgrade,
    );
  }

  static Future<void> configurePragmas(Database db) async {
    try {
      await db.rawQuery('PRAGMA journal_mode = WAL;');
    } catch (e) {
      debugPrint('Warning: Failed to set PRAGMA journal_mode: $e');
    }

    try {
      await db.execute('PRAGMA synchronous = NORMAL;');
    } catch (e) {
      debugPrint('Warning: Failed to set PRAGMA synchronous: $e');
    }

    try {
      await db.execute('PRAGMA foreign_keys = ON;');
    } catch (e) {
      debugPrint('Warning: Failed to set PRAGMA foreign_keys: $e');
    }
  }
}
