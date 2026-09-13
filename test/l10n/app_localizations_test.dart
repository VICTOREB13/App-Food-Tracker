import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/l10n/app_localizations_en.dart';
import 'package:food_tracker/l10n/app_localizations_es.dart';

void main() {
  group('AppLocalizations Unit Tests', () {
    test('AppLocalizationsEs contains valid Spanish strings', () {
      final l10n = AppLocalizationsEs();

      expect(l10n.localeName, equals('es'));
      expect(l10n.appTitle, equals('Victor Engineer - Food Tracker'));
      expect(l10n.dashboard, equals('Panel Principal'));
      expect(l10n.saveAndStart, equals('Guardar y Comenzar'));
      expect(l10n.calories, equals('Calorías'));
      expect(l10n.protein, equals('Proteína'));
      expect(l10n.carbs, equals('Carbohidratos'));
      expect(l10n.fat, equals('Grasa'));
      expect(l10n.streak, equals('Racha'));
    });

    test('AppLocalizationsEn contains valid English strings', () {
      final l10n = AppLocalizationsEn();

      expect(l10n.localeName, equals('en'));
      expect(l10n.appTitle, equals('Victor Engineer - Food Tracker'));
      expect(l10n.dashboard, equals('Dashboard'));
      expect(l10n.saveAndStart, equals('Save and Start'));
      expect(l10n.calories, equals('Calories'));
      expect(l10n.protein, equals('Protein'));
      expect(l10n.carbs, equals('Carbohydrates'));
      expect(l10n.fat, equals('Fat'));
      expect(l10n.streak, equals('Streak'));
    });

    test('lookupAppLocalizations returns appropriate instance for locale', () {
      final es = lookupAppLocalizations(const Locale('es'));
      expect(es, isA<AppLocalizationsEs>());

      final en = lookupAppLocalizations(const Locale('en'));
      expect(en, isA<AppLocalizationsEn>());

      final fallback = lookupAppLocalizations(const Locale('fr'));
      expect(fallback, isA<AppLocalizationsEs>());
    });

    test('AppLocalizations.supportedLocales contains es and en', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('es')));
      expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    });
  });
}
