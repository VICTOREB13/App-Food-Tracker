import 'dart:ui' show Locale;
import '../l10n/app_localizations.dart';

/// Dictionary mapping of localized widget strings for Android native home widgets.
class HomeWidgetStrings {
  final String localeCode;
  final String caloriesLabel;
  final String caloriesSubtitle;
  final String kcalRemaining;
  final String actionAdd;
  final String labelProtein;
  final String labelCarbs;
  final String labelFat;
  final String suffixLeft;
  final String scanCameraTitle;
  final String scanCameraSubtitle;
  final String scanBarcodeTitle;
  final String scanBarcodeSubtitle;
  final String streakHeader;
  final String streakSubtitle;
  final String streakStatus;
  final String streakDaySingular;
  final String streakDayPlural;
  final String fastingStatusActive;
  final String fastingStatusInactive;
  final String fastingInactive;
  final String fastingTargetActivePrefix;
  final String fastingTargetInactivePrefix;
  final String btnFastingEnd;
  final String btnFastingStart;
  final String actionScanFood;
  final String actionBarcode;
  final String actionQuickMeal;
  final String actionWater;

  const HomeWidgetStrings({
    required this.localeCode,
    required this.caloriesLabel,
    required this.caloriesSubtitle,
    required this.kcalRemaining,
    required this.actionAdd,
    required this.labelProtein,
    required this.labelCarbs,
    required this.labelFat,
    required this.suffixLeft,
    required this.scanCameraTitle,
    required this.scanCameraSubtitle,
    required this.scanBarcodeTitle,
    required this.scanBarcodeSubtitle,
    required this.streakHeader,
    required this.streakSubtitle,
    required this.streakStatus,
    required this.streakDaySingular,
    required this.streakDayPlural,
    required this.fastingStatusActive,
    required this.fastingStatusInactive,
    required this.fastingInactive,
    required this.fastingTargetActivePrefix,
    required this.fastingTargetInactivePrefix,
    required this.btnFastingEnd,
    required this.btnFastingStart,
    required this.actionScanFood,
    required this.actionBarcode,
    required this.actionQuickMeal,
    required this.actionWater,
  });

  /// Builds a [HomeWidgetStrings] instance resolved from the given [Locale].
  factory HomeWidgetStrings.fromLocale(Locale locale) {
    final l10n = lookupAppLocalizations(locale);
    return HomeWidgetStrings(
      localeCode: locale.languageCode,
      caloriesLabel: l10n.widgetLabelCalories,
      caloriesSubtitle: l10n.widgetCaloriesSubtitle,
      kcalRemaining: l10n.widgetKcalRemaining,
      actionAdd: l10n.widgetActionAdd,
      labelProtein: l10n.widgetLabelProtein,
      labelCarbs: l10n.widgetLabelCarbs,
      labelFat: l10n.widgetLabelFat,
      suffixLeft: l10n.widgetSuffixLeft,
      scanCameraTitle: l10n.widgetScanCameraTitle,
      scanCameraSubtitle: l10n.widgetScanCameraSubtitle,
      scanBarcodeTitle: l10n.widgetScanBarcodeTitle,
      scanBarcodeSubtitle: l10n.widgetScanBarcodeSubtitle,
      streakHeader: l10n.widgetStreakHeader,
      streakSubtitle: l10n.widgetStreakSubtitle,
      streakStatus: l10n.widgetStreakStatus,
      streakDaySingular: l10n.widgetStreakDaySingular,
      streakDayPlural: l10n.widgetStreakDayPlural,
      fastingStatusActive: l10n.widgetFastingStatusActive,
      fastingStatusInactive: l10n.widgetFastingStatusInactive,
      fastingInactive: l10n.widgetFastingInactive,
      fastingTargetActivePrefix: l10n.widgetFastingTargetActivePrefix,
      fastingTargetInactivePrefix: l10n.widgetFastingTargetInactivePrefix,
      btnFastingEnd: l10n.widgetBtnFastingEnd,
      btnFastingStart: l10n.widgetBtnFastingStart,
      actionScanFood: l10n.widgetActionScanFood,
      actionBarcode: l10n.widgetActionBarcode,
      actionQuickMeal: l10n.widgetActionQuickMeal,
      actionWater: l10n.widgetActionWater,
    );
  }

  /// Exports key-value pairs matching Android SharedPreferences keys.
  Map<String, String> toMap() => {
    'app_locale_code': localeCode,
    'widget_label_calories': caloriesLabel,
    'label_calories': caloriesLabel,
    'widget_calories_subtitle': caloriesSubtitle,
    'label_calories_subtitle': caloriesSubtitle,
    'widget_kcal_remaining': kcalRemaining,
    'label_kcal_remaining': kcalRemaining,
    'widget_action_add': actionAdd,
    'label_action_add': actionAdd,
    'widget_label_protein': labelProtein,
    'label_protein': labelProtein,
    'widget_label_carbs': labelCarbs,
    'label_carbs': labelCarbs,
    'widget_label_fat': labelFat,
    'label_fat': labelFat,
    'widget_suffix_left': suffixLeft,
    'label_suffix_left': suffixLeft,
    'widget_scan_camera_title': scanCameraTitle,
    'label_scan_camera_title': scanCameraTitle,
    'widget_scan_camera_subtitle': scanCameraSubtitle,
    'label_scan_camera_subtitle': scanCameraSubtitle,
    'widget_scan_barcode_title': scanBarcodeTitle,
    'label_scan_barcode_title': scanBarcodeTitle,
    'widget_scan_barcode_subtitle': scanBarcodeSubtitle,
    'label_scan_barcode_subtitle': scanBarcodeSubtitle,
    'widget_streak_header': streakHeader,
    'label_streak_header': streakHeader,
    'widget_streak_subtitle': streakSubtitle,
    'label_streak_subtitle': streakSubtitle,
    'widget_streak_status': streakStatus,
    'label_streak_status': streakStatus,
    'widget_streak_day_singular': streakDaySingular,
    'label_streak_day_singular': streakDaySingular,
    'widget_streak_day_plural': streakDayPlural,
    'label_streak_day_plural': streakDayPlural,
    'widget_fasting_status_active': fastingStatusActive,
    'label_fasting_status_active': fastingStatusActive,
    'widget_fasting_status_inactive': fastingStatusInactive,
    'label_fasting_status_inactive': fastingStatusInactive,
    'widget_fasting_inactive': fastingInactive,
    'label_fasting_inactive': fastingInactive,
    'widget_fasting_target_active_prefix': fastingTargetActivePrefix,
    'label_fasting_target_active_prefix': fastingTargetActivePrefix,
    'widget_fasting_target_inactive_prefix': fastingTargetInactivePrefix,
    'label_fasting_target_inactive_prefix': fastingTargetInactivePrefix,
    'widget_btn_fasting_end': btnFastingEnd,
    'label_btn_fasting_end': btnFastingEnd,
    'widget_btn_fasting_start': btnFastingStart,
    'label_btn_fasting_start': btnFastingStart,
    'widget_action_scan_food': actionScanFood,
    'label_action_scan_food': actionScanFood,
    'widget_action_barcode': actionBarcode,
    'label_action_barcode': actionBarcode,
    'widget_action_quick_meal': actionQuickMeal,
    'label_action_quick_meal': actionQuickMeal,
    'widget_action_water': actionWater,
    'label_action_water': actionWater,
  };
}
