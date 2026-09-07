import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/daily_goals.dart';
import 'package:food_tracker/services/theme_manager.dart';
import 'package:food_tracker/widgets/dashboard/daily_calorie_summary_card.dart';

void main() {
  testWidgets('DailyCalorieSummaryCard muestra calorias y macros correctamente', (tester) async {
    const goals = DailyGoals(
      calories: 2000,
      protein: 150,
      carbs: 200,
      fat: 65,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: DailyCalorieSummaryCard(
            currentCalories: 1450,
            currentProtein: 110,
            currentCarbs: 160,
            currentFat: 45,
            goals: goals,
          ),
        ),
      ),
    );

    expect(find.text('RESUMEN DEL DÍA'), findsOneWidget);
    expect(find.text('1450'), findsOneWidget);
    expect(find.text('/ 2000 kcal'), findsOneWidget);
    expect(find.text('550 restantes'), findsOneWidget);
    expect(find.text('Proteína'), findsOneWidget);
    expect(find.text('Carbos'), findsOneWidget);
    expect(find.text('Grasas'), findsOneWidget);
  });
}
