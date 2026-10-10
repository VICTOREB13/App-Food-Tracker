import 'app_localizations_en_meal.dart';

abstract class AppLocalizationsEnMetrics extends AppLocalizationsEnMeal {
  AppLocalizationsEnMetrics([super.locale = 'en']);

  @override String get metrics => 'Metrics';
  @override String get streak => 'Streak';
  @override String get weeklyDigest => 'Weekly Digest';
  @override String get clinicalReport => 'Clinical Report';
  @override String get analysisStageVolumetric => 'Estimating 3D geometry and volumetric portion...';
  @override String get clinicalReportTitle => 'Clinical Report';
  @override String get timeRangeLabel => 'Time range:';
  @override String get streakOneDay => '1 day';
  @override String streakMultipleDays(String days) => '${days} days';
  @override String get metricsAndProgress => 'Metrics & Progress';
  @override String targetCaloriesCompliance(String target, String percent) => 'Target: ${target} kcal (${percent}%)';
  @override String daysRange(String days) => '${days} days';
  @override String get macroDistributionHeader => 'MACRO DISTRIBUTION';
  @override String get weightRangeError => 'Weight must be between 20.0 and 350.0 kg';
  @override String get streakDaySingular => 'day streak';
  @override String get streakDayPlural => 'days streak';
  @override String get weeklyDigestHeader => 'WEEKLY SUMMARY (7 DAYS)';
  @override String get noWeightDataInRange => 'No weight records in this range';
  @override String get weightTrendHeader => 'WEIGHT TREND';
  @override String get enterValidBiometricsPrompt => 'Please complete your valid body measurements to continue.';
  @override String get clinicalMetabolismTitle => 'Precise Clinical Metabolism';
  @override String get clinicalMetabolismDesc => 'Mifflin-St Jeor formulas tailored to your routine and goals.';
  @override String get biometricsTitle => 'Biological Parameters';
  @override String get biometricsSubtitle => 'Clinical Mifflin-St Jeor formulas to accurately calculate metabolism.';
  @override String get fatLossClinicalDesc => 'Clinical calorie deficit with BMR protection floor';
  @override String get biometricDataHeader => 'BIOMETRIC DATA';
  @override String get enterBiometricsToCalculate => 'Enter your biometric data to calculate profile';
  @override String get macroDistributionTitle => 'Macronutrient Distribution';

  @override String macroGoalTarget(String percent, String target) => '$percent% · Goal: ${target}g';
  @override String weightLoggedSuccess(String weight) => '⚖️ Weight logged: $weight kg';
  @override String weightLogError(String error) => 'Error recording weight: $error';
  @override String get dayStreak => 'day streak';
  @override String get daysStreak => 'days streak';
  @override String activeDaysTotalLogged(String count) => '$count total days logged';
  @override String activeDaysTotalConsistency(String active, String total, String percent) => '$active of $total days logged ($percent%)';
  @override String get macroConsistencyLabel => 'Macronutrient Consistency (Average / Goal):';

  @override String get streakUnstoppable => 'Unstoppable 🔥';
  @override String get streakGoodPace => 'Good pace ✨';
  @override String get streakActive => 'Active 💪';
  @override String get streakStartToday => 'Start today 🎯';

  @override String get singleRecord => 'log';
  @override String get multipleRecords => 'logs';
  @override String get viewLess => 'View less';
  @override String viewAllCount(String count) => 'View all ($count)';
  @override String get noWeightLogsInRange => 'No weight logs in this range';
}

