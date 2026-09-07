import 'package:uuid/uuid.dart';
import 'model_sanitizer.dart';

class PantryItem {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isFavorite;

  static const Object _sentinel = Object();

  PantryItem({
    String? id,
    required String name,
    String? brand,
    String? category,
    num? calories,
    num? protein,
    num? carbs,
    num? fat,
    this.isFavorite = false,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        name = ModelSanitizer.truncate(name, ModelSanitizer.maxNameLength, fallback: 'Alimento despensa'),
        brand = ModelSanitizer.truncateNullable(brand, ModelSanitizer.maxNameLength),
        category = ModelSanitizer.truncateNullable(category, 100),
        calories = ModelSanitizer.clampDouble(calories),
        protein = ModelSanitizer.clampDouble(protein),
        carbs = ModelSanitizer.clampDouble(carbs),
        fat = ModelSanitizer.clampDouble(fat);

  PantryItem copyWith({
    String? id,
    String? name,
    Object? brand = _sentinel,
    Object? category = _sentinel,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    bool? isFavorite,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: identical(brand, _sentinel) ? this.brand : (brand as String?),
      category: identical(category, _sentinel) ? this.category : (category as String?),
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory PantryItem.fromSqliteMap(Map<String, dynamic> map) {
    return PantryItem(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? 'Alimento',
      brand: map['brand']?.toString(),
      category: map['category']?.toString(),
      calories: ModelSanitizer.clampDouble(map['calories']),
      protein: ModelSanitizer.clampDouble(map['protein']),
      carbs: ModelSanitizer.clampDouble(map['carbs']),
      fat: ModelSanitizer.clampDouble(map['fat']),
      isFavorite: (map['is_favorite'] == 1 || map['is_favorite'] == true),
    );
  }

  Map<String, dynamic> toJson() => toSqliteMap();

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem.fromSqliteMap(json);
}
