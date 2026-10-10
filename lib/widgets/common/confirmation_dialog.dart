import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../services/theme_manager.dart';

Future<bool?> showVeConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) {
  final l10n = AppLocalizations.of(context);
  final effectiveConfirmLabel = confirmLabel ?? l10n.confirm;
  final effectiveCancelLabel = cancelLabel ?? l10n.cancel;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(context),
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            effectiveCancelLabel,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? AppColors.primary : AppColors.surfaceSubtle(context),
            foregroundColor: isDestructive ? Colors.white : AppColors.textPrimary(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isDestructive ? BorderSide.none : BorderSide(color: AppColors.border(context)),
            ),
          ),
          child: Text(
            effectiveConfirmLabel,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
