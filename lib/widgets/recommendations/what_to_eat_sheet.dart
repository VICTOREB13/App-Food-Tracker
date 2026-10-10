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
import '../../services/theme_manager.dart';

/// Interactive modal sheet displaying "¿Qué debería comer hoy?" based on remaining macros.
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
  String? _addingDishId;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlan != null) {
      _plan = widget.initialPlan;
      _isLoading = false;
    } else {
      _loadPlan();
    }
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    try {
      final s = widget.service ?? NutritionalRecommendationService.instance;
      final plan = await s.getWhatShouldIEatToday(date: widget.date);
      if (mounted) setState(() { _plan = plan; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
        items: dish.ingredients.map((ing) => FoodItem(name: ing, calories: 0, protein: 0, carbs: 0, fat: 0)).toList(),
      );
      await DatabaseService.instance.insertMeal(meal);
      await MealController.instance.loadMeals();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dishRegisteredSuccess(dish.name)), backgroundColor: AppColors.protein),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _addingDishId = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorRegisteringMeal(e.toString())), backgroundColor: AppColors.primary));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

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
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.protein.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.protein, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.whatToEatTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                        if (_plan != null)
                          Text(
                            l10n.nextMealSuggestions(_plan!.nextMealType),
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('what_to_eat_close_button'),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.closeButton,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              if (_isLoading)
                const Expanded(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())))
              else if (_plan == null)
                Expanded(child: Center(child: Text(l10n.unableToCalculateRecommendations, style: GoogleFonts.inter())))
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.border(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.todayRemainingMargin, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context))),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildMacroBadge(l10n.calories, '${_plan!.remainingCalories.round()} kcal', AppColors.primary),
                                  _buildMacroBadge(l10n.protein, '${_plan!.remainingProtein.round()}g', AppColors.protein),
                                  _buildMacroBadge(l10n.carbs, '${_plan!.remainingCarbs.round()}g', AppColors.carbs),
                                  _buildMacroBadge(l10n.fat, '${_plan!.remainingFat.round()}g', AppColors.fat),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_plan!.generalAdvice, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), fontStyle: FontStyle.italic)),
                        const SizedBox(height: 16),
                        Text(l10n.tailoredRecommendedDishes, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ..._plan!.recommendedOptions.map((dish) => _buildDishCard(dish, l10n)),
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

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
      ],
    );
  }

  Widget _buildDishCard(RecommendedDish dish, AppLocalizations l10n) {
    final isAdding = _addingDishId == dish.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(dish.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.protein.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(l10n.fitScoreLabel(dish.fitScore.toString()), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.protein)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(dish.description, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
          const SizedBox(height: 8),
          Text(
            '${dish.calories.round()} kcal • P: ${dish.protein.round()}g • C: ${dish.carbs.round()}g • G: ${dish.fat.round()}g',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(l10n.whyRecommendedLabel(dish.whyRecommended), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context))),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isAdding ? null : () => _addDishToToday(dish),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.protein, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              icon: isAdding
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add, size: 14),
              label: Text(l10n.logInTodayAction, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
