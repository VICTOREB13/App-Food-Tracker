import '../models/user_profile.dart';
import 'metabolic_calculator.dart';

/// Clinical Master Prompt synthesizer translating user biometrics and metabolic targets
/// into Markdown format for multimodal AI visual meal analysis (Gemini Vision).
class MetabolicPromptGenerator {
  /// Synthesizes the Master Prompt in Markdown format for injection into Gemini Vision
  static String generate(UserProfile profile) {
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
    buffer.writeln('- **Proteínas**: ${profile.targetProtein.toStringAsFixed(0)} g/día (${(profile.targetProtein * 4.0).toStringAsFixed(0)} kcal)');
    buffer.writeln('- **Carbohidratos**: ${profile.targetCarbs.toStringAsFixed(0)} g/día (${(profile.targetCarbs * 4.0).toStringAsFixed(0)} kcal)');
    buffer.writeln('- **Grasas**: ${profile.targetFat.toStringAsFixed(0)} g/día (${(profile.targetFat * 9.0).toStringAsFixed(0)} kcal)');
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

  static String _formatActivityDisplay(String activityLevel) {
    switch (MetabolicCalculator.normalizeActivityLevel(activityLevel)) {
      case 'very_active':
        return 'Muy Activo (ejercicio intenso 6-7 días/semana, factor 1.725x)';
      case 'moderate':
        return 'Moderado (ejercicio moderado 3-5 días/semana, factor 1.55x)';
      case 'light':
        return 'Ligero (ejercicio ligero 1-3 días/semana, factor 1.375x)';
      case 'sedentary':
      default:
        return 'Sedentario (poco o ningún ejercicio, factor 1.2x)';
    }
  }

  static String _formatGoalDisplay(String bodyGoal) {
    switch (MetabolicCalculator.normalizeBodyGoal(bodyGoal)) {
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
    switch (MetabolicCalculator.normalizeBodyGoal(bodyGoal)) {
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
