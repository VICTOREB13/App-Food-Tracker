import 'app_localizations_es_meal.dart';

abstract class AppLocalizationsEsMetrics extends AppLocalizationsEsMeal {
  AppLocalizationsEsMetrics([super.locale = 'es']);

  @override String get metrics => 'Métricas';
  @override String get streak => 'Racha';
  @override String get weeklyDigest => 'Resumen Semanal';
  @override String get clinicalReport => 'Reporte Clínico';
  @override String get analysisStageVolumetric => 'Estimando geometría 3D y cubicaje volumétrico...';
  @override String get clinicalReportTitle => 'Reporte Clínico';
  @override String get timeRangeLabel => 'Rango temporal:';
  @override String get streakOneDay => '1 día';
  @override String streakMultipleDays(String days) => '$days días';
  @override String get metricsAndProgress => 'Métricas y Progreso';
  @override String targetCaloriesCompliance(String target, String percent) => 'Meta: $target kcal ($percent%)';
  @override String daysRange(String days) => '$days días';
  @override String get macroDistributionHeader => 'DISTRIBUCIÓN DE MACROS';
  @override String get weightRangeError => 'El peso debe estar entre 20.0 y 350.0 kg';
  @override String get streakDaySingular => 'día racha';
  @override String get streakDayPlural => 'días racha';
  @override String get weeklyDigestHeader => 'RESUMEN SEMANAL (7 DÍAS)';
  @override String get noWeightDataInRange => 'Sin registros de peso en este rango';
  @override String get weightTrendHeader => 'TENDENCIA DE PESO';
  @override String get enterValidBiometricsPrompt => 'Por favor, completa tus datos corporales válidos para continuar.';
  @override String get clinicalMetabolismTitle => 'Metabolismo Clínico Preciso';
  @override String get clinicalMetabolismDesc => 'Fórmulas de Mifflin-St Jeor adaptadas a tu rutina y objetivos.';
  @override String get biometricsTitle => 'Parámetros Biológicos';
  @override String get biometricsSubtitle => 'Fórmulas clínicas de Mifflin-St Jeor para determinar con precisión tu gasto metabólico.';
  @override String get fatLossClinicalDesc => 'Déficit calórico clínico con piso de protección en TMB';
  @override String get biometricDataHeader => 'DATOS BIOMÉTRICOS';
  @override String get enterBiometricsToCalculate => 'Ingresa tus datos biométricos para calcular el perfil';
  @override String get macroDistributionTitle => 'Distribución de Macronutrientes';

  @override String macroGoalTarget(String percent, String target) => '$percent% · Meta: ${target}g';
  @override String weightLoggedSuccess(String weight) => '⚖️ Peso guardado: $weight kg';
  @override String weightLogError(String error) => 'Error al registrar peso: $error';
  @override String get dayStreak => 'día racha';
  @override String get daysStreak => 'días racha';
  @override String activeDaysTotalLogged(String count) => '$count días registrados en total';
  @override String activeDaysTotalConsistency(String active, String total, String percent) => '$active de $total días registrados ($percent%)';
  @override String get macroConsistencyLabel => 'Consistencia de Macronutrientes (Promedio / Meta):';

  @override String get streakUnstoppable => 'Imparable 🔥';
  @override String get streakGoodPace => 'Buen ritmo ✨';
  @override String get streakActive => 'Activo 💪';
  @override String get streakStartToday => 'Comienza hoy 🎯';

  @override String get singleRecord => 'registro';
  @override String get multipleRecords => 'registros';
  @override String get viewLess => 'Ver menos';
  @override String viewAllCount(String count) => 'Ver todos ($count)';
  @override String get noWeightLogsInRange => 'Sin registros de peso en este rango';
}

