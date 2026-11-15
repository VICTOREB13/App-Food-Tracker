import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_tracker/core/constants/app_constants.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/core/interfaces/app_update_service_interface.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/features/food_entry/models/food_item.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';
import 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';
import 'package:food_tracker/features/food_entry/food_entry.dart';
import 'package:food_tracker/features/biometrics_weight/biometrics_weight.dart';
import 'package:food_tracker/features/settings_profile/settings_profile.dart';
import 'package:food_tracker/features/food_entry/services/analysis_queue_service.dart';
import 'package:food_tracker/core/services/platform/home_widget_service.dart';
import 'package:food_tracker/features/food_entry/services/image_processing_service.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'package:food_tracker/core/ui/components/barcode_scanner_dialog.dart';
import 'package:food_tracker/features/dashboard/widgets/api_key_prompt_dialog.dart';
import 'package:food_tracker/features/dashboard/widgets/dashboard_fab_menu.dart';
import 'package:food_tracker/features/dashboard/widgets/quick_meal_dialog.dart';
import 'package:food_tracker/features/dashboard/widgets/voice_meal_recording_dialog.dart';
import 'package:food_tracker/features/dashboard/widgets/recommendations/what_to_eat_sheet.dart';
import 'package:food_tracker/features/settings_profile/widgets/in_app_update_dialog.dart';
import 'dashboard.controller.dart';
import 'dashboard_bento_grid.view.dart';
import 'dashboard_header.view.dart';

/// Primary dashboard view orchestrating Bento Grid modules, actions, and deep links.
class DashboardView extends StatefulWidget {
  final DashboardController? controller;

  const DashboardView({super.key, this.controller});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  static bool _hasCheckedForUpdatesInSession = false;
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DashboardController.instance;
    _controller.addListener(_onControllerChange);
    _controller.init();
    HomeWidgetService.instance.init(onDeepLink: _handleWidgetDeepLink);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdateSilently());
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
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
      case 'scan_food':
        _handleAiPhotoScan(ImageSource.camera);
        break;
      case 'scan_barcode':
        _handleBarcodeScan();
        break;
      case 'new_meal':
        _openManualEntry();
        break;
      case 'quick_meal':
        _handleQuickMeal();
        break;
      case 'add_water':
        _handleQuickWater();
        break;
      case 'metrics':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MetricsScreen()));
        break;
      case 'fasting':
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
    }
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
      date: _controller.selectedDate,
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
      name: item.name,
      estimatedGrams: 100,
      calories: item.calories,
      protein: item.protein,
      carbs: item.carbs,
      fat: item.fat,
      visualJustification: l10n.barcodeScannedDefaultNote,
    );

    final meal = Meal(
      name: item.name,
      date: _controller.selectedDate,
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
    final type = defaultType ?? ImageProcessingService.inferMealTypeByTime(_controller.selectedDate);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealDetailScreen(defaultMealType: type)),
    );
  }

  Future<void> _handleQuickWater() async {
    final l10n = AppLocalizations.of(context);
    try {
      await _controller.logWater(
        mealName: l10n.quickWaterMealName,
        notes: l10n.quickHydrationNote,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.waterLoggedSuccess),
        backgroundColor: AppColors.water,
        duration: const Duration(seconds: 2),
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
    final quickMeal = await showQuickMealDialog(context, date: _controller.selectedDate);
    if (quickMeal != null) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      try {
        await _controller.saveMeal(quickMeal);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            l10n.quickMealLoggedSuccess(quickMeal.name, quickMeal.calories.toInt().toString()),
          ),
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
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhatToEatSheet(date: _controller.selectedDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeaderView(
        streakDays: _controller.streakDays,
        onMetricsTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MetricsScreen()),
        ),
        onSettingsTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
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
        onRefresh: () => _controller.loadMeals(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
          children: [
            DashboardBentoGridView(
              state: _controller.state,
              onDateSelected: _controller.setSelectedDate,
              onPreviousDay: _controller.goToPreviousDay,
              onNextDay: _controller.goToNextDay,
              onToday: _controller.goToToday,
              onMealTap: (meal) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MealDetailScreen(initialMeal: meal)),
              ),
              onAddMeal: (type) => _openManualEntry(defaultType: type),
              onOpenMeal: (meal) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MealDetailScreen(initialMeal: meal)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
