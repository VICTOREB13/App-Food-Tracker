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
  final String? notes;
  final String? aiBreakdownJson;

  static const List<String> validMealTypes = [
    'Desayuno',
    'Almuerzo',
    'Cena',
    'Snack',
  ];

  static const Object _sentinel = Object();

  Meal({
    String? id,
    required String name,
    String mealType = 'Almuerzo',
    DateTime? date,
    String? imagePath,
    num? calories,
    num? protein,
    num? carbs,
    num? fat,
    String? notes,
    String? aiBreakdownJson,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        name = ModelSanitizer.truncate(name, ModelSanitizer.maxNameLength, fallback: 'Comida'),
        mealType = _sanitizeMealType(mealType),
        date = date ?? DateTime.now(),
        imagePath = ModelSanitizer.truncateNullable(imagePath, ModelSanitizer.maxPathLength),
        calories = ModelSanitizer.clampDouble(calories),
        protein = ModelSanitizer.clampDouble(protein),
        carbs = ModelSanitizer.clampDouble(carbs),
        fat = ModelSanitizer.clampDouble(fat),
        notes = ModelSanitizer.truncateNullable(notes, ModelSanitizer.maxNotesLength),
        aiBreakdownJson = ModelSanitizer.truncateNullable(aiBreakdownJson, ModelSanitizer.maxJsonLength);

  static String _sanitizeMealType(String? raw) {
    if (raw == null) return 'Almuerzo';
    final trimmed = raw.trim();
    for (final valid in validMealTypes) {
      if (valid.toLowerCase() == trimmed.toLowerCase()) return valid;
    }
    return 'Almuerzo';
  }

  List<FoodItem> get items {
    if (aiBreakdownJson == null || aiBreakdownJson!.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = json.decode(aiBreakdownJson!);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => FoodItem.fromJson(e))
            .toList();
      } else if (decoded is Map<String, dynamic> && decoded['items'] is List) {
        return (decoded['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => FoodItem.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Meal recalculateFromItems(List<FoodItem> newItems) {
    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;

    for (final item in newItems) {
      totalCalories += item.calories;
      totalProtein += item.protein;
      totalCarbs += item.carbs;
      totalFat += item.fat;
    }

    final newBreakdown = json.encode({
      'plato': name,
      'items': newItems.map((e) => e.toJson()).toList(),
      'totales': {
        'calorias': totalCalories,
        'proteina_g': totalProtein,
        'carbohidratos_g': totalCarbs,
        'grasas_g': totalFat,
      }
    });

    return copyWith(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      aiBreakdownJson: newBreakdown,
    );
  }

  Meal copyWith({
    String? id,
    String? name,
    String? mealType,
    DateTime? date,
    Object? imagePath = _sentinel,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
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
      notes: identical(notes, _sentinel) ? this.notes : (notes as String?),
      aiBreakdownJson: identical(aiBreakdownJson, _sentinel)
          ? this.aiBreakdownJson
          : (aiBreakdownJson as String?),
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'name': name,
      'meal_type': mealType,
      'date': date.toIso8601String(),
      'image_path': imagePath,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'notes': notes,
      'ai_breakdown_json': aiBreakdownJson,
    };
  }

  factory Meal.fromSqliteMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? 'Comida',
      mealType: map['meal_type']?.toString() ?? 'Almuerzo',
      date: ModelSanitizer.parseDate(map['date']),
      imagePath: map['image_path']?.toString(),
      calories: (map['calories'] ?? 0) as num?,
      protein: (map['protein'] ?? 0) as num?,
      carbs: (map['carbs'] ?? 0) as num?,
      fat: (map['fat'] ?? 0) as num?,
      notes: map['notes']?.toString(),
      aiBreakdownJson: map['ai_breakdown_json']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toSqliteMap();

  factory Meal.fromJson(Map<String, dynamic> json) => Meal.fromSqliteMap(json);
}
