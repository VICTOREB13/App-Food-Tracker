import 'package:food_tracker/core/models/nutritional_recommendation.dart';
import 'package:food_tracker/features/dashboard/services/recommendations/breakfast_dish_catalog.dart';
import 'package:food_tracker/features/dashboard/services/recommendations/dinner_dish_catalog.dart';
import 'package:food_tracker/features/dashboard/services/recommendations/lunch_dish_catalog.dart';
import 'package:food_tracker/features/dashboard/services/recommendations/snack_dish_catalog.dart';

/// Exhaustive, modular aggregator of nutritional plates, balanced meals, and practical snacks.
class RecommendationDishCatalog {
  const RecommendationDishCatalog._();

  static List<RecommendedDish> get breakfast => BreakfastDishCatalog.dishes;
  static List<RecommendedDish> get lunch => LunchDishCatalog.dishes;
  static List<RecommendedDish> get dinner => DinnerDishCatalog.dishes;
  static List<RecommendedDish> get snacks => SnackDishCatalog.snacks;

  static List<RecommendedDish> get mainMeals => [
        ...breakfast,
        ...lunch,
        ...dinner,
      ];

  static List<RecommendedDish> get dishes => [
        ...mainMeals,
        ...snacks,
      ];
}
