import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/models/pantry_item.dart';
import 'package:food_tracker/widgets/pantry/pantry_item_editor_dialog.dart';

void main() {
  group('PantryItemEditorDialog Widget Tests', () {
    testWidgets('renders input fields for reference portion and package weight', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PantryItemEditorDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Añadir Producto a Despensa'), findsOneWidget);
      expect(find.byKey(const Key('pantry_name_input')), findsOneWidget);
      expect(find.byKey(const Key('pantry_brand_input')), findsOneWidget);
      expect(find.byKey(const Key('pantry_serving_input')), findsOneWidget);
      expect(find.byKey(const Key('pantry_package_input')), findsOneWidget);
      expect(find.byKey(const Key('pantry_cal_input')), findsOneWidget);
      expect(find.byKey(const Key('pantry_prot_input')), findsOneWidget);
      expect(find.byKey(const Key('pantry_carbs_input')), findsOneWidget);
      expect(find.byKey(const Key('pantry_fat_input')), findsOneWidget);
      expect(find.byKey(const Key('pantry_save_button')), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('pre-populates existing item servingSize and packageWeight', (tester) async {
      final existing = PantryItem(
        id: 'p1',
        name: 'Avena Quaker',
        brand: 'Quaker',
        servingSize: 40.0,
        packageWeight: 500.0,
        calories: 150,
        protein: 5.0,
        carbs: 27.0,
        fat: 3.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PantryItemEditorDialog(initialItem: existing),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Editar Producto'), findsOneWidget);
      expect(find.text('Avena Quaker'), findsOneWidget);
      expect(find.text('Quaker'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('Guardar Cambios'), findsOneWidget);
    });
  });
}
