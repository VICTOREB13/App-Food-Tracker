import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Handler callback for deep links triggered from home widgets.
typedef HomeWidgetDeepLinkHandler = void Function(Uri uri);

/// Service orchestrating data synchronization and interaction with Android Native Home Widgets.
class HomeWidgetService {
  static final HomeWidgetService instance = HomeWidgetService._();
  HomeWidgetService._();

  static const String appGroupId = 'group.com.victorengineer.foodtracker';
  static const String compactWidgetProvider = 'FoodTrackerCompactWidgetProvider';
  static const String wideWidgetProvider = 'FoodTrackerWideWidgetProvider';

  HomeWidgetDeepLinkHandler? _deepLinkHandler;
  StreamSubscription<Uri?>? _widgetClickedSubscription;
  bool _isInitialized = false;

  /// Whether the host platform supports Android/iOS native home widgets.
  static bool get isPlatformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Initializes deep link listeners and registers app group id.
  Future<void> init({HomeWidgetDeepLinkHandler? onDeepLink}) async {
    if (onDeepLink != null) {
      _deepLinkHandler = onDeepLink;
    }

    if (_isInitialized) return;
    _isInitialized = true;

    if (!isPlatformSupported) {
      return;
    }

    try {
      await HomeWidget.setAppGroupId(appGroupId).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('HomeWidget setAppGroupId timeout');
          return null;
        },
      );
    } catch (e) {
      debugPrint('HomeWidgetService: Failed to set app group id: $e');
    }

    try {
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (initialUri != null) {
        handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('HomeWidgetService: Error checking initial launch uri: $e');
    }

    _widgetClickedSubscription?.cancel();
    try {
      _widgetClickedSubscription = HomeWidget.widgetClicked.listen(
        (Uri? uri) {
          if (uri != null) {
            handleDeepLink(uri);
          }
        },
        onError: (dynamic error) {
          debugPrint('HomeWidgetService: Widget clicked listener error: $error');
        },
      );
    } catch (e) {
      debugPrint('HomeWidgetService: Failed to subscribe to widget clicked: $e');
    }
  }

  /// Sets or updates the active deep link callback.
  void setDeepLinkHandler(HomeWidgetDeepLinkHandler handler) {
    _deepLinkHandler = handler;
  }

  /// Dispatches recognized widget deep links to the registered handler.
  @visibleForTesting
  void handleDeepLink(Uri uri) {
    debugPrint('HomeWidgetService: Received deep link: $uri');
    if (uri.scheme == 'foodtracker') {
      _deepLinkHandler?.call(uri);
    }
  }

  /// Saves macro & calorie summary values into native widget storage.
  Future<void> saveSummaryData({
    required int caloriesConsumed,
    required int caloriesTarget,
    required int caloriesLeft,
    required int proteinConsumed,
    required int proteinLeft,
    required int carbsConsumed,
    required int carbsLeft,
    required int fatConsumed,
    required int fatLeft,
  }) async {
    if (!isPlatformSupported) return;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<int>('calories_consumed', caloriesConsumed),
        HomeWidget.saveWidgetData<int>('calories_target', caloriesTarget),
        HomeWidget.saveWidgetData<int>('calories_left', caloriesLeft),
        HomeWidget.saveWidgetData<int>('protein_consumed', proteinConsumed),
        HomeWidget.saveWidgetData<int>('protein_left', proteinLeft),
        HomeWidget.saveWidgetData<int>('carbs_consumed', carbsConsumed),
        HomeWidget.saveWidgetData<int>('carbs_left', carbsLeft),
        HomeWidget.saveWidgetData<int>('fat_consumed', fatConsumed),
        HomeWidget.saveWidgetData<int>('fat_left', fatLeft),
      ]).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('HomeWidgetService: Failed saving widget data: $e');
    }
  }

  /// Notifies the Android widget subsystem to re-render the compact and wide widgets.
  Future<void> updateWidgets() async {
    if (!isPlatformSupported) return;
    try {
      await Future.wait([
        HomeWidget.updateWidget(
          name: compactWidgetProvider,
          androidName: compactWidgetProvider,
        ),
        HomeWidget.updateWidget(
          name: wideWidgetProvider,
          androidName: wideWidgetProvider,
        ),
      ]).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('HomeWidgetService: Failed updating native widgets: $e');
    }
  }

  /// Calculates rounded totals and syncs both data and UI for native widgets.
  Future<void> updateFromDailyTotals({
    required double consumedCalories,
    required double targetCalories,
    required double consumedProtein,
    required double targetProtein,
    required double consumedCarbs,
    required double targetCarbs,
    required double consumedFat,
    required double targetFat,
  }) async {
    final cConsumed = consumedCalories.round();
    final cTarget = targetCalories.round();
    final cLeft = (targetCalories - consumedCalories).round().clamp(0, 99999);

    final pConsumed = consumedProtein.round();
    final pLeft = (targetProtein - consumedProtein).round().clamp(0, 9999);

    final carbConsumed = consumedCarbs.round();
    final carbLeft = (targetCarbs - consumedCarbs).round().clamp(0, 9999);

    final fConsumed = consumedFat.round();
    final fLeft = (targetFat - consumedFat).round().clamp(0, 9999);

    await saveSummaryData(
      caloriesConsumed: cConsumed,
      caloriesTarget: cTarget,
      caloriesLeft: cLeft,
      proteinConsumed: pConsumed,
      proteinLeft: pLeft,
      carbsConsumed: carbConsumed,
      carbsLeft: carbLeft,
      fatConsumed: fConsumed,
      fatLeft: fLeft,
    );

    await updateWidgets();
  }

  /// Disposes background subscriptions.
  void dispose() {
    _widgetClickedSubscription?.cancel();
    _widgetClickedSubscription = null;
    _deepLinkHandler = null;
    _isInitialized = false;
  }
}
