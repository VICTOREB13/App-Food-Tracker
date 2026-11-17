import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/core/models/gemini_model_info.dart';
import 'package:food_tracker/core/services/ai/gemini_model_service.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'package:food_tracker/core/ui/components/ve_card.dart';
import 'model_picker_bottom_sheet.dart';

class GeminiModelSelectorCard extends StatefulWidget {
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

  @override
  State<GeminiModelSelectorCard> createState() => _GeminiModelSelectorCardState();
}

class _GeminiModelSelectorCardState extends State<GeminiModelSelectorCard> {
  String _thinkingLevel = 'MEDIUM';
  int _maxOutputTokens = 16384;

  static const List<String> _thinkingLevels = ['OFF', 'LOW', 'MEDIUM', 'HIGH', 'XHIGH'];
  static const Map<String, int> _outputTokenOptions = {'4k': 4096, '8k': 8192, '16k': 16384};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final level = await SecureStorageService.instance.getThinkingLevel();
    final tokens = await SecureStorageService.instance.getMaxOutputTokens();
    if (mounted) {
      setState(() {
        if (level != null && _thinkingLevels.contains(level)) {
          _thinkingLevel = level;
        }
        if (tokens != null) {
          _maxOutputTokens = tokens;
        }
      });
    }
  }

  Future<void> _updateThinkingLevel(String level) async {
    setState(() => _thinkingLevel = level);
    await SecureStorageService.instance.setThinkingLevel(level);
  }

  Future<void> _updateMaxOutputTokens(int tokens) async {
    setState(() => _maxOutputTokens = tokens);
    await SecureStorageService.instance.setMaxOutputTokens(tokens);
  }

  Color _getBadgeColor(String? label) {
    if (label == null) {
      return AppColors.primary;
    }
    final lower = label.toLowerCase();
    if (lower.contains('think') || lower.contains('pro')) {
      return AppColors.primary;
    }
    if (lower.contains('fast') || lower.contains('flash')) {
      return AppColors.protein;
    }
    return AppColors.carbs;
  }

  String? _resolveBadgeLabel(GeminiModelInfo model) {
    final lower = model.name.toLowerCase();
    if (lower.contains('pro')) {
      return 'Think';
    }
    if (lower.contains('flash')) {
      return 'Fast';
    }
    if (model.recommendationLabel != null && model.recommendationLabel!.isNotEmpty) {
      return model.recommendationLabel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasKey = widget.apiKey != null && widget.apiKey!.trim().isNotEmpty;

    if (!hasKey) {
      return VeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.psychology_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(l10n.aiModelHeader, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondary(context))),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border(context))),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 20, color: AppColors.carbs),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.enterGeminiKeyToSelect, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500))),
              ]),
            ),
          ],
        ),
      );
    }

    final effectiveList = (widget.models != null && widget.models!.isNotEmpty) ? widget.models! : GeminiModelService.fallbackModels;
    final effectiveSelected = (widget.selectedModel != null && effectiveList.any((m) => m.name == widget.selectedModel)) ? widget.selectedModel! : effectiveList.first.name;
    final currentModelInfo = effectiveList.firstWhere((m) => m.name == effectiveSelected, orElse: () => effectiveList.first);
    final activeBadge = _resolveBadgeLabel(currentModelInfo);
    final activeBadgeColor = _getBadgeColor(activeBadge);

    final inputLimit = currentModelInfo.inputTokenLimit > 0 ? currentModelInfo.inputTokenLimit : 1048576;
    final contextRatio = (2100 / inputLimit).clamp(0.001, 1.0);

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.aiModelHeader, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondary(context)))),
              if (widget.isLoading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              else
                IconButton(icon: const Icon(Icons.refresh, size: 18), tooltip: l10n.refreshModelsTooltip, padding: EdgeInsets.zero, constraints: const BoxConstraints(), color: AppColors.textSecondary(context), onPressed: widget.onRefresh),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.isOnline ? AppColors.protein : AppColors.carbs)),
            const SizedBox(width: 6),
            Text(widget.isOnline ? l10n.onlineModelsFromStudio : l10n.offlineModeDefaultModels, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: widget.isOnline ? AppColors.protein : AppColors.carbs)),
          ]),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final selected = await ModelPickerBottomSheet.show(context, currentModel: effectiveSelected, models: effectiveList);
              if (selected != null && widget.onSelectModel != null) {
                widget.onSelectModel!(selected);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border(context))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(currentModelInfo.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)))),
                    if (activeBadge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: activeBadgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: activeBadgeColor.withValues(alpha: 0.3), width: 0.5)),
                        child: Text(activeBadge, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: activeBadgeColor)),
                      ),
                    ],
                  ]),
                  if (currentModelInfo.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(currentModelInfo.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context), height: 1.3)),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: Text('ID: ${currentModelInfo.name}', overflow: TextOverflow.ellipsis, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted(context)))),
                    Text('~2.1k / ${(inputLimit / 1024).round()}k tokens', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(value: contextRatio, minHeight: 3, backgroundColor: AppColors.border(context), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('NIVEL DE PENSAMIENTO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textSecondary(context))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _thinkingLevels.map((lvl) {
              final isSel = _thinkingLevel == lvl;
              return ChoiceChip(
                label: Text(lvl, style: GoogleFonts.inter(fontSize: 10, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : AppColors.textSecondary(context))),
                selected: isSel, onSelected: (_) => _updateThinkingLevel(lvl),
                selectedColor: AppColors.primary, backgroundColor: AppColors.surfaceSubtle(context),
                side: BorderSide(color: isSel ? AppColors.primary : AppColors.border(context)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                visualDensity: VisualDensity.compact, showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text('TOKENS MÁXIMOS DE SALIDA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textSecondary(context))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _outputTokenOptions.entries.map((entry) {
              final isSel = _maxOutputTokens == entry.value;
              return ChoiceChip(
                label: Text(entry.key, style: GoogleFonts.inter(fontSize: 10, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : AppColors.textSecondary(context))),
                selected: isSel, onSelected: (_) => _updateMaxOutputTokens(entry.value),
                selectedColor: AppColors.protein, backgroundColor: AppColors.surfaceSubtle(context),
                side: BorderSide(color: isSel ? AppColors.protein : AppColors.border(context)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                visualDensity: VisualDensity.compact, showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final selected = await ModelPickerBottomSheet.show(context, currentModel: effectiveSelected, models: effectiveList);
                if (selected != null && widget.onSelectModel != null) {
                  widget.onSelectModel!(selected);
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border(context)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
              label: Text(l10n.exploreAndChangeModel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
