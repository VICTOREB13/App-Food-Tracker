import 'app_localizations.dart';

/// English localizations for NutriTracker.
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([super.locale = 'en']);

  @override
  String get appTitle => 'Victor Engineer - Food Tracker';
  @override
  String get dashboard => 'Dashboard';
  @override
  String get metrics => 'Metrics';
  @override
  String get settings => 'Settings';
  @override
  String get profile => 'Profile';
  @override
  String get calories => 'Calories';
  @override
  String get protein => 'Protein';
  @override
  String get carbs => 'Carbs';
  @override
  String get fat => 'Fats';
  @override
  String get breakfast => 'Breakfast';
  @override
  String get lunch => 'Lunch';
  @override
  String get dinner => 'Dinner';
  @override
  String get snack => 'Snack';
  @override
  String get other => 'Other';
  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get confirm => 'Confirm';
  @override
  String get saveAndStart => 'Save and Start';
  @override
  String get back => 'Back';
  @override
  String get continueButton => 'Continue';
  @override
  String get quickMeal => 'Quick Meal';
  @override
  String get quickMealTitle => 'Quick Meal Entry';
  @override
  String get streak => 'Streak';
  @override
  String get days => 'days';
  @override
  String get weight => 'Weight';
  @override
  String get targetCalories => 'Target Calories';
  @override
  String get targetProtein => 'Target Protein';
  @override
  String get targetCarbs => 'Target Carbohydrates';
  @override
  String get targetFat => 'Target Fat';
  @override
  String get dailySummary => 'Daily Summary';
  @override
  String get consumed => 'Consumed';
  @override
  String get remaining => 'Remaining';
  @override
  String get addMeal => 'Add Meal';
  @override
  String get recordWeight => 'Record Weight';
  @override
  String get scanBarcode => 'Scan Barcode';
  @override
  String get takePhoto => 'Take Photo';
  @override
  String get chooseGallery => 'Choose from Gallery';
  @override
  String get apiKeyConfig => 'API Key Configuration';
  @override
  String get apiKeyPrompt => 'Enter your Google Gemini API Key';
  @override
  String get databaseMaintenance => 'Database Maintenance';
  @override
  String get optimizeDatabase => 'Optimize Database';
  @override
  String get backupAndRestore => 'Backup & Restore';
  @override
  String get exportBackup => 'Export Backup';
  @override
  String get importBackup => 'Import Backup';
  @override
  String get themeMode => 'Theme Mode';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get photoRetention => 'Photo Retention';
  @override
  String get noMealsToday => 'No meals logged for this day';
  @override
  String get noWeightLogs => 'No weight logs recorded yet';
  @override
  String get onboardingTitle => 'Welcome to NutriTracker';
  @override
  String get onboardingSubtitle =>
      'Your smart nutrition and body composition companion';
  @override
  String get calculateNeeds => 'Calculate Requirements';
  @override
  String get age => 'Age';
  @override
  String get gender => 'Gender';
  @override
  String get genderMale => 'Male';
  @override
  String get genderFemale => 'Female';
  @override
  String get height => 'Height';
  @override
  String get activityLevel => 'Activity Level';
  @override
  String get bodyGoal => 'Body Goal';
  @override
  String get bmr => 'Basal Metabolic Rate';
  @override
  String get tdee => 'Total Daily Energy Expenditure';
  @override
  String get fiber => 'Fiber';
  @override
  String get sodium => 'Sodium';
  @override
  String get sugar => 'Sugar';
  @override
  String get fasting => 'Intermittent Fasting';
  @override
  String get fastingWindow => 'Fasting Window';
  @override
  String get startFast => 'Start Fast';
  @override
  String get endFast => 'End Fast';
  @override
  String get weeklyDigest => 'Weekly Digest';
  @override
  String get clinicalReport => 'Clinical Report';
  @override
  String get calibratedDishware => 'Calibrated Dishware';
  @override
  String get myPantry => 'My Pantry';
  @override
  String get voiceDictation => 'Voice Dictation';
  @override
  String get language => 'Language';
  @override
  String get spanish => 'Spanish';
  @override
  String get english => 'English';
  @override
  String remainingCalories(String count) => '$count remaining';
  @override
  String overCalories(String count) => '+$count over';
  @override
  String get today => 'Today';
  @override
  String get yesterday => 'Yesterday';
  @override
  String get tomorrow => 'Tomorrow';
  @override
  String get previousDayTooltip => 'Previous day';
  @override
  String get nextDayTooltip => 'Next day';
  @override
  String get goToTodayTooltip => 'Go to today';
  @override
  String get noMealsForSection => 'No meals logged in this section.';
  @override
  String addToMealSection(String mealType) => 'Add to $mealType';
  @override
  String get mealDetails => 'Meal Details';
  @override
  String get newMeal => 'New Meal';
  @override
  String get deleteMealTooltip => 'Delete meal';
  @override
  String get dishNameLabel => 'Dish name *';
  @override
  String get dishNameHint => 'E.g., Grilled chicken breast with rice';
  @override
  String get mealTypeLabel => 'Meal Type';
  @override
  String get notesLabel => 'Notes / Observations';
  @override
  String get notesHint => 'E.g., Light oil used, medium portion';
  @override
  String get inspectMeal => 'Inspect meal';
  @override
  String get changePhoto => 'Change photo';
  @override
  String get takePhotoAction => 'Take photo';
  @override
  String get noMealImage => 'No meal image';
  @override
  String get saving => 'Saving...';
  @override
  String get updateMeal => 'Update Meal';
  @override
  String get registerMeal => 'Register Meal';
  @override
  String get addManualIngredient => 'Add manual ingredient';
  @override
  String get editIngredient => 'Edit ingredient';
  @override
  String get deleteIngredient => 'Delete ingredient';
  @override
  String get gramsLabel => 'Grams';
  @override
  String get estimationLabel => 'Estimation';
  @override
  String get reanalyzeWithAi => 'Re-analyze with corrections';
  @override
  String get reanalyzingAi => 'Re-analyzing with AI...';
  @override
  String get analysisStageOptimizing => 'Optimizing photo and dish calibration...';
  @override
  String get analysisStageConnecting => 'Securely connecting to Gemini Vision...';
  @override
  String get analysisStageVolumetric => 'Estimating 3D geometry and volumetric portion...';
  @override
  String get analysisStageDensities => 'Deducing food densities and hidden fats/oils...';
  @override
  String get analysisStageMacros => 'Nutritional breakdown and macro cross-checking...';
  @override
  String get analysisStageComplete => 'Nutritional breakdown complete!';
}
