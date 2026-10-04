import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/meal_controller.dart';
import '../../models/food_item.dart';
import '../../models/meal.dart';
import '../../models/nutritional_recommendation.dart';
import '../../core/interfaces/nutritional_recommendation_service_interface.dart';
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
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });
      }
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
        items: dish.ingredients
            .map((ing) => FoodItem(name: ing, calories: 0, protein: 0, carbs: 0, fat: 0))
            .toList(),
      );

      await DatabaseService.instance.insertMeal(meal);
      await MealController.instance.loadMeals();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ "${dish.name}" registrada con éxito en tu día'),
            backgroundColor: AppColors.protein,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addingDishId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar comida: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: _isLoading
          ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          : _plan == null
              ? Center(child: Text('No fue posible calcular recomendaciones', style: GoogleFonts.inter()))
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.protein.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.protein, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Qué debería comer hoy?',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Sugerencias para tu próxima comida: ${_plan!.nextMealType}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Remaining macros strip
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.border(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Margen restante de hoy:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context))),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMacroBadge('Calorías', '${_plan!.remainingCalories.round()} kcal', AppColors.primary),
                                _buildMacroBadge('Proteína', '${_plan!.remainingProtein.round()}g', AppColors.protein),
                                _buildMacroBadge('Carbos', '${_plan!.remainingCarbs.round()}g', AppColors.carbs),
                                _buildMacroBadge('Grasas', '${_plan!.remainingFat.round()}g', AppColors.fat),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_plan!.generalAdvice, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      Text('Platos recomendados a tu medida:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ..._plan!.recommendedOptions.map((dish) => _buildDishCard(dish)),
                    ],
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

  Widget _buildDishCard(RecommendedDish dish) {
    final isAdding = _addingDishId == dish.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  dish.name,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.protein.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${dish.fitScore}% Ajuste',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.protein),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(dish.description, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${dish.calories.round()} kcal', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Text(' • '),
              Text('P: ${dish.protein.round()}g', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.protein)),
              const Text(' • '),
              Text('C: ${dish.carbs.round()}g', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.carbs)),
              const Text(' • '),
              Text('G: ${dish.fat.round()}g', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.fat)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Por qué: ${dish.whyRecommended}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context))),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isAdding ? null : () => _addDishToToday(dish),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.protein,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: isAdding
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add, size: 14),
              label: Text('Registrar en hoy', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
