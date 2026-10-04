import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'controllers/settings_controller.dart';
import 'core/di/service_locator.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/analysis_queue_service.dart';
import 'services/database_service.dart';
import 'services/secure_storage_service.dart';
import 'services/theme_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Intercept uncaught framework and asynchronous errors to prevent native black screen crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('PlatformDispatcher uncaught error: $error\n$stack');
    return true; // Mark as handled to keep app running
  };

  // Synchronously configure service locator for dependency injection
  setupServiceLocator();

  // Render UI immediately at frame 0 to prevent Android 16 ANR/Watchdog kills
  runApp(const NutriTrackerApp());

  // Initialize heavy background services asynchronously without blocking initial frame
  unawaited(_initializeBackgroundServices());
}

Future<void> _initializeBackgroundServices() async {
  try {
    await initializeDateFormatting('es', null);
  } catch (e) {
    debugPrint('DateFormatting initialization warning: $e');
  }

  try {
    await DatabaseService.instance.init().timeout(
      const Duration(seconds: 4),
      onTimeout: () => debugPrint('DatabaseService init timeout warning'),
    );
    await AnalysisQueueService.instance.init().timeout(
      const Duration(seconds: 3),
      onTimeout: () => debugPrint('AnalysisQueueService init timeout warning'),
    );
  } catch (e, stack) {
    debugPrint('Database initialization warning: $e\n$stack');
  }

  try {
    await ThemeManager.instance.loadTheme().timeout(
      const Duration(seconds: 2),
      onTimeout: () => debugPrint('Theme load timeout warning'),
    );
  } catch (e, stack) {
    debugPrint('Theme initialization warning: $e\n$stack');
  }

  try {
    await SettingsController.instance.loadLocale().timeout(
      const Duration(seconds: 2),
      onTimeout: () => debugPrint('Locale load timeout warning'),
    );
  } catch (e) {
    debugPrint('SettingsController loadLocale warning: $e');
  }
}

class NutriTrackerApp extends StatefulWidget {
  final bool? hasCompletedOnboarding;
  final Locale? locale;

  const NutriTrackerApp({
    super.key,
    this.hasCompletedOnboarding,
    this.locale,
  });

  @override
  State<NutriTrackerApp> createState() => _NutriTrackerAppState();
}

class _NutriTrackerAppState extends State<NutriTrackerApp> {
  late bool _hasCompletedOnboarding;

  @override
  void initState() {
    super.initState();
    _hasCompletedOnboarding = widget.hasCompletedOnboarding ?? true;
    if (widget.hasCompletedOnboarding == null) {
      _checkOnboardingInBackground();
    }
  }

  @override
  void didUpdateWidget(covariant NutriTrackerApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasCompletedOnboarding != null &&
        widget.hasCompletedOnboarding != oldWidget.hasCompletedOnboarding) {
      _hasCompletedOnboarding = widget.hasCompletedOnboarding!;
    }
  }

  Future<void> _checkOnboardingInBackground() async {
    try {
      final completed = await SecureStorageService.instance
          .hasCompletedOnboarding()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => true,
          );
      if (!completed) {
        // Fallback verification against local SQLite profile
        // If the user already has a persisted profile, avoid booting them into onboarding
        // due to transient Keystore delay or timeout.
        final profile = await DatabaseService.instance.getUserProfile().timeout(
          const Duration(seconds: 1),
          onTimeout: () => null,
        );
        if (profile != null) {
          unawaited(SecureStorageService.instance.setCompletedOnboarding(true));
          return;
        }
      }
      if (mounted && _hasCompletedOnboarding != completed) {
        setState(() => _hasCompletedOnboarding = completed);
      }
    } catch (e) {
      debugPrint('Onboarding background check warning: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager.instance, SettingsController.instance]),
      builder: (context, _) {
        final ctrlLocale = SettingsController.instance.currentLocale;
        final targetLocale = widget.locale ?? ctrlLocale;
        Locale? effectiveLocale;
        if (targetLocale != null) {
          final isSupported = AppLocalizations.supportedLocales.any(
            (s) => s.languageCode == targetLocale.languageCode,
          );
          effectiveLocale = isSupported ? targetLocale : const Locale('es');
        }

        return MaterialApp(
          title: 'Victor Engineer - Food Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeManager.instance.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: effectiveLocale,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (effectiveLocale != null) return effectiveLocale;
            if (deviceLocale != null) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == deviceLocale.languageCode) {
                  return supported;
                }
              }
            }
            return const Locale('es');
          },
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _hasCompletedOnboarding
                ? const DashboardScreen(key: ValueKey('dashboard'))
                : OnboardingScreen(
                    key: const ValueKey('onboarding'),
                    onCompleted: () {
                      if (mounted) {
                        setState(() => _hasCompletedOnboarding = true);
                      }
                    },
                  ),
          ),
        );
      },
    );
  }
}
