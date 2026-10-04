import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'food_item.dart';
import 'model_sanitizer.dart';

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

  static const List<String> validMealTypes = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];
  static const Object _sentinel = Object();

  Meal({
    String? id,
    required String name,
    String mealType = 'Almuerzo',
    DateTime? date,
    String? imagePath,
    num? calories, num? protein, num? carbs, num? fat,
    num? fiber, num? sodium, num? sugar,
    String? notes,
    String? aiBreakdownJson,
    List<FoodItem>? items,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        name = ModelSanitizer.truncate(name, ModelSanitizer.maxNameLength, fallback: 'Comida'),
        mealType = _sanitizeMealType(mealType),
        date = date ?? DateTime.now(),
        imagePath = ModelSanitizer.truncateNullable(imagePath, ModelSanitizer.maxPathLength),
        calories = ModelSanitizer.clampDouble(calories),
        protein = ModelSanitizer.clampDouble(protein),
        carbs = ModelSanitizer.clampDouble(carbs),
        fat = ModelSanitizer.clampDouble(fat),
        fiber = ModelSanitizer.clampDouble(fiber),
        sodium = ModelSanitizer.clampDouble(sodium, max: 50000.0),
        sugar = ModelSanitizer.clampDouble(sugar),
        notes = ModelSanitizer.truncateNullable(notes, ModelSanitizer.maxNotesLength),
        aiBreakdownJson = ModelSanitizer.truncateNullable(
          _resolveBreakdownJson(
            rawJson: aiBreakdownJson,
            items: items,
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sodium: sodium,
            sugar: sugar,
          ),
          ModelSanitizer.maxJsonLength,
        );

  static String? _resolveBreakdownJson({
    String? rawJson,
    List<FoodItem>? items,
    required String name,
    num? calories,
    num? protein,
    num? carbs,
    num? fat,
    num? fiber,
    num? sodium,
    num? sugar,
  }) {
    if (items != null && items.isNotEmpty) {
      return json.encode({
        'plato': name,
        'items': items.map((e) => e.toJson()).toList(),
        'totales': {
          'calorias': ModelSanitizer.clampDouble(calories),
          'proteina_g': ModelSanitizer.clampDouble(protein),
          'carbohidratos_g': ModelSanitizer.clampDouble(carbs),
          'grasas_g': ModelSanitizer.clampDouble(fat),
          'fibra_g': ModelSanitizer.clampDouble(fiber),
          'sodio_mg': ModelSanitizer.clampDouble(sodium, max: 50000.0),
          'azucar_g': ModelSanitizer.clampDouble(sugar),
        }
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
      var raw = aiBreakdownJson!.trim();
      final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
      if (fenceMatch != null) {
        raw = fenceMatch.group(1)!.trim();
      } else {
        final firstBrace = raw.indexOf('{');
        final lastBrace = raw.lastIndexOf('}');
        final firstBracket = raw.indexOf('[');
        final lastBracket = raw.lastIndexOf(']');
        if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace &&
            (firstBracket == -1 || firstBrace < firstBracket)) {
          raw = raw.substring(firstBrace, lastBrace + 1).trim();
        } else if (firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket) {
          raw = raw.substring(firstBracket, lastBracket + 1).trim();
        }
      }

      final decoded = json.decode(raw);
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

  Meal recalculateFromItems(List<FoodItem> newItems) {
    if (newItems.isEmpty) return this;
    double totalCalories = 0.0, totalProtein = 0.0, totalCarbs = 0.0, totalFat = 0.0;
    double totalFiber = 0.0, totalSodium = 0.0, totalSugar = 0.0;

    for (final item in newItems) {
      totalCalories += item.calories;
      totalProtein += item.protein;
      totalCarbs += item.carbs;
      totalFat += item.fat;
      totalFiber += item.fiber;
      totalSodium += item.sodium;
      totalSugar += item.sugar;
    }

    final effectiveCal = (totalCalories == 0.0 && calories > 0) ? calories : totalCalories;
    final effectiveProt = (totalProtein == 0.0 && protein > 0) ? protein : totalProtein;
    final effectiveCarbs = (totalCarbs == 0.0 && carbs > 0) ? carbs : totalCarbs;
    final effectiveFat = (totalFat == 0.0 && fat > 0) ? fat : totalFat;
    final effectiveFiber = (totalFiber == 0.0 && fiber > 0) ? fiber : totalFiber;
    final effectiveSodium = (totalSodium == 0.0 && sodium > 0) ? sodium : totalSodium;
    final effectiveSugar = (totalSugar == 0.0 && sugar > 0) ? sugar : totalSugar;

    final newBreakdown = json.encode({
      'plato': name,
      'items': newItems.map((e) => e.toJson()).toList(),
      'totales': {
        'calorias': effectiveCal,
        'proteina_g': effectiveProt,
        'carbohidratos_g': effectiveCarbs,
        'grasas_g': effectiveFat,
        'fibra_g': effectiveFiber,
        'sodio_mg': effectiveSodium,
        'azucar_g': effectiveSugar,
      }
    });

    return copyWith(
      calories: effectiveCal,
      protein: effectiveProt,
      carbs: effectiveCarbs,
      fat: effectiveFat,
      fiber: effectiveFiber,
      sodium: effectiveSodium,
      sugar: effectiveSugar,
      aiBreakdownJson: newBreakdown,
    );
  }

  Meal copyWith({
    String? id,
    String? name,
    String? mealType,
    DateTime? date,
    Object? imagePath = _sentinel,
    double? calories, double? protein, double? carbs, double? fat,
    double? fiber, double? sodium, double? sugar,
    Object? notes = _sentinel,
    Object? aiBreakdownJson = _sentinel,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      date: date ?? this.date,
      imagePath: identical(imagePath, _sentinel) ? this.imagePath : (imagePath as String?),
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      sugar: sugar ?? this.sugar,
      notes: identical(notes, _sentinel) ? this.notes : (notes as String?),
      aiBreakdownJson: identical(aiBreakdownJson, _sentinel)
          ? this.aiBreakdownJson
          : (aiBreakdownJson as String?),
    );
  }

  Map<String, dynamic> toSqliteMap() => {
        'id': id,
        'name': name,
        'meal_type': mealType,
        'date': date.toIso8601String(),
        'image_path': imagePath,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
        'sugar': sugar,
        'notes': notes,
        'ai_breakdown_json': aiBreakdownJson,
      };

  factory Meal.fromSqliteMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? 'Comida',
      mealType: map['meal_type']?.toString() ?? 'Almuerzo',
      date: ModelSanitizer.parseDate(map['date']),
      imagePath: map['image_path']?.toString(),
      calories: ModelSanitizer.clampDouble(map['calories']),
      protein: ModelSanitizer.clampDouble(map['protein']),
      carbs: ModelSanitizer.clampDouble(map['carbs']),
      fat: ModelSanitizer.clampDouble(map['fat']),
      fiber: ModelSanitizer.clampDouble(map['fiber']),
      sodium: ModelSanitizer.clampDouble(map['sodium'], max: 50000.0),
      sugar: ModelSanitizer.clampDouble(map['sugar']),
      notes: map['notes']?.toString(),
      aiBreakdownJson: map['ai_breakdown_json']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => toSqliteMap();
  factory Meal.fromMap(Map<String, dynamic> map) => Meal.fromSqliteMap(map);
  Map<String, dynamic> toJson() => toSqliteMap();
  factory Meal.fromJson(Map<String, dynamic> json) => Meal.fromSqliteMap(json);
}
