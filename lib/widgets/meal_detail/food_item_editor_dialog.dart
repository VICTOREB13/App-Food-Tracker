import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/food_item.dart';
import '../../models/food_search_suggestion.dart';
import '../../services/food_search_coordinator.dart';
import '../../services/offline_food_estimator_service.dart';
import '../../services/theme_manager.dart';
import 'food_search_suggestions_list.dart';

Future<FoodItem?> showFoodItemEditorDialog(BuildContext context, {FoodItem? initialItem}) {
  return showDialog<FoodItem>(
    context: context,
    builder: (ctx) => _FoodItemEditorDialog(initialItem: initialItem),
  );
}

class _FoodItemEditorDialog extends StatefulWidget {
  final FoodItem? initialItem;
  const _FoodItemEditorDialog({this.initialItem});

  @override
  State<_FoodItemEditorDialog> createState() => _FoodItemEditorDialogState();
}

class _FoodItemEditorDialogState extends State<_FoodItemEditorDialog> {
  late final TextEditingController _nameController, _gramsController, _caloriesController;
  late final TextEditingController _proteinController, _carbsController, _fatController;
  double? _estimatedFiber, _estimatedSodium, _estimatedSugar;
  bool _hasAutoEstimated = false;
  Timer? _debounceTimer;
  List<FoodSearchSuggestion> _suggestions = [];
  FoodSearchSuggestion? _activeSuggestion;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _gramsController = TextEditingController(text: item != null ? item.estimatedGrams.toStringAsFixed(0) : '100');
    _caloriesController = TextEditingController(text: item != null ? item.calories.toStringAsFixed(0) : '150');
    _proteinController = TextEditingController(text: item != null ? item.protein.toStringAsFixed(1) : '5.0');
    _carbsController = TextEditingController(text: item != null ? item.carbs.toStringAsFixed(1) : '20.0');
    _fatController = TextEditingController(text: item != null ? item.fat.toStringAsFixed(1) : '3.0');

    _nameController.addListener(_onNameInputChanged);
    _gramsController.addListener(_onGramsChanged);
    _caloriesController.addListener(_checkAndAutoEstimate);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.removeListener(_onNameInputChanged);
    _gramsController.removeListener(_onGramsChanged);
    _caloriesController.removeListener(_checkAndAutoEstimate);
    _nameController.dispose();
    _gramsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _onGramsChanged() {
    if (_activeSuggestion != null) {
      final grams = double.tryParse(_gramsController.text.trim()) ?? 0.0;
      if (grams > 0) {
        final ratio = grams / 100.0;
        _caloriesController.text = (_activeSuggestion!.caloriesPer100g * ratio).toStringAsFixed(0);
        _proteinController.text = (_activeSuggestion!.proteinPer100g * ratio).toStringAsFixed(1);
        _carbsController.text = (_activeSuggestion!.carbsPer100g * ratio).toStringAsFixed(1);
        _fatController.text = (_activeSuggestion!.fatPer100g * ratio).toStringAsFixed(1);
        _estimatedFiber = _activeSuggestion!.fiberPer100g * ratio;
        _estimatedSodium = _activeSuggestion!.sodiumPer100g * ratio;
        _estimatedSugar = _activeSuggestion!.sugarPer100g * ratio;
        if (mounted) setState(() {});
        return;
      }
    }
    _checkAndAutoEstimate();
  }

  void _onNameInputChanged() {
    _checkAndAutoEstimate();
    final query = _nameController.text.trim();
    _debounceTimer?.cancel();
    if (query.length < 2) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final results = await FoodSearchCoordinator.instance.search(query);
      if (mounted) setState(() => _suggestions = results);
    });
  }

  void _applySuggestion(FoodSearchSuggestion s) {
    _activeSuggestion = s;
    final grams = double.tryParse(_gramsController.text.trim()) ?? 100.0;
    final ratio = grams / 100.0;
    _nameController.text = s.brand != null && s.brand!.isNotEmpty ? '${s.name} (${s.brand})' : s.name;
    _caloriesController.text = (s.caloriesPer100g * ratio).toStringAsFixed(0);
    _proteinController.text = (s.proteinPer100g * ratio).toStringAsFixed(1);
    _carbsController.text = (s.carbsPer100g * ratio).toStringAsFixed(1);
    _fatController.text = (s.fatPer100g * ratio).toStringAsFixed(1);
    _estimatedFiber = s.fiberPer100g * ratio;
    _estimatedSodium = s.sodiumPer100g * ratio;
    _estimatedSugar = s.sugarPer100g * ratio;
    setState(() {
      _suggestions = [];
      _hasAutoEstimated = true;
    });
  }

  void _checkAndAutoEstimate() {
    final query = _nameController.text.trim();
    final grams = double.tryParse(_gramsController.text.trim()) ?? 0.0;
    if (query.isEmpty || grams <= 0) return;

    final cal = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    final prot = double.tryParse(_proteinController.text.trim()) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0.0;

    if (cal == 0.0 || (prot == 0.0 && carbs == 0.0 && fat == 0.0)) {
      final estimated = OfflineFoodEstimatorService.instance.estimateNutrients(query: query, grams: grams);
      if (estimated != null) {
        _hasAutoEstimated = true;
        _caloriesController.text = estimated.calories.toStringAsFixed(0);
        _proteinController.text = estimated.protein.toStringAsFixed(1);
        _carbsController.text = estimated.carbs.toStringAsFixed(1);
        _fatController.text = estimated.fat.toStringAsFixed(1);
        _estimatedFiber = estimated.fiber;
        _estimatedSodium = estimated.sodium;
        _estimatedSugar = estimated.sugar;
        if (mounted) setState(() {});
      }
    }
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final grams = double.tryParse(_gramsController.text.trim()) ?? 0.0;
    final cal = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    final prot = double.tryParse(_proteinController.text.trim()) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0.0;

    final result = FoodItem(
      id: widget.initialItem?.id,
      name: name,
      estimatedGrams: grams,
      calories: cal,
      protein: prot,
      carbs: carbs,
      fat: fat,
      fiber: _estimatedFiber ?? widget.initialItem?.fiber ?? 0.0,
      sodium: _estimatedSodium ?? widget.initialItem?.sodium ?? 0.0,
      sugar: _estimatedSugar ?? widget.initialItem?.sugar ?? 0.0,
      visualJustification: widget.initialItem?.visualJustification,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.initialItem != null;
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppColors.border(context))),
      title: Text(isEditing ? l10n.editIngredientTitle : l10n.addIngredientTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  labelText: l10n.foodNameLabel,
                  labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                  suffixIcon: const Icon(Icons.search, size: 18, color: AppColors.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              FoodSearchSuggestionsList(
                suggestions: _suggestions,
                onSelect: _applySuggestion,
              ),
              if (_hasAutoEstimated && _suggestions.isEmpty) ...[
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerLeft, child: Text(l10n.nutritionalSuggestionApplied, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success))),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gramsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(labelText: l10n.gramsLabel, suffixText: 'g', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _caloriesController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(labelText: l10n.calories, suffixText: 'kcal', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildMacroField(l10n.protein, _proteinController, AppColors.protein)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMacroField(l10n.fat, _fatController, AppColors.fat)),
                ],
              ),
              const SizedBox(height: 12),
              _buildMacroField(l10n.carbs, _carbsController, AppColors.carbs),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel, style: GoogleFonts.inter(color: AppColors.textSecondary(context)))),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text(l10n.save, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildMacroField(String label, TextEditingController ctrl, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            suffixText: 'g',
            suffixStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted(context)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
