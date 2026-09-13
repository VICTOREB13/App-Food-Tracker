import 'dart:io';
import 'package:flutter/material.dart';
import '../../controllers/meal_controller.dart';
import '../../models/food_item.dart';
import '../../models/meal.dart';
import '../../services/gemini_vision_service.dart';
import '../../services/image_processing_service.dart';
import '../../services/secure_storage_service.dart';
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
    String? effectiveImagePath = imagePath;
    if (effectiveImagePath != null && effectiveImagePath.trim().isNotEmpty) {
      try {
        effectiveImagePath = await ImageProcessingService.instance.renameMealImage(
          currentPath: effectiveImagePath,
          newMealType: mealType,
          date: date,
        );
      } catch (_) {}
    }

    final baseMeal = (initialMeal ?? Meal(name: name, mealType: mealType, date: date)).copyWith(
      name: name,
      mealType: mealType,
      date: date,
      imagePath: effectiveImagePath,
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

Future<MealAnalysisResult?> reanalyzeMealWithAi({
  required BuildContext context,
  required String? imagePath,
  required String currentDishName,
  required String currentNotes,
  required List<FoodItem> currentItems,
}) async {
  if (imagePath == null) return null;
  final file = File(imagePath);
  if (!file.existsSync()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el archivo de imagen en disco.')),
      );
    }
    return null;
  }

  final apiKey = await SecureStorageService.instance.getGeminiApiKey();
  if (apiKey == null || apiKey.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configura tu API Key de Gemini en Perfil para re-analizar.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    return null;
  }

  try {
    final selectedModel = await SecureStorageService.instance.getSelectedGeminiModel();
    final masterPrompt = await SecureStorageService.instance.getMasterPrompt();
    final gemini = GeminiVisionService(
      apiKey: apiKey,
      modelName: selectedModel ?? GeminiVisionService.defaultModel,
      masterPrompt: masterPrompt,
    );

    final bytes = await file.readAsBytes();
    final itemsSummary = currentItems.isNotEmpty
        ? currentItems.map((e) => '${e.name}: ${e.estimatedGrams.toStringAsFixed(0)}g').join(', ')
        : 'sin ingredientes';

    final String? userContext;
    if (currentDishName.isEmpty && currentItems.isEmpty) {
      userContext = currentNotes.isNotEmpty
          ? 'Notas/Indicaciones del comensal: "$currentNotes"'
          : null;
    } else {
      userContext = 'El comensal corrigió ingredientes del plato: '
          'Plato: "$currentDishName", Notas/Indicaciones: "$currentNotes", Ingredientes actuales: $itemsSummary. '
          'Desglosa CADA ingrediente de forma independiente con sus gramos y macronutrientes reales ajustados a las indicaciones del comensal. PROHIBIDO unificar todo en un solo ingrediente o usar 200g genéricos.';
    }

    final analysis = await gemini.analyzeMealPhoto(
      rawImageBytes: bytes,
      userContext: userContext,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plato re-analizado y actualizado con IA.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    return analysis;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al re-analizar imagen: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    return null;
  }
}
