import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/pantry_item.dart';
import '../../services/database_service.dart';
import '../../services/theme_manager.dart';

Future<PantryItem?> showPantryItemEditorDialog(BuildContext context, {PantryItem? item}) {
  return showDialog<PantryItem>(
    context: context,
    builder: (_) => PantryItemEditorDialog(initialItem: item),
  );
}

class PantryItemEditorDialog extends StatefulWidget {
  final PantryItem? initialItem;

  const PantryItemEditorDialog({super.key, this.initialItem});

  @override
  State<PantryItemEditorDialog> createState() => _PantryItemEditorDialogState();
}

class _PantryItemEditorDialogState extends State<PantryItemEditorDialog> {
  late final TextEditingController _nameCtrl, _brandCtrl, _servingSizeCtrl;
  late final TextEditingController _packageWeightCtrl, _calCtrl, _protCtrl, _carbsCtrl, _fatCtrl;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _brandCtrl = TextEditingController(text: item?.brand ?? '');
    _servingSizeCtrl = TextEditingController(text: item != null ? item.servingSize.toStringAsFixed(0) : '100');
    _packageWeightCtrl = TextEditingController(text: item?.packageWeight != null ? item!.packageWeight!.toStringAsFixed(0) : '');
    _calCtrl = TextEditingController(text: item != null ? item.calories.toStringAsFixed(0) : '100');
    _protCtrl = TextEditingController(text: item != null ? item.protein.toStringAsFixed(1) : '5.0');
    _carbsCtrl = TextEditingController(text: item != null ? item.carbs.toStringAsFixed(1) : '15.0');
    _fatCtrl = TextEditingController(text: item != null ? item.fat.toStringAsFixed(1) : '2.0');
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _brandCtrl, _servingSizeCtrl, _packageWeightCtrl, _calCtrl, _protCtrl, _carbsCtrl, _fatCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final serving = double.tryParse(_servingSizeCtrl.text.trim()) ?? 100.0;
    final package = double.tryParse(_packageWeightCtrl.text.trim());
    final cal = double.tryParse(_calCtrl.text.trim()) ?? 0.0;
    final prot = double.tryParse(_protCtrl.text.trim()) ?? 0.0;
    final carbs = double.tryParse(_carbsCtrl.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatCtrl.text.trim()) ?? 0.0;

    final newItem = PantryItem(
      id: widget.initialItem?.id,
      name: name,
      brand: _brandCtrl.text.trim().isNotEmpty ? _brandCtrl.text.trim() : null,
      category: widget.initialItem?.category,
      servingSize: serving > 0 ? serving : 100.0,
      packageWeight: package != null && package > 0 ? package : null,
      calories: cal,
      protein: prot,
      carbs: carbs,
      fat: fat,
    );

    final dao = DatabaseService.instance.pantryDao;
    if (widget.initialItem == null) {
      await dao.insertPantryItem(newItem);
    } else {
      await dao.updatePantryItem(newItem);
    }

    if (mounted) Navigator.of(context).pop(newItem);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.initialItem != null;

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border(context))),
      title: Text(isEditing ? l10n.editProductTitle : l10n.addProductToPantryTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(key: const Key('pantry_name_input'), controller: _nameCtrl, decoration: InputDecoration(labelText: l10n.productNameRequired, isDense: true)),
              const SizedBox(height: 8),
              TextField(key: const Key('pantry_brand_input'), controller: _brandCtrl, decoration: InputDecoration(labelText: l10n.brandOptionalLabel, isDense: true)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(key: const Key('pantry_serving_input'), controller: _servingSizeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.servingGramsLabel, isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(key: const Key('pantry_package_input'), controller: _packageWeightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.packageGramsLabel, isDense: true))),
                ],
              ),
            const SizedBox(height: 4),
            Text(l10n.nutrientsPerReferenceServing, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(key: const Key('pantry_cal_input'), controller: _calCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.calories, suffixText: 'kcal', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(key: const Key('pantry_prot_input'), controller: _protCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.protein, suffixText: 'g', isDense: true))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(key: const Key('pantry_carbs_input'), controller: _carbsCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.carbs, suffixText: 'g', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(key: const Key('pantry_fat_input'), controller: _fatCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.fat, suffixText: 'g', isDense: true))),
              ],
            ),
          ],
        ),
      ),
    ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel, style: GoogleFonts.inter(color: AppColors.textSecondary(context)))),
        ElevatedButton(
          key: const Key('pantry_save_button'),
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text(isEditing ? l10n.saveChangesAction : l10n.addAction, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
