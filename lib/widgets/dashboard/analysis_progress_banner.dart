import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/meal.dart';
import '../../services/analysis_queue_service.dart';
import '../../services/theme_manager.dart';
import '../common/ve_loading_ring.dart';

class AnalysisProgressBanner extends StatelessWidget {
  final void Function(Meal meal) onOpenMeal;

  const AnalysisProgressBanner({
    super.key,
    required this.onOpenMeal,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AnalysisQueueService.instance,
      builder: (context, _) {
        final task = AnalysisQueueService.instance.currentActiveTask ??
            AnalysisQueueService.instance.latestCompletedTask;

        if (task == null) return const SizedBox.shrink();

        final isPending = task.isPending;
        final isCompleted = task.status == AnalysisStatus.completed;
        final isFailed = task.status == AnalysisStatus.failed;

        final hasImage = File(task.imagePath).existsSync();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.12)
                : isFailed
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.40)
                  : isFailed
                      ? AppColors.primary.withValues(alpha: 0.40)
                      : AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. Mini-thumbnail o Anillo de Carga
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.file(
                        File(task.imagePath),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                      if (isPending)
                        Container(
                          width: 44,
                          height: 44,
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: VeLoadingRing(
                            size: 26,
                            strokeWidth: 2.8,
                            color: Colors.white,
                            progress: task.progress,
                          ),
                        ),
                    ],
                  ),
                )
              else if (isPending)
                VeLoadingRing(
                  size: 34,
                  strokeWidth: 3.5,
                  color: AppColors.primary,
                  progress: task.progress,
                )
              else
                Icon(
                  isCompleted
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: isCompleted ? AppColors.success : AppColors.primary,
                  size: 32,
                ),
              const SizedBox(width: 12),

              // 2. Información del estado y barra
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isCompleted
                                ? (task.resultMeal?.name ?? '¡Comida analizada!')
                                : isFailed
                                    ? 'Error en el análisis'
                                    : 'Analizando en segundo plano',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? AppColors.success
                                  : isFailed
                                      ? AppColors.primary
                                      : AppColors.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPending)
                          Text(
                            '${(task.progress * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isCompleted
                          ? '${task.resultMeal?.calories.toInt() ?? 0} kcal · ${task.resultMeal?.items.length ?? 0} ingredientes'
                          : isFailed
                              ? (task.error ?? 'Ocurrió un error inesperado')
                              : task.stage,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: task.progress,
                          minHeight: 4,
                          backgroundColor:
                              AppColors.border(context).withValues(alpha: 0.3),
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3. Botones de acción
              if (isCompleted && task.resultMeal != null)
                IconButton(
                  tooltip: 'Abrir plato',
                  icon: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppColors.success),
                  onPressed: () {
                    final meal = task.resultMeal!;
                    AnalysisQueueService.instance.dismissTask(task.id);
                    onOpenMeal(meal);
                  },
                )
              else
                IconButton(
                  tooltip: 'Cerrar',
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textMuted(context)),
                  onPressed: () {
                    AnalysisQueueService.instance.dismissTask(task.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
