import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class BiometricInputsCard extends StatefulWidget {
  final String? initialName;
  final int initialAge;
  final String initialGender;
  final double initialHeight;
  final double initialWeight;
  final void Function({String? name, int? age, String? gender, double? height, double? weight}) onChanged;

  const BiometricInputsCard({
    super.key,
    this.initialName,
    required this.initialAge,
    required this.initialGender,
    required this.initialHeight,
    required this.initialWeight,
    required this.onChanged,
  });

  @override
  State<BiometricInputsCard> createState() => _BiometricInputsCardState();
}

class _BiometricInputsCardState extends State<BiometricInputsCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _ageController = TextEditingController(text: widget.initialAge > 0 ? widget.initialAge.toString() : '');
    _heightController = TextEditingController(text: widget.initialHeight > 0 ? widget.initialHeight.toStringAsFixed(0) : '');
    _weightController = TextEditingController(text: widget.initialWeight > 0 ? widget.initialWeight.toStringAsFixed(1) : '');
  }

  @override
  void didUpdateWidget(covariant BiometricInputsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGender != widget.initialGender && _selectedGender != widget.initialGender) {
      _selectedGender = widget.initialGender;
    }
    if (oldWidget.initialName != widget.initialName && widget.initialName != null && _nameController.text != widget.initialName) {
      _nameController.text = widget.initialName!;
    }
    if (oldWidget.initialAge != widget.initialAge) {
      final p = int.tryParse(_ageController.text.trim());
      if (_ageController.text.isNotEmpty && p != null && p != widget.initialAge) {
        _ageController.text = widget.initialAge.toString();
      }
    }
    if (oldWidget.initialHeight != widget.initialHeight) {
      final p = double.tryParse(_heightController.text.trim());
      if (_heightController.text.isNotEmpty && p != null && p != widget.initialHeight) {
        _heightController.text = widget.initialHeight.toStringAsFixed(0);
      }
    }
    if (oldWidget.initialWeight != widget.initialWeight) {
      final p = double.tryParse(_weightController.text.trim());
      if (_weightController.text.isNotEmpty && p != null && p != widget.initialWeight) {
        _weightController.text = widget.initialWeight.toStringAsFixed(1);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    final name = _nameController.text.trim();
    widget.onChanged(
      name: name.isNotEmpty ? name : null,
      age: int.tryParse(_ageController.text.trim()),
      gender: _selectedGender,
      height: double.tryParse(_heightController.text.trim()),
      weight: double.tryParse(_weightController.text.trim()),
    );
  }

  void _setGender(String gender) {
    if (_selectedGender == gender) return;
    setState(() => _selectedGender = gender);
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
              const Icon(Icons.fingerprint_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'DATOS BIOMÉTRICOS',
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

          // Name Input
          _buildFieldLabel(context, 'Nombre o Alias'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            onChanged: (_) => _notifyChanges(),
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
            decoration: const InputDecoration(
              hintText: 'Ej. Victor Engineer',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Biological Gender Selector
          _buildFieldLabel(context, 'Género Biológico (Mifflin-St Jeor)'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  label: 'Masculino',
                  icon: Icons.male_rounded,
                  value: 'male',
                  isSelected: _selectedGender == 'male',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption(
                  label: 'Femenino',
                  icon: Icons.female_rounded,
                  value: 'female',
                  isSelected: _selectedGender == 'female',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Age, Height, Weight Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Age
              Expanded(
                flex: 2,
                child: _buildNumericInputColumn(
                  context: context,
                  label: 'Edad',
                  controller: _ageController,
                  hintText: '28',
                  suffixText: 'años',
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Height (cm)
              Expanded(
                flex: 3,
                child: _buildNumericInputColumn(
                  context: context,
                  label: 'Estatura',
                  controller: _heightController,
                  hintText: '175',
                  suffixText: 'cm',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),

              // Weight (kg)
              Expanded(
                flex: 3,
                child: _buildNumericInputColumn(
                  context: context,
                  label: 'Peso Actual',
                  controller: _weightController,
                  hintText: '75.0',
                  suffixText: 'kg',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumericInputColumn({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String suffixText,
    required TextInputType keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(context, label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          onChanged: (_) => _notifyChanges(),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
          decoration: InputDecoration(hintText: hintText, suffixText: suffixText),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary(context),
      ),
    );
  }

  Widget _buildGenderOption({
    required String label,
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border(context);
    final bgColor = isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceSubtle(context);

    return InkWell(
      onTap: () => _setGender(value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
