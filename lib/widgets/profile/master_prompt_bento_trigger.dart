import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../services/theme_manager.dart';

/// Interactive, responsive trigger banner for viewing, configuring, and copying the Multimodal Master Prompt.
class MasterPromptBentoTrigger extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const MasterPromptBentoTrigger({
    super.key,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('master_prompt_bento_trigger'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.25)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 340;

              final iconCircle = Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, size: 18, color: AppColors.primaryLight),
              );

              final textColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.multimodalMasterPrompt,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  Text(
                    l10n.viewEditPromptSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final copyButton = IconButton(
                key: const Key('master_prompt_quick_copy_button'),
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryLight),
                tooltip: l10n.copyPromptAction,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: onCopy,
              );

              final openButton = FilledButton.tonalIcon(
                key: const Key('master_prompt_open_sheet_button'),
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.20),
                  foregroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(
                  l10n.viewEditPromptAction,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        iconCircle,
                        const SizedBox(width: 8),
                        Expanded(child: textColumn),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        copyButton,
                        const SizedBox(width: 6),
                        openButton,
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  iconCircle,
                  const SizedBox(width: 8),
                  Expanded(child: textColumn),
                  copyButton,
                  const SizedBox(width: 4),
                  openButton,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
