import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

/// Fourth step in the onboarding flow: Body Goal & Live Metabolic Summary.
class OnboardingGoalStep extends StatelessWidget {
  final String bodyGoal;
  final ValueChanged<String> onGoalChanged;
  final UserProfile profile;

  const OnboardingGoalStep({
    super.key,
    required this.bodyGoal,
    required this.onGoalChanged,
    required this.profile,
  });

  static const List<Map<String, dynamic>> _goalOptions = [
    {
      'id': 'fat_loss',
      'title': 'Pérdida de Grasa',
      'delta': '-500 kcal',
      'desc': 'Déficit óptimo para quemar grasa preservando músculo',
      'icon': Icons.local_fire_department_rounded,
      'color': AppColors.calories,
    },
    {
      'id': 'maintenance',
      'title': 'Mantenimiento',
      'delta': 'Normocalórico',
      'desc': 'Mantener peso y composición corporal actual',
      'icon': Icons.balance_rounded,
      'color': AppColors.carbs,
    },
    {
      'id': 'muscle_gain',
      'title': 'Ganancia Muscular',
      'delta': '+300 kcal',
      'desc': 'Superávit limpio para favorecer síntesis proteica',
      'icon': Icons.fitness_center_rounded,
      'color': AppColors.protein,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final genderStr = profile.gender == 'male' ? 'Masculino' : 'Femenino';
    final biometricsPill = '${profile.age} años • ${profile.height.toStringAsFixed(0)} cm • ${profile.weight.toStringAsFixed(1)} kg • $genderStr';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            'Objetivo y Plan Metabólico',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajustamos tu ingesta diaria para alcanzar tu meta de composición corporal.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 20),

          // Goal selection options
          ..._goalOptions.map((opt) {
            final isSelected = bodyGoal == opt['id'];
            final optColor = opt['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onGoalChanged(opt['id'] as String),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? optColor.withValues(alpha: 0.12) : AppColors.surfaceSubtle(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? optColor : AppColors.border(context), width: isSelected ? 1.5 : 1.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: optColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Icon(opt['icon'] as IconData, size: 20, color: optColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(opt['title'] as String, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? optColor : AppColors.textPrimary(context))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: optColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                  child: Text(opt['delta'] as String, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: optColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(opt['desc'] as String, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
                          ],
                        ),
                      ),
                      if (isSelected) Icon(Icons.check_circle_rounded, size: 20, color: optColor),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),

          // Live calculated Bento Summary
          VeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 18, color: AppColors.calories),
                    const SizedBox(width: 6),
                    Text('RESUMEN METABÓLICO EN VIVO', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondary(context))),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border(context))),
                  child: Text(biometricsPill, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary(context))),
                ),
                const SizedBox(height: 16),

                // Target Calories Hero Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('META CALÓRICA DIARIA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(profile.targetCalories.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary(context), letterSpacing: -1.0)),
                          const SizedBox(width: 4),
                          Text('kcal / día', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('BMR: ${profile.bmr.toStringAsFixed(0)} kcal • TDEE: ${profile.tdee.toStringAsFixed(0)} kcal', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted(context))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Macros 3-Column Breakdown
                Row(
                  children: [
                    Expanded(child: _buildMacroItem(context, label: 'Proteínas', grams: profile.targetProtein, color: AppColors.protein)),
                    Container(width: 1, height: 44, color: AppColors.border(context)),
                    Expanded(child: _buildMacroItem(context, label: 'Carbos', grams: profile.targetCarbs, color: AppColors.carbs)),
                    Container(width: 1, height: 44, color: AppColors.border(context)),
                    Expanded(child: _buildMacroItem(context, label: 'Grasas', grams: profile.targetFat, color: AppColors.fat)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(
    BuildContext context, {
    required String label,
    required double grams,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(grams.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
            const SizedBox(width: 2),
            Text('g', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
          ],
        ),
      ],
    );
  }
}

