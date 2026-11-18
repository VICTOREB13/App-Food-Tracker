import 'package:food_tracker/features/settings_profile/models/user_profile.dart';
import 'package:food_tracker/features/biometrics_weight/services/metabolic_calculator.dart';

/// Clinical Master Prompt synthesizer translating user biometrics and metabolic targets
/// into Markdown format for multimodal AI visual meal analysis (Gemini Vision).
class MetabolicPromptGenerator {
  /// Synthesizes the Master Prompt in Markdown format for injection into Gemini Vision
  static String generate(UserProfile profile, {String language = 'es'}) {
    final isEn = language.toLowerCase().startsWith('en');
    final genderDisplay = isEn
        ? (profile.gender == 'female' ? 'Female' : 'Male')
        : (profile.gender == 'female' ? 'Femenino' : 'Masculino');
    final activityDisplay = _formatActivityDisplay(profile.activityLevel, isEn: isEn);
    final goalDisplay = _formatGoalDisplay(profile.bodyGoal, isEn: isEn);

    final weightDisplay = (profile.weight % 1 == 0)
        ? profile.weight.toStringAsFixed(1)
        : profile.weight.toString();

    final buffer = StringBuffer();
    if (isEn) {
      buffer.writeln('# Diner Biological Context and Nutritional Goals\n');
      buffer.writeln('## 1. Biometric Data');
      buffer.writeln('- **Name**: ${profile.name?.trim().isNotEmpty == true ? profile.name : 'Diner'}');
      buffer.writeln('- **Age**: ${profile.age} years');
      buffer.writeln('- **Biological Sex**: $genderDisplay');
      buffer.writeln('- **Height**: ${profile.height.toStringAsFixed(1)} cm');
      buffer.writeln('- **Current Weight**: $weightDisplay kg\n');
      buffer.writeln('## 2. Activity Level and Energy Expenditure');
      buffer.writeln('- **Activity Level**: $activityDisplay');
      buffer.writeln('- **Estimated Daily Steps**: ${profile.estimatedSteps} steps/day');
      buffer.writeln('- **Basal Metabolic Rate (BMR - Mifflin-St Jeor)**: ${profile.bmr.toStringAsFixed(0)} kcal/day');
      buffer.writeln('- **Total Daily Energy Expenditure (TDEE)**: ${profile.tdee.toStringAsFixed(0)} kcal/day\n');
      buffer.writeln('## 3. Metabolic Goals and Objectives');
      buffer.writeln('- **Body Goal**: $goalDisplay');
      buffer.writeln('- **Daily Caloric Budget**: ${profile.targetCalories.toStringAsFixed(0)} kcal/day');
      buffer.writeln('- **Protein**: ${profile.targetProtein.toStringAsFixed(0)} g/day (${(profile.targetProtein * 4.0).toStringAsFixed(0)} kcal)');
      buffer.writeln('- **Carbohydrates**: ${profile.targetCarbs.toStringAsFixed(0)} g/day (${(profile.targetCarbs * 4.0).toStringAsFixed(0)} kcal)');
      buffer.writeln('- **Fat**: ${profile.targetFat.toStringAsFixed(0)} g/day (${(profile.targetFat * 9.0).toStringAsFixed(0)} kcal)\n');
      buffer.writeln('## 4. Clinical Directives for Visual Estimation (Gemini Vision)');
      buffer.writeln('- **Protein Priority**: Pay close attention to protein portions to ensure goal requirements ($goalDisplay).');
      buffer.writeln('- **Caloric Density & Hidden Fat**: Account for cooking oils and hidden fats considering the daily calorie budget.');
      buffer.writeln('- **Carbohydrate Volumetrics**: Rigorously assess starches, grains, and cooked legumes following anatomical volumetric rules.');
      buffer.writeln('- **Goal Alignment**: Tailor observations towards achieving ${_formatGoalShort(profile.bodyGoal, isEn: isEn)}.');
    } else {
      buffer.writeln('# Contexto Biológico y Metas Nutricionales del Comensal\n');
      buffer.writeln('## 1. Datos Biométricos');
      buffer.writeln('- **Nombre**: ${profile.name?.trim().isNotEmpty == true ? profile.name : 'Comensal'}');
      buffer.writeln('- **Edad**: ${profile.age} años');
      buffer.writeln('- **Género Biológico**: $genderDisplay');
      buffer.writeln('- **Estatura**: ${profile.height.toStringAsFixed(1)} cm');
      buffer.writeln('- **Peso Actual**: $weightDisplay kg\n');
      buffer.writeln('## 2. Nivel de Actividad y Gasto Energético');
      buffer.writeln('- **Nivel de Actividad**: $activityDisplay');
      buffer.writeln('- **Pasos Diarios Estimados**: ${profile.estimatedSteps} pasos/día');
      buffer.writeln('- **Tasa Metabólica Basal (TMB / BMR - Mifflin-St Jeor)**: ${profile.bmr.toStringAsFixed(0)} kcal/día');
      buffer.writeln('- **Gasto Energético Diario Total (TDEE)**: ${profile.tdee.toStringAsFixed(0)} kcal/día\n');
      buffer.writeln('## 3. Metas Metabólicas y Objetivos');
      buffer.writeln('- **Objetivo Corporal**: $goalDisplay');
      buffer.writeln('- **Presupuesto Calórico Diario**: ${profile.targetCalories.toStringAsFixed(0)} kcal/día');
      buffer.writeln('- **Proteínas**: ${profile.targetProtein.toStringAsFixed(0)} g/día (${(profile.targetProtein * 4.0).toStringAsFixed(0)} kcal)');
      buffer.writeln('- **Carbohidratos**: ${profile.targetCarbs.toStringAsFixed(0)} g/día (${(profile.targetCarbs * 4.0).toStringAsFixed(0)} kcal)');
      buffer.writeln('- **Grasas**: ${profile.targetFat.toStringAsFixed(0)} g/día (${(profile.targetFat * 9.0).toStringAsFixed(0)} kcal)\n');
      buffer.writeln('## 4. Instrucciones Clínicas para la Estimación Visual (Gemini Vision)');
      buffer.writeln('- **Prioridad Proteica**: Presta atención especial a las fuentes de proteína para verificar si la porción cubre los requerimientos del objetivo ($goalDisplay).');
      buffer.writeln('- **Densidad Calórica y Grasa Oculta**: Ajusta las estimaciones de grasa oculta y aceite de cocina teniendo en cuenta el presupuesto calórico del comensal.');
      buffer.writeln('- **Volumetría de Carbohidratos**: Evalúa con rigor la cantidad de almidones, cereales y legumbres cocidas según las reglas volumétricas anatómicas.');
      buffer.writeln('- **Alineación con el Objetivo**: Ofrece observaciones en la justificación visual orientadas al cumplimiento de la meta de ${_formatGoalShort(profile.bodyGoal, isEn: isEn)}.');
    }

    return buffer.toString();
  }

  static String _formatActivityDisplay(String activityLevel, {bool isEn = false}) {
    switch (MetabolicCalculator.normalizeActivityLevel(activityLevel)) {
      case 'very_active':
        return isEn
            ? 'Very Active (intense exercise 6-7 days/week, 1.725x factor)'
            : 'Muy Activo (ejercicio intenso 6-7 días/semana, factor 1.725x)';
      case 'moderate':
        return isEn
            ? 'Moderate (moderate exercise 3-5 days/week, 1.55x factor)'
            : 'Moderado (ejercicio moderado 3-5 días/semana, factor 1.55x)';
      case 'light':
        return isEn
            ? 'Light (light exercise 1-3 days/week, 1.375x factor)'
            : 'Ligero (ejercicio ligero 1-3 días/semana, factor 1.375x)';
      case 'sedentary':
      default:
        return isEn
            ? 'Sedentary (little or no exercise, 1.2x factor)'
            : 'Sedentario (poco o ningún ejercicio, factor 1.2x)';
    }
  }

  static String _formatGoalDisplay(String bodyGoal, {bool isEn = false}) {
    switch (MetabolicCalculator.normalizeBodyGoal(bodyGoal)) {
      case 'fat_loss':
        return isEn
            ? 'Fat Loss (Caloric deficit of -500 kcal)'
            : 'Pérdida de Grasa (Déficit calórico de -500 kcal)';
      case 'muscle_gain':
        return isEn
            ? 'Muscle Gain (Caloric surplus of +300 kcal)'
            : 'Ganancia Muscular (Superávit calórico de +300 kcal)';
      case 'maintenance':
      default:
        return isEn
            ? 'Maintenance (TDEE Expenditure)'
            : 'Mantenimiento Normocalórico (Gasto TDEE)';
    }
  }

  static String _formatGoalShort(String bodyGoal, {bool isEn = false}) {
    switch (MetabolicCalculator.normalizeBodyGoal(bodyGoal)) {
      case 'fat_loss':
        return isEn ? 'controlled caloric deficit for fat loss' : 'déficit calórico controlado para pérdida de grasa';
      case 'muscle_gain':
        return isEn ? 'clean caloric surplus for hypertrophy' : 'superávit calórico limpio para hipertrofia';
      case 'maintenance':
      default:
        return isEn ? 'normocaloric maintenance and recomposition' : 'mantenimiento normocalórico y recomposición';
    }
  }
}
