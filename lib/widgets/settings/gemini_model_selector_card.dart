import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/gemini_model_info.dart';
import '../../services/gemini_model_service.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';
import 'model_picker_bottom_sheet.dart';

class GeminiModelSelectorCard extends StatelessWidget {
  final String? apiKey;
  final String? selectedModel;
  final List<GeminiModelInfo>? models;
  final bool isLoading;
  final bool isOnline;
  final ValueChanged<String>? onSelectModel;
  final Future<void> Function()? onRefresh;

  const GeminiModelSelectorCard({
    super.key,
    this.apiKey,
    this.selectedModel,
    this.models,
    this.isLoading = false,
    this.isOnline = false,
    this.onSelectModel,
    this.onRefresh,
  });

  Color _getBadgeColor(String? label) {
    if (label == null) return AppColors.primary;
    final lower = label.toLowerCase();
    if (lower.contains('think') || lower.contains('pro')) return AppColors.primary;
    if (lower.contains('fast') || lower.contains('flash')) return AppColors.protein;
    return AppColors.carbs;
  }

  String? _resolveBadgeLabel(GeminiModelInfo model) {
    final lower = model.name.toLowerCase();
    if (lower.contains('pro')) return 'Think';
    if (lower.contains('flash')) return 'Fast';
    if (model.recommendationLabel != null && model.recommendationLabel!.isNotEmpty) {
      return model.recommendationLabel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = apiKey != null && apiKey!.trim().isNotEmpty;

    if (!hasKey) {
      return VeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'MODELO DE IA',
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppColors.carbs),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ingresa tu Gemini API Key para descubrir y seleccionar modelos',
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final effectiveList = (models != null && models!.isNotEmpty)
        ? models!
        : GeminiModelService.fallbackModels;

    final effectiveSelected = (selectedModel != null && effectiveList.any((m) => m.name == selectedModel))
        ? selectedModel!
        : effectiveList.first.name;

    final currentModelInfo = effectiveList.firstWhere(
      (m) => m.name == effectiveSelected,
      orElse: () => effectiveList.first,
    );

    final activeBadge = _resolveBadgeLabel(currentModelInfo);
    final activeBadgeColor = _getBadgeColor(activeBadge);

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MODELO DE IA',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondary(context)),
                ),
              ),
              if (isLoading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Actualizar modelos',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppColors.textSecondary(context),
                  onPressed: onRefresh,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: isOnline ? AppColors.protein : AppColors.carbs)),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'Modelos en línea desde Google AI Studio' : 'Modo offline (modelos por defecto)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: isOnline ? AppColors.protein : AppColors.carbs),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Active Model Details Panel (tap opens picker modal)
          InkWell(
            onTap: () async {
              final selected = await ModelPickerBottomSheet.show(
                context,
                currentModel: effectiveSelected,
                models: effectiveList,
              );
              if (selected != null && onSelectModel != null) {
                onSelectModel!(selected);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          currentModelInfo.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                        ),
                      ),
                      if (activeBadge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: activeBadgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: activeBadgeColor.withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: Text(activeBadge, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: activeBadgeColor)),
                        ),
                      ],
                    ],
                  ),
                  if (currentModelInfo.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      currentModelInfo.description,
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context), height: 1.3),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ID: ${currentModelInfo.name}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted(context)),
                        ),
                      ),
                      if (currentModelInfo.inputTokenLimit > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Ventana: ${(currentModelInfo.inputTokenLimit / 1024).round()}k tokens',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Interactive Modal Selector Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final selected = await ModelPickerBottomSheet.show(
                  context,
                  currentModel: effectiveSelected,
                  models: effectiveList,
                );
                if (selected != null && onSelectModel != null) {
                  onSelectModel!(selected);
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
              label: Text('Explorar y Cambiar Modelo', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

