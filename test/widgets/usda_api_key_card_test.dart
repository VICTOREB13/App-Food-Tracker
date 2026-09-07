import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/widgets/settings/usda_api_key_card.dart';

void main() {
  Widget buildWidget({
    String? currentApiKey,
    required ValueChanged<String> onSaveApiKey,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: UsdaApiKeyCard(
            currentApiKey: currentApiKey,
            onSaveApiKey: onSaveApiKey,
          ),
        ),
      ),
    );
  }

  group('UsdaApiKeyCard Widget Tests', () {
    testWidgets('Renderiza estado inicial sin clave con badge OPCIONAL y descripción fallback', (tester) async {
      await tester.pumpWidget(buildWidget(
        currentApiKey: null,
        onSaveApiKey: (_) {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('USDA FOODDATA CENTRAL (API KEY)'), findsOneWidget);
      expect(find.text('OPCIONAL'), findsOneWidget);
      expect(find.textContaining('Open Food Facts automáticamente como respaldo'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Guardar Key'), findsOneWidget);
      expect(find.text('Eliminar'), findsNothing);
    });

    testWidgets('Renderiza estado con clave configurada y botón Eliminar disponible', (tester) async {
      await tester.pumpWidget(buildWidget(
        currentApiKey: 'DEMO_KEY_XYZ_123',
        onSaveApiKey: (_) {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('CONFIGURADA'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
      expect(find.text('Guardar Key'), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('DEMO_KEY_XYZ_123'));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Alterna visibilidad del texto de la API Key', (tester) async {
      await tester.pumpWidget(buildWidget(
        currentApiKey: 'SECRET_USDA_KEY',
        onSaveApiKey: (_) {},
      ));
      await tester.pumpAndSettle();

      TextField textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      // Tocar botón de visibilidad
      final visibilityBtn = find.byIcon(Icons.visibility_outlined);
      expect(visibilityBtn, findsOneWidget);
      await tester.tap(visibilityBtn);
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);

      // Tocar nuevamente para ocultar
      final visibilityOffBtn = find.byIcon(Icons.visibility_off_outlined);
      expect(visibilityOffBtn, findsOneWidget);
      await tester.tap(visibilityOffBtn);
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Guardar clave invoca callback onSaveApiKey con el valor ingresado', (tester) async {
      String? savedKey;

      await tester.pumpWidget(buildWidget(
        currentApiKey: null,
        onSaveApiKey: (val) => savedKey = val,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'MY_NEW_USDA_KEY_789');
      await tester.pumpAndSettle();

      final saveBtn = find.text('Guardar Key');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedKey, equals('MY_NEW_USDA_KEY_789'));
    });

    testWidgets('Presionar Eliminar limpia campo e invoca callback con string vacío', (tester) async {
      String? savedKey;

      await tester.pumpWidget(buildWidget(
        currentApiKey: 'OLD_KEY_TO_DELETE',
        onSaveApiKey: (val) => savedKey = val,
      ));
      await tester.pumpAndSettle();

      final deleteBtn = find.text('Eliminar');
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(savedKey, equals(''));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });
  });
}
