import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/meal_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_es.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../services/image_processing_service.dart';
import '../services/secure_storage_service.dart';
import '../services/theme_manager.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/meal_detail/food_item_editor_dialog.dart';
import '../widgets/meal_detail/food_items_list_card.dart';
import '../widgets/meal_detail/meal_ai_reanalyze_button.dart';
import '../widgets/meal_detail/meal_analysis_pacing.dart';
import '../widgets/meal_detail/meal_detail_actions.dart';
import '../widgets/meal_detail/meal_form_fields.dart';
import '../widgets/meal_detail/meal_image_card.dart';
import '../widgets/meal_detail/meal_image_picker.dart';
import '../widgets/meal_detail/meal_macro_chips_row.dart';
import '../widgets/meal_detail/meal_micronutrient_chips_row.dart';
import '../widgets/meal_detail/meal_save_button.dart';

class MealDetailScreen extends StatefulWidget {
  final Meal? initialMeal;
  final String? defaultMealType;

  const MealDetailScreen({super.key, this.initialMeal, this.defaultMealType});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late final TextEditingController _nameController, _notesController;
  late String _mealType;
  late DateTime _date;
  String? _imagePath;
  List<FoodItem> _items = [];
  double _calories = 0.0, _protein = 0.0, _carbs = 0.0, _fat = 0.0;
  double _fiber = 0.0, _sodium = 0.0, _sugar = 0.0;
  bool _isSaving = false, _isReanalyzing = false;
  String? _analysisStage;
  double? _analysisProgress;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    final meal = widget.initialMeal;
    _date = meal?.date ?? MealController.instance.selectedDate;
    _mealType = meal?.mealType ?? widget.defaultMealType ?? ImageProcessingService.inferMealTypeByTime(_date);
    _nameController = TextEditingController(text: meal?.name ?? '');
    _notesController = TextEditingController(text: meal?.notes ?? '');
    _imagePath = meal?.imagePath;

    if (meal != null) {
      _items = List.from(meal.items);
      _calories = meal.calories; _protein = meal.protein; _carbs = meal.carbs; _fat = meal.fat;
      _fiber = meal.fiber; _sodium = meal.sodium; _sugar = meal.sugar;
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateTotals() {
    double cal = 0, prot = 0, carbs = 0, fat = 0, fib = 0, sod = 0, sug = 0;
    for (final item in _items) {
      cal += item.calories; prot += item.protein; carbs += item.carbs; fat += item.fat;
      fib += item.fiber; sod += item.sodium; sug += item.sugar;
    }
    setState(() {
      _calories = cal; _protein = prot; _carbs = carbs; _fat = fat;
      _fiber = fib; _sodium = sod; _sugar = sug;
    });
  }

  void _startAnalysisProgress() {
    _progressTimer?.cancel();
    final l10n = AppLocalizations.of(context);
    _analysisProgress = MealAnalysisPacing.initialProgress;
    _analysisStage = l10n != null
        ? MealAnalysisPacing.getStageMessage(_analysisProgress!, l10n)
        : 'Optimizando foto y calibración de vajilla...';
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (!mounted || !_isReanalyzing) return t.cancel();
      final cur = _analysisProgress ?? MealAnalysisPacing.initialProgress;
      final next = MealAnalysisPacing.nextProgress(cur);
      final currentL10n = AppLocalizations.of(context);
      setState(() {
        _analysisProgress = next;
        if (currentL10n != null) {
          _analysisStage = MealAnalysisPacing.getStageMessage(next, currentL10n);
        }
      });
    });
  }

  Future<void> _pickImage() async {
    final savedPath = await pickAndSaveMealImage(
      context: context,
      mealType: _mealType,
      date: _date,
      mealId: widget.initialMeal?.id,
      currentPath: _imagePath,
    );
    if (savedPath != null && mounted) {
      setState(() => _imagePath = savedPath);
      final apiKey = await SecureStorageService.instance.getGeminiApiKey();
      if (apiKey != null && apiKey.trim().isNotEmpty && mounted) {
        await _reanalyzeWithAi();
      }
    }
  }

  Future<void> _reanalyzeWithAi() async {
    if (_isSaving || _imagePath == null) return;
    setState(() => _isReanalyzing = true);
    _startAnalysisProgress();

    try {
      final analysis = await reanalyzeMealWithAi(
        context: context,
        imagePath: _imagePath,
        currentDishName: _nameController.text.trim(),
        currentNotes: _notesController.text.trim(),
        currentItems: _items,
      );
      if (analysis != null && mounted) {
        _progressTimer?.cancel();
        final l10n = AppLocalizations.of(context);
        setState(() {
          _analysisProgress = 1.0;
          _analysisStage = l10n?.analysisStageComplete ?? '¡Desglose nutricional completado!';
        });
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        setState(() {
          if (_nameController.text.trim().isEmpty && analysis.dishName.isNotEmpty) {
            _nameController.text = analysis.dishName;
          }
          if (_notesController.text.trim().isEmpty && analysis.items.isNotEmpty) {
            final summary = analysis.items.map((e) => '${e.name} (${e.estimatedGrams.toStringAsFixed(0)}g)').join(', ');
            _notesController.text = 'Ingredientes: $summary';
          }
          _items = List.from(analysis.items);
          _calories = analysis.totalCalories;
          _protein = analysis.totalProtein;
          _carbs = analysis.totalCarbs;
          _fat = analysis.totalFat;
        });
        if (_items.isNotEmpty) _recalculateTotals();
      }
    } finally {
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _isReanalyzing = false;
          _analysisStage = null;
          _analysisProgress = null;
        });
      }
    }
  }

  Future<void> _saveMeal() async {
    if (_isSaving || _isReanalyzing) return;
    final notes = _notesController.text.trim();
    setState(() => _isSaving = true);
    final saved = await saveMealEntry(
      context: context,
      initialMeal: widget.initialMeal,
      name: _nameController.text.trim(),
      mealType: _mealType,
      date: _date,
      imagePath: _imagePath,
      calories: _calories,
      protein: _protein,
      carbs: _carbs,
      fat: _fat,
      notes: notes.isNotEmpty ? notes : null,
      items: _items,
    );
    if (mounted) setState(() => _isSaving = false);
    if (saved && mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteMeal() async {
    final meal = widget.initialMeal;
    if (meal == null) return;
    if (await confirmAndDeleteMeal(context, meal) && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _addItem() async {
    final newItem = await showFoodItemEditorDialog(context);
    if (newItem != null) {
      setState(() => _items.add(newItem));
      _recalculateTotals();
    }
  }

  Future<void> _editItem(FoodItem item) async {
    final edited = await showFoodItemEditorDialog(context, initialItem: item);
    if (edited != null) {
      final idx = _items.indexWhere((e) => e.id == item.id);
      if (idx != -1) setState(() => _items[idx] = edited);
      _recalculateTotals();
    }
  }

  void _deleteItem(FoodItem item) {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    _recalculateTotals();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    final isEditing = widget.initialMeal != null;

    return Scaffold(
      appBar: VeAppBar(
        title: isEditing ? l10n.mealDetails : l10n.newMeal,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.primaryLight),
              tooltip: l10n.deleteMealTooltip,
              onPressed: _deleteMeal,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          MealImageCard(
            imagePath: _imagePath,
            dishName: _nameController.text,
            onPickImage: _pickImage,
            isAnalyzing: _isReanalyzing,
            analysisStage: _analysisStage,
            analysisProgress: _analysisProgress,
          ),
          if (_imagePath != null) ...[
            const SizedBox(height: 10),
            MealAiReanalyzeButton(
              isReanalyzing: _isReanalyzing,
              onPressed: _reanalyzeWithAi,
            ),
          ],
          const SizedBox(height: 16),
          MealMacroChipsRow(calories: _calories, protein: _protein, carbs: _carbs, fat: _fat),
          if (_fiber > 0 || _sodium > 0 || _sugar > 0) ...[
            const SizedBox(height: 8),
            MealMicronutrientChipsRow(fiber: _fiber, sodium: _sodium, sugar: _sugar),
          ],
          const SizedBox(height: 16),
          MealFormFields(
            nameController: _nameController,
            notesController: _notesController,
            mealType: _mealType,
            onMealTypeChanged: (val) {
              if (val != null && val != _mealType) {
                setState(() => _mealType = val);
              }
            },
          ),
          const SizedBox(height: 16),
          FoodItemsListCard(
            items: _items,
            onAddItem: _addItem,
            onEditItem: _editItem,
            onDeleteItem: _deleteItem,
          ),
          const SizedBox(height: 24),
          MealSaveButton(
            isSaving: _isSaving,
            isEditing: isEditing,
            onSave: _saveMeal,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
