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
    String? visualJustification,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        name = ModelSanitizer.truncate(name, ModelSanitizer.maxNameLength, fallback: 'Alimento sin nombre'),
        estimatedGrams = ModelSanitizer.clampDouble(estimatedGrams, min: 0.0, max: 50000.0),
        calories = ModelSanitizer.clampDouble(calories),
        protein = ModelSanitizer.clampDouble(protein),
        carbs = ModelSanitizer.clampDouble(carbs),
        fat = ModelSanitizer.clampDouble(fat),
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
      visualJustification: identical(visualJustification, _sentinel)
          ? this.visualJustification
          : (visualJustification as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'alimento': name,
        'gramos_estimados': estimatedGrams,
        'calorias': calories,
        'proteinas_g': protein,
        'carbohidratos_g': carbs,
        'grasas_g': fat,
        'justificacion_visual': visualJustification,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id']?.toString(),
      name: (json['alimento'] ?? json['nombre'] ?? json['name'] ?? json['ingrediente'] ?? json['item'] ?? 'Alimento').toString(),
      estimatedGrams: ModelSanitizer.clampDouble(
        json['gramos_estimados'] ?? json['gramos'] ?? json['estimated_grams'] ?? json['grams'] ?? json['peso_g'] ?? json['peso'],
        min: 0.0,
        max: 50000.0,
      ),
      calories: ModelSanitizer.clampDouble(
        json['calorias'] ?? json['calories'] ?? json['kcal'] ?? json['total_calorias'],
      ),
      protein: ModelSanitizer.clampDouble(
        json['proteinas_g'] ?? json['proteina_g'] ?? json['protein'] ?? json['proteins_g'] ?? json['proteina'],
      ),
      carbs: ModelSanitizer.clampDouble(
        json['carbohidratos_g'] ?? json['carbohidratos'] ?? json['carbs'] ?? json['carbohydrates_g'] ?? json['carbohidrato_g'] ?? json['carbohidrato'],
      ),
      fat: ModelSanitizer.clampDouble(
        json['grasas_g'] ?? json['grasa_g'] ?? json['fat'] ?? json['fats_g'] ?? json['lipidos_g'] ?? json['lipidos'] ?? json['grasas'],
      ),
      visualJustification: (json['justificacion_visual'] ?? json['justificacion'] ?? json['visual_justification'] ?? json['notas'] ?? json['justification'] ?? json['nota'])?.toString(),
    );
  }

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
      visualJustification.hashCode;
}
