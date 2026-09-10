import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/widgets/dashboard/meal_section_card.dart';

void main() {
  group('MealSectionCard Widget Tests', () {
    testWidgets('MealSectionCard without meals renders empty label without Divider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSectionCard(
              mealType: 'Desayuno',
              meals: const [],
              onMealTap: (_) {},
              onAddMeal: () {},
            ),
          ),
        ),
      );

      expect(find.text('Desayuno'), findsOneWidget);
      expect(find.text('Sin registros en esta comida.'), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('MealSectionCard with meals renders meal tiles without redundant dividing line', (tester) async {
      final sampleMeal = Meal(
        name: 'Arroz con Pollo',
        mealType: 'Almuerzo',
        calories: 585,
        protein: 38,
        carbs: 62,
        fat: 19,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSectionCard(
              mealType: 'Almuerzo',
              meals: [sampleMeal],
              onMealTap: (_) {},
              onAddMeal: () {},
            ),
          ),
        ),
      );

      expect(find.text('Almuerzo'), findsOneWidget);
      expect(find.text('585 kcal'), findsOneWidget);
      expect(find.text('Arroz con Pollo'), findsOneWidget);
      // Ensures the redundant gray line above food items is removed for visual cohesion
      expect(find.byType(Divider), findsNothing);
    });
  });
}
