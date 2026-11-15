import 'package:flutter/material.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';
import 'package:food_tracker/features/dashboard/widgets/analysis_progress_banner.dart';
import 'package:food_tracker/features/dashboard/widgets/daily_calorie_summary_card.dart';
import 'package:food_tracker/features/dashboard/widgets/date_selector_bar.dart';
import 'package:food_tracker/features/dashboard/widgets/fasting_window_bento_card.dart';
import 'package:food_tracker/features/dashboard/widgets/meal_section_card.dart';
import 'package:food_tracker/features/dashboard/widgets/week_calendar_strip.dart';
import 'dashboard.model.dart';

/// Bento Grid layout presenting the daily timeline, nutritional progress,
/// fasting window, and categorized meal sections.
class DashboardBentoGridView extends StatelessWidget {
  final DashboardState state;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onToday;
  final ValueChanged<Meal> onMealTap;
  final ValueChanged<String> onAddMeal;
  final ValueChanged<Meal> onOpenMeal;

  const DashboardBentoGridView({
    super.key,
    required this.state,
    required this.onDateSelected,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onToday,
    required this.onMealTap,
    required this.onAddMeal,
    required this.onOpenMeal,
  });

  @override
  Widget build(BuildContext context) {
    final mealsMap = state.mealsByType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DateSelectorBar(
          selectedDate: state.selectedDate,
          onPreviousDay: onPreviousDay,
          onNextDay: onNextDay,
          onToday: onToday,
          onDateSelected: onDateSelected,
        ),
        const SizedBox(height: 8),
        WeekCalendarStrip(
          selectedDate: state.selectedDate,
          onDateSelected: onDateSelected,
        ),
        const SizedBox(height: 12),
        AnalysisProgressBanner(
          onOpenMeal: onOpenMeal,
        ),
        DailyCalorieSummaryCard(
          currentCalories: state.budget.consumedCalories,
          currentProtein: state.macros.protein,
          currentCarbs: state.macros.carbs,
          currentFat: state.macros.fat,
          goals: state.goals,
        ),
        const SizedBox(height: 12),
        const FastingWindowBentoCard(),
        const SizedBox(height: 14),
        for (final type in Meal.validMealTypes) ...[
          MealSectionCard(
            mealType: type,
            meals: mealsMap[type] ?? const [],
            onMealTap: onMealTap,
            onAddMeal: () => onAddMeal(type),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
