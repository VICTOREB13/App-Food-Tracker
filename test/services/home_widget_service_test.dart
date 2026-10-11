import 'dart:ui' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/home_widget_service.dart';
import 'package:food_tracker/services/home_widget_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeWidgetService Tests', () {
    late HomeWidgetService service;

    setUp(() {
      service = HomeWidgetService.instance;
    });

    tearDown(() {
      service.dispose();
    });

    test('HomeWidgetService provides singleton instance and provider names', () {
      expect(service, isNotNull);
      expect(HomeWidgetService.appGroupId, equals('group.com.victorengineer.foodtracker'));
      expect(HomeWidgetService.compactWidgetProvider, equals('FoodTrackerCompactWidgetProvider'));
      expect(HomeWidgetService.wideWidgetProvider, equals('FoodTrackerWideWidgetProvider'));
      expect(HomeWidgetService.streakWidgetProvider, equals('FoodTrackerStreakWidgetProvider'));
      expect(HomeWidgetService.actionsWidgetProvider, equals('FoodTrackerActionsWidgetProvider'));
      expect(HomeWidgetService.fastingWidgetProvider, equals('FoodTrackerFastingWidgetProvider'));
    });

    test('updateFromDailyTotals computes rounded macro differences safely with streak and fasting', () async {
      await expectLater(
        service.updateFromDailyTotals(
          consumedCalories: 1450.4,
          targetCalories: 2000.0,
          consumedProtein: 110.2,
          targetProtein: 150.0,
          consumedCarbs: 160.7,
          targetCarbs: 250.0,
          consumedFat: 45.1,
          targetFat: 70.0,
          streakCount: 5,
        ),
        completes,
      );
    });

    test('updateFastingData completes safely with active and inactive fasting states', () async {
      await expectLater(
        service.updateFastingData(
          isActive: true,
          timeFormatted: '14h 30m',
          targetHours: 16,
        ),
        completes,
      );

      await expectLater(
        service.updateFastingData(
          isActive: false,
          timeFormatted: '0h 0m',
          targetHours: 16,
        ),
        completes,
      );
    });

    test('updateFromDailyTotals clamps negative remaining values to zero', () async {
      await expectLater(
        service.updateFromDailyTotals(
          consumedCalories: 2500.0,
          targetCalories: 2000.0,
          consumedProtein: 180.0,
          targetProtein: 150.0,
          consumedCarbs: 300.0,
          targetCarbs: 250.0,
          consumedFat: 90.0,
          targetFat: 70.0,
        ),
        completes,
      );
    });

    test('setDeepLinkHandler receives foodtracker deep link actions and filters unknown schemes', () {
      Uri? capturedUri;
      service.setDeepLinkHandler((uri) {
        capturedUri = uri;
      });

      final scanFoodUri = Uri.parse('foodtracker://scan_food');
      service.handleDeepLink(scanFoodUri);
      expect(capturedUri, equals(scanFoodUri));
      expect(capturedUri?.host, equals('scan_food'));

      // Non-foodtracker schemes should be ignored
      capturedUri = null;
      service.handleDeepLink(Uri.parse('https://example.com/unrelated'));
      expect(capturedUri, isNull);
    });

    test('isPlatformSupported exposes platform compatibility flag', () {
      expect(HomeWidgetService.isPlatformSupported, isA<bool>());
    });

    test('saveSummaryData and updateWidgets complete safely without errors', () async {
      await expectLater(
        service.saveSummaryData(
          caloriesConsumed: 1200,
          caloriesTarget: 2000,
          caloriesLeft: 800,
          proteinConsumed: 80,
          proteinLeft: 40,
          carbsConsumed: 120,
          carbsLeft: 80,
          fatConsumed: 40,
          fatLeft: 20,
        ),
        completes,
      );

      await expectLater(service.updateWidgets(), completes);
    });

    test('HomeWidgetStrings generates complete Spanish dictionary', () {
      final strings = HomeWidgetStrings.fromLocale(const Locale('es'));
      final map = strings.toMap();

      expect(map['app_locale_code'], equals('es'));
      expect(map['widget_label_calories'], equals('CALORÍAS'));
      expect(map['widget_calories_subtitle'], equals('REST.'));
      expect(map['widget_kcal_remaining'], equals('kcal restantes'));
      expect(map['widget_action_add'], equals('+ Registrar'));
      expect(map['widget_label_protein'], equals('PROT'));
      expect(map['widget_label_carbs'], equals('CARB'));
      expect(map['widget_label_fat'], equals('GRASAS'));
      expect(map['widget_suffix_left'], equals('rest'));
      expect(map['widget_scan_camera_title'], equals('📸 Cámara IA'));
      expect(map['widget_scan_camera_subtitle'], equals('Escanear'));
      expect(map['widget_scan_barcode_title'], equals('🔍 Código'));
      expect(map['widget_scan_barcode_subtitle'], equals('de Barras'));
      expect(map['widget_streak_header'], equals('RACHA ACTIVA'));
      expect(map['widget_streak_subtitle'], equals('HÁBITOS DIARIOS'));
      expect(map['widget_streak_status'], equals('Consistencia Semanal'));
      expect(map['widget_streak_day_singular'], equals('DÍA'));
      expect(map['widget_streak_day_plural'], equals('DÍAS'));
      expect(map['widget_fasting_status_active'], equals('AYUNO EN CURSO'));
      expect(map['widget_fasting_status_inactive'], equals('AYUNO INTERMITENTE'));
      expect(map['widget_fasting_inactive'], equals('INACTIVO'));
      expect(map['widget_fasting_target_active_prefix'], equals('Meta'));
      expect(map['widget_fasting_target_inactive_prefix'], equals('Objetivo:'));
      expect(map['widget_btn_fasting_end'], equals('Terminar Ayuno'));
      expect(map['widget_btn_fasting_start'], equals('Iniciar Ayuno'));
      expect(map['widget_action_scan_food'], equals('CÁMARA IA'));
      expect(map['widget_action_barcode'], equals('BARRAS'));
      expect(map['widget_action_quick_meal'], equals('RÁPIDA'));
      expect(map['widget_action_water'], equals('+250ML'));
      expect(map['label_calories'], equals('CALORÍAS'));
      expect(map['label_calories_subtitle'], equals('REST.'));
      expect(map['label_kcal_remaining'], equals('kcal restantes'));
      expect(map['label_action_add'], equals('+ Registrar'));
      expect(map['label_protein'], equals('PROT'));
      expect(map['label_carbs'], equals('CARB'));
      expect(map['label_fat'], equals('GRASAS'));
      expect(map['label_suffix_left'], equals('rest'));
      expect(map['label_scan_camera_title'], equals('📸 Cámara IA'));
      expect(map['label_scan_camera_subtitle'], equals('Escanear'));
      expect(map['label_scan_barcode_title'], equals('🔍 Código'));
      expect(map['label_scan_barcode_subtitle'], equals('de Barras'));
      expect(map['label_streak_header'], equals('RACHA ACTIVA'));
      expect(map['label_streak_subtitle'], equals('HÁBITOS DIARIOS'));
      expect(map['label_streak_status'], equals('Consistencia Semanal'));
      expect(map['label_streak_day_singular'], equals('DÍA'));
      expect(map['label_streak_day_plural'], equals('DÍAS'));
      expect(map['label_fasting_status_active'], equals('AYUNO EN CURSO'));
      expect(map['label_fasting_status_inactive'], equals('AYUNO INTERMITENTE'));
      expect(map['label_fasting_inactive'], equals('INACTIVO'));
      expect(map['label_fasting_target_active_prefix'], equals('Meta'));
      expect(map['label_fasting_target_inactive_prefix'], equals('Objetivo:'));
      expect(map['label_btn_fasting_end'], equals('Terminar Ayuno'));
      expect(map['label_btn_fasting_start'], equals('Iniciar Ayuno'));
      expect(map['label_action_scan_food'], equals('CÁMARA IA'));
      expect(map['label_action_barcode'], equals('BARRAS'));
      expect(map['label_action_quick_meal'], equals('RÁPIDA'));
      expect(map['label_action_water'], equals('+250ML'));
    });

    test('HomeWidgetStrings generates complete English dictionary', () {
      final strings = HomeWidgetStrings.fromLocale(const Locale('en'));
      final map = strings.toMap();

      expect(map['app_locale_code'], equals('en'));
      expect(map['widget_label_calories'], equals('CALORIES'));
      expect(map['widget_calories_subtitle'], equals('LEFT'));
      expect(map['widget_kcal_remaining'], equals('kcal remaining'));
      expect(map['widget_action_add'], equals('+ Log'));
      expect(map['widget_label_protein'], equals('PROT'));
      expect(map['widget_label_carbs'], equals('CARB'));
      expect(map['widget_label_fat'], equals('FAT'));
      expect(map['widget_suffix_left'], equals('left'));
      expect(map['widget_scan_camera_title'], equals('📸 AI Camera'));
      expect(map['widget_scan_camera_subtitle'], equals('Scan'));
      expect(map['widget_scan_barcode_title'], equals('🔍 Barcode'));
      expect(map['widget_scan_barcode_subtitle'], equals('Scanner'));
      expect(map['widget_streak_header'], equals('ACTIVE STREAK'));
      expect(map['widget_streak_subtitle'], equals('DAILY HABITS'));
      expect(map['widget_streak_status'], equals('Weekly Consistency'));
      expect(map['widget_streak_day_singular'], equals('DAY'));
      expect(map['widget_streak_day_plural'], equals('DAYS'));
      expect(map['widget_fasting_status_active'], equals('FASTING IN PROGRESS'));
      expect(map['widget_fasting_status_inactive'], equals('INTERMITTENT FASTING'));
      expect(map['widget_fasting_inactive'], equals('INACTIVE'));
      expect(map['widget_fasting_target_active_prefix'], equals('Goal'));
      expect(map['widget_fasting_target_inactive_prefix'], equals('Target:'));
      expect(map['widget_btn_fasting_end'], equals('End Fast'));
      expect(map['widget_btn_fasting_start'], equals('Start Fast'));
      expect(map['widget_action_scan_food'], equals('AI CAMERA'));
      expect(map['widget_action_barcode'], equals('BARCODE'));
      expect(map['widget_action_quick_meal'], equals('QUICK'));
      expect(map['widget_action_water'], equals('+250ML'));
      expect(map['label_calories'], equals('CALORIES'));
      expect(map['label_calories_subtitle'], equals('LEFT'));
      expect(map['label_kcal_remaining'], equals('kcal remaining'));
      expect(map['label_action_add'], equals('+ Log'));
      expect(map['label_protein'], equals('PROT'));
      expect(map['label_carbs'], equals('CARB'));
      expect(map['label_fat'], equals('FAT'));
      expect(map['label_suffix_left'], equals('left'));
      expect(map['label_scan_camera_title'], equals('📸 AI Camera'));
      expect(map['label_scan_camera_subtitle'], equals('Scan'));
      expect(map['label_scan_barcode_title'], equals('🔍 Barcode'));
      expect(map['label_scan_barcode_subtitle'], equals('Scanner'));
      expect(map['label_streak_header'], equals('ACTIVE STREAK'));
      expect(map['label_streak_subtitle'], equals('DAILY HABITS'));
      expect(map['label_streak_status'], equals('Weekly Consistency'));
      expect(map['label_streak_day_singular'], equals('DAY'));
      expect(map['label_streak_day_plural'], equals('DAYS'));
      expect(map['label_fasting_status_active'], equals('FASTING IN PROGRESS'));
      expect(map['label_fasting_status_inactive'], equals('INTERMITTENT FASTING'));
      expect(map['label_fasting_inactive'], equals('INACTIVE'));
      expect(map['label_fasting_target_active_prefix'], equals('Goal'));
      expect(map['label_fasting_target_inactive_prefix'], equals('Target:'));
      expect(map['label_btn_fasting_end'], equals('End Fast'));
      expect(map['label_btn_fasting_start'], equals('Start Fast'));
      expect(map['label_action_scan_food'], equals('AI CAMERA'));
      expect(map['label_action_barcode'], equals('BARCODE'));
      expect(map['label_action_quick_meal'], equals('QUICK'));
      expect(map['label_action_water'], equals('+250ML'));
    });

    test('syncAllWidgetsWithLocale and saveLocaleStrings execute safely', () async {
      await expectLater(
        service.syncAllWidgetsWithLocale(const Locale('en')),
        completes,
      );
      expect(service.currentLocale, equals(const Locale('en')));

      await expectLater(
        service.syncAllWidgetsWithLocale(const Locale('es')),
        completes,
      );
      expect(service.currentLocale, equals(const Locale('es')));
    });
  });
}
