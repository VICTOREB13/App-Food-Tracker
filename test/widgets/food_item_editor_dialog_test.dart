import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/food_item.dart';
import 'package:food_tracker/widgets/meal_detail/food_item_editor_dialog.dart';

void main() {
  group('FoodItemEditorDialog Widget Tests', () {
    testWidgets('shows dialog in add mode and returns new FoodItem on submit', (tester) async {
      FoodItem? returnedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedItem = await showFoodItemEditorDialog(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Añadir Ingrediente'), findsOneWidget);
      expect(find.text('Nombre del alimento *'), findsOneWidget);
      expect(find.text('Gramos'), findsOneWidget);
      expect(find.text('Calorías'), findsOneWidget);
      expect(find.text('Proteína'), findsOneWidget);
      expect(find.text('Carbohidratos'), findsOneWidget);
      expect(find.text('Grasas'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);

      // Enter food name
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre del alimento *'),
        'Pechuga a la plancha',
      );

      // Tap Guardar
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(returnedItem, isNotNull);
      expect(returnedItem!.name, equals('Pechuga a la plancha'));
      expect(returnedItem!.estimatedGrams, equals(100.0));
      expect(returnedItem!.calories, equals(150.0));
      expect(returnedItem!.protein, equals(5.0));
      expect(returnedItem!.carbs, equals(20.0));
      expect(returnedItem!.fat, equals(3.0));
    });

    testWidgets('shows dialog in edit mode with prefilled values and updates item', (tester) async {
      FoodItem? returnedItem;
      final existingItem = FoodItem(
        id: 'existing-id-123',
        name: 'Arroz Integral',
        estimatedGrams: 200,
        calories: 220,
        protein: 5.0,
        carbs: 45.0,
        fat: 1.8,
        visualJustification: '1 taza cocida',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedItem = await showFoodItemEditorDialog(
                    context,
                    initialItem: existingItem,
                  );
                },
                child: const Text('Edit Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Ingrediente'), findsOneWidget);
      expect(find.text('Arroz Integral'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.text('220'), findsOneWidget);

      // Modify name
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre del alimento *'),
        'Arroz Salvaje',
      );

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(returnedItem, isNotNull);
      expect(returnedItem!.id, equals('existing-id-123'));
      expect(returnedItem!.name, equals('Arroz Salvaje'));
      expect(returnedItem!.estimatedGrams, equals(200.0));
      expect(returnedItem!.calories, equals(220.0));
      expect(returnedItem!.visualJustification, equals('1 taza cocida'));
    });

    testWidgets('cancels dialog and returns null when Cancelar is tapped', (tester) async {
      FoodItem? returnedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedItem = await showFoodItemEditorDialog(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(returnedItem, isNull);
    });

    testWidgets('does not save or close dialog when name is empty', (tester) async {
      FoodItem? returnedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedItem = await showFoodItemEditorDialog(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Guardar without entering name
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Dialog is still open
      expect(find.text('Añadir Ingrediente'), findsOneWidget);
      expect(returnedItem, isNull);
    });
  });
}
