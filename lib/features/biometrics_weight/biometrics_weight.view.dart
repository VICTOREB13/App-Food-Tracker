import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'package:food_tracker/core/ui/components/ve_card.dart';
import 'package:food_tracker/features/biometrics_weight/widgets/quick_weight_adjuster_row.dart';
import 'package:food_tracker/features/biometrics_weight/widgets/quick_weight_entry_dialog.dart';
import 'package:food_tracker/features/biometrics_weight/widgets/weight_line_chart_painter.dart';
import 'biometrics_weight.controller.dart';
import 'biometrics_weight.model.dart';

/// Micro-MVC View for the Biometrics & Weight vertical slice.
/// Composes WeightLineChartPainter, QuickWeightAdjusterRow, and filter controls (< 300 LoC).
class BiometricsWeightView extends StatelessWidget {
  final BiometricsWeightController? controller;
  final VoidCallback? onAddWeight;

  const BiometricsWeightView({super.key, this.controller, this.onAddWeight});

  BiometricsWeightController get _ctrl =>
      controller ?? BiometricsWeightController.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        final state = _ctrl.state;
        final l10n = AppLocalizations.of(context);

        return VeCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, l10n),
              const SizedBox(height: 12),
              _buildRangeFilterRow(context, l10n, state.filterRange),
              const SizedBox(height: 14),
              _buildStatsRow(context, l10n, state),
              const SizedBox(height: 14),
              _buildChartArea(context, l10n, state),
              const SizedBox(height: 14),
              QuickWeightAdjusterRow(
                onAdjust: (delta) async {
                  final cur = state.currentWeight ?? 70.0;
                  final next = (cur + delta).clamp(20.0, 350.0);
                  await _ctrl.recordWeight(next);
                  if (context.mounted) {
                    final str = next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.weightLoggedSuccess(str)),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 1),
                    ));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.show_chart, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.weightTrendHeader,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () => onAddWeight != null
              ? onAddWeight!()
              : showQuickWeightEntryDialog(context, initialWeight: _ctrl.currentWeight),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  l10n.quickLogWeight,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeFilterRow(BuildContext context, AppLocalizations l10n, WeightFilterRange currentRange) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: WeightFilterRange.values.map((range) {
          final isSelected = currentRange == range;
          final label = range.days == 0 ? l10n.allTimeHistorical : l10n.periodDays(range.days.toString());
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => _ctrl.setFilterRange(range),
              labelStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary(context),
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceSubtle(context),
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border(context)),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AppLocalizations l10n, BiometricsWeightState state) {
    final curWeight = state.currentWeight;
    final delta = state.weightDelta;
    final startWeight = state.logs.isNotEmpty ? state.logs.first.weight : null;

    final IconData trendIcon = delta == null || delta.abs() <= 0.05
        ? Icons.trending_flat
        : (delta < 0 ? Icons.trending_down : Icons.trending_up);
    final Color trendColor = delta == null || delta.abs() <= 0.05
        ? AppColors.textSecondary(context)
        : (delta < 0 ? AppColors.protein : AppColors.carbs);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.currentWeightHeader,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  curWeight != null ? curWeight.toStringAsFixed(1) : '--',
                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context), letterSpacing: -0.5),
                ),
                const SizedBox(width: 4),
                Text('kg', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
              ],
            ),
          ],
        ),
        if (startWeight != null && state.logs.length >= 2) ...[
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.startWeightHeader, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.textSecondary(context))),
              const SizedBox(height: 2),
              Text('${startWeight.toStringAsFixed(1)} kg', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context))),
            ],
          ),
        ],
        const Spacer(),
        if (delta != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: trendColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: 3),
                Text('${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: trendColor)),
              ],
            ),
          ),
        if (state.movingAverage7d > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border(context))),
            child: Text(
              '${l10n.movingAverage7dLabel}: ${state.movingAverage7d.toStringAsFixed(1)} kg',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChartArea(BuildContext context, AppLocalizations l10n, BiometricsWeightState state) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: WeightLineChartPainter(
          logs: state.logs,
          lineColor: AppColors.primary,
          gradientColor: AppColors.primary,
          gridColor: AppColors.border(context),
          labelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary(context)),
          emptyPlaceholderText: l10n.noWeightLogsInRange,
        ),
      ),
    );
  }
}
