import 'dart:convert';
import 'dart:math' as math;
import 'food_item.dart';
import 'json_repair_helper.dart';
import 'meal_decomposer.dart';
import 'model_sanitizer.dart';

export 'json_repair_helper.dart';
export 'meal_decomposer.dart';

class MealAnalysisResult {
  final String dishName;
  final List<FoodItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String rawJson;
  final int? confidencePercentage;
  final int? calorieErrorMargin;

  const MealAnalysisResult({
    required this.dishName,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.rawJson,
    this.confidencePercentage,
    this.calorieErrorMargin,
  });

  /// Extracts individual food component names from a composite text
  static List<String> extractComponents(String text) =>
      MealDecomposer.extractComponents(text);

  /// Identifies seasonings, spices, and herbs to protect macro allocation
  static bool isSeasoningOrHerb(String name) =>
      MealDecomposer.isSeasoningOrHerb(name);

  /// Decomposes composite foods or dishes into distinct ingredients
  static List<FoodItem> decomposeCompositeFood(
    List<String> componentNames,
    double cal,
    double prot,
    double carbs,
    double fat,
  ) =>
      MealDecomposer.decomposeCompositeFood(componentNames, cal, prot, carbs, fat);

  /// Repairs truncated JSON by closing dangling strings and matching unclosed braces/brackets.
  static String repairTruncatedJson(String raw) => JsonRepairHelper.repair(raw);

  factory MealAnalysisResult.fromJsonString(String jsonStr) {
    var cleaned = jsonStr.trim();

    final jsonFenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(cleaned);
    if (jsonFenceMatch != null) {
      cleaned = jsonFenceMatch.group(1)!.trim();
    } else {
      final firstBrace = cleaned.indexOf('{');
      final lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        cleaned = cleaned.substring(firstBrace, lastBrace + 1).trim();
      }
    }

    Map<String, dynamic> data;
    try {
      data = json.decode(cleaned);
    } catch (_) {
      try {
        data = json.decode(repairTruncatedJson(cleaned));
      } catch (_) {
        data = {
          'plato': 'Comida Analizada',
          'items': [],
          'totales': {'calorias': 0.0, 'proteina_g': 0.0, 'carbohidratos_g': 0.0, 'grasas_g': 0.0}
        };
      }
    }
    final String dish = (data['plato'] ?? data['nombre'] ?? data['dish'] ?? data['name'] ?? 'Comida Analizada').toString();

    final List<FoodItem> parsedItems = [];
    final dynamic itemsList = data['items'] ?? data['ingredientes'] ?? data['alimentos'] ??
        data['ingredients'] ?? data['componentes'] ?? data['desglose'] ?? data['food_items'] ?? data['foods'];

    if (itemsList is List) {
      for (final itemMap in itemsList) {
        if (itemMap is Map<String, dynamic>) {
          parsedItems.add(FoodItem.fromJson(itemMap));
        } else if (itemMap is String && itemMap.trim().isNotEmpty) {
          parsedItems.add(FoodItem(
            name: itemMap.trim(),
            estimatedGrams: 110,
            calories: 0, protein: 0, carbs: 0, fat: 0,
            visualJustification: 'Ingrediente identificado por IA',
          ));
        }
      }
    } else if (itemsList is Map<String, dynamic>) {
      for (final entry in itemsList.entries) {
        if (entry.value is Map<String, dynamic>) {
          final map = Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
          if (!map.containsKey('alimento') && !map.containsKey('nombre') && !map.containsKey('name')) {
            map['alimento'] = entry.key;
          }
          parsedItems.add(FoodItem.fromJson(map));
        } else {
          parsedItems.add(FoodItem(
            name: entry.key,
            estimatedGrams: 110,
            calories: 0, protein: 0, carbs: 0, fat: 0,
            visualJustification: 'Ingrediente identificado por IA',
          ));
        }
      }
    } else if (itemsList is String && itemsList.trim().isNotEmpty) {
      final parts = extractComponents(itemsList);
      for (final part in parts) {
        parsedItems.add(FoodItem(
          name: part,
          estimatedGrams: 110,
          calories: 0, protein: 0, carbs: 0, fat: 0,
          visualJustification: 'Ingrediente identificado por IA',
        ));
      }
    }

    double cal = 0.0, prot = 0.0, carbs = 0.0, fat = 0.0;
    final totalesMap = data['totales'] ?? data['totals'];
    if (totalesMap is Map<String, dynamic>) {
      cal = ModelSanitizer.clampDouble(totalesMap['calorias'] ?? totalesMap['calories'] ?? totalesMap['total_calorias']);
      prot = ModelSanitizer.clampDouble(totalesMap['proteina_g'] ?? totalesMap['proteinas_g'] ?? totalesMap['protein'] ?? totalesMap['proteins_g']);
      carbs = ModelSanitizer.clampDouble(totalesMap['carbohidratos_g'] ?? totalesMap['carbohidratos'] ?? totalesMap['carbs'] ?? totalesMap['carbohydrates_g']);
      fat = ModelSanitizer.clampDouble(totalesMap['grasas_g'] ?? totalesMap['grasa_g'] ?? totalesMap['fat'] ?? totalesMap['fats_g']);
    } else {
      for (final item in parsedItems) {
        cal += item.calories; prot += item.protein; carbs += item.carbs; fat += item.fat;
      }
    }

    // Parse self-validation metrics (porcentaje_certeza and margen_error_kcal)
    int? confidence;
    final dynamic rawConf = data['porcentaje_certeza'] ??
        data['confidence_percentage'] ??
        data['certeza'] ??
        data['confidence'];
    if (rawConf is num) {
      confidence = rawConf.toInt().clamp(0, 100);
    } else if (rawConf is String) {
      final cleanStr = rawConf.replaceAll(RegExp(r'[^0-9.-]'), '');
      final d = double.tryParse(cleanStr);
      if (d != null) confidence = d.round().clamp(0, 100);
    }

    int? errorMargin;
    final dynamic rawMargin = data['margen_error_kcal'] ??
        data['calorie_error_margin'] ??
        data['margen_error'] ??
        data['error_margin_kcal'];
    if (rawMargin is num) {
      errorMargin = rawMargin.toInt().clamp(0, 2000);
    } else if (rawMargin is String) {
      final cleanStr = rawMargin.replaceAll(RegExp(r'[^0-9.-]'), '');
      final d = double.tryParse(cleanStr);
      if (d != null) errorMargin = d.round().clamp(0, 2000);
    }

    // Decompose single lumped items or empty item lists
    if (parsedItems.length == 1) {
      final singleItem = parsedItems.first;
      final isLumped = singleItem.name.trim().toLowerCase() == dish.trim().toLowerCase() ||
          singleItem.estimatedGrams == 200.0 ||
          singleItem.name.contains(',') ||
          singleItem.name.contains(';');
      if (isLumped) {
        final components = extractComponents(singleItem.name);
        final dishComponents = extractComponents(dish);
        final effectiveComponents = components.length > 1
            ? components
            : (dishComponents.length > 1 ? dishComponents : const <String>[]);
        if (effectiveComponents.length > 1) {
          parsedItems.clear();
          parsedItems.addAll(decomposeCompositeFood(
            effectiveComponents,
            cal > 0 ? cal : singleItem.calories,
            prot > 0 ? prot : singleItem.protein,
            carbs > 0 ? carbs : singleItem.carbs,
            fat > 0 ? fat : singleItem.fat,
          ));
        }
      }
    } else if (parsedItems.isEmpty && (cal > 0 || prot > 0 || carbs > 0 || fat > 0)) {
      final components = extractComponents(dish);
      if (components.length > 1) {
        parsedItems.addAll(decomposeCompositeFood(components, cal, prot, carbs, fat));
      } else {
        final double estimatedWeight = (cal > 0 ? (cal / 1.5).clamp(120.0, 500.0) : 250.0).roundToDouble();
        parsedItems.add(FoodItem(
          name: dish,
          estimatedGrams: estimatedWeight == 200.0 ? 210.0 : estimatedWeight,
          calories: cal, protein: prot, carbs: carbs, fat: fat,
          visualJustification: 'Porción completa del plato estimada por IA',
        ));
      }
    }

    // Distribute macros if items have 0 calories but total calories exist
    final itemsCalSum = parsedItems.fold(0.0, (acc, e) => acc + e.calories);
    if (itemsCalSum == 0.0 && parsedItems.isNotEmpty && cal > 0) {
      final substantialItems = parsedItems.where((it) => !isSeasoningOrHerb(it.name)).toList();
      final hasSubstantial = substantialItems.isNotEmpty;
      final mainCount = hasSubstantial ? substantialItems.length : parsedItems.length;
      final hasSeasoning = parsedItems.any((it) => isSeasoningOrHerb(it.name));
      final factor = hasSeasoning ? 0.99 : 1.0;
      for (int i = 0; i < parsedItems.length; i++) {
        final item = parsedItems[i];
        if (hasSubstantial && isSeasoningOrHerb(item.name)) {
          parsedItems[i] = item.copyWith(
            estimatedGrams: 5.0,
            calories: math.min(5.0, cal * 0.01),
            protein: 0.1, carbs: 0.5, fat: 0.1,
            visualJustification: 'Nota de saborización / condimento marginal',
          );
        } else {
          parsedItems[i] = item.copyWith(
            calories: ModelSanitizer.clampDouble((cal * factor) / mainCount),
            protein: ModelSanitizer.clampDouble((prot * factor) / mainCount),
            carbs: ModelSanitizer.clampDouble((carbs * factor) / mainCount),
            fat: ModelSanitizer.clampDouble((fat * factor) / mainCount),
          );
        }
      }
    }

    return MealAnalysisResult(
      dishName: dish, items: parsedItems,
      totalCalories: ModelSanitizer.clampDouble(cal), totalProtein: ModelSanitizer.clampDouble(prot),
      totalCarbs: ModelSanitizer.clampDouble(carbs), totalFat: ModelSanitizer.clampDouble(fat),
      rawJson: cleaned,
      confidencePercentage: confidence,
      calorieErrorMargin: errorMargin,
    );
  }

  Map<String, dynamic> toMap() => {
        'plato': dishName,
        'items': items.map((e) => e.toJson()).toList(),
        'totales': {
          'calorias': totalCalories,
          'proteina_g': totalProtein,
          'carbohidratos_g': totalCarbs,
          'grasas_g': totalFat,
        },
        if (confidencePercentage != null) 'porcentaje_certeza': confidencePercentage,
        if (calorieErrorMargin != null) 'margen_error_kcal': calorieErrorMargin,
        'rawJson': rawJson,
      };

  Map<String, dynamic> toJson() => toMap();

  MealAnalysisResult copyWith({
    String? dishName,
    List<FoodItem>? items,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    String? rawJson,
    int? confidencePercentage,
    int? calorieErrorMargin,
  }) {
    return MealAnalysisResult(
      dishName: dishName ?? this.dishName,
      items: items ?? this.items,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      rawJson: rawJson ?? this.rawJson,
      confidencePercentage: confidencePercentage ?? this.confidencePercentage,
      calorieErrorMargin: calorieErrorMargin ?? this.calorieErrorMargin,
    );
  }
}
