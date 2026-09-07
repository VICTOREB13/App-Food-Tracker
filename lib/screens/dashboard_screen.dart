import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/meal_controller.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/pantry_item.dart';
import '../services/gemini_vision_service.dart';
import '../services/image_processing_service.dart';
import '../services/secure_storage_service.dart';
import '../services/theme_manager.dart';
import '../widgets/common/barcode_scanner_dialog.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/dashboard/api_key_prompt_dialog.dart';
import '../widgets/dashboard/daily_calorie_summary_card.dart';
import '../widgets/dashboard/dashboard_fab_menu.dart';
import '../widgets/dashboard/date_selector_bar.dart';
import '../widgets/dashboard/meal_section_card.dart';
import '../widgets/dashboard/quick_meal_dialog.dart';
import '../widgets/dashboard/streak_badge.dart';
import '../widgets/dashboard/week_calendar_strip.dart';
import 'meal_detail_screen.dart';
import 'metrics_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MealController _mealController = MealController.instance;

  @override
  void initState() {
    super.initState();
    _mealController.addListener(_onControllerChange);
    _mealController.init();
  }

  @override
  void dispose() {
    _mealController.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  Future<void> _handleAiPhotoScan([ImageSource source = ImageSource.camera]) async {
    final apiKey = await SecureStorageService.instance.getGeminiApiKey();
    if (!mounted) return;

    if (apiKey == null || apiKey.trim().isEmpty) {
      showApiKeyPromptDialog(context);
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    final selectedModel = await SecureStorageService.instance.getSelectedGeminiModel();
    final masterPrompt = await SecureStorageService.instance.getMasterPrompt();
    final effectiveModel = selectedModel ?? GeminiVisionService.defaultModel;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Analizando con $effectiveModel...\nCubicando volumen y macros.',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final gemini = GeminiVisionService(
        apiKey: apiKey,
        modelName: effectiveModel,
        masterPrompt: masterPrompt,
      );
      final analysis = await gemini.analyzeMealPhoto(rawImageBytes: bytes);
      final savedPath = await ImageProcessingService.instance.saveMealImage(
        bytes,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      final meal = Meal(
        name: analysis.dishName,
        date: _mealController.selectedDate,
        imagePath: savedPath,
        calories: analysis.totalCalories,
        protein: analysis.totalProtein,
        carbs: analysis.totalCarbs,
        fat: analysis.totalFat,
        aiBreakdownJson: analysis.rawJson,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MealDetailScreen(initialMeal: meal)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al analizar imagen: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _handleBarcodeScan() async {
    final PantryItem? item = await showBarcodeScannerDialog(context);
    if (item == null || !mounted) return;

    final foodItem = FoodItem(
      name: item.name,
      estimatedGrams: 100,
      calories: item.calories,
      protein: item.protein,
      carbs: item.carbs,
      fat: item.fat,
      visualJustification: 'Escaneado por código de barras (100g base)',
    );

    final meal = Meal(
      name: item.name,
      date: _mealController.selectedDate,
      calories: item.calories,
      protein: item.protein,
      carbs: item.carbs,
      fat: item.fat,
    ).recalculateFromItems([foodItem]);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealDetailScreen(initialMeal: meal)),
    );
  }

  void _openManualEntry({String? defaultType}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealDetailScreen(defaultMealType: defaultType)),
    );
  }

  Future<void> _handleQuickWater() async {
    final waterMeal = Meal(
      name: 'Agua (+250 ml)',
      mealType: 'Snack',
      date: _mealController.selectedDate,
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      notes: 'Hidratación rápida (+250 ml)',
    );
    try {
      await _mealController.saveMeal(waterMeal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('💧 +250 ml de agua registrados con éxito.'),
        backgroundColor: AppColors.water,
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al registrar agua: $e'),
        backgroundColor: AppColors.primary,
      ));
    }
  }

  Future<void> _handleQuickMeal() async {
    final quickMeal = await showQuickMealDialog(context, date: _mealController.selectedDate);
    if (quickMeal != null) {
      try {
        await _mealController.saveMeal(quickMeal);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚡ ${quickMeal.name} registrado (${quickMeal.calories.toInt()} kcal).'),
          backgroundColor: AppColors.protein,
        ));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al registrar comida rápida: $e'),
          backgroundColor: AppColors.primary,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealsMap = _mealController.mealsByType;

    return Scaffold(
      appBar: VeAppBar(
        title: 'Food Tracker',
        subtitle: 'Victor Engineer',
        actions: [
          const Center(child: StreakBadge(streakDays: 3)),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Métricas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MetricsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: DashboardFabMenu(
        onAiPhotoScan: () => _handleAiPhotoScan(ImageSource.camera),
        onGalleryScan: () => _handleAiPhotoScan(ImageSource.gallery),
        onBarcodeScan: _handleBarcodeScan,
        onManualEntry: () => _openManualEntry(),
        onQuickWater: _handleQuickWater,
        onQuickMeal: _handleQuickMeal,
      ),
      body: RefreshIndicator(
        onRefresh: () => _mealController.loadMeals(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
          children: [
            DateSelectorBar(
              selectedDate: _mealController.selectedDate,
              onPreviousDay: _mealController.goToPreviousDay,
              onNextDay: _mealController.goToNextDay,
              onToday: _mealController.goToToday,
              onDateSelected: _mealController.setSelectedDate,
            ),
            const SizedBox(height: 8),
            WeekCalendarStrip(
              selectedDate: _mealController.selectedDate,
              onDateSelected: _mealController.setSelectedDate,
            ),
            const SizedBox(height: 14),
            DailyCalorieSummaryCard(
              currentCalories: _mealController.totalCalories,
              currentProtein: _mealController.totalProtein,
              currentCarbs: _mealController.totalCarbs,
              currentFat: _mealController.totalFat,
              goals: _mealController.dailyGoals,
            ),
            const SizedBox(height: 14),
            for (final type in Meal.validMealTypes) ...[
              MealSectionCard(
                mealType: type,
                meals: mealsMap[type] ?? const [],
                onMealTap: (meal) => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MealDetailScreen(initialMeal: meal)),
                ),
                onAddMeal: () => _openManualEntry(defaultType: type),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
