import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/controllers/meal_controller.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/models/weight_log.dart';
import 'package:food_tracker/screens/metrics_screen.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/widgets/metrics/calorie_compliance_bento_card.dart';
import 'package:food_tracker/widgets/metrics/macro_distribution_bento_card.dart';
import 'package:food_tracker/widgets/metrics/quick_weight_entry_dialog.dart';
import 'package:food_tracker/widgets/metrics/streak_compliance_bento_card.dart';
import 'package:food_tracker/widgets/metrics/weight_trend_bento_card.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late Database testDb;

  setUp(() async {
    testDb = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE weight_logs (
              id TEXT PRIMARY KEY,
              date TEXT NOT NULL,
              weight REAL NOT NULL,
              notes TEXT
            );
          ''');
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
            );
          ''');
        },
      ),
    );
    DatabaseService.instance.setDatabaseForTesting(testDb);

    // Seed sample weight logs
    final now = DateTime.now();
    await DatabaseService.instance.insertWeightLog(
      WeightLog(
        id: 'w1',
        weight: 80.0,
        date: now.subtract(const Duration(days: 15)),
      ),
    );
    await DatabaseService.instance.insertWeightLog(
      WeightLog(
        id: 'w2',
        weight: 78.5,
        date: now.subtract(const Duration(days: 2)),
      ),
    );

    // Seed sample meals
    await DatabaseService.instance.insertMeal(
      Meal(
        id: 'm1',
        name: 'Avena con Proteína',
        mealType: 'Desayuno',
        date: now.subtract(const Duration(days: 1)),
        calories: 450,
        protein: 35,
        carbs: 55,
        fat: 10,
      ),
    );
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('MetricsScreen Widget Tests', () {
    testWidgets('renders all essential bento cards and controls', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MetricsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check App Bar
      expect(find.text('Métricas y Progreso'), findsOneWidget);
      expect(find.text('Analítica Local-First'), findsOneWidget);

      // Check Range Chips
      expect(find.text('7 días'), findsOneWidget);
      expect(find.text('30 días'), findsOneWidget);
      expect(find.text('90 días'), findsOneWidget);

      // Check Bento Cards
      expect(find.byType(WeightTrendBentoCard), findsOneWidget);
      expect(find.byType(CalorieComplianceBentoCard), findsOneWidget);
      expect(find.byType(StreakComplianceBentoCard), findsOneWidget);
      expect(find.byType(MacroDistributionBentoCard), findsOneWidget);

      // Check FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Registrar Peso'), findsWidgets);
    });

    testWidgets('range filter switches correctly between 7, 30 and 90 days', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MetricsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Default is 30 days
      expect(MealController.instance.selectedWeightDays, equals(30));

      // Switch to 7 days
      await tester.tap(find.text('7 días'));
      await tester.pumpAndSettle();
      expect(MealController.instance.selectedWeightDays, equals(7));

      // Switch to 90 days
      await tester.tap(find.text('90 días'));
      await tester.pumpAndSettle();
      expect(MealController.instance.selectedWeightDays, equals(90));
    });

    testWidgets('tapping FAB opens QuickWeightEntryDialog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MetricsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(QuickWeightEntryDialog), findsOneWidget);
      expect(find.text('PESO CORPORAL (KG)'), findsOneWidget);
    });
  });
}
