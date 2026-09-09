import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/meal_controller.dart';
import '../models/meal.dart';
import '../services/database_service.dart';
import '../services/theme_manager.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/metrics/calorie_compliance_bento_card.dart';
import '../widgets/metrics/macro_distribution_bento_card.dart';
import '../widgets/metrics/quick_weight_entry_dialog.dart';
import '../widgets/metrics/streak_compliance_bento_card.dart';
import '../widgets/metrics/weight_history_bento_card.dart';
import '../widgets/metrics/weight_trend_bento_card.dart';

/// Dedicated screen with Bento Grid for historical analytics and progress tracking.
class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  final MealController _mealController = MealController.instance;
  int _selectedDays = 30;
  List<Meal> _rangeMeals = [];

  static const List<int> _availableRanges = [7, 30, 90, 0];

  @override
  void initState() {
    super.initState();
    _mealController.addListener(_onControllerChange);
    _loadData();
  }

  @override
  void dispose() {
    _mealController.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    try {
      await _mealController.loadWeightLogs(days: _selectedDays);
      final allMeals = await DatabaseService.instance.getAllMeals();
      if (_selectedDays == 0) {
        if (mounted) {
          setState(() {
            _rangeMeals = allMeals;
          });
        }
      } else {
        final cutoff = DateTime.now().subtract(Duration(days: _selectedDays));
        if (mounted) {
          setState(() {
            _rangeMeals = allMeals.where((m) => m.date.isAfter(cutoff)).toList();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _rangeMeals = []);
      }
    }
  }

  Future<void> _onSelectRange(int days) async {
    if (_selectedDays == days) return;
    setState(() => _selectedDays = days);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VeAppBar(
        title: 'Métricas y Progreso',
        subtitle: 'Analítica Local-First',
        showVeBadge: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickWeightEntryDialog(
          context,
          initialWeight: _mealController.currentWeight,
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.monitor_weight_outlined, color: Colors.white),
        label: Text(
          'Registrar Peso',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // 1. Time range filter
            _buildRangeSelector(),
            const SizedBox(height: 14),

            // 2. Weight trend chart bento card
            WeightTrendBentoCard(
              logs: _mealController.weightLogs,
            ),
            const SizedBox(height: 14),

            // 3. Bento row: Calorie compliance & Streak compliance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CalorieComplianceBentoCard(
                    meals: _rangeMeals,
                    days: _selectedDays,
                    goals: _mealController.dailyGoals,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreakComplianceBentoCard(
                    meals: _rangeMeals,
                    days: _selectedDays,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Macro distribution bento card
            MacroDistributionBentoCard(
              meals: _rangeMeals,
              goals: _mealController.dailyGoals,
            ),
            const SizedBox(height: 14),

            // 5. Weight history bento card with notes
            WeightHistoryBentoCard(
              logs: _mealController.weightLogs,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            'PERÍODO:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: _availableRanges.map((days) {
              final isSelected = _selectedDays == days;
              final label = days == 0 ? 'Histórico' : '$days días';
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => _onSelectRange(days),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary(context),
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface(context),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
