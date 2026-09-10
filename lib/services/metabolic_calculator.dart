import 'dart:math' as math;
import '../controllers/meal_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/daily_goals.dart';
import '../models/user_profile.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';

/// Class representing the macronutrient split distribution in grams
class MacroDistribution {
  final double protein;
  final double carbs;
  final double fat;

  const MacroDistribution({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  double get proteinCalories => protein * 4.0;
  double get carbsCalories => carbs * 4.0;
  double get fatCalories => fat * 9.0;
  double get totalCalories => proteinCalories + carbsCalories + fatCalories;

  @override
  String toString() =>
      'MacroDistribution(protein: ${protein}g, carbs: ${carbs}g, fat: ${fat}g, total: ${totalCalories}kcal)';
}

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
    if (lower == 'female' ||
        lower == 'femenino' ||
        lower == 'mujer' ||
        lower == 'f') {
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
    if (lower.contains('fat') ||
        lower.contains('perdid') ||
        lower.contains('déficit') ||
        lower.contains('deficit') ||
        lower.contains('grasa')) {
      return 'fat_loss';
    }
    if (lower.contains('gain') ||
        lower.contains('gananc') ||
        lower.contains('superávit') ||
        lower.contains('superavit') ||
        lower.contains('musculo') ||
        lower.contains('músculo')) {
      return 'muscle_gain';
    }
    return 'maintenance';
  }

  /// Returns the numeric multiplier associated with an activity level
  static double getActivityMultiplier(String activityLevel) {
    final normalized = normalizeActivityLevel(activityLevel);
    switch (normalized) {
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

  /// Calculates Basal Metabolic Rate (BMR / TMB) using Mifflin-St Jeor formula:
  /// - Male: (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
  /// - Female: (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161
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

  /// Calculates Total Daily Energy Expenditure (TDEE):
  /// TDEE = BMR * ActivityMultiplier
  static double calculateTdee({
    required double bmr,
    required String activityLevel,
  }) {
    final multiplier = getActivityMultiplier(activityLevel);
    final tdee = bmr * multiplier;
    return double.parse(tdee.toStringAsFixed(1));
  }

  /// Calculates Daily Caloric Goal based on body goal:
  /// - fat_loss: TDEE - 500 (with floor at BMR)
  /// - maintenance: TDEE
  /// - muscle_gain: TDEE + 300
  static double calculateCaloricGoal({
    required double tdee,
    required double bmr,
    required String bodyGoal,
  }) {
    final goal = normalizeBodyGoal(bodyGoal);
    double target;
    switch (goal) {
      case 'fat_loss':
        final rawDeficit = tdee - fatLossDeficit;
        target = math.max(bmr, rawDeficit);
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

  /// Calculates Macronutrient Distribution in grams:
  /// - Protein: 2.0 g/kg (fat_loss), 1.8 g/kg (maintenance), 2.2 g/kg (muscle_gain)
  /// - Fat: 25% of target calories / 9 (minimum 0.8 g/kg)
  /// - Carbs: (Target calories - protein*4 - fat*9) / 4
  static MacroDistribution calculateMacros({
    required double targetCalories,
    required double weightKg,
    required String bodyGoal,
  }) {
    final goal = normalizeBodyGoal(bodyGoal);

    // 1. Protein
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
    final rawProtein = weightKg * proteinFactor;
    final proteinGrams = double.parse(rawProtein.toStringAsFixed(1));
    final proteinCals = proteinGrams * 4.0;

    // 2. Fat (25% of target calories / 9, minimum 0.8 g/kg)
    final fatFromPercentage = (targetCalories * fatCaloriePercentage) / 9.0;
    final fatFloor = weightKg * fatMinimumPerKg;
    final rawFat = math.max(fatFromPercentage, fatFloor);
    final fatGrams = double.parse(rawFat.toStringAsFixed(1));
    final fatCals = fatGrams * 9.0;

    // 3. Carbs (Remaining calories / 4)
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
  static String generateMasterPrompt(UserProfile profile) {
    final genderDisplay = profile.gender == 'female' ? 'Femenino' : 'Masculino';
    final activityDisplay = _formatActivityDisplay(profile.activityLevel);
    final goalDisplay = _formatGoalDisplay(profile.bodyGoal);

    final buffer = StringBuffer();
    buffer.writeln('# Contexto Biológico y Metas Nutricionales del Comensal');
    buffer.writeln();
    buffer.writeln('## 1. Datos Biométricos');
    buffer.writeln('- **Nombre**: ${profile.name?.trim().isNotEmpty == true ? profile.name : 'Comensal'}');
    buffer.writeln('- **Edad**: ${profile.age} años');
    buffer.writeln('- **Género Biológico**: $genderDisplay');
    final weightDisplay = (profile.weight % 1 == 0)
        ? profile.weight.toStringAsFixed(1)
        : profile.weight.toString();
    buffer.writeln('- **Estatura**: ${profile.height.toStringAsFixed(1)} cm');
    buffer.writeln('- **Peso Actual**: $weightDisplay kg');
    buffer.writeln();
    buffer.writeln('## 2. Nivel de Actividad y Gasto Energético');
    buffer.writeln('- **Nivel de Actividad**: $activityDisplay');
    buffer.writeln('- **Pasos Diarios Estimados**: ${profile.estimatedSteps} pasos/día');
    buffer.writeln('- **Tasa Metabólica Basal (TMB / BMR - Mifflin-St Jeor)**: ${profile.bmr.toStringAsFixed(0)} kcal/día');
    buffer.writeln('- **Gasto Energético Diario Total (TDEE)**: ${profile.tdee.toStringAsFixed(0)} kcal/día');
    buffer.writeln();
    buffer.writeln('## 3. Metas Metabólicas y Objetivos');
    buffer.writeln('- **Objetivo Corporal**: $goalDisplay');
    buffer.writeln('- **Presupuesto Calórico Diario**: ${profile.targetCalories.toStringAsFixed(0)} kcal/día');
    buffer.writeln();
    buffer.writeln('## 4. Distribución de Macronutrientes Objetivo');
    buffer.writeln('- **Proteínas**: ${profile.targetProtein.toStringAsFixed(0)} g/día (${(profile.targetProtein * 4.0).toStringAsFixed(0)} kcal)');
    buffer.writeln('- **Carbohidratos**: ${profile.targetCarbs.toStringAsFixed(0)} g/día (${(profile.targetCarbs * 4.0).toStringAsFixed(0)} kcal)');
    buffer.writeln('- **Grasas**: ${profile.targetFat.toStringAsFixed(0)} g/día (${(profile.targetFat * 9.0).toStringAsFixed(0)} kcal)');
    buffer.writeln();
    buffer.writeln('## 5. Instrucciones Clínicas para la Estimación Visual (Gemini Vision)');
    buffer.writeln('- **Prioridad Proteica**: Presta atención especial a las fuentes de proteína para verificar si la porción cubre los requerimientos del objetivo ($goalDisplay).');
    buffer.writeln('- **Densidad Calórica y Grasa Oculta**: Ajusta las estimaciones de grasa oculta y aceite de cocina teniendo en cuenta el presupuesto calórico del comensal.');
    buffer.writeln('- **Volumetría de Carbohidratos**: Evalúa con rigor la cantidad de almidones, cereales y legumbres cocidas según las reglas volumétricas anatómicas.');
    buffer.writeln('- **Alineación con el Objetivo**: Ofrece observaciones en la justificación visual orientadas al cumplimiento de la meta de ${_formatGoalShort(profile.bodyGoal)}.');

    return buffer.toString();
  }

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

    final prompt = generateMasterPrompt(preliminary);
    return preliminary.copyWith(masterPrompt: prompt);
  }

  /// Direct conversion helper to DailyGoals
  static DailyGoals toDailyGoals(UserProfile profile) => profile.dailyGoals;

  /// Saves the profile to SQLite, synchronizes DailyGoals and Master Prompt
  /// into SecureStorage, sets onboarding complete, and refreshes active controllers.
  static Future<UserProfile> saveAndSynchronizeProfile(UserProfile profile) async {
    // 1. Persist to SQLite
    await DatabaseService.instance.saveUserProfile(profile);

    // 2. Sync DailyGoals to SecureStorage
    await SecureStorageService.instance.setDailyGoals(profile.dailyGoals);

    // 3. Persist Master Prompt in SecureStorage
    if (profile.masterPrompt != null && profile.masterPrompt!.trim().isNotEmpty) {
      await SecureStorageService.instance.setMasterPrompt(profile.masterPrompt!);
    }

    // 4. Mark onboarding completed
    await SecureStorageService.instance.setCompletedOnboarding(true);

    // 5. Refresh reactive goals in MealController if loaded
    try {
      await MealController.instance.refreshGoals();
    } catch (_) {}

    // 6. Synchronize in-memory SettingsController state
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

  // --- Display helpers ---

  static String _formatActivityDisplay(String activityLevel) {
    switch (normalizeActivityLevel(activityLevel)) {
      case 'sedentary':
        return 'Sedentario (poco o ningún ejercicio, factor 1.2x)';
      case 'light':
        return 'Ligero (ejercicio ligero 1-3 días/semana, factor 1.375x)';
      case 'moderate':
        return 'Moderado (ejercicio moderado 3-5 días/semana, factor 1.55x)';
      case 'very_active':
        return 'Muy Activo (ejercicio intenso 6-7 días/semana, factor 1.725x)';
      default:
        return 'Sedentario (factor 1.2x)';
    }
  }

  static String _formatGoalDisplay(String bodyGoal) {
    switch (normalizeBodyGoal(bodyGoal)) {
      case 'fat_loss':
        return 'Pérdida de Grasa (Déficit calórico de -500 kcal)';
      case 'muscle_gain':
        return 'Ganancia Muscular (Superávit calórico de +300 kcal)';
      case 'maintenance':
      default:
        return 'Mantenimiento Normocalórico (Gasto TDEE)';
    }
  }

  static String _formatGoalShort(String bodyGoal) {
    switch (normalizeBodyGoal(bodyGoal)) {
      case 'fat_loss':
        return 'déficit calórico controlado para pérdida de grasa';
      case 'muscle_gain':
        return 'superávit calórico limpio para hipertrofia';
      case 'maintenance':
      default:
        return 'mantenimiento normocalórico y recomposición';
    }
  }
}
