import 'dart:math' as math;
import '../controllers/meal_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/daily_goals.dart';
import '../models/macro_distribution.dart';
import '../models/user_profile.dart';
import 'database_service.dart';
import 'metabolic_prompt_generator.dart';
import 'secure_storage_service.dart';

export '../models/macro_distribution.dart';

/// Architectural alias for UserProfile in metabolic engine domain
typedef MetabolicProfile = UserProfile;

/// Clinical Metabolic Engine implementing Mifflin-St Jeor equation,
/// activity multipliers, TDEE, caloric targets, macro splits, and Master Prompt synthesis.
class MetabolicCalculator {
  // Activity Multipliers
  static const double multiplierSedentary = 1.2;
  static const double multiplierLight = 1.375;
  static const double multiplierModerate = 1.55;
  static const double multiplierVeryActive = 1.725;

  // Caloric Goal Adjustments
  static const double fatLossDeficit = 500.0;
  static const double muscleGainSurplus = 300.0;

  // Protein Factors (g/kg)
  static const double proteinFactorFatLoss = 2.0;
  static const double proteinFactorMaintenance = 1.8;
  static const double proteinFactorMuscleGain = 2.2;

  // Fat Minimum Factor (g/kg)
  static const double fatMinimumPerKg = 0.8;
  static const double fatCaloriePercentage = 0.25;

  /// Sanitizes and standardizes biological sex
  static String normalizeGender(String? raw) {
    if (raw == null) return 'male';
    final lower = raw.trim().toLowerCase();
    if (lower == 'female' || lower == 'femenino' || lower == 'mujer' || lower == 'f') {
      return 'female';
    }
    return 'male';
  }

  /// Sanitizes activity level key
  static String normalizeActivityLevel(String? raw) {
    if (raw == null) return 'sedentary';
    final lower = raw.trim().toLowerCase();
    if (lower.contains('very') || lower.contains('muy') || lower.contains('intenso')) {
      return 'very_active';
    }
    if (lower.contains('moderat') || lower.contains('moderado')) {
      return 'moderate';
    }
    if (lower.contains('light') || lower.contains('ligero')) {
      return 'light';
    }
    return 'sedentary';
  }

  /// Sanitizes body goal key
  static String normalizeBodyGoal(String? raw) {
    if (raw == null) return 'maintenance';
    final lower = raw.trim().toLowerCase();
    if (lower.contains('fat') || lower.contains('perdid') || lower.contains('déficit') ||
        lower.contains('deficit') || lower.contains('grasa')) {
      return 'fat_loss';
    }
    if (lower.contains('gain') || lower.contains('gananc') || lower.contains('superávit') ||
        lower.contains('superavit') || lower.contains('musculo') || lower.contains('músculo')) {
      return 'muscle_gain';
    }
    return 'maintenance';
  }

  /// Returns the numeric multiplier associated with an activity level
  static double getActivityMultiplier(String activityLevel) {
    switch (normalizeActivityLevel(activityLevel)) {
      case 'very_active':
        return multiplierVeryActive;
      case 'moderate':
        return multiplierModerate;
      case 'light':
        return multiplierLight;
      case 'sedentary':
      default:
        return multiplierSedentary;
    }
  }

  /// Calculates Basal Metabolic Rate (BMR / TMB) using Mifflin-St Jeor formula
  static double calculateBmr({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final isFemale = normalizeGender(gender) == 'female';
    final offset = isFemale ? -161.0 : 5.0;
    final bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + offset;
    return double.parse(bmr.toStringAsFixed(1));
  }

  /// Calculates Total Daily Energy Expenditure (TDEE): BMR * ActivityMultiplier
  static double calculateTdee({
    required double bmr,
    required String activityLevel,
  }) {
    final multiplier = getActivityMultiplier(activityLevel);
    final tdee = bmr * multiplier;
    return double.parse(tdee.toStringAsFixed(1));
  }

  /// Calculates Daily Caloric Goal based on body goal
  static double calculateCaloricGoal({
    required double tdee,
    required double bmr,
    required String bodyGoal,
  }) {
    final goal = normalizeBodyGoal(bodyGoal);
    double target;
    switch (goal) {
      case 'fat_loss':
        target = math.max(bmr, tdee - fatLossDeficit);
        break;
      case 'muscle_gain':
        target = tdee + muscleGainSurplus;
        break;
      case 'maintenance':
      default:
        target = tdee;
        break;
    }
    return double.parse(target.toStringAsFixed(1));
  }

  /// Calculates Macronutrient Distribution in grams with ABW obesity adjustment
  static MacroDistribution calculateMacros({
    required double targetCalories,
    required double weightKg,
    required String bodyGoal,
    double? heightCm,
    String? gender,
  }) {
    final goal = normalizeBodyGoal(bodyGoal);
    double effectiveWeight = weightKg;

    if (heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100.0;
      final bmi = weightKg / (heightM * heightM);
      if (bmi >= 30.0) {
        final isFemale = normalizeGender(gender) == 'female';
        final baseIbw = isFemale ? 45.5 : 50.0;
        double ibw = baseIbw + 0.91 * (heightCm - 152.4);
        if (ibw <= 0 || heightCm < 152.4) {
          ibw = 22.0 * (heightM * heightM);
        }
        if (weightKg > ibw) {
          final abw = ibw + 0.4 * (weightKg - ibw);
          effectiveWeight = double.parse(abw.toStringAsFixed(2));
        }
      }
    }

    double proteinFactor;
    switch (goal) {
      case 'fat_loss':
        proteinFactor = proteinFactorFatLoss;
        break;
      case 'muscle_gain':
        proteinFactor = proteinFactorMuscleGain;
        break;
      case 'maintenance':
      default:
        proteinFactor = proteinFactorMaintenance;
        break;
    }
    final rawProtein = effectiveWeight * proteinFactor;
    final proteinGrams = double.parse(rawProtein.toStringAsFixed(1));
    final proteinCals = proteinGrams * 4.0;

    final fatFromPercentage = (targetCalories * fatCaloriePercentage) / 9.0;
    final fatFloor = effectiveWeight * fatMinimumPerKg;
    final rawFat = math.max(fatFromPercentage, fatFloor);
    final fatGrams = double.parse(rawFat.toStringAsFixed(1));
    final fatCals = fatGrams * 9.0;

    final remainingCalories = targetCalories - proteinCals - fatCals;
    final rawCarbs = math.max(0.0, remainingCalories / 4.0);
    final carbsGrams = double.parse(rawCarbs.toStringAsFixed(1));

    return MacroDistribution(
      protein: proteinGrams,
      carbs: carbsGrams,
      fat: fatGrams,
    );
  }

  /// Synthesizes the Master Prompt in Markdown format for injection into Gemini Vision
  static String generateMasterPrompt(UserProfile profile) =>
      MetabolicPromptGenerator.generate(profile);

  /// Calculates a complete UserProfile with BMR, TDEE, Caloric goal, macros, and Master Prompt
  static UserProfile calculateProfile({
    String? id,
    String? name,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activityLevel,
    required String bodyGoal,
    int estimatedSteps = 8000,
    DateTime? updatedAt,
  }) {
    final bmr = calculateBmr(
      gender: gender,
      weightKg: weight,
      heightCm: height,
      age: age,
    );
    final tdee = calculateTdee(
      bmr: bmr,
      activityLevel: activityLevel,
    );
    final targetCalories = calculateCaloricGoal(
      tdee: tdee,
      bmr: bmr,
      bodyGoal: bodyGoal,
    );
    final macros = calculateMacros(
      targetCalories: targetCalories,
      weightKg: weight,
      bodyGoal: bodyGoal,
      heightCm: height,
      gender: gender,
    );

    final preliminary = UserProfile(
      id: id ?? 'primary',
      name: name,
      age: age,
      gender: normalizeGender(gender),
      height: height,
      weight: weight,
      activityLevel: normalizeActivityLevel(activityLevel),
      bodyGoal: normalizeBodyGoal(bodyGoal),
      estimatedSteps: estimatedSteps,
      bmr: bmr,
      tdee: tdee,
      targetCalories: targetCalories,
      targetProtein: macros.protein,
      targetCarbs: macros.carbs,
      targetFat: macros.fat,
      updatedAt: updatedAt ?? DateTime.now(),
    );

    return preliminary.copyWith(masterPrompt: generateMasterPrompt(preliminary));
  }

  /// Direct conversion helper to DailyGoals
  static DailyGoals toDailyGoals(UserProfile profile) => profile.dailyGoals;

  /// Saves the profile to SQLite, synchronizes DailyGoals and Master Prompt
  /// into SecureStorage, sets onboarding complete, and refreshes active controllers.
  static Future<UserProfile> saveAndSynchronizeProfile(UserProfile profile) async {
    await DatabaseService.instance.saveUserProfile(profile);
    await SecureStorageService.instance.setDailyGoals(profile.dailyGoals);

    if (profile.masterPrompt != null && profile.masterPrompt!.trim().isNotEmpty) {
      await SecureStorageService.instance.setMasterPrompt(profile.masterPrompt!);
    }

    await SecureStorageService.instance.setCompletedOnboarding(true);

    try {
      await MealController.instance.refreshGoals();
    } catch (_) {}

    try {
      await SettingsController.instance.refreshDailyGoals(profile.dailyGoals);
    } catch (_) {}

    return profile;
  }

  /// All-in-one helper that calculates, saves, and synchronizes profile
  static Future<UserProfile> calculateAndSaveProfile({
    String? id,
    String? name,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activityLevel,
    required String bodyGoal,
    int estimatedSteps = 8000,
  }) async {
    final profile = calculateProfile(
      id: id,
      name: name,
      age: age,
      gender: gender,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      bodyGoal: bodyGoal,
      estimatedSteps: estimatedSteps,
    );
    return await saveAndSynchronizeProfile(profile);
  }
}
