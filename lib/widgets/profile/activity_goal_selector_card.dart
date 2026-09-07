import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class ActivityGoalSelectorCard extends StatefulWidget {
  final String initialActivityLevel;
  final String initialBodyGoal;
  final int initialEstimatedSteps;
  final void Function({
    String? activityLevel,
    String? bodyGoal,
    int? estimatedSteps,
  }) onChanged;

  const ActivityGoalSelectorCard({
    super.key,
    required this.initialActivityLevel,
    required this.initialBodyGoal,
    required this.initialEstimatedSteps,
    required this.onChanged,
  });

  @override
  State<ActivityGoalSelectorCard> createState() => _ActivityGoalSelectorCardState();
}

class _ActivityGoalSelectorCardState extends State<ActivityGoalSelectorCard> {
  late String _selectedActivity;
  late String _selectedGoal;
  late final TextEditingController _stepsController;

  static const List<Map<String, String>> _activityOptions = [
    {
      'key': 'sedentary',
      'title': 'Sedentario (1.2x)',
      'subtitle': 'Trabajo de escritorio, sin ejercicio formal',
      'badge': '1.2x',
    },
    {
      'key': 'light',
      'title': 'Ligero (1.375x)',
      'subtitle': 'Caminatas o actividad ligera 1-3 días/sem',
      'badge': '1.375x',
    },
    {
      'key': 'moderate',
      'title': 'Moderado (1.55x)',
      'subtitle': 'Entrenamiento de fuerza o cardio 3-5 días/sem',
      'badge': '1.55x',
    },
    {
      'key': 'very_active',
      'title': 'Muy Activo (1.725x)',
      'subtitle': 'Atleta o entrenamiento pesado 6-7 días/sem',
      'badge': '1.725x',
    },
  ];

  static const List<Map<String, String>> _goalOptions = [
    {
      'key': 'fat_loss',
      'title': 'Pérdida de Grasa',
      'delta': '-500 kcal',
      'desc': 'Déficit calórico clínico con piso de protección en TMB',
    },
    {
      'key': 'maintenance',
      'title': 'Mantenimiento',
      'delta': 'Normocalórico',
      'desc': 'Balance energético total para recomposición o sostén',
    },
    {
      'key': 'muscle_gain',
      'title': 'Ganancia Muscular',
      'delta': '+300 kcal',
      'desc': 'Superávit calórico controlado para hipertrofia magra',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedActivity = widget.initialActivityLevel;
    _selectedGoal = widget.initialBodyGoal;
    _stepsController = TextEditingController(
      text: widget.initialEstimatedSteps > 0 ? widget.initialEstimatedSteps.toString() : '8000',
    );
  }

  @override
  void didUpdateWidget(covariant ActivityGoalSelectorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialActivityLevel != widget.initialActivityLevel &&
        _selectedActivity != widget.initialActivityLevel) {
      _selectedActivity = widget.initialActivityLevel;
    }
    if (oldWidget.initialBodyGoal != widget.initialBodyGoal &&
        _selectedGoal != widget.initialBodyGoal) {
      _selectedGoal = widget.initialBodyGoal;
    }
    if (oldWidget.initialEstimatedSteps != widget.initialEstimatedSteps &&
        int.tryParse(_stepsController.text) != widget.initialEstimatedSteps) {
      _stepsController.text = widget.initialEstimatedSteps.toString();
    }
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    final steps = int.tryParse(_stepsController.text.trim()) ?? widget.initialEstimatedSteps;
    widget.onChanged(
      activityLevel: _selectedActivity,
      bodyGoal: _selectedGoal,
      estimatedSteps: steps,
    );
  }

  void _selectActivity(String key) {
    if (_selectedActivity == key) return;
    setState(() => _selectedActivity = key);
    _notifyChanges();
  }

  void _selectGoal(String key) {
    if (_selectedGoal == key) return;
    setState(() => _selectedGoal = key);
    _notifyChanges();
  }

  @override
  Widget build(BuildContext context) {
    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded, size: 20, color: AppColors.protein),
              const SizedBox(width: 8),
              Text(
                'ACTIVIDAD Y OBJETIVO',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Activity Level
          Text(
            'Nivel de Actividad Física (Multiplicador TDEE)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          ..._activityOptions.map((opt) {
            final isSelected = _selectedActivity == opt['key'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildActivityTile(
                title: opt['title']!,
                subtitle: opt['subtitle']!,
                badge: opt['badge']!,
                isSelected: isSelected,
                onTap: () => _selectActivity(opt['key']!),
              ),
            );
          }),
          const SizedBox(height: 12),

          // Body Goal
          Text(
            'Objetivo Corporal',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          ..._goalOptions.map((opt) {
            final isSelected = _selectedGoal == opt['key'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildGoalTile(
                title: opt['title']!,
                delta: opt['delta']!,
                desc: opt['desc']!,
                isSelected: isSelected,
                onTap: () => _selectGoal(opt['key']!),
              ),
            );
          }),
          const SizedBox(height: 12),

          // Daily steps estimation
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasos Diarios Estimados',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Para calibración de gasto NEAT',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _stepsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _notifyChanges(),
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
                  decoration: const InputDecoration(
                    hintText: '8000',
                    suffixText: 'pasos',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required String title,
    required String subtitle,
    required String badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? AppColors.protein : AppColors.border(context);
    final bgColor = isSelected
        ? AppColors.protein.withValues(alpha: 0.10)
        : AppColors.surfaceSubtle(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: isSelected ? AppColors.protein : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTile({
    required String title,
    required String delta,
    required String desc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border(context);
    final bgColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.10)
        : AppColors.surfaceSubtle(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.20)
                              : AppColors.border(context).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          delta,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
