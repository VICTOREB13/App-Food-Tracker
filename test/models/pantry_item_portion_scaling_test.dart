import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('PantryItem packageWeight & Sentinel Tests', () {
    test('serialización y deserialización de packageWeight en SQLite map', () {
      final item = PantryItem(
        id: 'p-weight-1',
        name: 'Arroz Diana',
        brand: 'Diana',
        servingSize: 50.0,
        packageWeight: 500.0,
        calories: 175.0,
      );

      final map = item.toSqliteMap();
      expect(map['package_weight'], equals(500.0));

      final restored = PantryItem.fromSqliteMap(map);
      expect(restored.packageWeight, equals(500.0));
      expect(restored.servingSize, equals(50.0));
    });

    test(
        'soporte retrocompatible para claves legadas en español (peso_neto, peso_paquete)',
        () {
      final legacy1 =
          PantryItem.fromSqliteMap({'name': 'Pasta', 'peso_neto': 450.0});
      expect(legacy1.packageWeight, equals(450.0));

      final legacy2 =
          PantryItem.fromSqliteMap({'name': 'Atún', 'peso_paquete': 160.0});
      expect(legacy2.packageWeight, equals(160.0));

      final noWeight = PantryItem.fromSqliteMap({'name': 'Sin peso'});
      expect(noWeight.packageWeight, isNull);
    });

    test('copyWith con Sentinel permite actualizar o limpiar packageWeight a null',
        () {
      final item = PantryItem(
        name: 'Cereal',
        packageWeight: 400.0,
      );

      final updated = item.copyWith(packageWeight: 800.0);
      expect(updated.packageWeight, equals(800.0));

      final cleared = item.copyWith(packageWeight: null);
      expect(cleared.packageWeight, isNull);

      final unchanged = item.copyWith(name: 'Nuevo Nombre');
      expect(unchanged.packageWeight, equals(400.0));
      expect(unchanged.name, equals('Nuevo Nombre'));
    });
  });

  group('PantryItem toScaledFoodItem Tests', () {
    test(
        'escala proporcionalmente macros y calorías según gramos consumidos (factor 1.5x)',
        () {
      final pantry = PantryItem(
        name: 'Yogurt Griego',
        brand: 'Chobani',
        servingSize: 100.0,
        servingUnit: 'g',
        packageWeight: 900.0,
        calories: 120.0,
        protein: 16.0,
        carbs: 6.0,
        fat: 4.0,
        fiber: 1.0,
        sodium: 50.0,
        sugar: 4.0,
      );

      final foodItem = pantry.toScaledFoodItem(gramsConsumed: 150.0);

      expect(foodItem.name, equals('Yogurt Griego (Chobani)'));
      expect(foodItem.estimatedGrams, equals(150.0));
      expect(foodItem.calories, equals(180.0)); // 120 * 1.5
      expect(foodItem.protein, equals(24.0)); // 16 * 1.5
      expect(foodItem.carbs, equals(9.0)); // 6 * 1.5
      expect(foodItem.fat, equals(6.0)); // 4 * 1.5
      expect(foodItem.fiber, equals(1.5)); // 1 * 1.5
      expect(foodItem.sodium, equals(75.0)); // 50 * 1.5
      expect(foodItem.sugar, equals(6.0)); // 4 * 1.5
      expect(foodItem.visualJustification, contains('150g'));
      expect(foodItem.visualJustification, contains('100g'));
    });

    test('escala correctamente con servingSize distinto de 100g (ej. 30g scoop)',
        () {
      final whey = PantryItem(
        name: 'Proteína Whey',
        servingSize: 30.0,
        calories: 120.0,
        protein: 24.0,
        carbs: 2.0,
        fat: 1.5,
      );

      // Consumo de 60g -> factor 2.0x
      final doublePortion = whey.toScaledFoodItem(gramsConsumed: 60.0);
      expect(doublePortion.calories, equals(240.0));
      expect(doublePortion.protein, equals(48.0));
      expect(doublePortion.carbs, equals(4.0));
      expect(doublePortion.fat, equals(3.0));

      // Consumo de 15g -> factor 0.5x
      final halfPortion = whey.toScaledFoodItem(gramsConsumed: 15.0);
      expect(halfPortion.calories, equals(60.0));
      expect(halfPortion.protein, equals(12.0));
    });

    test('fallback seguro si servingSize es <= 0', () {
      final item = PantryItem(
        name: 'Item especial',
        servingSize: 0.0,
        calories: 200.0,
      );

      final scaled = item.toScaledFoodItem(gramsConsumed: 50.0);
      expect(scaled.estimatedGrams, equals(50.0));
      expect(scaled.calories, greaterThan(0.0));
    });
  });

  group('SQLite Migration v3 -> v4 Tests', () {
    test('onUpgrade añade columna package_weight sin pérdida de datos en v4',
        () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, v) async {
            // Esquema v3 previo sin package_weight
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
          },
        ),
      );

      // Inserción de registro preexistente en v3
      await db.insert('pantry_items', {
        'id': 'legacy-item-1',
        'name': 'Avena Antigua',
        'calories': 380.0,
        'protein': 14.0,
        'carbs': 60.0,
        'fat': 7.0,
      });

      // Ejecutar migración v3 -> v4
      await DatabaseSchema.onUpgrade(db, 3, 4);

      // Verificar que la columna fue añadida
      final tableInfo = await db.rawQuery('PRAGMA table_info(pantry_items);');
      final hasPackageWeight =
          tableInfo.any((col) => col['name'] == 'package_weight');
      expect(hasPackageWeight, isTrue);

      // El registro existente debe tener package_weight como null
      final rows = await db
          .query('pantry_items', where: 'id = ?', whereArgs: ['legacy-item-1']);
      expect(rows.length, equals(1));
      expect(rows.first['package_weight'], isNull);

      // Insertar nuevo registro v4 con package_weight
      await db.insert('pantry_items', {
        'id': 'v4-item-2',
        'name': 'Avena Nueva v4',
        'calories': 380.0,
        'protein': 14.0,
        'carbs': 60.0,
        'fat': 7.0,
        'package_weight': 500.0,
      });

      final v4Rows = await db
          .query('pantry_items', where: 'id = ?', whereArgs: ['v4-item-2']);
      expect(v4Rows.first['package_weight'], equals(500.0));

      final restoredItem = PantryItem.fromSqliteMap(v4Rows.first);
      expect(restoredItem.packageWeight, equals(500.0));

      await db.close();
    });
  });
}
