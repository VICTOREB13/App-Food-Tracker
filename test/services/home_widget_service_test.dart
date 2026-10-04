import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/services/home_widget_service.dart';

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
    });

    test('updateFromDailyTotals computes rounded macro differences safely', () async {
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
  });
}
