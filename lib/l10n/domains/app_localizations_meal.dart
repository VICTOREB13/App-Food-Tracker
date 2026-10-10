import 'package:flutter/widgets.dart';

import '../app_localizations.dart';
import 'app_localizations_dashboard.dart';

abstract class AppLocalizationsMeal extends AppLocalizationsDashboard {
  AppLocalizationsMeal(super.locale);

  String get calories;
  String get protein;
  String get carbs;
  String get fat;
  String get lunch;
  String get dinner;
  String get snack;
  String get targetCalories;
  String get targetProtein;
  String get targetCarbs;
  String get targetFat;
  String get consumed;
  String get addMeal;
  String get scanBarcode;
  String get chooseGallery;
  String get noMealsToday;
  String get fiber;
  String get sodium;
  String get sugar;
  String get calibratedDishware;
  String get myPantry;
  String remainingCalories(String count);
  String overCalories(String count);
  String get noMealsForSection;
  String addToMealSection(String mealType);
  String get mealDetails;
  String get newMeal;
  String get deleteMealTooltip;
  String get mealTypeLabel;
  String get inspectMeal;
  String get registerMeal;
  String get addManualIngredient;
  String get editIngredient;
  String get deleteIngredient;
  String get gramsLabel;
  String get mealAnalysisSuccessTitle;
  String mealAnalysisSuccessBody(String dishName, String calories);
  String get mealAnalysisErrorTitle;
  String get mealAnalysisErrorFallback;
  String get barcodeScannedDefaultNote;
  String get mealAnalyzedSuccess;
  String get mealAnalysisAiError;
  String get estimatedCaloriesLabel;
  String get fatGramsLabel;
  String get mealTypeFieldLabel;
  String get calibrateDishTitle;
  String get editDishTitle;
  String get dishwareSubtitle;
  String get dishwareDescription;
  String get noCalibratedDishware;
  String get newDishAction;
  String dishDimensions(String diameter, String depth);
  String get inspectDishTitle;
  String get editIngredientTitle;
  String get addIngredientTitle;
  String ingredientsBreakdownTitle(String count);
  String get noIngredientsInMeal;
  String calorieErrorMarginTooltip(String margin);
  String get deleteMealConfirmTitle;
  String deleteMealError(String error);
  String saveMealError(String error);
  String get mealReanalyzedSuccess;
  String reanalyzeMealError(String error);
  String get userCorrectedIngredientsPrompt;
  String get cameraLabel;
  String get galleryLabel;
  String get caloriesHeader;
  String get logMealsToBuildHabit;
  String get pantryCategoriesAll;
  String get pantryCategoriesGrains;
  String get pantryCategoriesDairy;
  String get pantryCategoriesProteins;
  String get pantryCategoriesSnacks;
  String scanError(String error);
  String get pantryDescription;
  String servingPortion(String serving);
  String get logToMealTooltip;
  String pantryItemLoggedSuccess(String name, String meal, String calories);
  String get pantryLogToMealTitle;
  String get targetMealLabel;
  String addToMealTypeAction(String meal);
  String get addProductToPantryTitle;
  String get servingGramsLabel;
  String get energyAndCarbsTitle;
  String dishLoggedSuccess(String name);
  String nextMealSuggestions(String mealType);
  String get tailoredRecommendedDishes;
  String get filePathCopiedSnackBar;
  String get caloriesKcalLabel;
  String get proteinGramsLabel;
  String get carbsGramsLabel;
  String previewPantryCount(String count);
  String get navDishwareTitle;
  String get navDishwareSubtitle;
  String get navPantryTitle;
  String get scanBarcodeDialogTitle;
  String get openDish;
  String get gramsToConsume;
  String referencePortion(String grams);
  String get ingredients;
  String get foodItemExamples;

  String pantryReferenceServing(String grams);
  String addToMealType(String mealType);
  String get portionGramsLabel;
  String get packageGramsLabel;
  String get brandOptionalLabel;
  String mealLoggedSnackSuccess(String name, String mealType, String calories);

  String get fatControlTitle;
  String fitScoreLabel(String score);
}

/// Extension to localize invariant meal keys ('Desayuno', 'Almuerzo', 'Cena', 'Snack', 'Otro')
/// into the current active UI locale without mutating database storage values.
extension MealTypeLocalization on String {
  String toLocalizedMealType(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lower = trim().toLowerCase();
    if (lower == 'desayuno' || lower == 'breakfast') return l10n.breakfast;
    if (lower == 'almuerzo' || lower == 'lunch') return l10n.lunch;
    if (lower == 'cena' || lower == 'dinner') return l10n.dinner;
    if (lower == 'snack') return l10n.snack;
    if (lower == 'otro' || lower == 'other') return l10n.other;
    return this;
  }
}
