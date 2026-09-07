import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class MetabolicSummaryBentoCard extends StatefulWidget {
  final UserProfile? profile;
  final bool isCalculating;

  const MetabolicSummaryBentoCard({
    super.key,
    required this.profile,
    this.isCalculating = false,
  });

  @override
  State<MetabolicSummaryBentoCard> createState() => _MetabolicSummaryBentoCardState();
}

class _MetabolicSummaryBentoCardState extends State<MetabolicSummaryBentoCard> {
  bool _showPromptDetails = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    if (profile == null) {
      return VeCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Ingresa tus datos biométricos para calcular el perfil',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
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

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 20, color: AppColors.carbs),
                  const SizedBox(width: 8),
                  Text(
                    'RESUMEN METABÓLICO',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.carbs.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.carbs.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Mifflin-St Jeor',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.carbs,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bento Hero Tile: Target Calories
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.surfaceSubtle(context),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRESUPUESTO DIARIO OBJETIVO',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          profile.targetCalories.toStringAsFixed(0),
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kcal/día',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Two Bento Tiles: BMR & TDEE
          Row(
            children: [
              // BMR Tile
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border(context),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TMB (En reposo)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            profile.bmr.toStringAsFixed(0),
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'kcal',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // TDEE Tile
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border(context),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TDEE (Gasto total)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            profile.tdee.toStringAsFixed(0),
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'kcal',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Macro Distribution Title & Visual Ratio Bar
          Text(
            'Distribución de Macronutrientes',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),

          // Multi-color ratio bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (protRatio * 100).toInt().clamp(1, 100),
                    child: Container(color: AppColors.protein),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (carbRatio * 100).toInt().clamp(1, 100),
                    child: Container(color: AppColors.carbs),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (fatRatio * 100).toInt().clamp(1, 100),
                    child: Container(color: AppColors.fat),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Macro Breakdown 3 Cards
          Row(
            children: [
              Expanded(
                child: _buildMacroBadge(
                  label: 'Proteínas',
                  grams: profile.targetProtein,
                  calories: protCals,
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBadge(
                  label: 'Carbohidratos',
                  grams: profile.targetCarbs,
                  calories: carbCals,
                  color: AppColors.carbs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBadge(
                  label: 'Grasas',
                  grams: profile.targetFat,
                  calories: fatCals,
                  color: AppColors.fat,
                ),
              ),
            ],
          ),

          // Master Prompt Expandable Section
          if (profile.masterPrompt != null && profile.masterPrompt!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _showPromptDetails = !_showPromptDetails),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_outlined, size: 16, color: AppColors.primaryLight),
                        const SizedBox(width: 6),
                        Text(
                          'Master Prompt IA Multimodal (Generado)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _showPromptDetails ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.textSecondary(context),
                    ),
                  ],
                ),
              ),
            ),
            if (_showPromptDetails) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: SelectableText(
                  profile.masterPrompt!,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10.5,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMacroBadge({
    required String label,
    required double grams,
    required double calories,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                grams.toStringAsFixed(0),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'g',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          Text(
            '${calories.toStringAsFixed(0)} kcal',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              color: AppColors.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}
