import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/meal_detail/meal_ai_reanalyze_button.dart';

void main() {
  group('MealAiReanalyzeButton Widget Tests', () {
    testWidgets('renders idle state with icon and text, triggers onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealAiReanalyzeButton(
              isReanalyzing: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Re-analizar con correcciones'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(OutlinedButton));
      expect(pressed, isTrue);
    });

    testWidgets('renders loading state when isReanalyzing is true and disables tap', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealAiReanalyzeButton(
              isReanalyzing: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Re-analizando con IA...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
      expect(pressed, isFalse);
    });
  });
}
