import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/meal.dart';
import '../models/pantry_item.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static Future<Database>? _initFuture;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  @visibleForTesting
  void setDatabaseForTesting(Database db) {
    _database = db;
    _initFuture = Future.value(db);
  }

  @visibleForTesting
  Future<void> closeForTesting() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
    _initFuture = null;
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    if (_initFuture != null) {
      return await _initFuture!;
    }
    _initFuture = _initDatabase();
    try {
      _database = await _initFuture!;
      return _database!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'app_food_tracker.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode = WAL;');
        await db.execute('PRAGMA synchronous = NORMAL;');
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        date TEXT NOT NULL,
        image_path TEXT,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        notes TEXT,
        ai_breakdown_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pantry_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT,
        category TEXT,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createIndices(db);
  }

  Future<void> _createIndices(DatabaseExecutor db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON meals(meal_type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date_type ON meals(date, meal_type);');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_name ON pantry_items(name COLLATE NOCASE);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_category ON pantry_items(category);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_favorite ON pantry_items(is_favorite);');
  }

  Future<int> insertMeal(Meal meal) async {
    final db = await database;
    return await db.insert(
      'meals',
      meal.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateMeal(Meal meal) async {
    final db = await database;
    return await db.update(
      'meals',
      meal.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  Future<int> deleteMeal(String id) async {
    final db = await database;
    return await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  Future<Meal?> getMealById(String id) async {
    final db = await database;
    final results = await db.query(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Meal.fromSqliteMap(results.first);
  }

  Future<List<Meal>> getMealsForDay(DateTime day) async {
    final db = await database;
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

  Future<List<Meal>> getAllMeals() async {
    final db = await database;
    final results = await db.query('meals', orderBy: 'date DESC');
    return results.map((m) => Meal.fromSqliteMap(m)).toList();
  }

  Future<int> insertPantryItem(PantryItem item) async {
    final db = await database;
    return await db.insert(
      'pantry_items',
      item.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePantryItem(PantryItem item) async {
    final db = await database;
    return await db.update(
      'pantry_items',
      item.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deletePantryItem(String id) async {
    final db = await database;
    return await db.delete('pantry_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PantryItem>> getPantryItems({
    String? query,
    String? category,
    bool? onlyFavorites,
  }) async {
    final db = await database;
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

  Future<void> executeVacuum() async {
    final db = await database;
    await db.execute('VACUUM;');
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    final mealsCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM meals;');
    final mealsCount = Sqflite.firstIntValue(mealsCountRes) ?? 0;

    final pantryCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM pantry_items;');
    final pantryCount = Sqflite.firstIntValue(pantryCountRes) ?? 0;

    int fileSizeBytes = 0;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = p.join(directory.path, 'app_food_tracker.db');
      final file = File(dbPath);
      if (await file.exists()) {
        fileSizeBytes = await file.length();
      }
    } catch (_) {}

    return {
      'meals_count': mealsCount,
      'pantry_count': pantryCount,
      'file_size_bytes': fileSizeBytes,
      'file_size_kb': (fileSizeBytes / 1024).toStringAsFixed(1),
    };
  }
}
