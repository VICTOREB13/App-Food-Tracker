import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

/// Callers can lookup localized strings via [AppLocalizations.of(context)].
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
  ];

  String get appTitle;
  String get dashboard;
  String get metrics;
  String get settings;
  String get profile;
  String get calories;
  String get protein;
  String get carbs;
  String get fat;
  String get breakfast;
  String get lunch;
  String get dinner;
  String get snack;
  String get other;
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get confirm;
  String get saveAndStart;
  String get back;
  String get continueButton;
  String get quickMeal;
  String get quickMealTitle;
  String get streak;
  String get days;
  String get weight;
  String get targetCalories;
  String get targetProtein;
  String get targetCarbs;
  String get targetFat;
  String get dailySummary;
  String get consumed;
  String get remaining;
  String get addMeal;
  String get recordWeight;
  String get scanBarcode;
  String get takePhoto;
  String get chooseGallery;
  String get apiKeyConfig;
  String get apiKeyPrompt;
  String get databaseMaintenance;
  String get optimizeDatabase;
  String get backupAndRestore;
  String get exportBackup;
  String get importBackup;
  String get themeMode;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get photoRetention;
  String get noMealsToday;
  String get noWeightLogs;
  String get onboardingTitle;
  String get onboardingSubtitle;
  String get calculateNeeds;
  String get age;
  String get gender;
  String get genderMale;
  String get genderFemale;
  String get height;
  String get activityLevel;
  String get bodyGoal;
  String get bmr;
  String get tdee;
  String get fiber;
  String get sodium;
  String get sugar;
  String get fasting;
  String get fastingWindow;
  String get startFast;
  String get endFast;
  String get weeklyDigest;
  String get clinicalReport;
  String get calibratedDishware;
  String get myPantry;
  String get voiceDictation;
  String get language;
  String get spanish;
  String get english;
  String remainingCalories(String count);
  String overCalories(String count);
  String get today;
  String get yesterday;
  String get tomorrow;
  String get previousDayTooltip;
  String get nextDayTooltip;
  String get goToTodayTooltip;
  String get noMealsForSection;
  String addToMealSection(String mealType);
  String get mealDetails;
  String get newMeal;
  String get deleteMealTooltip;
  String get dishNameLabel;
  String get dishNameHint;
  String get mealTypeLabel;
  String get notesLabel;
  String get notesHint;
  String get inspectMeal;
  String get changePhoto;
  String get takePhotoAction;
  String get noMealImage;
  String get saving;
  String get updateMeal;
  String get registerMeal;
  String get addManualIngredient;
  String get editIngredient;
  String get deleteIngredient;
  String get gramsLabel;
  String get estimationLabel;
  String get reanalyzeWithAi;
  String get reanalyzingAi;
  String get analysisStageOptimizing;
  String get analysisStageConnecting;
  String get analysisStageVolumetric;
  String get analysisStageDensities;
  String get analysisStageMacros;
  String get analysisStageComplete;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue on GitHub with '
    'a reproducible sample app and the gen-l10n configuration that was used.',
  );
}
