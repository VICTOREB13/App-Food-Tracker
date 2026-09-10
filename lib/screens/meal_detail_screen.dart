import 'dart:io';
import 'package:flutter/material.dart';
import '../controllers/meal_controller.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../services/gemini_vision_service.dart';
import '../services/secure_storage_service.dart';
import '../services/theme_manager.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/meal_detail/food_item_editor_dialog.dart';
import '../widgets/meal_detail/food_items_list_card.dart';
import '../widgets/meal_detail/meal_ai_reanalyze_button.dart';
import '../widgets/meal_detail/meal_detail_actions.dart';
import '../widgets/meal_detail/meal_form_fields.dart';
import '../widgets/meal_detail/meal_image_card.dart';
import '../widgets/meal_detail/meal_image_picker.dart';
import '../widgets/meal_detail/meal_macro_chips_row.dart';
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
  bool _isSaving = false, _isReanalyzing = false;

  @override
  void initState() {
    super.initState();
    final meal = widget.initialMeal;
    _nameController = TextEditingController(text: meal?.name ?? '');
    _notesController = TextEditingController(text: meal?.notes ?? '');
    _mealType = meal?.mealType ?? widget.defaultMealType ?? 'Almuerzo';
    _date = meal?.date ?? MealController.instance.selectedDate;
    _imagePath = meal?.imagePath;

    if (meal != null) {
      _items = List.from(meal.items);
      _calories = meal.calories;
      _protein = meal.protein;
      _carbs = meal.carbs;
      _fat = meal.fat;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateTotals() {
    double cal = 0.0, prot = 0.0, carbs = 0.0, fat = 0.0;
    for (final item in _items) {
      cal += item.calories;
      prot += item.protein;
      carbs += item.carbs;
      fat += item.fat;
    }
    setState(() {
      _calories = cal;
      _protein = prot;
      _carbs = carbs;
      _fat = fat;
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
    if (savedPath != null) setState(() => _imagePath = savedPath);
  }

  Future<void> _reanalyzeWithAi() async {
    if (_isSaving || _isReanalyzing) return;
    final path = _imagePath;
    if (path == null) return;
    final file = File(path);
    if (!file.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el archivo de imagen en disco.')),
        );
      }
      return;
    }

    final apiKey = await SecureStorageService.instance.getGeminiApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configura tu API Key de Gemini en Perfil para re-analizar.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isReanalyzing = true);
    try {
      final selectedModel = await SecureStorageService.instance.getSelectedGeminiModel();
      final masterPrompt = await SecureStorageService.instance.getMasterPrompt();
      final gemini = GeminiVisionService(
        apiKey: apiKey,
        modelName: selectedModel ?? GeminiVisionService.defaultModel,
        masterPrompt: masterPrompt,
      );

      final bytes = await file.readAsBytes();
      final currentPlato = _nameController.text.trim();
      final currentNotes = _notesController.text.trim();
      final itemsSummary = _items.isNotEmpty
          ? _items.map((e) => '${e.name}: ${e.estimatedGrams.toStringAsFixed(0)}g').join(', ')
          : 'sin ingredientes';

      final userContext = 'El comensal corrigió ingredientes del plato: '
          'Plato: "$currentPlato", Notas: "$currentNotes", Ingredientes: $itemsSummary. '
          'Recalcula los gramos y macronutrientes inteligentemente con esta corrección.';

      final analysis = await gemini.analyzeMealPhoto(
        rawImageBytes: bytes,
        userContext: userContext,
      );

      if (!mounted) return;

      setState(() {
        if (_nameController.text.trim().isEmpty && analysis.dishName.isNotEmpty) {
          _nameController.text = analysis.dishName;
        }
        _items = List.from(analysis.items);
        _calories = analysis.totalCalories;
        _protein = analysis.totalProtein;
        _carbs = analysis.totalCarbs;
        _fat = analysis.totalFat;
      });
      if (_items.isNotEmpty) {
        _recalculateTotals();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plato re-analizado y actualizado con IA.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al re-analizar imagen: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isReanalyzing = false);
    }
  }

  Future<void> _saveMeal() async {
    if (_isSaving || _isReanalyzing) return;
    final name = _nameController.text.trim();
    final rawNotes = _notesController.text.trim();
    final notes = rawNotes.isNotEmpty ? rawNotes : null;

    setState(() => _isSaving = true);
    final saved = await saveMealEntry(
      context: context,
      initialMeal: widget.initialMeal,
      name: name,
      mealType: _mealType,
      date: _date,
      imagePath: _imagePath,
      calories: _calories,
      protein: _protein,
      carbs: _carbs,
      fat: _fat,
      notes: notes,
      items: _items,
    );
    if (mounted) setState(() => _isSaving = false);
    if (saved && mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteMeal() async {
    final meal = widget.initialMeal;
    if (meal == null) return;
    final deleted = await confirmAndDeleteMeal(context, meal);
    if (deleted && mounted) Navigator.of(context).pop();
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
      if (idx != -1) {
        setState(() => _items[idx] = edited);
        _recalculateTotals();
      }
    }
  }

  void _deleteItem(FoodItem item) {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    _recalculateTotals();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMeal != null;

    return Scaffold(
      appBar: VeAppBar(
        title: isEditing ? 'Detalle de Comida' : 'Nueva Comida',
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.primaryLight),
              tooltip: 'Eliminar comida',
              onPressed: _deleteMeal,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          MealImageCard(imagePath: _imagePath, onPickImage: _pickImage),
          if (_imagePath != null) ...[
            const SizedBox(height: 10),
            MealAiReanalyzeButton(
              isReanalyzing: _isReanalyzing,
              onPressed: _reanalyzeWithAi,
            ),
          ],
          const SizedBox(height: 16),
          MealMacroChipsRow(
            calories: _calories,
            protein: _protein,
            carbs: _carbs,
            fat: _fat,
          ),
          const SizedBox(height: 16),
          MealFormFields(
            nameController: _nameController,
            notesController: _notesController,
            mealType: _mealType,
            onMealTypeChanged: (val) {
              if (val != null) setState(() => _mealType = val);
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
