import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/controllers/meal_controller.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/widgets/metrics/quick_weight_entry_dialog.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database testDb;

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(
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
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('QuickWeightEntryDialog Widget Tests', () {
    testWidgets('shows dialog with prefilled weight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showQuickWeightEntryDialog(
                  context,
                  initialWeight: 82.5,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Peso'), findsOneWidget);
      expect(find.text('82.5'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('shows inline validation error for out-of-bounds weight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showQuickWeightEntryDialog(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter weight below 20.0
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '15.0');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('El peso debe estar entre 20.0 y 350.0 kg'), findsOneWidget);

      // Enter weight above 350.0
      await tester.enterText(textField, '400.0');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('El peso debe estar entre 20.0 y 350.0 kg'), findsOneWidget);
    });

    testWidgets('cancels dialog without saving when Cancelar is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showQuickWeightEntryDialog(context, initialWeight: 75.0),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Peso'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Peso'), findsNothing);
      expect(MealController.instance.weightLogs, isEmpty);
    });

    testWidgets('successfully records valid weight entry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showQuickWeightEntryDialog(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '77.8');
      await tester.enterText(textFields.at(1), 'En ayunas');

      await tester.tap(find.text('Guardar'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Registrar Peso'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('77.8 kg'), findsOneWidget);

      // Verify controller state
      expect(MealController.instance.latestWeightLog, isNotNull);
      expect(MealController.instance.latestWeightLog!.weight, equals(77.8));
      expect(MealController.instance.latestWeightLog!.notes, equals('En ayunas'));
    });
  });
}
