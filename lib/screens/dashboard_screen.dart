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
import '../widgets/dashboard/daily_calorie_summary_card.dart';
import '../widgets/dashboard/dashboard_fab_menu.dart';
import '../widgets/dashboard/date_selector_bar.dart';
import '../widgets/dashboard/meal_section_card.dart';
import 'meal_detail_screen.dart';
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

  Future<void> _handleAiPhotoScan() async {
    final apiKey = await SecureStorageService.instance.getGeminiApiKey();
    if (!mounted) return;

    if (apiKey == null || apiKey.trim().isEmpty) {
      _promptConfigureApiKey();
      return;
    }

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar Foto con Cámara'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de Galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final file = await picker.pickImage(source: source);
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();

    if (!mounted) return;
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
                'Analizando con Gemini 2.5 Flash...\nCubicando volumen y macros.',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final gemini = GeminiVisionService(apiKey: apiKey);
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

  void _promptConfigureApiKey() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text('Configurar Gemini API Key', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Para usar visión multimodal y cubicaje con IA necesitas agregar tu clave gratuita de Google Gemini en Ajustes.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Ir a Ajustes'),
          ),
        ],
      ),
    );
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
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(defaultMealType: defaultType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealsMap = _mealController.mealsByType;

    return Scaffold(
      appBar: VeAppBar(
        title: 'NutriTracker',
        subtitle: 'Registro Local-First sin Báscula',
        actions: [
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
        onAiPhotoScan: _handleAiPhotoScan,
        onBarcodeScan: _handleBarcodeScan,
        onManualEntry: () => _openManualEntry(),
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
