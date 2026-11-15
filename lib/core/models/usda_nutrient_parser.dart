import 'model_sanitizer.dart';

/// Robust nutrient parser for USDA FoodData Central payloads.
/// Supports both flat (`nutrientId`, `value`) and nested (`nutrient.id`, `amount`) schemas.
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
