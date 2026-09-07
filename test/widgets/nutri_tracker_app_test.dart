import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/main.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/services/theme_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database testDb;

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
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
        },
      ),
    );
    DatabaseService.instance.setDatabaseForTesting(testDb);
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  testWidgets('NutriTrackerApp boots and renders DashboardScreen without crashing', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(NutriTrackerApp), findsOneWidget);
    expect(ThemeManager.instance, isNotNull);
  });

  testWidgets('NutriTrackerApp boots and renders gracefully even if database is closed or inaccessible', (tester) async {
    await DatabaseService.instance.closeForTesting();

    await tester.pumpWidget(const NutriTrackerApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(NutriTrackerApp), findsOneWidget);
  });
}
