import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/models/daily_goals.dart';
import 'package:food_tracker/models/user_profile.dart';
import 'package:food_tracker/services/daos/database_schema.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/widgets/recommendations/recommendation_diagnostic_card.dart';
import 'package:food_tracker/widgets/recommendations/what_to_eat_sheet.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    setupServiceLocator(isTesting: true);
  });

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await DatabaseSchema.createAllTables(db);
        },
      ),
    );

    DatabaseService.instance.setDatabaseForTesting(db);
    await DatabaseService.instance.saveUserProfile(
      UserProfile(
        name: 'Victor UI Test',
        age: 28,
        gender: 'male',
        height: 178,
        weight: 78,
        targetCalories: 2000,
        targetProtein: 140,
        targetCarbs: 220,
        targetFat: 60,
      ),
    );
  });

  tearDown(() async {
    await DatabaseService.instance.closeForTesting();
  });

  group('Recommendation Widgets UI Tests', () {
    testWidgets('WhatToEatSheet renders remaining macros and dish recommendations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhatToEatSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('¿Qué debería comer hoy?'), findsOneWidget);
      expect(find.text('Margen restante de hoy:'), findsOneWidget);
      expect(find.text('Calorías'), findsOneWidget);
      expect(find.text('Proteína'), findsOneWidget);
      expect(find.text('Carbos'), findsOneWidget);
      expect(find.text('Grasas'), findsOneWidget);
      expect(find.text('Platos recomendados a tu medida:'), findsOneWidget);
      expect(find.text('Pechuga de Pollo con Quinoa y Espárragos'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('RecommendationDiagnosticCard renders period chips and macro gauges', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecommendationDiagnosticCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MOTOR DE RECOMENDACIÓN NUTRICIONAL'), findsOneWidget);
      expect(find.text('7 días'), findsOneWidget);
      expect(find.text('15 días'), findsOneWidget);
      expect(find.text('30 días'), findsOneWidget);
      expect(find.text('Control de Grasas'), findsOneWidget);
      expect(find.text('Metas de Proteína'), findsOneWidget);
      expect(find.text('Energía y Carbohidratos'), findsOneWidget);
      expect(find.text('Sustituciones Inteligentes Sugeridas:'), findsOneWidget);

      // Tap 15 days chip
      await tester.tap(find.text('15 días'));
      await tester.pumpAndSettle();
      expect(find.text('Control de Grasas'), findsOneWidget);
    });
  });
}
