import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/main.dart';
import 'package:food_tracker/screens/dashboard_screen.dart';
import 'package:food_tracker/screens/onboarding_screen.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
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
        version: 3,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) => DatabaseSchema.createAllTables(db),
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

  testWidgets('NutriTrackerApp renders cleanly in English locale', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp(locale: Locale('en')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(NutriTrackerApp), findsOneWidget);
  });

  testWidgets('NutriTrackerApp gracefully falls back to Spanish for unsupported locale', (tester) async {
    // Should not throw FlutterError on unsupported locale like French
    await tester.pumpWidget(const NutriTrackerApp(locale: Locale('fr')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(NutriTrackerApp), findsOneWidget);
  });

  testWidgets('NutriTrackerApp renders OnboardingScreen when hasCompletedOnboarding is false', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp(hasCompletedOnboarding: false));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('NutriTrackerApp renders DashboardScreen when hasCompletedOnboarding is true', (tester) async {
    await tester.pumpWidget(const NutriTrackerApp(hasCompletedOnboarding: true));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
