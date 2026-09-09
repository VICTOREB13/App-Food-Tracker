import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/weight_log.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

/// Bento card displaying the recent weight log history with dates, values, and notes.
class WeightHistoryBentoCard extends StatefulWidget {
  final List<WeightLog> logs;

  const WeightHistoryBentoCard({
    super.key,
    required this.logs,
  });

  @override
  State<WeightHistoryBentoCard> createState() => _WeightHistoryBentoCardState();
}

class _WeightHistoryBentoCardState extends State<WeightHistoryBentoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sortedLogs = List<WeightLog>.from(widget.logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    final displayLogs = _expanded ? sortedLogs : sortedLogs.take(4).toList();

    return VeCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
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
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'HISTORIAL DE PESO',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              Text(
                '${sortedLogs.length} ${sortedLogs.length == 1 ? 'registro' : 'registros'}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (sortedLogs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Sin registros de peso en este período.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayLogs.length,
              separatorBuilder: (_, __) => Divider(
                color: AppColors.border(context),
                height: 16,
              ),
              itemBuilder: (context, index) {
                final log = displayLogs[index];
                final dateStr = DateFormat('EEE, d MMM yyyy', 'es').format(log.date);
                final hasNotes = log.notes != null && log.notes!.trim().isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              log.weight.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'kg',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (hasNotes) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 13,
                            color: AppColors.textMuted(context),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              log.notes!.trim(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary(context),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),

            if (sortedLogs.length > 4) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _expanded ? 'Ver menos' : 'Ver todos (${sortedLogs.length})',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
