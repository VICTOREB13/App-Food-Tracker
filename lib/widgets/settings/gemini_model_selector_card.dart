import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/gemini_model_info.dart';
import '../../services/gemini_model_service.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

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
    if (label.contains('Ultrarrápido') || label.contains('RECOMENDADO')) {
      return AppColors.protein;
    }
    if (label.contains('Alta Velocidad') || label.contains('ESTABLE')) {
      return AppColors.fat;
    }
    if (label.contains('Razonamiento') || label.contains('PRECISIÓN')) {
      return AppColors.primary;
    }
    return AppColors.carbs;
  }

  String? _resolveBadgeLabel(GeminiModelInfo model) {
    if (model.recommendationLabel != null && model.recommendationLabel!.isNotEmpty) {
      return model.recommendationLabel;
    }
    final lower = model.name.toLowerCase();
    if (lower.contains('2.5-flash') || (lower.contains('3') && lower.contains('flash'))) {
      return 'RECOMENDADO (Ultrarrápido)';
    }
    if (lower.contains('2.0-flash')) {
      return 'ESTABLE (Alta Velocidad)';
    }
    if (lower.contains('2.5-pro') || (lower.contains('3') && lower.contains('pro'))) {
      return 'MÁXIMA PRECISIÓN (Razonamiento)';
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
                  'MODELO DE IA (VISIÓN)',
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
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
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
                  'MODELO DE IA (VISIÓN)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
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
          // Live status row
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.protein : AppColors.carbs,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline
                    ? 'Modelos en línea desde Google AI Studio'
                    : 'Modo offline (modelos por defecto)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isOnline ? AppColors.protein : AppColors.carbs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dropdown selector
          DropdownButtonFormField<String>(
            value: effectiveSelected,
            isExpanded: true,
            dropdownColor: AppColors.surface(context),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
            ),
            items: effectiveList.map((model) {
              final badge = _resolveBadgeLabel(model);
              final badgeColor = _getBadgeColor(badge);

              return DropdownMenuItem<String>(
                value: model.name,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        model.displayName.isNotEmpty ? model.displayName : model.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null && onSelectModel != null) {
                onSelectModel!(val);
              }
            },
          ),
          const SizedBox(height: 12),
          // Active Model Details Panel
          Container(
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
                  children: [
                    Text(
                      currentModelInfo.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    if (activeBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: activeBadgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: activeBadgeColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          activeBadge,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: activeBadgeColor,
                          ),
                        ),
                      ),
                  ],
                ),
                if (currentModelInfo.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    currentModelInfo.description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'ID: ${currentModelInfo.name}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted(context),
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (currentModelInfo.inputTokenLimit > 0) ...[
                      const Spacer(),
                      Text(
                        'Ventana: ${(currentModelInfo.inputTokenLimit / 1024).round()}k tokens',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
