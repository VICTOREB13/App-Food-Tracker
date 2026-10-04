import 'package:uuid/uuid.dart';
import 'food_item.dart';
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
  final double servingSize;
  final String servingUnit;
  final double? packageWeight;
  final double fiber;
  final double sodium;
  final double sugar;
  final String? barcode;
  final String? nutritionLabelImagePath;
  final bool isVerifiedByUser;
  final String? matchKeywords;
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
    num? servingSize = 100.0,
    String? servingUnit = 'g',
    num? packageWeight,
    num? fiber = 0.0,
    num? sodium = 0.0,
    num? sugar = 0.0,
    String? barcode,
    String? nutritionLabelImagePath,
    this.isVerifiedByUser = false,
    String? matchKeywords,
    this.isFavorite = false,
  })  : id = ModelSanitizer.truncate(id, 128, fallback: const Uuid().v4()),
        name = ModelSanitizer.truncate(name, ModelSanitizer.maxNameLength, fallback: 'Alimento despensa'),
        brand = ModelSanitizer.truncateNullable(brand, ModelSanitizer.maxNameLength),
        category = ModelSanitizer.truncateNullable(category, 100),
        calories = ModelSanitizer.clampDouble(calories),
        protein = ModelSanitizer.clampDouble(protein),
        carbs = ModelSanitizer.clampDouble(carbs),
        fat = ModelSanitizer.clampDouble(fat),
        servingSize = ModelSanitizer.clampDouble(servingSize, min: 0.1, fallback: 100.0),
        servingUnit = ModelSanitizer.truncate(servingUnit, 32, fallback: 'g'),
        packageWeight = packageWeight != null
            ? ModelSanitizer.clampDouble(packageWeight, min: 0.1, max: 50000.0)
            : null,
        fiber = ModelSanitizer.clampDouble(fiber),
        sodium = ModelSanitizer.clampDouble(sodium),
        sugar = ModelSanitizer.clampDouble(sugar),
        barcode = ModelSanitizer.truncateNullable(barcode, 64),
        nutritionLabelImagePath = ModelSanitizer.truncateNullable(nutritionLabelImagePath, 512),
        matchKeywords = ModelSanitizer.truncateNullable(matchKeywords, 512);

  PantryItem copyWith({
    String? id,
    String? name,
    Object? brand = _sentinel,
    Object? category = _sentinel,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? servingSize,
    String? servingUnit,
    Object? packageWeight = _sentinel,
    double? fiber,
    double? sodium,
    double? sugar,
    Object? barcode = _sentinel,
    Object? nutritionLabelImagePath = _sentinel,
    bool? isVerifiedByUser,
    Object? matchKeywords = _sentinel,
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
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      packageWeight: identical(packageWeight, _sentinel)
          ? this.packageWeight
          : (packageWeight as double?),
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      sugar: sugar ?? this.sugar,
      barcode: identical(barcode, _sentinel) ? this.barcode : (barcode as String?),
      nutritionLabelImagePath: identical(nutritionLabelImagePath, _sentinel)
          ? this.nutritionLabelImagePath
          : (nutritionLabelImagePath as String?),
      isVerifiedByUser: isVerifiedByUser ?? this.isVerifiedByUser,
      matchKeywords: identical(matchKeywords, _sentinel)
          ? this.matchKeywords
          : (matchKeywords as String?),
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  FoodItem toScaledFoodItem({required double gramsConsumed, String? justification}) {
    final refServing = servingSize > 0 ? servingSize : 100.0;
    final factor = gramsConsumed / refServing;
    final displayName = (brand != null && brand!.isNotEmpty) ? '$name ($brand)' : name;
    return FoodItem(
      name: displayName,
      estimatedGrams: gramsConsumed,
      calories: ModelSanitizer.clampDouble(calories * factor),
      protein: ModelSanitizer.clampDouble(protein * factor),
      carbs: ModelSanitizer.clampDouble(carbs * factor),
      fat: ModelSanitizer.clampDouble(fat * factor),
      fiber: ModelSanitizer.clampDouble(fiber * factor),
      sodium: ModelSanitizer.clampDouble(sodium * factor, max: 50000.0),
      sugar: ModelSanitizer.clampDouble(sugar * factor),
      visualJustification: justification ??
          'Despensa: ${gramsConsumed.toStringAsFixed(0)}g (ref. ${refServing.toStringAsFixed(0)}g)',
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
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'package_weight': packageWeight,
      'fiber': fiber,
      'sodium': sodium,
      'sugar': sugar,
      'barcode': barcode,
      'nutrition_label_image_path': nutritionLabelImagePath,
      'is_verified_by_user': isVerifiedByUser ? 1 : 0,
      'match_keywords': matchKeywords,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory PantryItem.fromSqliteMap(Map<String, dynamic> map) {
    final rawPackageWeight =
        map['package_weight'] ?? map['peso_neto'] ?? map['peso_paquete'];
    return PantryItem(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? 'Alimento',
      brand: map['brand']?.toString(),
      category: map['category']?.toString(),
      calories: ModelSanitizer.clampDouble(map['calories']),
      protein: ModelSanitizer.clampDouble(map['protein']),
      carbs: ModelSanitizer.clampDouble(map['carbs']),
      fat: ModelSanitizer.clampDouble(map['fat']),
      servingSize: ModelSanitizer.clampDouble(map['serving_size'], min: 0.1, fallback: 100.0),
      servingUnit: map['serving_unit']?.toString() ?? 'g',
      packageWeight: rawPackageWeight != null
          ? ModelSanitizer.clampDouble(rawPackageWeight, min: 0.1, max: 50000.0)
          : null,
      fiber: ModelSanitizer.clampDouble(map['fiber']),
      sodium: ModelSanitizer.clampDouble(map['sodium']),
      sugar: ModelSanitizer.clampDouble(map['sugar']),
      barcode: map['barcode']?.toString(),
      nutritionLabelImagePath: map['nutrition_label_image_path']?.toString(),
      isVerifiedByUser: (map['is_verified_by_user'] == 1 || map['is_verified_by_user'] == true),
      matchKeywords: map['match_keywords']?.toString(),
      isFavorite: (map['is_favorite'] == 1 || map['is_favorite'] == true),
    );
  }

  Map<String, dynamic> toJson() => toSqliteMap();

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem.fromSqliteMap(json);
}
