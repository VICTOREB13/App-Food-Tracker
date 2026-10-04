import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/widgets/pantry/pantry_consumption_dialog.dart';

void main() {
  group('PantryConsumptionDialog Widget Tests', () {
    final testItem = PantryItem(
      id: 'p1',
      name: 'Yogur Griego',
      brand: 'Chobani',
      servingSize: 100.0,
      packageWeight: 900.0,
      calories: 100,
      protein: 10.0,
      carbs: 6.0,
      fat: 2.0,
    );

    testWidgets('renders initial 100g portion and live calculated macros', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PantryConsumptionDialog(pantryItem: testItem),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Registrar a Comida'), findsOneWidget);
      expect(find.text('Yogur Griego'), findsOneWidget);
      expect(find.text('Desayuno'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget);
      expect(find.text('Cena'), findsOneWidget);
      expect(find.text('Snack'), findsOneWidget);
      expect(find.byKey(const Key('consumption_grams_input')), findsOneWidget);
      expect(find.text('100 kcal'), findsOneWidget);
      expect(find.text('10.0g'), findsOneWidget);
      expect(find.text('6.0g'), findsOneWidget);
      expect(find.text('2.0g'), findsOneWidget);
      expect(find.byKey(const Key('consumption_confirm_button')), findsOneWidget);
    });

    testWidgets('updating grams dynamically recalculates live macros (1.5x scaling)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PantryConsumptionDialog(pantryItem: testItem),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter 150 grams
      await tester.enterText(find.byKey(const Key('consumption_grams_input')), '150');
      await tester.pumpAndSettle();

      // 100 kcal * (150 / 100) = 150 kcal
      expect(find.text('150 kcal'), findsOneWidget);
      // 10.0g * 1.5 = 15.0g
      expect(find.text('15.0g'), findsOneWidget);
      // 6.0g * 1.5 = 9.0g
      expect(find.text('9.0g'), findsOneWidget);
      // 2.0g * 1.5 = 3.0g
      expect(find.text('3.0g'), findsOneWidget);
    });
  });
}
