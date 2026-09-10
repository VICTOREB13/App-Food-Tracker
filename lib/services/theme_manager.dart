import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._();
  ThemeManager._();

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static const String _prefKey = 'preferred_theme_mode';

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey) ?? 'dark';
      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.dark;
          break;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'dark';
      if (mode == ThemeMode.light) val = 'light';
      if (mode == ThemeMode.system) val = 'system';
      await prefs.setString(_prefKey, val);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

class AppColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? const Color(0xFF09090B) : const Color(0xFFFAFAFA);

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF121215) : const Color(0xFFFFFFFF);

  static Color surfaceSubtle(BuildContext context) =>
      isDark(context) ? const Color(0xFF18181B) : const Color(0xFFF4F4F5);

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFFAFAFA) : const Color(0xFF09090B);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

  static Color textMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);

  static const Color primary = Color(0xFFDC2626);
  static const Color primaryLight = Color(0xFFEF4444);
  static const Color primaryDark = Color(0xFF991B1B);
  static const Color crimson = Color(0xFFDC2626);

  static const Color calories = Color(0xFFDC2626);
  static const Color caloriesFlame = Color(0xFFF97316);
  static const Color protein = Color(0xFF10B981);
  static const Color proteinCoral = Color(0xFFEF4444);
  static const Color carbs = Color(0xFFF59E0B);
  static const Color carbsAmber = Color(0xFFEAB308);
  static const Color fat = Color(0xFF0EA5E9);
  static const Color fatSapphire = Color(0xFF3B82F6);
  static const Color water = Color(0xFF06B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color portion = Color(0xFF8B5CF6);

  static const double cardRadius = 20.0;
  static const double pillRadius = 32.0;
  static const double iconRadius = 14.0;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF09090B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFDC2626),
        secondary: Color(0xFF10B981),
        surface: Color(0xFF121215),
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSurface: Color(0xFFFAFAFA),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121215),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          side: const BorderSide(color: Color(0xFF27272A), width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF09090B),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFFAFAFA)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF27272A),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF121215),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(color: const Color(0xFFFAFAFA), fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: const Color(0xFFFAFAFA), fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: const Color(0xFFFAFAFA), fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: const Color(0xFFFAFAFA), fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: const Color(0xFFFAFAFA)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFFA1A1AA)),
        bodySmall: GoogleFonts.inter(color: const Color(0xFF71717A)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFDC2626),
        secondary: Color(0xFF10B981),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFDC2626),
        onPrimary: Colors.white,
        onSurface: Color(0xFF09090B),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF09090B)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE4E4E7),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(color: const Color(0xFF09090B), fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: const Color(0xFF09090B), fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: const Color(0xFF09090B), fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: const Color(0xFF09090B), fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: const Color(0xFF09090B)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF71717A)),
        bodySmall: GoogleFonts.inter(color: const Color(0xFFA1A1AA)),
      ),
    );
  }
}
