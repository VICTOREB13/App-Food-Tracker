import 'dart:math';
import '../../models/nutritional_recommendation.dart';

/// Engine responsible for scoring, categorizing, and dynamically rotating recommendations.
class RecommendationFilterEngine {
  const RecommendationFilterEngine._();

  /// Canonical normalization supporting both Spanish and English category names.
  static String normalizeCategory(String? category) {
    if (category == null) return 'Todos';
    final trimmed = category.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == 'todos' || trimmed == 'all') {
      return 'Todos';
    }
    if (trimmed == 'desayuno' || trimmed == 'breakfast') {
      return 'Desayuno';
    }
    if (trimmed == 'almuerzo' || trimmed == 'lunch') {
      return 'Almuerzo';
    }
    if (trimmed == 'cena' || trimmed == 'dinner') {
      return 'Cena';
    }
    if (trimmed.contains('snack') || trimmed == 'merienda') {
      return 'Snack';
    }
    return category.trim();
  }

  static List<RecommendedDish> filterAndScore({
    required List<RecommendedDish> catalog,
    required double remainingCal,
    required double remainingProt,
    String? category,
    String? preferredMealType,
    bool shuffle = false,
    int? seed,
    int limit = 6,
  }) {
    if (catalog.isEmpty) return const [];

    final normalizedCategory = normalizeCategory(category);
    final isAll = normalizedCategory == 'Todos';
    final normalizedPreferred = preferredMealType != null ? normalizeCategory(preferredMealType) : null;

    final filtered = catalog.where((dish) {
      if (isAll) return true;
      final type = normalizeCategory(dish.mealType);
      return type == normalizedCategory;
    }).toList();

    if (filtered.isEmpty) return const [];

    final scored = filtered.map((dish) {
      int score = dish.fitScore;

      // Time-of-day affinity boost when viewing all categories
      if (isAll && normalizedPreferred != null && normalizeCategory(dish.mealType) == normalizedPreferred) {
        score += 2;
      }

      if (remainingCal > 0) {
        if (dish.calories <= remainingCal) {
          score += 3;
        } else if (dish.calories > remainingCal + 150) {
          score -= 8;
        }
      }

      if (remainingProt > 20) {
        if (dish.protein >= 25) {
          score += 4;
        } else if (dish.protein < 10 && !dish.mealType.toLowerCase().contains('snack')) {
          score -= 4;
        }
      }

      return (dish: dish, rawScore: score);
    }).toList();

    List<({RecommendedDish dish, int rawScore})> selected;
    if (shuffle) {
      final random = seed != null ? Random(seed) : Random();
      final pool = List<({RecommendedDish dish, int rawScore})>.from(scored)..shuffle(random);
      selected = pool.take(limit).toList();
    } else {
      scored.sort((a, b) => b.rawScore.compareTo(a.rawScore));
      selected = scored.take(limit).toList();
    }

    return selected.map((item) {
      final d = item.dish;
      return RecommendedDish(
        id: d.id,
        name: d.name,
        mealType: d.mealType,
        calories: d.calories,
        protein: d.protein,
        carbs: d.carbs,
        fat: d.fat,
        description: d.description,
        ingredients: d.ingredients,
        whyRecommended: d.whyRecommended,
        fitScore: item.rawScore.clamp(70, 99),
      );
    }).toList();
  }
}
