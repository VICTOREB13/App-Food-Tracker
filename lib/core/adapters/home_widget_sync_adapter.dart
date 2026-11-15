import 'dart:ui' show Locale;
import 'package:home_widget/home_widget.dart';
import 'package:food_tracker/core/services/platform/home_widget_service.dart';
import '../ports/app_widget_sync_port.dart';

/// Native OS Home Widget data synchronization adapter for [IAppWidgetSyncPort].
class HomeWidgetSyncAdapter implements IAppWidgetSyncPort {
  final HomeWidgetService _service;

  HomeWidgetSyncAdapter({HomeWidgetService? service})
      : _service = service ?? HomeWidgetService.instance;

  @override
  bool get isPlatformSupported => HomeWidgetService.isPlatformSupported;

  @override
  Locale get currentLocale => _service.currentLocale;

  @override
  void setActiveLocale(Locale locale) => _service.setActiveLocale(locale);

  @override
  Future<void> init({HomeWidgetDeepLinkHandler? onDeepLink}) =>
      _service.init(onDeepLink: onDeepLink);

  @override
  void setDeepLinkHandler(HomeWidgetDeepLinkHandler handler) =>
      _service.setDeepLinkHandler(handler);

  @override
  void handleDeepLink(Uri uri) => _service.handleDeepLink(uri);

  @override
  Future<void> saveLocaleStrings([Locale? locale]) =>
      _service.saveLocaleStrings(locale);

  @override
  Future<void> syncAllWidgetsWithLocale(Locale locale) =>
      _service.syncAllWidgetsWithLocale(locale);

  @override
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
    int streakCount = 0,
  }) =>
      _service.saveSummaryData(
        caloriesConsumed: caloriesConsumed,
        caloriesTarget: caloriesTarget,
        caloriesLeft: caloriesLeft,
        proteinConsumed: proteinConsumed,
        proteinLeft: proteinLeft,
        carbsConsumed: carbsConsumed,
        carbsLeft: carbsLeft,
        fatConsumed: fatConsumed,
        fatLeft: fatLeft,
        streakCount: streakCount,
      );

  @override
  Future<void> updateFastingData({
    required bool isActive,
    required String timeFormatted,
    required int targetHours,
  }) =>
      _service.updateFastingData(
        isActive: isActive,
        timeFormatted: timeFormatted,
        targetHours: targetHours,
      );

  @override
  Future<void> updateWidgets() => _service.updateWidgets();

  @override
  Future<void> saveWidgetData<T>(String key, T? value) async {
    if (!isPlatformSupported) return;
    try {
      await HomeWidget.saveWidgetData<T>(key, value);
    } catch (_) {}
  }

  @override
  Future<T?> getWidgetData<T>(String key) async {
    if (!isPlatformSupported) return null;
    try {
      return await HomeWidget.getWidgetData<T>(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateWidgetByName(String name) async {
    if (!isPlatformSupported) return;
    try {
      await HomeWidget.updateWidget(
        name: name,
        androidName: name,
        iOSName: name,
      );
    } catch (_) {}
  }
}
