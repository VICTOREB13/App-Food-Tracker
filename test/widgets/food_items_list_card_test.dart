import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/food_item.dart';
import 'package:food_tracker/widgets/common/macro_indicator_chip.dart';
import 'package:food_tracker/widgets/meal_detail/food_items_list_card.dart';

void main() {
  group('FoodItemsListCard Widget Tests', () {
    testWidgets('displays empty state message when items list is empty', (tester) async {
      bool addTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodItemsListCard(
              items: const [],
              onAddItem: () => addTapped = true,
              onEditItem: (_) {},
              onDeleteItem: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('DESGLOSE DE INGREDIENTES (0)'), findsOneWidget);
      expect(find.text('No hay ingredientes desglosados en este plato.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      expect(addTapped, isTrue);
    });

    testWidgets('renders items with grams chip and no duplicate badge next to title', (tester) async {
      final testItem = FoodItem(
        id: 'item-1',
        name: 'Pechuga de pollo',
        estimatedGrams: 150,
        calories: 248,
        protein: 46.5,
        carbs: 0.0,
        fat: 5.4,
      );

      FoodItem? editedItem;
      FoodItem? deletedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodItemsListCard(
              items: [testItem],
              onAddItem: () {},
              onEditItem: (item) => editedItem = item,
              onDeleteItem: (item) => deletedItem = item,
            ),
          ),
        ),
      );

      expect(find.text('DESGLOSE DE INGREDIENTES (1)'), findsOneWidget);
      expect(find.text('Pechuga de pollo'), findsOneWidget);

      // Verify grams is displayed in MacroIndicatorChip and NOT in a duplicate title badge
      expect(find.text('150g'), findsOneWidget);
      expect(find.text('Gramos'), findsOneWidget);

      // Verify all macros are present in chips
      expect(find.text('Cal'), findsOneWidget);
      expect(find.text('248 kcal'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);
      expect(find.text('46.5g'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('0.0g'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
      expect(find.text('5.4g'), findsOneWidget);

      // Verify exactly one MacroIndicatorChip has label Gramos and value 150g
      final macroChips = tester.widgetList<MacroIndicatorChip>(find.byType(MacroIndicatorChip));
      expect(macroChips.where((c) => c.label == 'Gramos').length, equals(1));
      expect(macroChips.where((c) => c.value == '150g').length, equals(1));

      // Test Edit Callback
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(editedItem, equals(testItem));

      // Test Delete Callback
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      expect(deletedItem, equals(testItem));
    });

    testWidgets('renders visual justification when present', (tester) async {
      final testItem = FoodItem(
        id: 'item-2',
        name: 'Arroz cocido',
        estimatedGrams: 200,
        calories: 260,
        protein: 5.4,
        carbs: 56.4,
        fat: 0.6,
        visualJustification: 'Aproximadamente 1 taza colmada',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodItemsListCard(
              items: [testItem],
              onAddItem: () {},
              onEditItem: (_) {},
              onDeleteItem: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Estimación: Aproximadamente 1 taza colmada'), findsOneWidget);
    });
  });
}
