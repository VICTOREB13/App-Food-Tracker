import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/metabolic_calculator.dart';
import '../../services/theme_manager.dart';

/// Bottom sheet for inspecting and customizing the Master Prompt.
class MasterPromptBottomSheet extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<String> onSaved;

  const MasterPromptBottomSheet({
    super.key,
    required this.profile,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
    required ValueChanged<String> onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: MasterPromptBottomSheet(profile: profile, onSaved: onSaved),
      ),
    );
  }

  @override
  State<MasterPromptBottomSheet> createState() => _MasterPromptBottomSheetState();
}

class _MasterPromptBottomSheetState extends State<MasterPromptBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    final initial = widget.profile.masterPrompt ??
        MetabolicCalculator.generateMasterPrompt(widget.profile);
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
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.promptCopiedToClipboard),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _restoreDefault() {
    HapticFeedback.selectionClick();
    final defaultPrompt = MetabolicCalculator.generateMasterPrompt(widget.profile);
    setState(() => _promptController.text = defaultPrompt);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.promptResetSuccess),
        backgroundColor: AppColors.carbs,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _savePrompt() {
    HapticFeedback.selectionClick();
    final updatedText = _promptController.text.trim();
    widget.onSaved(updatedText);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.psychology_outlined, size: 22, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.multimodalMasterPrompt,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 19),
                tooltip: l10n.shareReportAction,
                onPressed: () => _copyToClipboard(context),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary(context),
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: l10n.previewTabTitle),
            Tab(text: l10n.editorTabTitle),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPreviewTab(context),
              _buildEditorTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('TDEE', '${widget.profile.tdee.round()} kcal', AppColors.primary),
                _buildMetricCol('META', '${widget.profile.targetCalories.round()} kcal', AppColors.calories),
                _buildMetricCol('PROT', '${widget.profile.targetProtein.round()}g', AppColors.protein),
                _buildMetricCol('GRASAS', '${widget.profile.targetFat.round()}g', AppColors.fat),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SelectableText(
            _promptController.text,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 24),
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
              controller: _promptController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceSubtle(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
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
                    side: BorderSide(color: AppColors.border(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: Text(
                    l10n.restoreDefaultPromptAction,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _savePrompt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: Text(
                    l10n.savePromptAction,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
