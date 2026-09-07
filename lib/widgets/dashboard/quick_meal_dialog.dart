import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/meal.dart';
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
  final _nameController = TextEditingController(text: 'Comida rápida');
  final _caloriesController = TextEditingController(text: '300');
  String _mealType = 'Snack';

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final cal = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    if (name.isEmpty || cal <= 0) return;

    final meal = Meal(
      name: name,
      mealType: _mealType,
      date: widget.date,
      calories: cal,
      protein: 0,
      carbs: 0,
      fat: 0,
      notes: 'Registro rápido de calorías',
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Descripción / Nombre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _caloriesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Calorías estimadas (kcal) *'),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Añadir', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
