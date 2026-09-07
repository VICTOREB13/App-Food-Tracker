import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/dashboard_screen.dart';
import 'services/database_service.dart';
import 'services/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('es', null);
  } catch (e) {
    debugPrint('DateFormatting initialization warning: $e');
  }

  try {
    await DatabaseService.instance.init();
  } catch (e, stack) {
    debugPrint('Database initialization warning: $e\n$stack');
  }

  try {
    await ThemeManager.instance.loadTheme();
  } catch (e, stack) {
    debugPrint('Theme initialization warning: $e\n$stack');
  }

  runApp(const NutriTrackerApp());
}

class NutriTrackerApp extends StatelessWidget {
  const NutriTrackerApp({super.key});

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
          home: const DashboardScreen(),
        );
      },
    );
  }
}
