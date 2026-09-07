import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'services/database_service.dart';
import 'services/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  await ThemeManager.instance.loadTheme();

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
