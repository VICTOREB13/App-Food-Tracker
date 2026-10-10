import 'app_localizations_meal.dart';

abstract class AppLocalizationsMetrics extends AppLocalizationsMeal {
  AppLocalizationsMetrics(super.locale);

  String get metrics;
  String get streak;
  String get weeklyDigest;
  String get clinicalReport;
  String get analysisStageVolumetric;
  String get clinicalReportTitle;
  String get timeRangeLabel;
  String get streakOneDay;
  String streakMultipleDays(String days);
  String get metricsAndProgress;
  String targetCaloriesCompliance(String target, String percent);
  String daysRange(String days);
  String get macroDistributionHeader;
  String get weightRangeError;
  String get streakDaySingular;
  String get streakDayPlural;
  String get weeklyDigestHeader;
  String get noWeightDataInRange;
  String get weightTrendHeader;
  String get enterValidBiometricsPrompt;
  String get clinicalMetabolismTitle;
  String get clinicalMetabolismDesc;
  String get biometricsTitle;
  String get biometricsSubtitle;
  String get fatLossClinicalDesc;
  String get biometricDataHeader;
  String get enterBiometricsToCalculate;
  String get macroDistributionTitle;

  String macroGoalTarget(String percent, String target);
  String weightLoggedSuccess(String weight);
  String weightLogError(String error);
  String get dayStreak;
  String get daysStreak;
  String activeDaysTotalLogged(String count);
  String activeDaysTotalConsistency(String active, String total, String percent);
  String get macroConsistencyLabel;

  String get streakUnstoppable;
  String get streakGoodPace;
  String get streakActive;
  String get streakStartToday;

  String get singleRecord;
  String get multipleRecords;
  String get viewLess;
  String viewAllCount(String count);
  String get noWeightLogsInRange;
}

