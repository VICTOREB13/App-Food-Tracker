import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../services/theme_manager.dart';

/// Top header bar for the recommendations bottom sheet with handle, icon, title, and close button.
class RecommendationSheetHeader extends StatelessWidget {
  final String? nextMealType;
  final VoidCallback onClose;

  const RecommendationSheetHeader({
    super.key,
    this.nextMealType,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.protein.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.protein, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.whatToEatTitle,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (nextMealType != null)
                    Text(
                      l10n.nextMealSuggestions(nextMealType!),
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              key: const Key('what_to_eat_close_button'),
              icon: const Icon(Icons.close),
              tooltip: l10n.closeButton,
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }
}
