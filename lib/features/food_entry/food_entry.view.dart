import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/features/food_entry/food_entry.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'package:food_tracker/core/ui/components/ve_app_bar.dart';
import 'package:food_tracker/core/ui/components/ve_card.dart';
import 'package:food_tracker/features/dashboard/widgets/quick_meal_dialog.dart';
/// Hub view for Food Entry and Meal Management under Vertical Slice Architecture (<300 LoC).
class FoodEntryView extends StatefulWidget {
  const FoodEntryView({super.key});

  @override
  State<FoodEntryView> createState() => _FoodEntryViewState();
}

class _FoodEntryViewState extends State<FoodEntryView> {
  final FoodEntryController _controller = FoodEntryController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.init();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _openCameraScan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MealDetailView()),
    );
    await _controller.loadMeals();
  }

  Future<void> _openQuickMealDialog() async {
    final quickMeal = await showQuickMealDialog(context, date: _controller.selectedDate);
    if (quickMeal != null && mounted) {
      await _controller.saveMeal(quickMeal);
    }
  }

  Future<void> _openManualMeal() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MealDetailView()),
    );
    await _controller.loadMeals();
  }

  Future<void> _openDishwareSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DishwareSettingsScreen()),
    );
    await _controller.loadDishware();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _controller.state;

    return Scaffold(
      appBar: VeAppBar(
        title: l10n.foodEntryTitle,
        subtitle: l10n.foodEntrySubtitle,
        showVeBadge: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildActionGrid(l10n),
                const SizedBox(height: 20),
                _buildSectionHeader(l10n.todayLoggedMeals, state.meals.length.toString()),
                const SizedBox(height: 10),
                if (state.meals.isEmpty)
                  _buildEmptyState(l10n)
                else
                  ...state.meals.map((meal) => _buildMealItemCard(meal, l10n)),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildActionGrid(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoAction(
                icon: Icons.camera_alt_outlined,
                title: l10n.scanMealPhotoTitle,
                subtitle: l10n.scanMealPhotoSubtitle,
                onTap: _openCameraScan,
                primary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoAction(
                icon: Icons.flash_on_outlined,
                title: l10n.quickMealTitle,
                subtitle: l10n.quickMealSubtitle,
                onTap: _openQuickMealDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBentoAction(
                icon: Icons.edit_note_outlined,
                title: l10n.manualMealTitle,
                subtitle: l10n.manualMealSubtitle,
                onTap: _openManualMeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoAction(
                icon: Icons.straighten_outlined,
                title: l10n.dishwareReferenceTitle,
                subtitle: l10n.dishwareReferenceSubtitle,
                onTap: _openDishwareSettings,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary ? AppColors.primary : AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primary ? AppColors.primary : AppColors.textPrimary(context), size: 24),
            const SizedBox(height: 10),
            Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(10)),
          child: Text(count, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.noMealsToday,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted(context)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMealItemCard(Meal meal, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: VeCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(meal.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: Text(
            '${meal.calories.toStringAsFixed(0)} kcal • P: ${meal.protein.toStringAsFixed(0)}g C: ${meal.carbs.toStringAsFixed(0)}g G: ${meal.fat.toStringAsFixed(0)}g',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _controller.deleteMeal(meal),
          ),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MealDetailView(initialMeal: meal)),
            );
            await _controller.loadMeals();
          },
        ),
      ),
    );
  }
}
