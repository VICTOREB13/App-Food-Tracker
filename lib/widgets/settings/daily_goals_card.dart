import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/daily_goals.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class DailyGoalsCard extends StatefulWidget {
  final DailyGoals initialGoals;
  final ValueChanged<DailyGoals> onSaveGoals;

  const DailyGoalsCard({
    super.key,
    required this.initialGoals,
    required this.onSaveGoals,
  });

  @override
  State<DailyGoalsCard> createState() => _DailyGoalsCardState();
}

class _DailyGoalsCardState extends State<DailyGoalsCard> {
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.initialGoals);
  }

  @override
  void didUpdateWidget(covariant DailyGoalsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGoals != widget.initialGoals) {
      _initControllers(widget.initialGoals);
    }
  }

  void _initControllers(DailyGoals goals) {
    _caloriesController = TextEditingController(text: goals.calories.toStringAsFixed(0));
    _proteinController = TextEditingController(text: goals.protein.toStringAsFixed(0));
    _carbsController = TextEditingController(text: goals.carbs.toStringAsFixed(0));
    _fatController = TextEditingController(text: goals.fat.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _onSave() {
    final cal = double.tryParse(_caloriesController.text.trim()) ?? 2000.0;
    final prot = double.tryParse(_proteinController.text.trim()) ?? 140.0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 220.0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 65.0;

    final updated = DailyGoals(
      calories: cal,
      protein: prot,
      carbs: carbs,
      fat: fat,
    );
    widget.onSaveGoals(updated);
  }

  @override
  Widget build(BuildContext context) {
    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_outlined, size: 20, color: AppColors.protein),
              const SizedBox(width: 8),
              Text(
                'METAS NUTRICIONALES DIARIAS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _caloriesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Calorías (kcal)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _proteinController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Proteínas (g)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _carbsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Carbohidratos (g)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fatController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Grasas (g)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceSubtle(context),
                foregroundColor: AppColors.textPrimary(context),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.border(context)),
                ),
              ),
              icon: const Icon(Icons.save_outlined, size: 16),
              label: Text('Actualizar Metas', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
