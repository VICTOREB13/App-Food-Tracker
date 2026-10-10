import 'app_localizations_core.dart';

abstract class AppLocalizationsDashboard extends AppLocalizationsCore {
  AppLocalizationsDashboard(super.locale);

  String get dashboard;
  String get breakfast;
  String get quickMeal;
  String get quickMealTitle;
  String get fasting;
  String get fastingWindow;
  String get startFast;
  String get endFast;
  String get voiceDictation;
  String get fastingCompletedTitle;
  String fastingCompletedBody(String hours);
  String get analyzingMealBackground;
  String get quickHydrationNote;
  String get waterLoggedSuccess;
  String waterLogError(String error);
  String quickMealLogError(String error);
  String quickMealLoggedSuccess(String name, String calories);
  String get fabCameraTitle;
  String get fabCameraSubtitle;
  String get fabGalleryTitle;
  String get fabGallerySubtitle;
  String get fabBarcodeTitle;
  String get fabBarcodeSubtitle;
  String get fabManualTitle;
  String get fabManualSubtitle;
  String get fabWaterTitle;
  String get fabWaterSubtitle;
  String get fabQuickTitle;
  String get fabQuickSubtitle;
  String get fabSectionHeader;
  String get whatToEatTitle;
  String get whatToEatSubtitle;
  String get unclassifiedMeal;
  String get startFastingTitle;
  String get selectFastingProtocol;
  String get endFastingDialogTitle;
  String endFastingDialogBody(String duration);
  String get noActiveFast;
  String get noActiveFastTitle;
  String get quickMealNotesDefault;
  String get quickMealDescriptionLabel;
  String voiceMealAddedSuccess(String name);
  String get voiceDictationTitle;
  String get voiceDictationInstruction;
  String get whatToEatCombinations;
  String get flashFastTag;
  String get proReasoningTag;
  String get fabVoiceTitle;
  String get fabVoiceSubtitle;
  String get fabVideoTitle;
  String get fabVideoSubtitle;
  String remainingFastDuration(String remaining, String total);
  String get fastingStartTrackingPrompt;

  String dishRegisteredSuccess(String name);
  String errorRegisteringMeal(String error);
  String suggestionsForNextMeal(String mealType);
  String get quickWaterMealName;
}

