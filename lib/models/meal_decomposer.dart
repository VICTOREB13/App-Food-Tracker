import 'food_item.dart';
import 'model_sanitizer.dart';

/// Helper to decompose composite meal descriptions into discrete FoodItem components
/// with realistic volumetric weights and macronutrient proportions.
class MealDecomposer {
  /// Extracts individual food component names from a composite text (e.g. "Arroz, frijoles y carne")
  static List<String> extractComponents(String text) {
    if (text.trim().isEmpty) return const [];
    final normalized = text
        .replaceAll(RegExp(r'\s+(?:y|e|con|and|with)\s+', caseSensitive: false), ', ')
        .replaceAll(RegExp(r'[;&/+\n]'), ', ');

    return normalized
        .split(',')
        .map((p) => p.trim())
        .map((p) => p.replaceAll(RegExp(r'^[-*•"\s]+|[-*•"\s]+$'), ''))
        .where((p) => p.length >= 2)
        .toSet()
        .toList();
  }

  /// Identifies seasonings, spices, and herbs to protect macro allocation
  static bool isSeasoningOrHerb(String name) {
    final s = name.toLowerCase();
    const exclusions = ['salmon', 'salmón', 'salchicha', 'salsa', 'ensalada', 'saltead'];
    if (exclusions.any((e) => s.contains(e))) {
      return false;
    }
    const keys = [
      'romero', 'perejil', 'orégano', 'oregano', 'cilantro', 'pimienta',
      'laurel', 'albahaca', 'comino', 'tomillo', 'especi', 'condimento',
      'hierba', 'eneldo', 'curry', 'canela'
    ];
    if (keys.any((k) => s.contains(k))) {
      return true;
    }
    final words = s.split(RegExp(r'[\s,.;:()/\-]+'));
    return words.contains('sal') || words.contains('ajo');
  }

  /// Decomposes composite foods or dishes into distinct ingredients with realistic volumetric grams
  static List<FoodItem> decomposeCompositeFood(
    List<String> componentNames,
    double cal,
    double prot,
    double carbs,
    double fat,
  ) {
    if (componentNames.isEmpty) return const [];
    final n = componentNames.length;

    // Weight coefficients per category: [calWeight, protWeight, carbWeight, fatWeight, baseGrams, density]
    List<double> weightsFor(String name) {
      final s = name.toLowerCase();
      if (isSeasoningOrHerb(s)) {
        return [0.01, 0.01, 0.01, 0.01, 5.0, 0.5];
      } else if (s.contains('arroz') || s.contains('pasta') || s.contains('fideo') || s.contains('papa') ||
          s.contains('platano') || s.contains('plátano') || s.contains('yuca') || s.contains('arepa')) {
        return [0.35, 0.10, 0.65, 0.05, 160.0, 1.3];
      } else if (s.contains('frijol') || s.contains('caraota') || s.contains('lenteja') || s.contains('garbanzo')) {
        return [0.25, 0.25, 0.30, 0.10, 135.0, 1.2];
      } else if (s.contains('carne') || s.contains('pollo') || s.contains('pescado') || s.contains('bistec') ||
          s.contains('pechuga') || s.contains('molida') || s.contains('mechada') || s.contains('huevo')) {
        return [0.35, 0.60, 0.02, 0.40, 125.0, 1.9];
      } else if (s.contains('aguacate') || s.contains('palta') || s.contains('aceite') || s.contains('grasa')) {
        return [0.18, 0.03, 0.05, 0.45, 65.0, 1.7];
      } else if (s.contains('ensalada') || s.contains('lechuga') || s.contains('tomate') || s.contains('vegetal')) {
        return [0.08, 0.05, 0.10, 0.02, 85.0, 0.4];
      }
      return [1.0 / n, 1.0 / n, 1.0 / n, 1.0 / n, 110.0, 1.4];
    }

    final profiles = componentNames.map(weightsFor).toList();
    double sumCalW = profiles.fold(0.0, (acc, p) => acc + p[0]);
    double sumProtW = profiles.fold(0.0, (acc, p) => acc + p[1]);
    double sumCarbW = profiles.fold(0.0, (acc, p) => acc + p[2]);
    double sumFatW = profiles.fold(0.0, (acc, p) => acc + p[3]);

    if (sumCalW == 0) sumCalW = 1.0;
    if (sumProtW == 0) sumProtW = 1.0;
    if (sumCarbW == 0) sumCarbW = 1.0;
    if (sumFatW == 0) sumFatW = 1.0;

    final items = <FoodItem>[];
    for (int i = 0; i < n; i++) {
      final name = componentNames[i];
      final prof = profiles[i];
      final itemCal = cal > 0 ? (cal * (prof[0] / sumCalW)) : 0.0;
      final itemProt = prot > 0 ? (prot * (prof[1] / sumProtW)) : 0.0;
      final itemCarb = carbs > 0 ? (carbs * (prof[2] / sumCarbW)) : 0.0;
      final itemFat = fat > 0 ? (fat * (prof[3] / sumFatW)) : 0.0;

      double grams = prof[4];
      if (itemCal > 0) {
        final minG = isSeasoningOrHerb(name) ? 2.0 : 35.0;
        final maxG = isSeasoningOrHerb(name) ? 15.0 : 320.0;
        grams = (itemCal / prof[5]).clamp(minG, maxG);
      }
      if (grams == 200.0) grams = 185.0;

      items.add(FoodItem(
        name: name,
        estimatedGrams: grams.roundToDouble(),
        calories: ModelSanitizer.clampDouble(itemCal),
        protein: ModelSanitizer.clampDouble(itemProt),
        carbs: ModelSanitizer.clampDouble(itemCarb),
        fat: ModelSanitizer.clampDouble(itemFat),
        visualJustification: 'Desglose volumétrico de porción de $name',
      ));
    }
    return items;
  }
}
