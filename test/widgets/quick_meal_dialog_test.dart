import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/widgets/dashboard/quick_meal_dialog.dart';

void main() {
  group('QuickMealDialog Widget Tests', () {
    testWidgets('shows dialog and returns quick meal on submit', (tester) async {
      Meal? returnedMeal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedMeal = await showQuickMealDialog(context);
                },
                child: const Text('Open Quick Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Quick Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Comida Rápida'), findsOneWidget);
      expect(find.text('Añadir'), findsOneWidget);

      await tester.tap(find.text('Añadir'));
      await tester.pumpAndSettle();

      expect(returnedMeal, isNotNull);
      expect(returnedMeal!.name, equals('Comida rápida'));
      expect(returnedMeal!.calories, equals(300.0));
      expect(returnedMeal!.mealType, equals('Snack'));
    });
  });
}
