import 'package:flutter/material.dart';
import '../../controllers/meal_controller.dart';
import '../../models/food_item.dart';
import '../../models/meal.dart';
import '../../services/theme_manager.dart';
import '../common/confirmation_dialog.dart';

Future<bool> confirmAndDeleteMeal(BuildContext context, Meal meal) async {
  final confirmed = await showVeConfirmationDialog(
    context,
    title: '¿Eliminar Comida?',
    message: 'Esta acción eliminará el registro de forma permanente de tu SQLite local.',
    confirmLabel: 'Eliminar',
    isDestructive: true,
  );

  if (confirmed != true) return false;
  try {
    await MealController.instance.deleteMeal(meal);
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar comida: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    return false;
  }
}

Future<bool> saveMealEntry({
  required BuildContext context,
  required Meal? initialMeal,
  required String name,
  required String mealType,
  required DateTime date,
  required String? imagePath,
  required double calories,
  required double protein,
  required double carbs,
  required double fat,
  required String? notes,
  required List<FoodItem> items,
}) async {
  if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor ingresa un nombre para el plato.')),
    );
    return false;
  }

  try {
    final baseMeal = (initialMeal ?? Meal(name: name, mealType: mealType, date: date)).copyWith(
      name: name,
      mealType: mealType,
      date: date,
      imagePath: imagePath,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      notes: notes,
    );

    final updated = items.isNotEmpty
        ? baseMeal.recalculateFromItems(items)
        : baseMeal.copyWith(aiBreakdownJson: null);
    await MealController.instance.upsertMeal(updated);
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar comida: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    return false;
  }
}
