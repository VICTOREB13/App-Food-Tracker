import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

/// Second step in the onboarding flow: Biometric Parameters (Mifflin-St Jeor).
class OnboardingBiometricsStep extends StatefulWidget {
  final String gender;
  final int age;
  final double height;
  final double weight;
  final void Function({
    String? gender,
    int? age,
    double? height,
    double? weight,
  }) onChanged;

  const OnboardingBiometricsStep({
    super.key,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.onChanged,
  });

  @override
  State<OnboardingBiometricsStep> createState() => _OnboardingBiometricsStepState();
}

class _OnboardingBiometricsStepState extends State<OnboardingBiometricsStep> {
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  static String _formatNum(double val) => (val % 1 == 0) ? val.toInt().toString() : val.toString();

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.age > 0 ? widget.age.toString() : '');
    _heightController = TextEditingController(text: widget.height > 0 ? _formatNum(widget.height) : '');
    _weightController = TextEditingController(text: widget.weight > 0 ? _formatNum(widget.weight) : '');
  }

  @override
  void didUpdateWidget(covariant OnboardingBiometricsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final parsedAge = int.tryParse(_ageController.text.trim());
    if (widget.age > 0 && parsedAge != widget.age) {
      _ageController.text = widget.age.toString();
    }
    final parsedHeight = double.tryParse(_heightController.text.trim().replaceAll(',', '.'));
    if (widget.height > 0 && parsedHeight != widget.height) {
      _heightController.text = _formatNum(widget.height);
    }
    final parsedWeight = double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
    if (widget.weight > 0 && parsedWeight != widget.weight) {
      _weightController.text = _formatNum(widget.weight);
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onAgeChanged(String val) {
    final parsed = int.tryParse(val.trim());
    widget.onChanged(age: (parsed != null && parsed >= 10 && parsed <= 120) ? parsed : 0);
  }

  void _onHeightChanged(String val) {
    final parsed = double.tryParse(val.trim().replaceAll(',', '.'));
    widget.onChanged(height: (parsed != null && parsed >= 80 && parsed <= 250) ? parsed : 0.0);
  }

  void _onWeightChanged(String val) {
    final parsed = double.tryParse(val.trim().replaceAll(',', '.'));
    widget.onChanged(weight: (parsed != null && parsed >= 30 && parsed <= 300) ? parsed : 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isMale = widget.gender == 'male';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            'Parámetros Biológicos',
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
            'Fórmulas clínicas de Mifflin-St Jeor para determinar con precisión tu gasto metabólico.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 24),

          // Gender Selection Segmented Button
          VeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEXO BIOLÓGICO',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondary(context)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderOption(
                        context,
                        label: 'Masculino',
                        icon: Icons.male_rounded,
                        isSelected: isMale,
                        onTap: () => widget.onChanged(gender: 'male'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGenderOption(
                        context,
                        label: 'Femenino',
                        icon: Icons.female_rounded,
                        isSelected: !isMale,
                        onTap: () => widget.onChanged(gender: 'female'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Age, Height, Weight inputs
          VeCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DATOS CORPORALES',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondary(context)),
                ),
                const SizedBox(height: 16),
                _buildNumericField(context, controller: _ageController, label: 'Edad', suffix: 'años', hintText: 'Ej: 25', icon: Icons.cake_outlined, onChanged: _onAgeChanged, keyboardType: TextInputType.number),
                const SizedBox(height: 14),
                _buildNumericField(context, controller: _heightController, label: 'Estatura', suffix: 'cm', hintText: 'Ej: 175', icon: Icons.height_rounded, onChanged: _onHeightChanged, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 14),
                _buildNumericField(context, controller: _weightController, label: 'Peso Actual', suffix: 'kg', hintText: 'Ej: 75', icon: Icons.monitor_weight_outlined, onChanged: _onWeightChanged, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceSubtle(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border(context), width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: isSelected ? AppColors.primary : AppColors.textSecondary(context)),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textPrimary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String suffix,
    String? hintText,
    required IconData icon,
    required ValueChanged<String> onChanged,
    required TextInputType keyboardType,
  }) {
    final borderStyle = OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border(context)));
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textMuted(context)),
              suffixText: suffix,
              suffixStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary(context)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: AppColors.surfaceSubtle(context),
              border: borderStyle,
              enabledBorder: borderStyle,
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }
}

