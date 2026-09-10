import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';
import '../common/ve_logo.dart';

/// First step in the onboarding flow: Welcome & User Name.
class OnboardingWelcomeStep extends StatefulWidget {
  final String name;
  final ValueChanged<String> onNameChanged;

  const OnboardingWelcomeStep({
    super.key,
    required this.name,
    required this.onNameChanged,
  });

  @override
  State<OnboardingWelcomeStep> createState() => _OnboardingWelcomeStepState();
}

class _OnboardingWelcomeStepState extends State<OnboardingWelcomeStep> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(covariant OnboardingWelcomeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && _nameController.text != widget.name) {
      _nameController.text = widget.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const VeLogo(size: 64, borderRadius: 16),
          const SizedBox(height: 24),
          Text(
            '¡Bienvenido a Food Tracker!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tu asistente nutricional 100% privado, local-first e impulsado por IA.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 32),
          VeCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿CÓMO TE LLAMAS?',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  onChanged: widget.onNameChanged,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Ej: Carlos',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceSubtle(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildFeaturePill(
            context,
            icon: Icons.shield_outlined,
            title: '100% Local-First & Privado',
            description: 'Tus fotos, comidas y métricas jamás salen de tu dispositivo.',
          ),
          const SizedBox(height: 12),
          _buildFeaturePill(
            context,
            icon: Icons.auto_awesome_outlined,
            title: 'Inteligencia Artificial Gemini',
            description: 'Estimación inmediata de calorías y macros con tu propia API Key.',
          ),
          const SizedBox(height: 12),
          _buildFeaturePill(
            context,
            icon: Icons.monitor_weight_outlined,
            title: 'Metabolismo Clínico Preciso',
            description: 'Fórmulas de Mifflin-St Jeor adaptadas a tu rutina y objetivos.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  description,
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
    );
  }
}
