import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations Unit Tests', () {
    test('AppLocalizationsEs contains valid Spanish strings', () {
      final l10n = AppLocalizationsEs();

      expect(l10n.localeName, equals('es'));
      expect(l10n.appTitle, equals('Victor Engineer - Food Tracker'));
      expect(l10n.dashboard, equals('Panel Principal'));
      expect(l10n.saveAndStart, equals('Guardar y Comenzar'));
      expect(l10n.back, equals('Atrás'));
      expect(l10n.continueButton, equals('Continuar'));
      expect(l10n.quickMeal, equals('Comida rápida'));
      expect(l10n.quickMealTitle, equals('Registro Rápido de Comida'));
      expect(l10n.calories, equals('Calorías'));
      expect(l10n.protein, equals('Proteína'));
      expect(l10n.carbs, equals('Carbohidratos'));
      expect(l10n.fat, equals('Grasa'));
      expect(l10n.streak, equals('Racha'));
      expect(l10n.fiber, equals('Fibra'));
      expect(l10n.sodium, equals('Sodio'));
      expect(l10n.fasting, equals('Ayuno Intermitente'));
      expect(l10n.clinicalReport, equals('Reporte Clínico'));
      expect(l10n.viewLess, equals('Ver menos'));
      expect(l10n.viewAllCount('5'), equals('Ver todos (5)'));
      expect(l10n.noWeightLogsInRange, equals('Sin registros de peso en este rango'));
      expect(l10n.quickWaterMealName, equals('Agua (+250 ml)'));
      expect(l10n.navPantrySubtitle, equals('Productos y contexto de marcas para Gemini Vision'));
    });

    test('AppLocalizationsEn contains valid English strings', () {
      final l10n = AppLocalizationsEn();

      expect(l10n.localeName, equals('en'));
      expect(l10n.appTitle, equals('Victor Engineer - Food Tracker'));
      expect(l10n.dashboard, equals('Dashboard'));
      expect(l10n.saveAndStart, equals('Save and Start'));
      expect(l10n.back, equals('Back'));
      expect(l10n.continueButton, equals('Continue'));
      expect(l10n.quickMeal, equals('Quick Meal'));
      expect(l10n.quickMealTitle, equals('Quick Meal Entry'));
      expect(l10n.calories, equals('Calories'));
      expect(l10n.protein, equals('Protein'));
      expect(l10n.carbs, equals('Carbohydrates'));
      expect(l10n.fat, equals('Fat'));
      expect(l10n.streak, equals('Streak'));
      expect(l10n.fiber, equals('Fiber'));
      expect(l10n.sodium, equals('Sodium'));
      expect(l10n.fasting, equals('Intermittent Fasting'));
      expect(l10n.clinicalReport, equals('Clinical Report'));
      expect(l10n.viewLess, equals('View less'));
      expect(l10n.viewAllCount('5'), equals('View all (5)'));
      expect(l10n.noWeightLogsInRange, equals('No weight logs in this range'));
      expect(l10n.quickWaterMealName, equals('Water (+250 ml)'));
      expect(l10n.navPantrySubtitle, equals('Products and brand context for Gemini Vision'));
    });

    test('lookupAppLocalizations returns appropriate instance for locale', () {
      final es = lookupAppLocalizations(const Locale('es'));
      expect(es, isA<AppLocalizationsEs>());

      final en = lookupAppLocalizations(const Locale('en'));
      expect(en, isA<AppLocalizationsEn>());

      expect(
        () => lookupAppLocalizations(const Locale('fr')),
        throwsA(isA<FlutterError>()),
      );
    });

    test('AppLocalizations.supportedLocales contains es and en', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('es')));
      expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    });

    testWidgets('MealTypeLocalization translates correctly in context', (tester) async {
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: AppLocalizations.localizationsDelegates,
          child: Builder(
            builder: (context) {
              expect('Desayuno'.toLocalizedMealType(context), equals('Breakfast'));
              expect('Almuerzo'.toLocalizedMealType(context), equals('Lunch'));
              expect('Cena'.toLocalizedMealType(context), equals('Dinner'));
              expect('Snack'.toLocalizedMealType(context), equals('Snack'));
              expect('Otro'.toLocalizedMealType(context), equals('Other'));
              expect('Custom'.toLocalizedMealType(context), equals('Custom'));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
