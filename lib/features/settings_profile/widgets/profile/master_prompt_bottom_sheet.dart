import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';
import 'package:food_tracker/features/biometrics_weight/services/metabolic_calculator.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';

/// Bottom sheet for inspecting and customizing the Master Prompt with Dark Bento summary.
class MasterPromptBottomSheet extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<String> onSaved;

  const MasterPromptBottomSheet({super.key, required this.profile, required this.onSaved});

  static Future<void> show(BuildContext context, {required UserProfile profile, required ValueChanged<String> onSaved}) {
    return showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: MasterPromptBottomSheet(profile: profile, onSaved: onSaved),
      ),
    );
  }

  @override
  State<MasterPromptBottomSheet> createState() => _MasterPromptBottomSheetState();
}

class _MasterPromptBottomSheetState extends State<MasterPromptBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final initial = widget.profile.masterPrompt ?? MetabolicCalculator.generateMasterPrompt(widget.profile);
    _promptController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: _promptController.text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Prompt copiado al portapapeles'), backgroundColor: AppColors.primary, duration: Duration(seconds: 2),
    ));
  }

  void _restoreDefault() {
    HapticFeedback.selectionClick();
    final defaultPrompt = MetabolicCalculator.generateMasterPrompt(widget.profile);
    setState(() => _promptController.text = defaultPrompt);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Prompt restablecido a valores predeterminados'), backgroundColor: AppColors.carbs, duration: Duration(seconds: 2),
    ));
  }

  void _savePrompt() {
    HapticFeedback.selectionClick();
    widget.onSaved(_promptController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.psychology_outlined, size: 22, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Prompt Maestro', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)))),
              IconButton(icon: const Icon(Icons.copy_rounded, size: 19), tooltip: 'Copiar', onPressed: () => _copyToClipboard(context)),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary, labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary(context),
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Resumen Bento'), Tab(text: 'Editor de Prompt')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildBentoSummaryTab(context), _buildEditorTab(context)],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoSummaryTab(BuildContext context) {
    final p = widget.profile;
    final genderStr = p.gender.toLowerCase().startsWith('m') ? 'Hombre' : 'Mujer';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildBentoCard(
                context, title: 'BIOMETRÍA', primaryValue: '${p.weight.toStringAsFixed(1)} kg',
                subtitle: '${p.age} años · $genderStr · ${p.height.toInt()} cm\nTMB: ${p.bmr.round()} kcal',
                accentColor: AppColors.protein,
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildBentoCard(
                context, title: 'GASTO TDEE', primaryValue: '${p.tdee.round()} kcal',
                subtitle: 'Nivel: ${p.activityLevel}\nPasos: ~${p.estimatedSteps}',
                accentColor: AppColors.primary,
              )),
            ],
          ),
          const SizedBox(height: 10),
          _buildBentoCard(
            context, title: 'PRESUPUESTO CALÓRICO', primaryValue: '${p.targetCalories.round()} kcal',
            subtitle: 'Objetivo metabólico: ${p.bodyGoal}', accentColor: AppColors.calories,
          ),
          const SizedBox(height: 10),
          _buildMacrosCard(context),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROMPT MULTIMODAL ACTIVO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context), letterSpacing: 0.4)),
              TextButton.icon(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
                onPressed: () => _copyToClipboard(context),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copiar prompt', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
            child: SelectableText(_promptController.text, style: GoogleFonts.robotoMono(fontSize: 11.5, height: 1.5, color: AppColors.textPrimary(context))),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBentoCard(BuildContext context, {
    required String title, required String primaryValue, required String subtitle, required Color accentColor,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: isDark ? 0.30 : 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text(primaryValue, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
          const SizedBox(height: 3),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context), height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildMacrosCard(BuildContext context) {
    final p = widget.profile;
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border(context))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISTRIBUCIÓN DE MACRONUTRIENTES', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context), letterSpacing: 0.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMacroMiniChip('Proteína', '${p.targetProtein.round()}g', AppColors.protein, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroMiniChip('Carbos', '${p.targetCarbs.round()}g', AppColors.carbs, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroMiniChip('Grasas', '${p.targetFat.round()}g', AppColors.fat, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroMiniChip(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.22)),
      ),
      child: Column(
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color))),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildEditorTab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Expanded(
            child: TextFormField(
              controller: _promptController, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.robotoMono(fontSize: 12, height: 1.45, color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.surfaceSubtle(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border(context))),
                hintText: l10n.aiVisionPromptHint,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restoreDefault,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border(context)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: Text(l10n.restoreDefaultPromptAction, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _savePrompt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: Text(l10n.savePromptAction, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
