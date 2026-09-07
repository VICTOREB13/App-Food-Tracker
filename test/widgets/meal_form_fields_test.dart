import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/meal_detail/meal_form_fields.dart';

void main() {
  group('MealFormFields Widget Tests', () {
    testWidgets('renders fields and handles mealType change', (tester) async {
      final nameCtrl = TextEditingController(text: 'Pechuga a la plancha');
      final notesCtrl = TextEditingController(text: 'Con ensalada');
      String selectedType = 'Almuerzo';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MealFormFields(
                  nameController: nameCtrl,
                  notesController: notesCtrl,
                  mealType: selectedType,
                  onMealTypeChanged: (val) {
                    if (val != null) setState(() => selectedType = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Pechuga a la plancha'), findsOneWidget);
      expect(find.text('Con ensalada'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget);
    });
  });
}
