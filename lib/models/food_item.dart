import 'package:uuid/uuid.dart';
import 'model_sanitizer.dart';

class FoodItem {
  final String id;
  final String name;
  final double estimatedGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final double sugar;
  final String? visualJustification;

  static const Object _sentinel = Object();

  FoodItem({
    String? id,
    required String name,
    num? estimatedGrams,
    num? calories,
    num? protein,
    num? carbs,
    num? fat,
    num? fiber,
    num? sodium,
    num? sugar,
    String? visualJustification,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        name = ModelSanitizer.truncate(name, ModelSanitizer.maxNameLength, fallback: 'Alimento sin nombre'),
        estimatedGrams = ModelSanitizer.clampDouble(estimatedGrams, min: 0.0, max: 50000.0),
        calories = ModelSanitizer.clampDouble(calories),
        protein = ModelSanitizer.clampDouble(protein),
        carbs = ModelSanitizer.clampDouble(carbs),
        fat = ModelSanitizer.clampDouble(fat),
        fiber = ModelSanitizer.clampDouble(fiber),
        sodium = ModelSanitizer.clampDouble(sodium, max: 50000.0),
        sugar = ModelSanitizer.clampDouble(sugar),
        visualJustification = ModelSanitizer.truncateNullable(
          visualJustification,
          ModelSanitizer.maxJustificationLength,
        );

  FoodItem copyWith({
    String? id,
    String? name,
    double? estimatedGrams,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sodium,
    double? sugar,
    Object? visualJustification = _sentinel,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      estimatedGrams: estimatedGrams ?? this.estimatedGrams,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      sugar: sugar ?? this.sugar,
      visualJustification: identical(visualJustification, _sentinel)
          ? this.visualJustification
          : (visualJustification as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'estimated_grams': estimatedGrams,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
        'sugar': sugar,
        'visual_justification': visualJustification,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'alimento': name,
        'gramos_estimados': estimatedGrams,
        'calorias': calories,
        'proteinas_g': protein,
        'carbohidratos_g': carbs,
        'grasas_g': fat,
        'fibra_g': fiber,
        'sodio_mg': sodium,
        'azucar_g': sugar,
        'justificacion_visual': visualJustification,
      };

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id']?.toString(),
      name: (map['name'] ?? map['alimento'] ?? map['nombre'] ?? map['ingrediente'] ?? map['item'] ?? 'Alimento').toString(),
      estimatedGrams: ModelSanitizer.clampDouble(
        map['estimated_grams'] ?? map['estimatedGrams'] ?? map['gramos_estimados'] ?? map['gramos'] ?? map['grams'] ?? map['peso_g'] ?? map['peso'],
        min: 0.0,
        max: 50000.0,
      ),
      calories: ModelSanitizer.clampDouble(
        map['calories'] ?? map['calorias'] ?? map['kcal'] ?? map['total_calorias'],
      ),
      protein: ModelSanitizer.clampDouble(
        map['protein'] ?? map['proteinas_g'] ?? map['proteina_g'] ?? map['proteins_g'] ?? map['proteina'],
      ),
      carbs: ModelSanitizer.clampDouble(
        map['carbs'] ?? map['carbohidratos_g'] ?? map['carbohidratos'] ?? map['carbohydrates_g'] ?? map['carbohidrato_g'] ?? map['carbohidrato'],
      ),
      fat: ModelSanitizer.clampDouble(
        map['fat'] ?? map['grasas_g'] ?? map['grasa_g'] ?? map['fats_g'] ?? map['lipidos_g'] ?? map['lipidos'] ?? map['grasas'],
      ),
      fiber: ModelSanitizer.clampDouble(
        map['fiber'] ?? map['fibra_g'] ?? map['fibra'] ?? map['fiber_g'],
      ),
      sodium: ModelSanitizer.clampDouble(
        map['sodium'] ?? map['sodio_mg'] ?? map['sodio'] ?? map['sodium_mg'],
        max: 50000.0,
      ),
      sugar: ModelSanitizer.clampDouble(
        map['sugar'] ?? map['azucar_g'] ?? map['azucar'] ?? map['azucares_g'] ?? map['sugars'] ?? map['sugar_g'],
      ),
      visualJustification: (map['visual_justification'] ?? map['visualJustification'] ?? map['justificacion_visual'] ?? map['justificacion'] ?? map['notas'] ?? map['justification'] ?? map['nota'])?.toString(),
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          estimatedGrams == other.estimatedGrams &&
          calories == other.calories &&
          protein == other.protein &&
          carbs == other.carbs &&
          fat == other.fat &&
          fiber == other.fiber &&
          sodium == other.sodium &&
          sugar == other.sugar &&
          visualJustification == other.visualJustification;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      estimatedGrams.hashCode ^
      calories.hashCode ^
      protein.hashCode ^
      carbs.hashCode ^
      fat.hashCode ^
      fiber.hashCode ^
      sodium.hashCode ^
      sugar.hashCode ^
      visualJustification.hashCode;
}
