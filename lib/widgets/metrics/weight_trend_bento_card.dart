import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/weight_log.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';
import 'weight_line_chart_painter.dart';

class WeightTrendBentoCard extends StatelessWidget {
  final List<WeightLog> logs;
  final VoidCallback? onAddWeight;

  const WeightTrendBentoCard({
    super.key,
    required this.logs,
    this.onAddWeight,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = logs.isNotEmpty;
    final sorted = List<WeightLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    final currentWeight = hasData ? sorted.last.weight : null;
    final startWeight = hasData ? sorted.first.weight : null;
    final double? delta = (currentWeight != null && startWeight != null && sorted.length >= 2)
        ? currentWeight - startWeight
        : null;

    final IconData trendIcon;
    final Color trendColor;
    if (delta == null) {
      trendIcon = Icons.trending_flat;
      trendColor = AppColors.textSecondary(context);
    } else if (delta < -0.05) {
      trendIcon = Icons.trending_down;
      trendColor = AppColors.protein;
    } else if (delta > 0.05) {
      trendIcon = Icons.trending_up;
      trendColor = AppColors.carbs;
    } else {
      trendIcon = Icons.trending_flat;
      trendColor = AppColors.textSecondary(context);
    }

    return VeCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'TENDENCIA DE PESO',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Stats Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Current Weight
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PESO ACTUAL',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currentWeight != null
                            ? currentWeight.toStringAsFixed(1)
                            : '--',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'kg',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Start Weight (if >= 2 logs)
              if (startWeight != null && sorted.length >= 2) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INICIO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${startWeight.toStringAsFixed(1)} kg',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
              ],

              // Net Delta
              if (delta != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, size: 16, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // CustomPainter Chart Container
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(
              painter: WeightLineChartPainter(
                logs: logs,
                lineColor: AppColors.primary,
                gradientColor: AppColors.primary,
                gridColor: AppColors.border(context),
                labelStyle: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
