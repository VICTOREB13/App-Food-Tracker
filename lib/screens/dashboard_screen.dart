import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/meal_controller.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/pantry_item.dart';
import '../services/analysis_queue_service.dart';
import '../services/home_widget_service.dart';
import '../services/image_processing_service.dart';
import '../services/secure_storage_service.dart';
import '../services/theme_manager.dart';
import '../widgets/common/barcode_scanner_dialog.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/dashboard/analysis_progress_banner.dart';
import '../widgets/dashboard/api_key_prompt_dialog.dart';
import '../widgets/dashboard/daily_calorie_summary_card.dart';
import '../widgets/dashboard/dashboard_fab_menu.dart';
import '../widgets/dashboard/date_selector_bar.dart';
import '../widgets/dashboard/fasting_window_bento_card.dart';
import '../widgets/dashboard/meal_section_card.dart';
import '../widgets/dashboard/quick_meal_dialog.dart';
import '../widgets/dashboard/streak_badge.dart';
import '../widgets/dashboard/voice_meal_recording_dialog.dart';
import '../widgets/dashboard/week_calendar_strip.dart';
import '../core/constants/app_constants.dart';
import '../core/di/service_locator.dart';
import '../core/interfaces/app_update_service_interface.dart';
import '../l10n/app_localizations.dart';
import '../widgets/recommendations/what_to_eat_sheet.dart';
import '../widgets/settings/in_app_update_dialog.dart';
import 'meal_detail_screen.dart';
import 'metrics_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static bool _hasCheckedForUpdatesInSession = false;
  final MealController _mealController = MealController.instance;

  @override
  void initState() {
    super.initState();
    _mealController.addListener(_onControllerChange);
    _mealController.init();
    HomeWidgetService.instance.init(onDeepLink: _handleWidgetDeepLink);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdateSilently());
  }

  void _checkUpdateSilently() async {
    if (_hasCheckedForUpdatesInSession) return;
    _hasCheckedForUpdatesInSession = true;
    try {
      if (!getIt.isRegistered<IAppUpdateService>()) return;
      final updateService = getIt<IAppUpdateService>();
      final release = await updateService.checkLatestRelease();
      if (!mounted || release == null) return;
      if (updateService.isUpdateAvailable(AppConstants.appVersion, release.tagName)) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.updateAvailable(release.tagName)),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: l10n.viewUpdateAction,
            textColor: AppColors.primaryLight,
            onPressed: () => showInAppUpdateDialog(context, release: release),
          ),
        ));
      }
    } catch (_) {}
  }

  void _handleWidgetDeepLink(Uri uri) {
    if (!mounted) return;
    final action = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');
    switch (action) {
      case 'scan_food': _handleAiPhotoScan(ImageSource.camera); break;
      case 'scan_barcode': _handleBarcodeScan(); break;
      case 'new_meal': _openManualEntry(); break;
    }
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

    final inferredMealType = ImageProcessingService.inferMealTypeByTime();

    await AnalysisQueueService.instance.enqueueMealAnalysis(
      rawImageBytes: bytes,
      mealType: inferredMealType,
      date: _mealController.selectedDate,
    );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.analyzingMealBackground),
      backgroundColor: AppColors.primary,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _handleBarcodeScan() async {
    final PantryItem? item = await showBarcodeScannerDialog(context);
    if (item == null || !mounted) return;
    final l10n = AppLocalizations.of(context);

    final foodItem = FoodItem(
      name: item.name, estimatedGrams: 100,
      calories: item.calories, protein: item.protein, carbs: item.carbs, fat: item.fat,
      visualJustification: l10n.barcodeScannedDefaultNote,
    );

    final meal = Meal(
      name: item.name, date: _mealController.selectedDate,
      calories: item.calories, protein: item.protein, carbs: item.carbs, fat: item.fat,
    ).recalculateFromItems([foodItem]);

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailScreen(initialMeal: meal)));
  }

  void _openManualEntry({String? defaultType}) {
    final type = defaultType ?? ImageProcessingService.inferMealTypeByTime(_mealController.selectedDate);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailScreen(defaultMealType: type)));
  }

  Future<void> _handleQuickWater() async {
    final l10n = AppLocalizations.of(context);
    final waterMeal = Meal(
      name: l10n.quickWaterMealName, mealType: 'Snack', date: _mealController.selectedDate,
      calories: 0, protein: 0, carbs: 0, fat: 0,
      notes: l10n.quickHydrationNote,
    );
    try {
      await _mealController.saveMeal(waterMeal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.waterLoggedSuccess),
        backgroundColor: AppColors.water, duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.waterLogError('$e')),
        backgroundColor: AppColors.primary,
      ));
    }
  }

  Future<void> _handleQuickMeal() async {
    final quickMeal = await showQuickMealDialog(context, date: _mealController.selectedDate);
    if (quickMeal != null) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      try {
        await _mealController.saveMeal(quickMeal);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.quickMealLoggedSuccess(quickMeal.name, quickMeal.calories.toInt().toString())),
          backgroundColor: AppColors.protein,
        ));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.quickMealLogError('$e')),
          backgroundColor: AppColors.primary,
        ));
      }
    }
  }

  void _openWhatToEatSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => WhatToEatSheet(date: _mealController.selectedDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealsMap = _mealController.mealsByType;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: VeAppBar(
        automaticallyImplyLeading: false,
        title: 'Food Tracker',
        subtitle: 'Victor Engineer',
        actions: [
          Center(child: StreakBadge(streakDays: _mealController.currentStreak)),
          IconButton(icon: const Icon(Icons.insights_outlined), tooltip: l10n.metrics, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MetricsScreen()))),
          IconButton(icon: const Icon(Icons.settings_outlined), tooltip: l10n.settings, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      floatingActionButton: DashboardFabMenu(
        onAiPhotoScan: () => _handleAiPhotoScan(ImageSource.camera),
        onGalleryScan: () => _handleAiPhotoScan(ImageSource.gallery),
        onBarcodeScan: _handleBarcodeScan,
        onManualEntry: () => _openManualEntry(),
        onQuickWater: _handleQuickWater,
        onQuickMeal: _handleQuickMeal,
        onVoiceDictation: () => showVoiceMealRecordingDialog(context),
        onWhatToEat: _openWhatToEatSheet,
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
            const SizedBox(height: 12),
            AnalysisProgressBanner(
              onOpenMeal: (meal) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MealDetailScreen(initialMeal: meal)),
              ),
            ),
            DailyCalorieSummaryCard(
              currentCalories: _mealController.totalCalories,
              currentProtein: _mealController.totalProtein,
              currentCarbs: _mealController.totalCarbs,
              currentFat: _mealController.totalFat,
              goals: _mealController.dailyGoals,
            ),
            const SizedBox(height: 12),
            const FastingWindowBentoCard(),
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
