import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/settings_screen.dart';
import '../../services/theme_manager.dart';

void showApiKeyPromptDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface(context),
      title: Text(l10n.apiKeyPromptDialogTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      content: Text(
        l10n.apiKeyPromptDialogBody,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: Text(l10n.goToSettings),
        ),
      ],
    ),
  );
}
