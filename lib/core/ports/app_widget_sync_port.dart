import 'dart:ui' show Locale;
import 'package:food_tracker/core/services/platform/home_widget_service.dart' show HomeWidgetDeepLinkHandler;

export 'package:food_tracker/core/services/platform/home_widget_service.dart' show HomeWidgetDeepLinkHandler;

/// Hexagonal port for native OS widget data synchronization and deep link handling.
abstract interface class IAppWidgetSyncPort {
  /// Whether the host platform natively supports Home Widgets (Android / iOS).
  bool get isPlatformSupported;

  /// Active locale currently utilized for widget string generation.
  Locale get currentLocale;

  /// Updates active locale in memory.
  void setActiveLocale(Locale locale);

  /// Initializes deep link listeners, app group id, and syncs initial localized strings.
  Future<void> init({HomeWidgetDeepLinkHandler? onDeepLink});

  /// Sets or updates the active deep link callback.
  void setDeepLinkHandler(HomeWidgetDeepLinkHandler handler);

  /// Dispatches recognized widget deep links to the registered handler.
  void handleDeepLink(Uri uri);

  /// Persists localized string resources to native storage for Android/iOS widgets.
  Future<void> saveLocaleStrings([Locale? locale]);

  /// Re-syncs all native widgets with active locale strings and updates their UI.
  Future<void> syncAllWidgetsWithLocale(Locale locale);

  /// Saves macro and calorie summary values into native widget storage.
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
  });

  /// Synchronizes fasting state and timing into native widget storage.
  Future<void> updateFastingData({
    required bool isActive,
    required String timeFormatted,
    required int targetHours,
  });

  /// Notifies the host OS widget subsystem to re-render all native widgets.
  Future<void> updateWidgets();

  /// Saves generic primitive data for native widget consumption.
  Future<void> saveWidgetData<T>(String key, T? value);

  /// Reads generic primitive data from native widget storage.
  Future<T?> getWidgetData<T>(String key);

  /// Updates a specific native widget by name/provider identifier.
  Future<void> updateWidgetByName(String name);
}
