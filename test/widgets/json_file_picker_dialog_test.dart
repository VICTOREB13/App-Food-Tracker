import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/settings/json_file_picker_dialog.dart';

void main() {
  group('JsonFilePickerDialog Widget Tests', () {
    testWidgets('renders native file picker button and cancel button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonFilePickerDialog(
              onRestoreFile: (file) async => {'meals': 5, 'pantry': 2, 'weights': 1},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Importar Respaldo JSON'), findsOneWidget);
      expect(find.byKey(const Key('native_file_picker_button')), findsOneWidget);
      expect(find.text('Seleccionar Archivo JSON'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.byKey(const Key('confirm_restore_button')), findsOneWidget);

      // Confirm button should be disabled initially (selectedFile is null)
      final confirmBtn = tester.widget<ElevatedButton>(find.byKey(const Key('confirm_restore_button')));
      expect(confirmBtn.onPressed, isNull);
    });

    testWidgets('cancel button closes dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog(
                  context: ctx,
                  builder: (_) => JsonFilePickerDialog(
                    onRestoreFile: (File file) async => {},
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Importar Respaldo JSON'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Importar Respaldo JSON'), findsNothing);
    });
  });
}
