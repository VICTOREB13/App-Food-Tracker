import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:food_tracker/features/food_entry/models/food_item.dart';
import 'package:food_tracker/core/models/model_sanitizer.dart';

class Meal {
  final String id;
  final String name;
  final String mealType;
  final DateTime date;
  final String? imagePath;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final double sugar;
  final String? notes;
  final String? aiBreakdownJson;

  Map<String, dynamic>? _decodeAiMap() {
    if (aiBreakdownJson == null || aiBreakdownJson!.isEmpty) return null;
    try {
      final d = json.decode(_cleanJson(aiBreakdownJson!));
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      return null;
    }
  }

  bool get isPartial => _decodeAiMap()?['is_partial'] == true || _decodeAiMap()?['isPartial'] == true;
  String? get modelUsed => _decodeAiMap()?['model_used']?.toString() ?? _decodeAiMap()?['modelUsed']?.toString();
  bool get isFallback => _decodeAiMap()?['is_fallback'] == true || _decodeAiMap()?['isFallback'] == true;
  String? get thinkingLevel => _decodeAiMap()?['thinking_level']?.toString() ?? _decodeAiMap()?['thinkingLevel']?.toString();

  static const List<String> validMealTypes = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];
  static const Object _sentinel = Object();

  Meal({
    String? id, required String name, String mealType = 'Almuerzo', DateTime? date, String? imagePath,
    num? calories, num? protein, num? carbs, num? fat, num? fiber, num? sodium, num? sugar,
    String? notes, String? aiBreakdownJson, List<FoodItem>? items,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        name = ModelSanitizer.truncate(name, ModelSanitizer.maxNameLength, fallback: 'Comida'),
        mealType = _sanitizeMealType(mealType),
        date = date ?? DateTime.now(),
        imagePath = ModelSanitizer.truncateNullable(imagePath, ModelSanitizer.maxPathLength),
        calories = ModelSanitizer.clampDouble(calories), protein = ModelSanitizer.clampDouble(protein),
        carbs = ModelSanitizer.clampDouble(carbs), fat = ModelSanitizer.clampDouble(fat),
        fiber = ModelSanitizer.clampDouble(fiber),
        sodium = ModelSanitizer.clampDouble(sodium, max: 50000.0), sugar = ModelSanitizer.clampDouble(sugar),
        notes = ModelSanitizer.truncateNullable(notes, ModelSanitizer.maxNotesLength),
        aiBreakdownJson = ModelSanitizer.truncateNullable(
          _resolveBreakdownJson(
            rawJson: aiBreakdownJson, items: items, name: name,
            calories: calories, protein: protein, carbs: carbs, fat: fat,
            fiber: fiber, sodium: sodium, sugar: sugar,
          ),
          ModelSanitizer.maxJsonLength,
        );

  static String _cleanJson(String raw) {
    var cleaned = raw.trim();
    final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(cleaned);
    if (fenceMatch != null) return fenceMatch.group(1)!.trim();
    final firstBrace = cleaned.indexOf('{'), lastBrace = cleaned.lastIndexOf('}');
    final firstBracket = cleaned.indexOf('['), lastBracket = cleaned.lastIndexOf(']');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace && (firstBracket == -1 || firstBrace < firstBracket)) {
      return cleaned.substring(firstBrace, lastBrace + 1).trim();
    } else if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
      return cleaned.substring(firstBracket, lastBracket + 1).trim();
    }
    return cleaned;
  }

  static String? _resolveBreakdownJson({
    String? rawJson,
    List<FoodItem>? items,
    required String name,
    num? calories, num? protein, num? carbs, num? fat,
    num? fiber, num? sodium, num? sugar,
  }) {
    if (items != null && items.isNotEmpty) {
      int? conf, margin;
      String? modelUsed, thinkingLevel, reasoning;
      bool? isPartial, isFallback;
      if (rawJson != null && rawJson.trim().isNotEmpty) {
        try {
          final d = json.decode(_cleanJson(rawJson));
          if (d is Map<String, dynamic>) {
            final c = d['porcentaje_certeza'] ?? d['confidence_percentage'] ?? d['certeza'];
            if (c is num) conf = c.toInt().clamp(0, 100);
            final m = d['margen_error_kcal'] ?? d['calorie_error_margin'] ?? d['margen_error'];
            if (m is num) margin = m.toInt().clamp(0, 2000);
            modelUsed = d['model_used']?.toString() ?? d['modelUsed']?.toString();
            thinkingLevel = d['thinking_level']?.toString() ?? d['thinkingLevel']?.toString();
            reasoning = d['razonamiento_volumetrico']?.toString();
            if (reasoning == null && d['rawJson'] != null) {
              try {
                final r = json.decode(_cleanJson(d['rawJson'].toString()));
                if (r is Map<String, dynamic>) reasoning = r['razonamiento_volumetrico']?.toString();
              } catch (_) {}
            }
            if (d['is_partial'] == true || d['isPartial'] == true) isPartial = true;
            if (d['is_fallback'] == true || d['isFallback'] == true) isFallback = true;
          }
        } catch (_) {}
      }
      return json.encode({
        'plato': name,
        'items': items.map((e) => e.toJson()).toList(),
        'totales': {
          'calorias': ModelSanitizer.clampDouble(calories), 'proteina_g': ModelSanitizer.clampDouble(protein),
          'carbohidratos_g': ModelSanitizer.clampDouble(carbs), 'grasas_g': ModelSanitizer.clampDouble(fat),
          'fibra_g': ModelSanitizer.clampDouble(fiber),
          'sodio_mg': ModelSanitizer.clampDouble(sodium, max: 50000.0), 'azucar_g': ModelSanitizer.clampDouble(sugar),
        },
        if (conf != null) 'porcentaje_certeza': conf,
        if (margin != null) 'margen_error_kcal': margin,
        if (isPartial == true) 'is_partial': true,
        if (modelUsed != null) 'model_used': modelUsed,
        if (isFallback == true) 'is_fallback': true,
        if (thinkingLevel != null) 'thinking_level': thinkingLevel,
        if (reasoning != null) 'razonamiento_volumetrico': reasoning,
      });
    }
    return rawJson;
  }

  static String _sanitizeMealType(String? raw) {
    if (raw == null) return 'Almuerzo';
    final trimmed = raw.trim();
    for (final valid in validMealTypes) {
      if (valid.toLowerCase() == trimmed.toLowerCase()) return valid;
    }
    return 'Almuerzo';
  }

  List<FoodItem> get items {
    if (aiBreakdownJson == null || aiBreakdownJson!.trim().isEmpty) return const [];
    try {
      final decoded = json.decode(_cleanJson(aiBreakdownJson!));
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().map((e) => FoodItem.fromJson(e)).toList();
      } else if (decoded is Map<String, dynamic>) {
        final dynamic itemsList = decoded['items'] ??
            decoded['ingredientes'] ??
            decoded['alimentos'] ??
            decoded['ingredients'] ??
            decoded['componentes'] ??
            decoded['desglose'] ??
            decoded['food_items'] ??
            decoded['foods'];
        if (itemsList is List) {
          final List<FoodItem> parsed = [];
          for (final entry in itemsList) {
            if (entry is Map<String, dynamic>) {
              parsed.add(FoodItem.fromJson(entry));
            } else if (entry is String && entry.trim().isNotEmpty) {
              parsed.add(FoodItem(name: entry.trim(), estimatedGrams: 100, calories: 0, protein: 0, carbs: 0, fat: 0));
            }
          }
          return parsed;
        } else if (itemsList is Map<String, dynamic>) {
          final List<FoodItem> parsed = [];
          for (final entry in itemsList.entries) {
            if (entry.value is Map<String, dynamic>) {
              final map = Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
              if (!map.containsKey('alimento') && !map.containsKey('nombre') && !map.containsKey('name')) {
                map['alimento'] = entry.key;
              }
              parsed.add(FoodItem.fromJson(map));
            } else {
              parsed.add(FoodItem(name: entry.key, estimatedGrams: 100, calories: 0, protein: 0, carbs: 0, fat: 0));
            }
          }
          return parsed;
        } else if (itemsList is String && itemsList.trim().isNotEmpty) {
          return itemsList
              .split(RegExp(r'[,;\n]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((name) => FoodItem(name: name, estimatedGrams: 100, calories: 0, protein: 0, carbs: 0, fat: 0))
              .toList();
        }
      }
    } catch (_) {}
    return const [];
  }

  int? get confidencePercentage => _parseAiMetric(['porcentaje_certeza', 'confidence_percentage', 'certeza']);
  int? get calorieErrorMargin => _parseAiMetric(['margen_error_kcal', 'calorie_error_margin', 'margen_error']);

  int? _parseAiMetric(List<String> keys) {
    final d = _decodeAiMap();
    if (d == null) return null;
    for (final k in keys) {
      final val = d[k];
      if (val is num) return val.toInt();
      if (val is String) {
        final n = num.tryParse(val.replaceAll(RegExp(r'[^0-9.-]'), ''));
        if (n != null) return n.round();
      }
    }
    return null;
  }

  Meal recalculateFromItems(List<FoodItem> newItems) {
    if (newItems.isEmpty) return this;
    double sumCal = 0, sumProt = 0, sumCarbs = 0, sumFat = 0, sumFiber = 0, sumSodium = 0, sumSugar = 0;
    for (final item in newItems) {
      sumCal += item.calories; sumProt += item.protein; sumCarbs += item.carbs; sumFat += item.fat;
      sumFiber += item.fiber; sumSodium += item.sodium; sumSugar += item.sugar;
    }
    double eff(double sum, double cur) => (sum == 0.0 && cur > 0) ? cur : sum;
    final effectiveCal = eff(sumCal, calories), effectiveProt = eff(sumProt, protein);
    final effectiveCarbs = eff(sumCarbs, carbs), effectiveFat = eff(sumFat, fat);
    final effectiveFiber = eff(sumFiber, fiber), effectiveSodium = eff(sumSodium, sodium), effectiveSugar = eff(sumSugar, sugar);

    final conf = confidencePercentage, margin = calorieErrorMargin;
    final model = modelUsed, fallback = isFallback, thinking = thinkingLevel, partial = isPartial;
    final reasoning = _decodeAiMap()?['razonamiento_volumetrico']?.toString();
    final newBreakdown = json.encode({
      'plato': name,
      'items': newItems.map((e) => e.toJson()).toList(),
      'totales': {
        'calorias': effectiveCal, 'proteina_g': effectiveProt, 'carbohidratos_g': effectiveCarbs,
        'grasas_g': effectiveFat, 'fibra_g': effectiveFiber, 'sodio_mg': effectiveSodium, 'azucar_g': effectiveSugar,
      },
      if (conf != null) 'porcentaje_certeza': conf,
      if (margin != null) 'margen_error_kcal': margin,
      if (partial) 'is_partial': true,
      if (model != null) 'model_used': model,
      if (fallback) 'is_fallback': true,
      if (thinking != null) 'thinking_level': thinking,
      if (reasoning != null) 'razonamiento_volumetrico': reasoning,
    });

    return copyWith(
      calories: effectiveCal, protein: effectiveProt, carbs: effectiveCarbs, fat: effectiveFat,
      fiber: effectiveFiber, sodium: effectiveSodium, sugar: effectiveSugar, aiBreakdownJson: newBreakdown,
    );
  }

  Meal copyWith({
    String? id, String? name, String? mealType, DateTime? date,
    Object? imagePath = _sentinel,
    double? calories, double? protein, double? carbs, double? fat,
    double? fiber, double? sodium, double? sugar,
    Object? notes = _sentinel, Object? aiBreakdownJson = _sentinel,
  }) {
    return Meal(
      id: id ?? this.id, name: name ?? this.name, mealType: mealType ?? this.mealType, date: date ?? this.date,
      imagePath: identical(imagePath, _sentinel) ? this.imagePath : (imagePath as String?),
      calories: calories ?? this.calories, protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs, fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber, sodium: sodium ?? this.sodium, sugar: sugar ?? this.sugar,
      notes: identical(notes, _sentinel) ? this.notes : (notes as String?),
      aiBreakdownJson: identical(aiBreakdownJson, _sentinel) ? this.aiBreakdownJson : (aiBreakdownJson as String?),
    );
  }

  Map<String, dynamic> toSqliteMap() => {
    'id': id, 'name': name, 'meal_type': mealType, 'date': date.toIso8601String(),
    'image_path': imagePath, 'calories': calories, 'protein': protein, 'carbs': carbs,
    'fat': fat, 'fiber': fiber, 'sodium': sodium, 'sugar': sugar, 'notes': notes,
    'ai_breakdown_json': aiBreakdownJson,
  };

  factory Meal.fromSqliteMap(Map<String, dynamic> map) => Meal(
    id: map['id']?.toString(), name: map['name']?.toString() ?? 'Comida',
    mealType: map['meal_type']?.toString() ?? 'Almuerzo',
    date: ModelSanitizer.parseDate(map['date']), imagePath: map['image_path']?.toString(),
    calories: ModelSanitizer.clampDouble(map['calories']), protein: ModelSanitizer.clampDouble(map['protein']),
    carbs: ModelSanitizer.clampDouble(map['carbs']), fat: ModelSanitizer.clampDouble(map['fat']),
    fiber: ModelSanitizer.clampDouble(map['fiber']),
    sodium: ModelSanitizer.clampDouble(map['sodium'], max: 50000.0), sugar: ModelSanitizer.clampDouble(map['sugar']),
    notes: map['notes']?.toString(), aiBreakdownJson: map['ai_breakdown_json']?.toString(),
  );

  Map<String, dynamic> toMap() => toSqliteMap();
  factory Meal.fromMap(Map<String, dynamic> map) => Meal.fromSqliteMap(map);
  Map<String, dynamic> toJson() => toSqliteMap();
  factory Meal.fromJson(Map<String, dynamic> json) => Meal.fromSqliteMap(json);
}
