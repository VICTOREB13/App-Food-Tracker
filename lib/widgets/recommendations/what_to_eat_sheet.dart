import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/meal_controller.dart';
import '../../core/interfaces/nutritional_recommendation_service_interface.dart';
import '../../l10n/app_localizations.dart';
import '../../models/food_item.dart';
import '../../models/meal.dart';
import '../../models/nutritional_recommendation.dart';
import '../../services/database_service.dart';
import '../../services/nutritional_recommendation_service.dart';
import '../../services/recommendations/recommendation_dish_catalog.dart';
import '../../services/recommendations/recommendation_filter_engine.dart';
import '../../services/theme_manager.dart';
import 'category_selector_bar.dart';
import 'recommendation_budget_summary.dart';
import 'recommendation_dish_card.dart';
import 'recommendation_sheet_header.dart';

/// Interactive modal sheet displaying "¿Qué debería comer hoy?" with category filters and dynamic refresh.
class WhatToEatSheet extends StatefulWidget {
  final DateTime? date;
  final TodayRecommendationPlan? initialPlan;
  final INutritionalRecommendationService? service;

  const WhatToEatSheet({
    super.key,
    this.date,
    this.initialPlan,
    this.service,
  });

  @override
  State<WhatToEatSheet> createState() => _WhatToEatSheetState();
}

class _WhatToEatSheetState extends State<WhatToEatSheet> {
  TodayRecommendationPlan? _plan;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _addingDishId;
  String _selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    if (widget.initialPlan != null) {
      _plan = widget.initialPlan;
      _selectedCategory = widget.initialPlan!.selectedCategory;
      _isLoading = false;
    } else {
      _loadPlan();
    }
  }

  Future<void> _loadPlan({String? category, bool shuffle = false}) async {
    final targetCategory = RecommendationFilterEngine.normalizeCategory(category ?? _selectedCategory);
    if (_plan == null) {
      setState(() {
        _selectedCategory = targetCategory;
        _isLoading = true;
      });
    } else {
      setState(() {
        _selectedCategory = targetCategory;
        _isRefreshing = true;
      });
    }

    try {
      final s = widget.service ?? NutritionalRecommendationService.instance;
      final plan = await s.getWhatShouldIEatToday(
        date: widget.date,
        category: targetCategory,
        shuffle: shuffle,
      );
      if (mounted) {
        setState(() {
          _plan = plan;
          _selectedCategory = targetCategory;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final currentPlan = _plan;
        final remCal = currentPlan?.remainingCalories ?? 1600.0;
        final remProt = currentPlan?.remainingProtein ?? 120.0;
        final fallbackDishes = RecommendationFilterEngine.filterAndScore(
          catalog: RecommendationDishCatalog.dishes,
          remainingCal: remCal,
          remainingProt: remProt,
          category: targetCategory,
          shuffle: shuffle,
        );
        setState(() {
          _plan = (currentPlan ??
                  const TodayRecommendationPlan(
                    remainingCalories: 1600.0,
                    remainingProtein: 120.0,
                    remainingCarbs: 180.0,
                    remainingFat: 50.0,
                    nextMealType: 'Almuerzo',
                    generalAdvice: 'Opciones equilibradas según tu meta diaria.',
                    recommendedOptions: [],
                  ))
              .copyWith(
            recommendedOptions: fallbackDishes,
            selectedCategory: targetCategory,
          );
          _selectedCategory = targetCategory;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _addDishToToday(RecommendedDish dish) async {
    setState(() => _addingDishId = dish.id);
    try {
      final targetDate = widget.date ?? DateTime.now();
      final meal = Meal(
        id: const Uuid().v4(),
        name: dish.name,
        mealType: dish.mealType,
        date: targetDate,
        calories: dish.calories,
        protein: dish.protein,
        carbs: dish.carbs,
        fat: dish.fat,
        items: dish.ingredients
            .map((ing) => FoodItem(name: ing, calories: 0, protein: 0, carbs: 0, fat: 0))
            .toList(),
      );
      await DatabaseService.instance.insertMeal(meal);
      await MealController.instance.loadMeals();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dishRegisteredSuccess(dish.name)),
            backgroundColor: AppColors.protein,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _addingDishId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorRegisteringMeal(e.toString())),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return SafeArea(
      top: true,
      bottom: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RecommendationSheetHeader(
                nextMealType: _plan?.nextMealType,
                onClose: () => Navigator.of(context).pop(),
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_plan == null)
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.unableToCalculateRecommendations,
                      style: GoogleFonts.inter(),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RecommendationBudgetSummary(
                          plan: _plan!,
                          selectedCategory: _selectedCategory,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _plan!.generalAdvice,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CategorySelectorBar(
                          selectedCategory: _selectedCategory,
                          isRefreshing: _isRefreshing,
                          onSelected: (cat) => _loadPlan(category: cat),
                          onRefresh: () => _loadPlan(shuffle: true),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.tailoredRecommendedDishes,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (_plan!.recommendedOptions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                l10n.insufficientDataForPeriod,
                                style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
                              ),
                            ),
                          )
                        else
                          ..._plan!.recommendedOptions.map(
                            (dish) => RecommendationDishCard(
                              dish: dish,
                              isAdding: _addingDishId == dish.id,
                              onAdd: () => _addDishToToday(dish),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
