import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/meal_controller.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../services/image_processing_service.dart';
import '../services/theme_manager.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/meal_detail/food_item_editor_dialog.dart';
import '../widgets/meal_detail/food_items_list_card.dart';
import '../widgets/meal_detail/meal_image_card.dart';
import '../widgets/meal_detail/meal_macro_chips_row.dart';

class MealDetailScreen extends StatefulWidget {
  final Meal? initialMeal;
  final String? defaultMealType;

  const MealDetailScreen({
    super.key,
    this.initialMeal,
    this.defaultMealType,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late String _mealType;
  late DateTime _date;
  String? _imagePath;
  List<FoodItem> _items = [];

  double _calories = 0.0;
  double _protein = 0.0;
  double _carbs = 0.0;
  double _fat = 0.0;
  bool _isSaving = false;

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
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final file = await picker.pickImage(source: source);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final compressed = ImageProcessingService.instance.compressAndResize(bytes);
    final savedPath = await ImageProcessingService.instance.saveMealImage(
      compressed,
      widget.initialMeal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );

    setState(() {
      _imagePath = savedPath;
    });
  }

  Future<void> _saveMeal() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre para el plato.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final baseMeal = widget.initialMeal ??
          Meal(
            name: name,
            mealType: _mealType,
            date: _date,
            imagePath: _imagePath,
            calories: _calories,
            protein: _protein,
            carbs: _carbs,
            fat: _fat,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );

      final updated = baseMeal.copyWith(
        name: name,
        mealType: _mealType,
        date: _date,
        imagePath: _imagePath,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      ).recalculateFromItems(_items);

      if (widget.initialMeal != null) {
        await MealController.instance.updateMeal(updated);
      } else {
        await MealController.instance.saveMeal(updated);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteMeal() async {
    final confirmed = await showVeConfirmationDialog(
      context,
      title: '¿Eliminar Comida?',
      message: 'Esta acción eliminará el registro de forma permanente de tu SQLite local.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );

    if (confirmed == true && widget.initialMeal != null) {
      await MealController.instance.deleteMeal(widget.initialMeal!);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
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
          const SizedBox(height: 16),
          MealMacroChipsRow(
            calories: _calories,
            protein: _protein,
            carbs: _carbs,
            fat: _fat,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              labelText: 'Nombre del plato *',
              hintText: 'Ej. Pechuga a la plancha con arroz',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _mealType,
            menuMaxHeight: 280,
            decoration: const InputDecoration(labelText: 'Tipo de Comida'),
            items: Meal.validMealTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _mealType = val);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas / Observaciones',
              hintText: 'Ej. Se usó poco aceite en sofrito, porción mediana',
            ),
          ),
          const SizedBox(height: 16),
          FoodItemsListCard(
            items: _items,
            onAddItem: () async {
              final newItem = await showFoodItemEditorDialog(context);
              if (newItem != null) {
                setState(() => _items.add(newItem));
                _recalculateTotals();
              }
            },
            onEditItem: (item) async {
              final edited = await showFoodItemEditorDialog(context, initialItem: item);
              if (edited != null) {
                final idx = _items.indexWhere((e) => e.id == item.id);
                if (idx != -1) {
                  setState(() => _items[idx] = edited);
                  _recalculateTotals();
                }
              }
            },
            onDeleteItem: (item) {
              setState(() => _items.removeWhere((e) => e.id == item.id));
              _recalculateTotals();
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveMeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(
              _isSaving ? 'Guardando...' : (isEditing ? 'Actualizar Comida' : 'Registrar Comida'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
