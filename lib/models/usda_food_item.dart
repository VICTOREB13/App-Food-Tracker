import 'food_item.dart';
import 'model_sanitizer.dart';
import 'pantry_item.dart';

class UsdaNutrientParser {
  static const int idEnergy = 1008;
  static const int idProtein = 1003;
  static const int idFat = 1004;
  static const int idCarbs = 1005;
  static const int idFiber = 1079;
  static const int idSodium = 1093;
  static const int idCalcium = 1087;
  static const int idIron = 1089;
  static const int idVitaminA = 1104;
  static const int idVitaminC = 1162;

  static const List<int> energyIds = [idEnergy, 2047, 2048];

  /// Parses a nutrient value by searching target IDs and fallback numbers.
  /// Handles both flattened (`nutrientId`, `value`) and nested (`nutrient.id`, `amount`) schemas.
  /// Automatically converts kJ to kcal for Energy (1008).
  static double parseNutrient(
    dynamic foodNutrientsRaw,
    List<int> targetIds, {
    List<String> targetNumbers = const [],
  }) {
    if (foodNutrientsRaw is! List) return 0.0;

    for (final item in foodNutrientsRaw) {
      if (item is! Map<String, dynamic>) continue;

      // 1. Resolve nutrient ID (flat or nested)
      final int? id = (item['nutrientId'] as num?)?.toInt() ??
          (item['nutrient'] is Map ? (item['nutrient']['id'] as num?)?.toInt() : null);

      // 2. Resolve nutrient number (flat or nested)
      final String? number = item['nutrientNumber']?.toString() ??
          item['number']?.toString() ??
          (item['nutrient'] is Map ? item['nutrient']['number']?.toString() : null);

      final bool idMatches = id != null && targetIds.contains(id);
      final bool numberMatches = number != null && targetNumbers.contains(number);

      if (idMatches || numberMatches) {
        // 3. Resolve numeric value (value or amount)
        final num? rawVal = (item['value'] as num?) ?? (item['amount'] as num?);
        if (rawVal == null) continue;

        // 4. Resolve unit
        final String unit = (item['unitName'] ??
                (item['nutrient'] is Map ? item['nutrient']['unitName'] : null) ??
                '')
            .toString()
            .trim()
            .toUpperCase();

        double val = rawVal.toDouble();

        // 5. Energy conversion if kJ
        final bool isEnergy = targetIds.contains(idEnergy) || targetNumbers.contains('208');
        if (isEnergy && (unit == 'KJ' || unit.contains('KILOJOULE'))) {
          val = val / 4.184;
        }

        return ModelSanitizer.clampDouble(val);
      }
    }

    return 0.0;
  }
}

class UsdaFoodItem {
  final int fdcId;
  final String description;
  final String? brandOwner;
  final String? brandName;
  final String? gtinUpc;
  final String? dataType;
  final double? servingSize;
  final String? servingSizeUnit;
  final String? householdServingFullText;
  final String? category;

  // Macronutrients (Kcal, Grams)
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  // Micronutrients (Fiber in g, Sodium/Calcium/Iron/VitC in mg, VitA in IU/mcg)
  final double fiber;
  final double sodium;
  final double calcium;
  final double iron;
  final double vitaminA;
  final double vitaminC;

  static const Object _sentinel = Object();

  const UsdaFoodItem({
    required this.fdcId,
    required this.description,
    this.brandOwner,
    this.brandName,
    this.gtinUpc,
    this.dataType,
    this.servingSize,
    this.servingSizeUnit,
    this.householdServingFullText,
    this.category,
    this.calories = 0.0,
    this.protein = 0.0,
    this.fat = 0.0,
    this.carbs = 0.0,
    this.fiber = 0.0,
    this.sodium = 0.0,
    this.calcium = 0.0,
    this.iron = 0.0,
    this.vitaminA = 0.0,
    this.vitaminC = 0.0,
  });

  UsdaFoodItem copyWith({
    int? fdcId,
    String? description,
    Object? brandOwner = _sentinel,
    Object? brandName = _sentinel,
    Object? gtinUpc = _sentinel,
    Object? dataType = _sentinel,
    Object? servingSize = _sentinel,
    Object? servingSizeUnit = _sentinel,
    Object? householdServingFullText = _sentinel,
    Object? category = _sentinel,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? fiber,
    double? sodium,
    double? calcium,
    double? iron,
    double? vitaminA,
    double? vitaminC,
  }) {
    return UsdaFoodItem(
      fdcId: fdcId ?? this.fdcId,
      description: description ?? this.description,
      brandOwner: identical(brandOwner, _sentinel) ? this.brandOwner : (brandOwner as String?),
      brandName: identical(brandName, _sentinel) ? this.brandName : (brandName as String?),
      gtinUpc: identical(gtinUpc, _sentinel) ? this.gtinUpc : (gtinUpc as String?),
      dataType: identical(dataType, _sentinel) ? this.dataType : (dataType as String?),
      servingSize: identical(servingSize, _sentinel) ? this.servingSize : (servingSize as double?),
      servingSizeUnit: identical(servingSizeUnit, _sentinel) ? this.servingSizeUnit : (servingSizeUnit as String?),
      householdServingFullText: identical(householdServingFullText, _sentinel)
          ? this.householdServingFullText
          : (householdServingFullText as String?),
      category: identical(category, _sentinel) ? this.category : (category as String?),
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      calcium: calcium ?? this.calcium,
      iron: iron ?? this.iron,
      vitaminA: vitaminA ?? this.vitaminA,
      vitaminC: vitaminC ?? this.vitaminC,
    );
  }

  /// Parses both search items (/foods/search) and detail items (/food/{id})
  factory UsdaFoodItem.fromFdcJson(Map<String, dynamic> json) {
    final nutrients = json['foodNutrients'];

    final calories = UsdaNutrientParser.parseNutrient(
      nutrients,
      UsdaNutrientParser.energyIds,
      targetNumbers: const ['208'],
    );
    final protein = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idProtein],
      targetNumbers: const ['203'],
    );
    final fat = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idFat],
      targetNumbers: const ['204'],
    );
    final carbs = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idCarbs],
      targetNumbers: const ['205'],
    );
    final fiber = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idFiber],
      targetNumbers: const ['291'],
    );
    final sodium = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idSodium],
      targetNumbers: const ['307'],
    );
    final calcium = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idCalcium],
      targetNumbers: const ['301'],
    );
    final iron = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idIron],
      targetNumbers: const ['303'],
    );
    final vitaminA = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idVitaminA, 1106],
      targetNumbers: const ['318', '320'],
    );
    final vitaminC = UsdaNutrientParser.parseNutrient(
      nutrients,
      const [UsdaNutrientParser.idVitaminC],
      targetNumbers: const ['400'],
    );

    return UsdaFoodItem(
      fdcId: (json['fdcId'] as num?)?.toInt() ?? 0,
      description: ModelSanitizer.truncate(
        json['description']?.toString(),
        ModelSanitizer.maxNameLength,
        fallback: 'Alimento USDA',
      ),
      brandOwner: ModelSanitizer.truncateNullable(json['brandOwner']?.toString(), ModelSanitizer.maxNameLength),
      brandName: ModelSanitizer.truncateNullable(json['brandName']?.toString(), ModelSanitizer.maxNameLength),
      gtinUpc: ModelSanitizer.truncateNullable(json['gtinUpc']?.toString(), 32),
      dataType: ModelSanitizer.truncateNullable(json['dataType']?.toString(), 64),
      servingSize: (json['servingSize'] as num?)?.toDouble(),
      servingSizeUnit: ModelSanitizer.truncateNullable(json['servingSizeUnit']?.toString(), 32),
      householdServingFullText: ModelSanitizer.truncateNullable(json['householdServingFullText']?.toString(), 128),
      category: ModelSanitizer.truncateNullable(
        json['brandedFoodCategory']?.toString() ??
            json['foodCategory']?.toString() ??
            (json['wweiaFoodCategory'] is Map ? json['wweiaFoodCategory']['wweiaFoodCategoryDescription']?.toString() : null),
        100,
      ),
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
      sodium: sodium,
      calcium: calcium,
      iron: iron,
      vitaminA: vitaminA,
      vitaminC: vitaminC,
    );
  }

  /// Converts USDA food item to local PantryItem (for pantry storage or barcode scanning)
  PantryItem toPantryItem({bool isFavorite = false}) {
    final brand = ModelSanitizer.truncateNullable(
      brandOwner ?? brandName,
      ModelSanitizer.maxNameLength,
    );
    final cat = ModelSanitizer.truncateNullable(
      category ?? dataType,
      100,
    );

    return PantryItem(
      name: ModelSanitizer.truncate(
        description,
        ModelSanitizer.maxNameLength,
        fallback: 'Alimento USDA',
      ),
      brand: brand,
      category: cat,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      isFavorite: isFavorite,
    );
  }

  /// Converts USDA food item to FoodItem (for plate/meal logging)
  FoodItem toFoodItem({
    double? estimatedGrams,
    String? visualJustification,
  }) {
    final baseGrams = (servingSize != null && (servingSizeUnit?.toLowerCase() == 'g' || servingSizeUnit?.toLowerCase() == 'gr'))
        ? servingSize!
        : 100.0;
    final grams = estimatedGrams ?? baseGrams;
    final double ratio = (estimatedGrams != null && baseGrams > 0) ? (estimatedGrams / baseGrams) : 1.0;

    return FoodItem(
      name: ModelSanitizer.truncate(
        description,
        ModelSanitizer.maxNameLength,
        fallback: 'Alimento USDA',
      ),
      estimatedGrams: grams,
      calories: ModelSanitizer.clampDouble(calories * ratio),
      protein: ModelSanitizer.clampDouble(protein * ratio),
      carbs: ModelSanitizer.clampDouble(carbs * ratio),
      fat: ModelSanitizer.clampDouble(fat * ratio),
      visualJustification: ModelSanitizer.truncateNullable(
        visualJustification ??
            (householdServingFullText != null
                ? 'Porción USDA: $householdServingFullText ($grams g)'
                : 'Base USDA ($grams g)'),
        ModelSanitizer.maxJustificationLength,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'fdcId': fdcId,
        'description': description,
        'brandOwner': brandOwner,
        'brandName': brandName,
        'gtinUpc': gtinUpc,
        'dataType': dataType,
        'servingSize': servingSize,
        'servingSizeUnit': servingSizeUnit,
        'householdServingFullText': householdServingFullText,
        'category': category,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'sodium': sodium,
        'calcium': calcium,
        'iron': iron,
        'vitaminA': vitaminA,
        'vitaminC': vitaminC,
      };

  factory UsdaFoodItem.fromJson(Map<String, dynamic> json) => UsdaFoodItem.fromFdcJson(json);
}
