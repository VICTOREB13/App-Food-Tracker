import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'food_item.dart';
import 'model_sanitizer.dart';

/// Immutable model representing a reusable meal template with items and micronutrients.
class MealTemplate {
  final String id;
  final String name;
  final String mealType;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final double sugar;
  final List<FoodItem> items;
  final DateTime createdAt;

  MealTemplate({
    String? id,
    required String name,
    String mealType = 'Almuerzo',
    num? calories,
    num? protein,
    num? carbs,
    num? fat,
    num? fiber,
    num? sodium,
    num? sugar,
    List<FoodItem>? items,
    DateTime? createdAt,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        name = ModelSanitizer.truncate(name, ModelSanitizer.maxNameLength, fallback: 'Plantilla de comida'),
        mealType = ModelSanitizer.truncate(mealType, 50, fallback: 'Almuerzo'),
        calories = ModelSanitizer.clampDouble(calories),
        protein = ModelSanitizer.clampDouble(protein),
        carbs = ModelSanitizer.clampDouble(carbs),
        fat = ModelSanitizer.clampDouble(fat),
        fiber = ModelSanitizer.clampDouble(fiber),
        sodium = ModelSanitizer.clampDouble(sodium, max: 50000.0),
        sugar = ModelSanitizer.clampDouble(sugar),
        items = List.unmodifiable(items ?? const <FoodItem>[]),
        createdAt = createdAt ?? DateTime.now();

  MealTemplate copyWith({
    String? id,
    String? name,
    String? mealType,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sodium,
    double? sugar,
    List<FoodItem>? items,
    DateTime? createdAt,
  }) {
    return MealTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      sugar: sugar ?? this.sugar,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'meal_type': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
        'sugar': sugar,
        'items_json': jsonEncode(items.map((i) => i.toJson()).toList()),
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toJson() => toMap();

  factory MealTemplate.fromMap(Map<String, dynamic> map) {
    List<FoodItem> parsedItems = const [];
    if (map['items'] is List) {
      parsedItems = (map['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((m) => FoodItem.fromJson(m))
          .toList();
    } else if (map['items_json'] is String && (map['items_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(map['items_json'] as String);
        if (decoded is List) {
          parsedItems = decoded
              .whereType<Map<String, dynamic>>()
              .map((m) => FoodItem.fromJson(m))
              .toList();
        }
      } catch (_) {}
    }

    return MealTemplate(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? 'Plantilla de comida',
      mealType: map['meal_type']?.toString() ?? map['mealType']?.toString() ?? 'Almuerzo',
      calories: ModelSanitizer.clampDouble(map['calories']),
      protein: ModelSanitizer.clampDouble(map['protein']),
      carbs: ModelSanitizer.clampDouble(map['carbs']),
      fat: ModelSanitizer.clampDouble(map['fat']),
      fiber: ModelSanitizer.clampDouble(map['fiber']),
      sodium: ModelSanitizer.clampDouble(map['sodium'], max: 50000.0),
      sugar: ModelSanitizer.clampDouble(map['sugar']),
      items: parsedItems,
      createdAt: ModelSanitizer.parseDate(map['created_at'] ?? map['createdAt']),
    );
  }

  factory MealTemplate.fromJson(Map<String, dynamic> json) => MealTemplate.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          mealType == other.mealType &&
          calories == other.calories &&
          protein == other.protein &&
          carbs == other.carbs &&
          fat == other.fat &&
          fiber == other.fiber &&
          sodium == other.sodium &&
          sugar == other.sugar;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      mealType.hashCode ^
      calories.hashCode ^
      protein.hashCode ^
      carbs.hashCode ^
      fat.hashCode ^
      fiber.hashCode ^
      sodium.hashCode ^
      sugar.hashCode;
}
