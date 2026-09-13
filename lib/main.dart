import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/analysis_queue_service.dart';
import 'services/database_service.dart';
import 'services/secure_storage_service.dart';
import 'services/theme_manager.dart';

void main() async {
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

  try {
    await initializeDateFormatting('es', null);
  } catch (e) {
    debugPrint('DateFormatting initialization warning: $e');
  }

  try {
    await DatabaseService.instance.init();
    await AnalysisQueueService.instance.init();
  } catch (e, stack) {
    debugPrint('Database initialization warning: $e\n$stack');
  }

  try {
    await ThemeManager.instance.loadTheme();
  } catch (e, stack) {
    debugPrint('Theme initialization warning: $e\n$stack');
  }

  bool hasCompletedOnboarding = false;
  try {
    hasCompletedOnboarding = await SecureStorageService.instance.hasCompletedOnboarding();
  } catch (e, stack) {
    debugPrint('Onboarding check warning: $e\n$stack');
  }

  runApp(NutriTrackerApp(hasCompletedOnboarding: hasCompletedOnboarding));
}

class NutriTrackerApp extends StatelessWidget {
  final bool hasCompletedOnboarding;

  const NutriTrackerApp({
    super.key,
    this.hasCompletedOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Victor Engineer - Food Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeManager.instance.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: hasCompletedOnboarding
              ? const DashboardScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
