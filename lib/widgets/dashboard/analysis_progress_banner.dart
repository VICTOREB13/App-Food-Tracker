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

  void _handleManualEdit(BuildContext context, AnalysisTask task) {
    final meal = AnalysisQueueService.instance.createManualMealFromFailedTask(task.id) ??
        Meal(
          id: task.id,
          name: 'Comida sin clasificar',
          mealType: task.mealType,
          date: task.date,
          imagePath: task.imagePath.isNotEmpty ? task.imagePath : null,
          calories: 0.0,
          protein: 0.0,
          carbs: 0.0,
          fat: 0.0,
          notes: task.userContext,
        );
    AnalysisQueueService.instance.dismissTask(task.id);
    onOpenMeal(meal);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AnalysisQueueService.instance,
      builder: (context, _) {
        final tasks = AnalysisQueueService.instance.visibleTasks;
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: tasks.map((task) => _buildTaskCard(context, task)).toList(),
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, AnalysisTask task) {
    final isPending = task.isPending;
    final isCompleted = task.status == AnalysisStatus.completed;
    final isFailed = task.status == AnalysisStatus.failed;
    final hasImage = task.imagePath.isNotEmpty && File(task.imagePath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withValues(alpha: 0.12)
            : isFailed
                ? AppColors.primary.withValues(alpha: 0.10)
                : AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.40)
              : isFailed
                  ? AppColors.primary.withValues(alpha: 0.35)
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(task, hasImage, isPending, isCompleted, isFailed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isCompleted
                                ? (task.resultMeal?.name ?? '¡Comida analizada!')
                                : isFailed
                                    ? 'No se pudo analizar la foto'
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
                              ? (task.error ?? 'Error de conexión o análisis con IA.')
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
                          backgroundColor: AppColors.border(context).withValues(alpha: 0.3),
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildRightAction(task, isCompleted),
            ],
          ),
          if (isFailed) _buildFailedActions(context, task),
        ],
      ),
    );
  }

  Widget _buildThumbnail(
    AnalysisTask task,
    bool hasImage,
    bool isPending,
    bool isCompleted,
    bool isFailed,
  ) {
    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.file(File(task.imagePath), width: 44, height: 44, fit: BoxFit.cover),
            if (isPending)
              Container(
                width: 44,
                height: 44,
                color: Colors.black.withValues(alpha: 0.45),
                alignment: Alignment.center,
                child: VeLoadingRing(size: 26, strokeWidth: 2.8, color: Colors.white, progress: task.progress),
              )
            else if (isFailed)
              Container(
                width: 44,
                height: 44,
                color: Colors.black.withValues(alpha: 0.40),
                alignment: Alignment.center,
                child: const Icon(Icons.error_outline_rounded, color: AppColors.primary, size: 22),
              ),
          ],
        ),
      );
    }
    if (isPending) {
      return VeLoadingRing(size: 34, strokeWidth: 3.5, color: AppColors.primary, progress: task.progress);
    }
    return Icon(
      isCompleted ? Icons.check_circle_outline : Icons.error_outline_rounded,
      color: isCompleted ? AppColors.success : AppColors.primary,
      size: 32,
    );
  }

  Widget _buildRightAction(AnalysisTask task, bool isCompleted) {
    if (isCompleted && task.resultMeal != null) {
      return IconButton(
        tooltip: 'Abrir plato',
        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.success),
        onPressed: () {
          final meal = task.resultMeal!;
          AnalysisQueueService.instance.dismissTask(task.id);
          onOpenMeal(meal);
        },
      );
    }
    return IconButton(
      tooltip: 'Cerrar',
      icon: const Icon(Icons.close_rounded, size: 16),
      onPressed: () => AnalysisQueueService.instance.dismissTask(task.id),
    );
  }

  Widget _buildFailedActions(BuildContext context, AnalysisTask task) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary(context),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 16),
            label: Text('Editar manualmente', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            onPressed: () => _handleManualEdit(context, task),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text('Reintentar', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => AnalysisQueueService.instance.retryTask(task.id),
          ),
        ],
      ),
    );
  }
}
