import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/food_search_suggestion.dart';
import '../../models/meal.dart';
import '../../services/food_search_coordinator.dart';
import '../../services/theme_manager.dart';

Future<Meal?> showQuickMealDialog(BuildContext context, {DateTime? date}) {
  return showDialog<Meal>(
    context: context,
    builder: (ctx) => _QuickMealDialog(date: date ?? DateTime.now()),
  );
}

class _QuickMealDialog extends StatefulWidget {
  final DateTime date;
  const _QuickMealDialog({required this.date});

  @override
  State<_QuickMealDialog> createState() => _QuickMealDialogState();
}

class _QuickMealDialogState extends State<_QuickMealDialog> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController(text: '300');
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  String _mealType = 'Snack';

  Timer? _debounceTimer;
  List<FoodSearchSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
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
    _nameController.text = s.brand != null && s.brand!.isNotEmpty ? '${s.name} (${s.brand})' : s.name;
    _caloriesController.text = s.caloriesPer100g.toStringAsFixed(0);
    _proteinController.text = s.proteinPer100g.toStringAsFixed(1);
    _carbsController.text = s.carbsPer100g.toStringAsFixed(1);
    _fatController.text = s.fatPer100g.toStringAsFixed(1);
    setState(() => _suggestions = []);
  }

  void _submit() {
    final name = _nameController.text.trim().isEmpty ? 'Comida rápida' : _nameController.text.trim();
    final cal = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    if (cal <= 0) return;

    final protein = double.tryParse(_proteinController.text.trim()) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0.0;

    final meal = Meal(
      name: name,
      mealType: _mealType,
      date: widget.date,
      calories: cal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      notes: 'Registro rápido de comida',
    );
    Navigator.of(context).pop(meal);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.carbsAmber, size: 22),
          const SizedBox(width: 8),
          Text(
            'Comida Rápida',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Descripción / Alimento',
                  hintText: 'Ej. Manzana, Avena, Yogur',
                  suffixIcon: const Icon(Icons.search, size: 18, color: AppColors.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 6),
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border(context)),
                    itemBuilder: (ctx, i) {
                      final s = _suggestions[i];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        subtitle: Text('${s.caloriesPer100g.toInt()} kcal (100g)', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context))),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(s.sourceBadgeLabel, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        onTap: () => _applySuggestion(s),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _caloriesController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Calorías estimadas (kcal) *'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Prot (g)', hintText: '0'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _carbsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Carb (g)', hintText: '0'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Grasa (g)', hintText: '0'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _mealType,
                menuMaxHeight: 280,
                decoration: const InputDecoration(labelText: 'Tipo de Comida'),
                items: Meal.validMealTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _mealType = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)?.cancel ?? 'Cancelar',
            style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            AppLocalizations.of(context)?.save ?? 'Añadir',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
