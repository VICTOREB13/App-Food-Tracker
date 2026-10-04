import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/controllers/settings_controller.dart';
import 'package:food_tracker/widgets/settings/language_selector_card.dart';

void main() {
  group('LanguageSelectorCard Widget Tests', () {
    testWidgets('renders language options and updates controller on tap', (tester) async {
      final controller = SettingsController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelectorCard(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('IDIOMA / LANGUAGE'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(controller.currentLocale?.languageCode, equals('en'));

      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(controller.currentLocale?.languageCode, equals('es'));
    });
  });
}
