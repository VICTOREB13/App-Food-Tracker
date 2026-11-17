import 'dart:convert';
import 'dart:math' as math;
import 'package:food_tracker/features/food_entry/models/food_item.dart';
import 'package:food_tracker/core/models/json_repair_helper.dart';
import 'meal_decomposer.dart';
import 'package:food_tracker/core/models/model_sanitizer.dart';

export 'package:food_tracker/core/models/json_repair_helper.dart';
export 'meal_decomposer.dart';

class MealAnalysisResult {
  final String dishName;
  final List<FoodItem> items;
  final double totalCalories, totalProtein, totalCarbs, totalFat;
  final double totalFiber, totalSodium, totalSugar;
  final String rawJson;
  final int? confidencePercentage;
  final int? calorieErrorMargin;
  final bool isPartial;
  final String? modelUsed;
  final bool isFallback;
  final String? thinkingLevel;

  const MealAnalysisResult({
    required this.dishName, required this.items,
    required this.totalCalories, required this.totalProtein,
    required this.totalCarbs, required this.totalFat,
    this.totalFiber = 0.0, this.totalSodium = 0.0, this.totalSugar = 0.0,
    required this.rawJson, this.confidencePercentage, this.calorieErrorMargin,
    this.isPartial = false,
    this.modelUsed,
    this.isFallback = false,
    this.thinkingLevel,
  });

  static List<String> extractComponents(String text) => MealDecomposer.extractComponents(text);
  static bool isSeasoningOrHerb(String name) => MealDecomposer.isSeasoningOrHerb(name);
  static List<FoodItem> decomposeCompositeFood(
    List<String> componentNames, double cal, double prot, double carbs, double fat,
  ) => MealDecomposer.decomposeCompositeFood(componentNames, cal, prot, carbs, fat);
  static String repairTruncatedJson(String raw) => JsonRepairHelper.repair(raw);

  factory MealAnalysisResult.fromJsonString(
    String jsonStr, {
    bool isPartial = false,
    String? modelUsed,
    bool isFallback = false,
    String? thinkingLevel,
  }) {
    var cleaned = jsonStr.trim();
    final jsonFenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(cleaned);
    if (jsonFenceMatch != null) {
      cleaned = jsonFenceMatch.group(1)!.trim();
    } else {
      final firstBrace = cleaned.indexOf('{'), lastBrace = cleaned.lastIndexOf('}');
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
        data = {'plato': 'Comida Analizada', 'items': []};
      }
    }
    final String dish = (data['plato'] ?? data['nombre'] ?? data['dish'] ?? data['name'] ?? 'Comida Analizada').toString();
    final bool partial = isPartial || data['is_partial'] == true || data['isPartial'] == true;
    final String? effectiveModel = (data['model_used'] ?? data['modelUsed'] ?? modelUsed)?.toString();
    final bool effectiveFallback = data['is_fallback'] == true || data['isFallback'] == true || isFallback;
    final String? effectiveThinking = (data['thinking_level'] ?? data['thinkingLevel'] ?? thinkingLevel)?.toString();

    final List<FoodItem> parsedItems = [];
    final dynamic itemsList = data['items'] ?? data['ingredientes'] ?? data['alimentos'] ??
        data['ingredients'] ?? data['componentes'] ?? data['desglose'] ?? data['food_items'] ?? data['foods'];

    if (itemsList is List) {
      for (final itemMap in itemsList) {
        if (itemMap is Map<String, dynamic>) {
          parsedItems.add(FoodItem.fromJson(itemMap));
        } else if (itemMap is String && itemMap.trim().isNotEmpty) {
          parsedItems.add(FoodItem(
            name: itemMap.trim(), estimatedGrams: 110, calories: 0, protein: 0, carbs: 0, fat: 0,
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
            name: entry.key, estimatedGrams: 110, calories: 0, protein: 0, carbs: 0, fat: 0,
            visualJustification: 'Ingrediente identificado por IA',
          ));
        }
      }
    } else if (itemsList is String && itemsList.trim().isNotEmpty) {
      for (final part in extractComponents(itemsList)) {
        parsedItems.add(FoodItem(
          name: part, estimatedGrams: 110, calories: 0, protein: 0, carbs: 0, fat: 0,
          visualJustification: 'Ingrediente identificado por IA',
        ));
      }
    }

    double legacyCal = 0.0, legacyProt = 0.0, legacyCarbs = 0.0, legacyFat = 0.0;
    final totalesMap = data['totales'] ?? data['totals'];
    if (totalesMap is Map<String, dynamic>) {
      legacyCal = ModelSanitizer.clampDouble(totalesMap['calorias'] ?? totalesMap['calories'] ?? totalesMap['total_calorias']);
      legacyProt = ModelSanitizer.clampDouble(totalesMap['proteina_g'] ?? totalesMap['proteinas_g'] ?? totalesMap['protein'] ?? totalesMap['proteins_g']);
      legacyCarbs = ModelSanitizer.clampDouble(totalesMap['carbohidratos_g'] ?? totalesMap['carbohidratos'] ?? totalesMap['carbs'] ?? totalesMap['carbohydrates_g']);
      legacyFat = ModelSanitizer.clampDouble(totalesMap['grasas_g'] ?? totalesMap['grasa_g'] ?? totalesMap['fat'] ?? totalesMap['fats_g']);
    }

    int? confidence;
    final dynamic rawConf = data['porcentaje_certeza'] ?? data['confidence_percentage'] ?? data['certeza'] ?? data['confidence'];
    if (rawConf is num) {
      confidence = rawConf.toInt().clamp(0, 100);
    } else if (rawConf is String) {
      final d = double.tryParse(rawConf.replaceAll(RegExp(r'[^0-9.-]'), ''));
      if (d != null) confidence = d.round().clamp(0, 100);
    }

    int? errorMargin;
    final dynamic rawMargin = data['margen_error_kcal'] ?? data['calorie_error_margin'] ?? data['margen_error'] ?? data['error_margin_kcal'];
    if (rawMargin is num) {
      errorMargin = rawMargin.toInt().clamp(0, 2000);
    } else if (rawMargin is String) {
      final d = double.tryParse(rawMargin.replaceAll(RegExp(r'[^0-9.-]'), ''));
      if (d != null) errorMargin = d.round().clamp(0, 2000);
    }

    if (parsedItems.length == 1) {
      final single = parsedItems.first;
      final isLumped = single.name.trim().toLowerCase() == dish.trim().toLowerCase() ||
          single.estimatedGrams == 200.0 || single.name.contains(',') || single.name.contains(';');
      if (isLumped) {
        final comps = extractComponents(single.name), dishComps = extractComponents(dish);
        final eff = comps.length > 1 ? comps : (dishComps.length > 1 ? dishComps : const <String>[]);
        if (eff.length > 1) {
          parsedItems.clear();
          parsedItems.addAll(decomposeCompositeFood(
            eff,
            single.calories > 0 ? single.calories : legacyCal,
            single.protein > 0 ? single.protein : legacyProt,
            single.carbs > 0 ? single.carbs : legacyCarbs,
            single.fat > 0 ? single.fat : legacyFat,
          ));
        }
      }
    } else if (parsedItems.isEmpty && (legacyCal > 0 || legacyProt > 0 || legacyCarbs > 0 || legacyFat > 0)) {
      final comps = extractComponents(dish);
      if (comps.length > 1) {
        parsedItems.addAll(decomposeCompositeFood(comps, legacyCal, legacyProt, legacyCarbs, legacyFat));
      } else {
        final estWeight = (legacyCal > 0 ? (legacyCal / 1.5).clamp(120.0, 500.0) : 250.0).roundToDouble();
        parsedItems.add(FoodItem(
          name: dish, estimatedGrams: estWeight == 200.0 ? 210.0 : estWeight,
          calories: legacyCal, protein: legacyProt, carbs: legacyCarbs, fat: legacyFat,
          visualJustification: 'Porción completa del plato estimada por IA',
        ));
      }
    }

    final itemsCalSum = parsedItems.fold(0.0, (acc, e) => acc + e.calories);
    if (itemsCalSum == 0.0 && parsedItems.isNotEmpty && legacyCal > 0) {
      final substantial = parsedItems.where((it) => !isSeasoningOrHerb(it.name)).toList();
      final count = substantial.isNotEmpty ? substantial.length : parsedItems.length;
      final factor = parsedItems.any((it) => isSeasoningOrHerb(it.name)) ? 0.99 : 1.0;
      for (int i = 0; i < parsedItems.length; i++) {
        final item = parsedItems[i];
        if (substantial.isNotEmpty && isSeasoningOrHerb(item.name)) {
          parsedItems[i] = item.copyWith(
            estimatedGrams: 5.0, calories: math.min(5.0, legacyCal * 0.01),
            protein: 0.1, carbs: 0.5, fat: 0.1,
            visualJustification: 'Nota de saborización / condimento marginal',
          );
        } else {
          parsedItems[i] = item.copyWith(
            calories: ModelSanitizer.clampDouble((legacyCal * factor) / count),
            protein: ModelSanitizer.clampDouble((legacyProt * factor) / count),
            carbs: ModelSanitizer.clampDouble((legacyCarbs * factor) / count),
            fat: ModelSanitizer.clampDouble((legacyFat * factor) / count),
          );
        }
      }
    }

    double cal = 0.0, prot = 0.0, carbs = 0.0, fat = 0.0;
    double fiber = 0.0, sodium = 0.0, sugar = 0.0;
    for (final item in parsedItems) {
      cal += item.calories; prot += item.protein; carbs += item.carbs;
      fat += item.fat; fiber += item.fiber; sodium += item.sodium; sugar += item.sugar;
    }
    if (parsedItems.isEmpty && legacyCal > 0) {
      cal = legacyCal; prot = legacyProt; carbs = legacyCarbs; fat = legacyFat;
    }

    return MealAnalysisResult(
      dishName: dish, items: parsedItems,
      totalCalories: ModelSanitizer.clampDouble(cal), totalProtein: ModelSanitizer.clampDouble(prot),
      totalCarbs: ModelSanitizer.clampDouble(carbs), totalFat: ModelSanitizer.clampDouble(fat),
      totalFiber: ModelSanitizer.clampDouble(fiber),
      totalSodium: ModelSanitizer.clampDouble(sodium, max: 50000.0),
      totalSugar: ModelSanitizer.clampDouble(sugar),
      rawJson: cleaned, confidencePercentage: confidence,
      calorieErrorMargin: errorMargin, isPartial: partial,
      modelUsed: effectiveModel, isFallback: effectiveFallback,
      thinkingLevel: effectiveThinking,
    );
  }

  Map<String, dynamic> toMap() => {
    'plato': dishName,
    'items': items.map((e) => e.toJson()).toList(),
    'totales': {
      'calorias': totalCalories, 'proteina_g': totalProtein, 'carbohidratos_g': totalCarbs,
      'grasas_g': totalFat, 'fibra_g': totalFiber, 'sodio_mg': totalSodium, 'azucar_g': totalSugar,
    },
    if (confidencePercentage != null) 'porcentaje_certeza': confidencePercentage,
    if (calorieErrorMargin != null) 'margen_error_kcal': calorieErrorMargin,
    'is_partial': isPartial,
    if (modelUsed != null) 'model_used': modelUsed,
    'is_fallback': isFallback,
    if (thinkingLevel != null) 'thinking_level': thinkingLevel,
    'rawJson': rawJson,
  };

  Map<String, dynamic> toJson() => toMap();

  MealAnalysisResult copyWith({
    String? dishName, List<FoodItem>? items, double? totalCalories, double? totalProtein,
    double? totalCarbs, double? totalFat, double? totalFiber, double? totalSodium, double? totalSugar,
    String? rawJson, int? confidencePercentage, int? calorieErrorMargin, bool? isPartial,
    String? modelUsed, bool? isFallback, String? thinkingLevel,
  }) => MealAnalysisResult(
    dishName: dishName ?? this.dishName, items: items ?? this.items,
    totalCalories: totalCalories ?? this.totalCalories, totalProtein: totalProtein ?? this.totalProtein,
    totalCarbs: totalCarbs ?? this.totalCarbs, totalFat: totalFat ?? this.totalFat,
    totalFiber: totalFiber ?? this.totalFiber, totalSodium: totalSodium ?? this.totalSodium,
    totalSugar: totalSugar ?? this.totalSugar, rawJson: rawJson ?? this.rawJson,
    confidencePercentage: confidencePercentage ?? this.confidencePercentage,
    calorieErrorMargin: calorieErrorMargin ?? this.calorieErrorMargin,
    isPartial: isPartial ?? this.isPartial,
    modelUsed: modelUsed ?? this.modelUsed,
    isFallback: isFallback ?? this.isFallback,
    thinkingLevel: thinkingLevel ?? this.thinkingLevel,
  );
}
