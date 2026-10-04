import 'package:sqflite/sqflite.dart';

/// Database schema definitions, DDL migrations, and index configurations.
class DatabaseSchema {
  static Future<void> createAllTables(DatabaseExecutor db) async {
    await createMealsTable(db);
    await createMealItemsTable(db);
    await createPantryTable(db);
    await createWeightLogsTable(db);
    await createUserProfileTable(db);
    await createDishwareTable(db);
    await createMealTemplatesTable(db);
    await createFastingLogsTable(db);
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
        fiber REAL NOT NULL DEFAULT 0.0,
        sodium REAL NOT NULL DEFAULT 0.0,
        sugar REAL NOT NULL DEFAULT 0.0,
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
        fiber REAL NOT NULL DEFAULT 0.0,
        sodium REAL NOT NULL DEFAULT 0.0,
        sugar REAL NOT NULL DEFAULT 0.0,
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
        serving_size REAL DEFAULT 100.0,
        serving_unit TEXT DEFAULT 'g',
        fiber REAL DEFAULT 0.0,
        sodium REAL DEFAULT 0.0,
        sugar REAL DEFAULT 0.0,
        barcode TEXT,
        nutrition_label_image_path TEXT,
        is_verified_by_user INTEGER DEFAULT 0,
        match_keywords TEXT,
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

  static Future<void> createDishwareTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS calibrated_dishware (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        diameter_cm REAL NOT NULL,
        depth_cm REAL DEFAULT 0.0,
        shape TEXT NOT NULL DEFAULT 'circle',
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> createMealTemplatesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL DEFAULT 0.0,
        sodium REAL DEFAULT 0.0,
        sugar REAL DEFAULT 0.0,
        items_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> createFastingLogsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fasting_logs (
        id TEXT PRIMARY KEY,
        start_time TEXT NOT NULL,
        target_hours REAL NOT NULL DEFAULT 16.0,
        end_time TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_calibrated_dishware_default ON calibrated_dishware(is_default);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meal_templates_meal_type ON meal_templates(meal_type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fasting_logs_start ON fasting_logs(start_time);');
  }

  static Future<void> _safeAddColumn(DatabaseExecutor db, String table, String colDef) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $colDef;');
    } catch (_) {
      // Column may already exist or table already upgraded.
    }
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await createWeightLogsTable(db);
      await createUserProfileTable(db);
      await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);');
    }
    if (oldVersion < 3) {
      await _safeAddColumn(db, 'meals', 'fiber REAL NOT NULL DEFAULT 0.0');
      await _safeAddColumn(db, 'meals', 'sodium REAL NOT NULL DEFAULT 0.0');
      await _safeAddColumn(db, 'meals', 'sugar REAL NOT NULL DEFAULT 0.0');

      await _safeAddColumn(db, 'meal_items', 'fiber REAL NOT NULL DEFAULT 0.0');
      await _safeAddColumn(db, 'meal_items', 'sodium REAL NOT NULL DEFAULT 0.0');
      await _safeAddColumn(db, 'meal_items', 'sugar REAL NOT NULL DEFAULT 0.0');

      await _safeAddColumn(db, 'pantry_items', 'serving_size REAL DEFAULT 100.0');
      await _safeAddColumn(db, 'pantry_items', 'serving_unit TEXT DEFAULT \'g\'');
      await _safeAddColumn(db, 'pantry_items', 'fiber REAL DEFAULT 0.0');
      await _safeAddColumn(db, 'pantry_items', 'sodium REAL DEFAULT 0.0');
      await _safeAddColumn(db, 'pantry_items', 'sugar REAL DEFAULT 0.0');
      await _safeAddColumn(db, 'pantry_items', 'barcode TEXT');
      await _safeAddColumn(db, 'pantry_items', 'nutrition_label_image_path TEXT');
      await _safeAddColumn(db, 'pantry_items', 'is_verified_by_user INTEGER DEFAULT 0');
      await _safeAddColumn(db, 'pantry_items', 'match_keywords TEXT');

      await createDishwareTable(db);
      await createMealTemplatesTable(db);
      await createFastingLogsTable(db);

      await db.execute('CREATE INDEX IF NOT EXISTS idx_calibrated_dishware_default ON calibrated_dishware(is_default);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_meal_templates_meal_type ON meal_templates(meal_type);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_fasting_logs_start ON fasting_logs(start_time);');
    }
  }
}
