import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/meal_controller.dart';
import '../../models/meal.dart';
import '../../models/pantry_item.dart';
import '../../services/theme_manager.dart';

Future<bool?> showPantryConsumptionDialog(BuildContext context, PantryItem item, {DateTime? date}) {
  return showDialog<bool>(context: context, builder: (_) => PantryConsumptionDialog(pantryItem: item, targetDate: date));
}

class PantryConsumptionDialog extends StatefulWidget {
  final PantryItem pantryItem;
  final DateTime? targetDate;

  const PantryConsumptionDialog({super.key, required this.pantryItem, this.targetDate});

  @override
  State<PantryConsumptionDialog> createState() => _PantryConsumptionDialogState();
}

class _PantryConsumptionDialogState extends State<PantryConsumptionDialog> {
  late final TextEditingController _gramsController;
  String _selectedMealType = 'Almuerzo';
  bool _isSaving = false;

  static const _mealTypes = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];

  @override
  void initState() {
    super.initState();
    final defaultGrams = widget.pantryItem.servingSize > 0 ? widget.pantryItem.servingSize : 100.0;
    _gramsController = TextEditingController(text: defaultGrams.toStringAsFixed(0));
    _gramsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  double get _currentGrams => double.tryParse(_gramsController.text.trim()) ?? 0.0;

  Future<void> _handleConfirm() async {
    final grams = _currentGrams;
    if (grams <= 0) return;

    setState(() => _isSaving = true);
    try {
      final scaledItem = widget.pantryItem.toScaledFoodItem(gramsConsumed: grams);
      final meal = Meal(
        name: widget.pantryItem.brand != null && widget.pantryItem.brand!.isNotEmpty
            ? '${widget.pantryItem.name} (${widget.pantryItem.brand})'
            : widget.pantryItem.name,
        mealType: _selectedMealType,
        date: widget.targetDate ?? DateTime.now(),
        calories: scaledItem.calories, protein: scaledItem.protein, carbs: scaledItem.carbs,
        fat: scaledItem.fat, fiber: scaledItem.fiber, sodium: scaledItem.sodium, sugar: scaledItem.sugar,
        items: [scaledItem],
      );

      await MealController.instance.saveMeal(meal);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🍽️ ${meal.name} registrado en $_selectedMealType (${meal.calories.toInt()} kcal).'),
            backgroundColor: AppColors.protein,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar: $e'), backgroundColor: AppColors.primary));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grams = _currentGrams;
    final scaled = widget.pantryItem.toScaledFoodItem(gramsConsumed: grams > 0 ? grams : 0.0);
    final ref = widget.pantryItem.servingSize > 0 ? widget.pantryItem.servingSize : 100.0;

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border(context))),
      title: Row(
        children: [
          const Icon(Icons.restaurant_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text('Registrar a Comida', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pantryItem.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            if (widget.pantryItem.brand != null)
              Text(widget.pantryItem.brand!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
            const SizedBox(height: 12),
            Text('Comida de destino:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _mealTypes.map((type) {
                final isSel = _selectedMealType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceSubtle(context),
                  labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? Colors.white : AppColors.textPrimary(context)),
                  onSelected: (val) { if (val) setState(() => _selectedMealType = type); },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('consumption_grams_input'),
              controller: _gramsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Gramos a consumir',
                suffixText: 'g',
                helperText: 'Porción de referencia del producto: ${ref.toInt()}g',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nutrientes Calculados en Vivo:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMacroItem('Calorías', '${scaled.calories.round()} kcal', AppColors.primary),
                      _buildMacroItem('Proteína', '${scaled.protein.toStringAsFixed(1)}g', AppColors.protein),
                      _buildMacroItem('Carbos', '${scaled.carbs.toStringAsFixed(1)}g', AppColors.carbs),
                      _buildMacroItem('Grasas', '${scaled.fat.toStringAsFixed(1)}g', AppColors.fat),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(context)))),
        ElevatedButton(
          key: const Key('consumption_confirm_button'),
          onPressed: (_isSaving || grams <= 0) ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: _isSaving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Añadir a $_selectedMealType', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
      ],
    );
  }
}
