import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

/// Third step in the onboarding flow: Activity Level & Estimated Daily Steps.
class OnboardingActivityStep extends StatelessWidget {
  final String activityLevel;
  final int estimatedSteps;
  final void Function({String? activityLevel, int? estimatedSteps}) onChanged;

  const OnboardingActivityStep({
    super.key,
    required this.activityLevel,
    required this.estimatedSteps,
    required this.onChanged,
  });

  static const List<Map<String, dynamic>> _activityOptions = [
    {
      'id': 'sedentary',
      'title': 'Sedentario',
      'subtitle': 'Oficina / poco o ningún ejercicio estructurado',
      'factor': '1.20x',
      'icon': Icons.weekend_outlined,
    },
    {
      'id': 'light',
      'title': 'Ligero',
      'subtitle': 'Caminatas o deporte ligero 1-3 días/semana',
      'factor': '1.375x',
      'icon': Icons.directions_walk_rounded,
    },
    {
      'id': 'moderate',
      'title': 'Moderado',
      'subtitle': 'Entrenamiento activo 3-5 días/semana',
      'factor': '1.55x',
      'icon': Icons.fitness_center_rounded,
    },
    {
      'id': 'very_active',
      'title': 'Muy Activo',
      'subtitle': 'Ejercicio intenso o físico 6-7 días/semana',
      'factor': '1.725x',
      'icon': Icons.sports_gymnastics_rounded,
    },
  ];

  static const List<int> _stepOptions = [6000, 8000, 10000, 12000, 15000];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            'Actividad y Movimiento Diario',
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
            'Selecciona el ritmo de tu rutina semanal para calcular tu gasto calórico real (TDEE).',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 24),

          // Activity options
          VeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NIVEL DE ACTIVIDAD',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 12),
                ..._activityOptions.map((opt) {
                  final isSelected = activityLevel == opt['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => onChanged(activityLevel: opt['id'] as String),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border(context),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.surface(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                opt['icon'] as IconData,
                                size: 20,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        opt['title'] as String,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? AppColors.primary : AppColors.textPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface(context),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.border(context)),
                                        ),
                                        child: Text(
                                          opt['factor'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opt['subtitle'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily steps chips
          VeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PASOS DIARIOS ESTIMADOS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    Text(
                      '${estimatedSteps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} pasos',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _stepOptions.map((steps) {
                    final isSelected = estimatedSteps == steps;
                    final formatted = steps.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (m) => '${m[1]},',
                        );
                    return ChoiceChip(
                      label: Text('$formatted pasos'),
                      selected: isSelected,
                      onSelected: (_) => onChanged(estimatedSteps: steps),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceSubtle(context),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border(context),
                      ),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary(context),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
