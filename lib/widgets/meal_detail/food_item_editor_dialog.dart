import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/food_item.dart';
import '../../services/theme_manager.dart';

Future<FoodItem?> showFoodItemEditorDialog(
  BuildContext context, {
  FoodItem? initialItem,
}) {
  return showDialog<FoodItem>(
    context: context,
    builder: (dialogContext) => _FoodItemEditorDialog(initialItem: initialItem),
  );
}

class _FoodItemEditorDialog extends StatefulWidget {
  final FoodItem? initialItem;
  const _FoodItemEditorDialog({this.initialItem});

  @override
  State<_FoodItemEditorDialog> createState() => _FoodItemEditorDialogState();
}

class _FoodItemEditorDialogState extends State<_FoodItemEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _gramsController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _justificationController;

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
    _justificationController = TextEditingController(text: item?.visualJustification ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose;
    _gramsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _justificationController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final grams = double.tryParse(_gramsController.text.trim()) ?? 0.0;
    final cal = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    final prot = double.tryParse(_proteinController.text.trim()) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0.0;
    final just = _justificationController.text.trim();

    final result = FoodItem(
      id: widget.initialItem?.id,
      name: name,
      estimatedGrams: grams,
      calories: cal,
      protein: prot,
      carbs: carbs,
      fat: fat,
      visualJustification: just.isNotEmpty ? just : null,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialItem != null;

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Text(
        isEditing ? 'Editar Ingrediente' : 'Añadir Ingrediente',
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(context),
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del alimento *'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gramsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Gramos (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _caloriesController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Calorías (kcal)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Prot (g)'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _carbsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Carb (g)'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _fatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Gras (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _justificationController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Justificación volumétrica / Notas',
                  hintText: 'Ej. Volumen aprox. 1 taza cocida',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
          ),
        ),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
