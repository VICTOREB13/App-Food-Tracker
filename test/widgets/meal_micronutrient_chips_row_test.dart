import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/meal_detail/meal_micronutrient_chips_row.dart';

void main() {
  testWidgets('MealMicronutrientChipsRow renders nothing when all zero', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MealMicronutrientChipsRow(
            fiber: 0.0,
            sodium: 0.0,
            sugar: 0.0,
          ),
        ),
      ),
    );

    expect(find.byType(MealMicronutrientChipsRow), findsOneWidget);
    expect(find.text('Fibra: '), findsNothing);
    expect(find.text('Sodio: '), findsNothing);
    expect(find.text('Azúcar: '), findsNothing);
  });

  testWidgets('MealMicronutrientChipsRow renders chips when positive values present', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MealMicronutrientChipsRow(
            fiber: 4.5,
            sodium: 320.0,
            sugar: 2.1,
          ),
        ),
      ),
    );

    expect(find.text('Fibra: '), findsOneWidget);
    expect(find.text('4.5g'), findsOneWidget);
    expect(find.text('Sodio: '), findsOneWidget);
    expect(find.text('320mg'), findsOneWidget);
    expect(find.text('Azúcar: '), findsOneWidget);
    expect(find.text('2.1g'), findsOneWidget);
  });
}
