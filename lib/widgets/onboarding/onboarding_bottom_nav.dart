import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

/// Bottom navigation bar for onboarding flow with responsive sizing and step validation.
class OnboardingBottomNav extends StatelessWidget {
  final int currentStep;
  final bool isSaving;
  final bool isValid;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onInvalidTap;

  const OnboardingBottomNav({
    super.key,
    required this.currentStep,
    required this.isSaving,
    required this.isValid,
    required this.onPrev,
    required this.onNext,
    required this.onFinish,
    required this.onInvalidTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            OutlinedButton(
              onPressed: onPrev,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary(context),
                side: BorderSide(color: AppColors.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: Text(
                'Atrás',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: isSaving
                  ? null
                  : (isLastStep
                      ? onFinish
                      : (isValid ? onNext : onInvalidTap)),
              style: ElevatedButton.styleFrom(
                backgroundColor: (isValid || isLastStep)
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastStep ? 'Guardar y Comenzar' : 'Continuar',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isLastStep ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
