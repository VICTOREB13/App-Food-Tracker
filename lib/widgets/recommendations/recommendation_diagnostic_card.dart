import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/interfaces/nutritional_recommendation_service_interface.dart';
import '../../l10n/app_localizations.dart';
import '../../models/nutritional_recommendation.dart';
import '../../services/nutritional_recommendation_service.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

/// Shows the nutritional recommendation diagnostic dialog in a bounded, scrollable modal
/// completely separating content from the close action.
Future<void> showRecommendationDiagnosticDialog(
  BuildContext context, {
  NutritionalAnalysisReport? initialReport,
  INutritionalRecommendationService? service,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border(context))),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: 400,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(l10n.nutritionalDiagnosticTitle, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: l10n.closeButton,
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: RecommendationDiagnosticCard(initialReport: initialReport, service: service),
              ),
            ),
          ],
        ),
      ),
      ),
    ),
  );
}

/// Card analyzing 7, 15, or 30 days nutritional history and diagnosing fats, proteins, carbs, and calories.
class RecommendationDiagnosticCard extends StatefulWidget {
  final NutritionalAnalysisReport? initialReport;
  final INutritionalRecommendationService? service;

  const RecommendationDiagnosticCard({
    super.key,
    this.initialReport,
    this.service,
  });

  @override
  State<RecommendationDiagnosticCard> createState() => _RecommendationDiagnosticCardState();
}

class _RecommendationDiagnosticCardState extends State<RecommendationDiagnosticCard> {
  int _selectedDays = 7;
  NutritionalAnalysisReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialReport != null) {
      _report = widget.initialReport;
      _isLoading = false;
    } else {
      _loadReport();
    }
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final s = widget.service ?? NutritionalRecommendationService.instance;
      final rep = await s.analyzeHistory(days: _selectedDays);
      if (mounted) setState(() { _report = rep; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColors.protein, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.nutritionalRecommendationEngine,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.textSecondary(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.analyzeHistoryLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildPeriodChip(7, l10n.sevenDaysLabel),
                  _buildPeriodChip(15, l10n.fifteenDaysLabel),
                  _buildPeriodChip(30, l10n.thirtyDaysLabel),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_report == null)
            Text(l10n.insufficientDataForPeriod, style: GoogleFonts.inter(fontSize: 12))
          else ...[
            _buildMacroGauges(l10n),
            const SizedBox(height: 12),
            _buildInsightTile(title: l10n.fatControlTitle, content: _report!.fatDiagnosis, color: AppColors.fat, icon: Icons.opacity),
            const SizedBox(height: 8),
            _buildInsightTile(title: l10n.proteinGoalsTitle, content: _report!.proteinDiagnosis, color: AppColors.protein, icon: Icons.fitness_center),
            const SizedBox(height: 8),
            _buildInsightTile(title: l10n.energyAndCarbsTitle, content: _report!.carbsDiagnosis, color: AppColors.carbs, icon: Icons.bolt),
            const SizedBox(height: 10),
            Text(l10n.suggestedSmartSubstitutions, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ..._report!.fatReductionSwaps.map(_buildSwapRow),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (val) {
        if (val && _selectedDays != days) {
          setState(() => _selectedDays = days);
          _loadReport();
        }
      },
      selectedColor: AppColors.protein.withValues(alpha: 0.2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildMacroGauges(AppLocalizations l10n) {
    final r = _report!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.border(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGaugeItem(l10n.calories, '${r.averageDailyCalories.round()} / ${r.targetCalories.round()} kcal', r.averageDailyCalories / (r.targetCalories > 0 ? r.targetCalories : 1), AppColors.primary),
            const SizedBox(width: 14),
            _buildGaugeItem(l10n.protein, '${r.averageDailyProtein.round()} / ${r.targetProtein.round()}g', r.averageDailyProtein / (r.targetProtein > 0 ? r.targetProtein : 1), AppColors.protein),
            const SizedBox(width: 14),
            _buildGaugeItem(l10n.carbs, '${r.averageDailyCarbs.round()} / ${r.targetCarbs.round()}g', r.averageDailyCarbs / (r.targetCarbs > 0 ? r.targetCarbs : 1), AppColors.carbs),
            const SizedBox(width: 14),
            _buildGaugeItem(l10n.fat, '${r.averageDailyFat.round()} / ${r.targetFat.round()}g', r.averageDailyFat / (r.targetFat > 0 ? r.targetFat : 1), AppColors.fat),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeItem(String label, String fraction, double ratio, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
        const SizedBox(height: 2),
        Text(fraction, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          width: 54,
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightTile({required String title, required String content, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(content, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary(context), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapRow(FoodSwapSuggestion swap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.swap_horiz, size: 14, color: AppColors.protein),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary(context)),
                children: [
                  TextSpan(text: '${swap.originalFood} → ', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                  TextSpan(text: swap.substituteFood, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.protein)),
                  TextSpan(text: ' (${swap.rationale})', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
