import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/daily_goals.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/widgets/metrics/weekly_digest_card.dart';

void main() {
  group('WeeklyDigestCard Widget Tests', () {
    testWidgets('renders weekly stats and macro consistency bars', (tester) async {
      final now = DateTime.now();
      final meals = [
        Meal(name: 'Pollo', calories: 600, protein: 45, carbs: 50, fat: 15, date: now),
        Meal(name: 'Arroz', calories: 400, protein: 10, carbs: 70, fat: 5, date: now.subtract(const Duration(days: 1))),
      ];
      const goals = DailyGoals(calories: 2000, protein: 150, carbs: 200, fat: 60);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyDigestCard(
              meals: meals,
              goals: goals,
            ),
          ),
        ),
      );

      expect(find.text('RESUMEN SEMANAL (7 DÍAS)'), findsOneWidget);
      expect(find.text('Promedio diario'), findsOneWidget);
      expect(find.text('Balance Neto Semanal'), findsOneWidget);
      expect(find.text('Proteína'), findsOneWidget);
      expect(find.text('Carbohidratos'), findsOneWidget);
      expect(find.text('Grasa'), findsOneWidget);
    });

    testWidgets('renders on narrow 320dp viewport without horizontal overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const goals = DailyGoals(calories: 2000, protein: 150, carbs: 200, fat: 60);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyDigestCard(
                meals: [],
                goals: goals,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('RESUMEN SEMANAL (7 DÍAS)'), findsOneWidget);
      expect(find.text('0 / 7 días con registro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
