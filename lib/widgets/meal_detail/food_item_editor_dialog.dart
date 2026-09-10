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
    _nameController.dispose();
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
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  labelText: 'Nombre del alimento *',
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gramos',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _gramsController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                          decoration: const InputDecoration(
                            suffixText: 'g',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calorías',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.calories,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _caloriesController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                          decoration: const InputDecoration(
                            suffixText: 'kcal',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroInputField(
                      context: context,
                      label: 'Proteína',
                      controller: _proteinController,
                      color: AppColors.protein,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMacroInputField(
                      context: context,
                      label: 'Grasas',
                      controller: _fatController,
                      color: AppColors.fat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMacroInputField(
                context: context,
                label: 'Carbohidratos',
                controller: _carbsController,
                color: AppColors.carbs,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _justificationController,
                maxLines: 2,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  labelText: 'Justificación volumétrica / Notas',
                  labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                  hintText: 'Ej. Volumen aprox. 1 taza cocida',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted(context)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
        ),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildMacroInputField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            suffixText: 'g',
            suffixStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted(context),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
