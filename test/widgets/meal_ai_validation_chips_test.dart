import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/theme_manager.dart';
import 'package:food_tracker/widgets/meal_detail/meal_ai_validation_chips.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('MealAiValidationChips Widget Tests', () {
    testWidgets('renders empty shrink widget when both metrics are null', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const MealAiValidationChips(
          confidencePercentage: null,
          calorieErrorMargin: null,
        ),
      ));

      expect(find.byType(MealAiValidationChips), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
      expect(find.byIcon(Icons.verified_outlined), findsNothing);
      expect(find.byIcon(Icons.tune), findsNothing);
    });

    testWidgets('renders green confidence chip for high confidence (>= 85)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const MealAiValidationChips(
          confidencePercentage: 90,
          calorieErrorMargin: null,
        ),
      ));

      expect(find.text('90% Certeza'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsNothing);

      final icon = tester.widget<Icon>(find.byIcon(Icons.verified_outlined));
      expect(icon.color, equals(AppColors.success));
    });

    testWidgets('renders amber confidence chip for medium confidence (>= 70 and < 85)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const MealAiValidationChips(
          confidencePercentage: 75,
          calorieErrorMargin: null,
        ),
      ));

      expect(find.text('75% Certeza'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.verified_outlined));
      expect(icon.color, equals(AppColors.carbs));
    });

    testWidgets('renders orange confidence chip for lower confidence (< 70)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const MealAiValidationChips(
          confidencePercentage: 62,
          calorieErrorMargin: null,
        ),
      ));

      expect(find.text('62% Certeza'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.verified_outlined));
      expect(icon.color, equals(AppColors.caloriesFlame));
    });

    testWidgets('renders error margin chip with tune icon and ±kcal', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const MealAiValidationChips(
          confidencePercentage: null,
          calorieErrorMargin: 45,
        ),
      ));

      expect(find.text('±45 kcal'), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsNothing);

      final icon = tester.widget<Icon>(find.byIcon(Icons.tune));
      expect(icon.color, equals(AppColors.portion));
    });

    testWidgets('renders both confidence and margin chips when both provided', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const MealAiValidationChips(
          confidencePercentage: 92,
          calorieErrorMargin: 50,
        ),
      ));

      expect(find.text('92% Certeza'), findsOneWidget);
      expect(find.text('±50 kcal'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });
  });
}
