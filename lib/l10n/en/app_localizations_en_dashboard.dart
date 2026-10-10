import 'app_localizations_en_core.dart';

abstract class AppLocalizationsEnDashboard extends AppLocalizationsEnCore {
  AppLocalizationsEnDashboard([super.locale = 'en']);

  @override String get dashboard => 'Dashboard';
  @override String get breakfast => 'Breakfast';
  @override String get quickMeal => 'Quick Meal';
  @override String get quickMealTitle => 'Quick Meal Entry';
  @override String get fasting => 'Intermittent Fasting';
  @override String get fastingWindow => 'Fasting Window';
  @override String get startFast => 'Start Fast';
  @override String get endFast => 'End Fast';
  @override String get voiceDictation => 'Voice Dictation';
  @override String get fastingCompletedTitle => 'Intermittent fast completed!';
  @override String fastingCompletedBody(String hours) => 'You reached your target of $hours hours of fasting. You can eat now!';
  @override String get analyzingMealBackground => '✨ Analyzing meal in background. You can continue using the app.';
  @override String get quickHydrationNote => 'Quick hydration (+250 ml)';
  @override String get waterLoggedSuccess => '💧 +250 ml water logged successfully.';
  @override String waterLogError(String error) => 'Error logging water: $error';
  @override String quickMealLogError(String error) => 'Error logging quick meal: $error';
  @override String quickMealLoggedSuccess(String name, String calories) => '⚡ $name logged ($calories kcal).';
  @override String get fabCameraTitle => 'AI Photo';
  @override String get fabCameraSubtitle => 'Gemini 2.5 Camera';
  @override String get fabGalleryTitle => 'Gallery';
  @override String get fabGallerySubtitle => 'Choose from gallery';
  @override String get fabBarcodeTitle => 'Barcode';
  @override String get fabBarcodeSubtitle => 'Open Food Facts';
  @override String get fabManualTitle => 'Manual';
  @override String get fabManualSubtitle => 'Pantry and macros';
  @override String get fabWaterTitle => '+250ml Water';
  @override String get fabWaterSubtitle => 'Quick hydration';
  @override String get fabQuickTitle => 'Quick';
  @override String get fabQuickSubtitle => 'Direct calories';
  @override String get fabSectionHeader => 'LOG MEAL OR ACTIVITY';
  @override String get whatToEatTitle => 'What should I eat today?';
  @override String get whatToEatSubtitle => 'Smart suggestions based on your macros';
  @override String get unclassifiedMeal => 'Unclassified meal';
  @override String get startFastingTitle => 'Start Intermittent Fasting';
  @override String get selectFastingProtocol => 'Select your fasting protocol:';
  @override String get endFastingDialogTitle => 'End Fasting?';
  @override String endFastingDialogBody(String duration) => 'You have fasted for $duration. The session will be saved to your history.';
  @override String get noActiveFast => '• No active fast';
  @override String get noActiveFastTitle => 'No active fast';
  @override String get quickMealNotesDefault => 'Quick meal entry';
  @override String get quickMealDescriptionLabel => 'Description / Food item';
  @override String voiceMealAddedSuccess(String name) => 'Meal "$name" added by voice.';
  @override String get voiceDictationTitle => 'Voice Dictation';
  @override String get voiceDictationInstruction => 'Describe your dish in natural language. Gemini Vision will extract ingredients, portions, and macros.';
  @override String get whatToEatCombinations => 'Combinations to reduce fat and reach goals';
  @override String get flashFastTag => 'Flash (Fast)';
  @override String get fabVoiceTitle => 'Voice / Audio';
  @override String get fabVoiceSubtitle => 'Natural dictation';
  @override String get fabVideoTitle => 'Video Pan';
  @override String get fabVideoSubtitle => '3D sampling';
  @override String remainingFastDuration(String remaining, String total) => '$remaining of ${total}h remaining';
  @override String get fastingStartTrackingPrompt => 'Start to track your eating window';

  @override String dishRegisteredSuccess(String name) => '✨ "$name" successfully logged today';
  @override String errorRegisteringMeal(String error) => 'Error logging meal: $error';
  @override String suggestionsForNextMeal(String mealType) => 'Suggestions for your next meal: $mealType';
  @override String get quickWaterMealName => 'Water (+250 ml)';
}

