import 'package:sqflite/sqflite.dart';

/// Database schema definitions, DDL migrations, and index configurations.
class DatabaseSchema {
  static Future<void> createAllTables(Database db) async {
    await createMealsTable(db);
    await createMealItemsTable(db);
    await createPantryTable(db);
    await createWeightLogsTable(db);
    await createUserProfileTable(db);
    await createIndices(db);
  }

  static Future<void> createMealsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meals (
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
  }

  static Future<void> createMealItemsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_items (
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meal_items_meal_id ON meal_items(meal_id);');
  }

  static Future<void> createPantryTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pantry_items (
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
  }

  static Future<void> createWeightLogsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weight_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        notes TEXT
      )
    ''');
  }

  static Future<void> createUserProfileTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id TEXT PRIMARY KEY,
        name TEXT,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        activity_level TEXT NOT NULL,
        body_goal TEXT NOT NULL,
        estimated_steps INTEGER NOT NULL DEFAULT 8000,
        bmr REAL NOT NULL,
        tdee REAL NOT NULL,
        target_calories REAL NOT NULL,
        target_protein REAL NOT NULL,
        target_carbs REAL NOT NULL,
        target_fat REAL NOT NULL,
        master_prompt TEXT,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> createIndices(DatabaseExecutor db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON meals(meal_type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date_type ON meals(date, meal_type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_name ON pantry_items(name COLLATE NOCASE);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_category ON pantry_items(category);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pantry_favorite ON pantry_items(is_favorite);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await createWeightLogsTable(db);
      await createUserProfileTable(db);
      await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
    }
  }
}
