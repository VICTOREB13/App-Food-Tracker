import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/metabolic_calculator.dart';
import '../../services/secure_storage_service.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';
import 'master_prompt_bento_trigger.dart';
import 'master_prompt_bottom_sheet.dart';
import 'metabolic_stat_tile.dart';

class MetabolicSummaryBentoCard extends StatefulWidget {
  final UserProfile? profile;
  final bool isCalculating;

  const MetabolicSummaryBentoCard({super.key, required this.profile, this.isCalculating = false});

  @override
  State<MetabolicSummaryBentoCard> createState() => _MetabolicSummaryBentoCardState();
}

class _MetabolicSummaryBentoCardState extends State<MetabolicSummaryBentoCard> {
  void _copyPrompt() {
    HapticFeedback.selectionClick();
    if (widget.profile == null) return;
    final prompt = widget.profile!.masterPrompt ??
        MetabolicCalculator.generateMasterPrompt(widget.profile!);
    Clipboard.setData(ClipboardData(text: prompt));
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.promptCopiedToClipboard),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openPromptBottomSheet() {
    HapticFeedback.selectionClick();
    if (widget.profile == null) return;
    MasterPromptBottomSheet.show(
      context,
      profile: widget.profile!,
      onSaved: (newPrompt) async {
        await SecureStorageService.instance.setMasterPrompt(newPrompt);
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.customPromptSavedSuccess), backgroundColor: AppColors.protein),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = widget.profile;
    if (profile == null) {
      return VeCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(l10n.enterBiometricsToCalculate, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)))),
        ),
      );
    }

    final protCals = profile.targetProtein * 4.0;
    final carbCals = profile.targetCarbs * 4.0;
    final fatCals = profile.targetFat * 9.0;
    final totalMacroCals = protCals + carbCals + fatCals;
    final protRatio = totalMacroCals > 0 ? (protCals / totalMacroCals).clamp(0.0, 1.0) : 0.3;
    final carbRatio = totalMacroCals > 0 ? (carbCals / totalMacroCals).clamp(0.0, 1.0) : 0.4;
    final fatRatio = totalMacroCals > 0 ? (fatCals / totalMacroCals).clamp(0.0, 1.0) : 0.3;
    final genderText = profile.gender == 'female' ? l10n.genderFemale : l10n.genderMale;
    final hStr = (profile.height % 1 == 0) ? profile.height.toInt().toString() : profile.height.toString();
    final wStr = (profile.weight % 1 == 0) ? profile.weight.toInt().toString() : profile.weight.toString();
    final bioSummary = l10n.profileBioSummary(profile.age.toString(), hStr, wStr, genderText);

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 20, color: AppColors.carbs),
                  const SizedBox(width: 8),
                  Text(l10n.metabolicSummaryHeader, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondary(context))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.carbs.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.carbs.withValues(alpha: 0.3))),
                child: Text('Mifflin-St Jeor', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.carbs)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Biometrics Chip / Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border(context))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(bioSummary, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bento Hero Tile: Target Calories
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.surfaceSubtle(context)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.dailyTargetBudget, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(profile.targetCalories.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: AppColors.textPrimary(context))),
                        const SizedBox(width: 4),
                        Text(l10n.kcalPerDay, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.20), shape: BoxShape.circle),
                  child: const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Two Bento Tiles: BMR & TDEE
          Row(
            children: [
              Expanded(child: MetabolicStatTile(label: l10n.bmrAtRestLabel, value: '${profile.bmr.toStringAsFixed(0)} kcal')),
              const SizedBox(width: 10),
              Expanded(child: MetabolicStatTile(label: l10n.tdeeTotalExpenseLabel, value: '${profile.tdee.toStringAsFixed(0)} kcal')),
            ],
          ),
          const SizedBox(height: 14),
          // Macro Distribution Ratio Bar
          Text(l10n.macroDistributionTitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(flex: (protRatio * 100).toInt().clamp(1, 100), child: Container(color: AppColors.protein)),
                  const SizedBox(width: 2),
                  Expanded(flex: (carbRatio * 100).toInt().clamp(1, 100), child: Container(color: AppColors.carbs)),
                  const SizedBox(width: 2),
                  Expanded(flex: (fatRatio * 100).toInt().clamp(1, 100), child: Container(color: AppColors.fat)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Macro Breakdown 3 Cards
          Row(
            children: [
              Expanded(child: MetabolicMacroBadge(label: l10n.protein, grams: profile.targetProtein, calories: protCals, color: AppColors.protein)),
              const SizedBox(width: 8),
              Expanded(child: MetabolicMacroBadge(label: l10n.carbs, grams: profile.targetCarbs, calories: carbCals, color: AppColors.carbs)),
              const SizedBox(width: 8),
              Expanded(child: MetabolicMacroBadge(label: l10n.fat, grams: profile.targetFat, calories: fatCals, color: AppColors.fat)),
            ],
          ),
          // Master Prompt Section
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          MasterPromptBentoTrigger(
            onTap: _openPromptBottomSheet,
            onCopy: _copyPrompt,
          ),
        ],
      ),
    );
  }
}

