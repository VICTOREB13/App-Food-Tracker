import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/settings_controller.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

/// Bento card for dynamic runtime language selection (Español / English).
class LanguageSelectorCard extends StatelessWidget {
  final SettingsController? controller;

  const LanguageSelectorCard({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? SettingsController.instance;

    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final currentCode = ctrl.currentLocale?.languageCode ??
            Localizations.localeOf(context).languageCode;
        final isSpanish = currentCode == 'es';

        return VeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'IDIOMA / LANGUAGE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Selecciona el idioma de la aplicación en tiempo real.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted(context),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LanguageOptionChip(
                      label: 'Español',
                      sublabel: 'Predeterminado (ES)',
                      isSelected: isSpanish,
                      onTap: () => ctrl.setLocale(const Locale('es')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LanguageOptionChip(
                      label: 'English',
                      sublabel: 'English (US)',
                      isSelected: !isSpanish,
                      onTap: () => ctrl.setLocale(const Locale('en')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageOptionChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionChip({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textPrimary(context),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
