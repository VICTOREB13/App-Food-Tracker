import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/food_search_suggestion.dart';
import '../../services/theme_manager.dart';

/// Suggestion list popup for food items matched from Local catalog or Online APIs.
class FoodSearchSuggestionsList extends StatelessWidget {
  final List<FoodSearchSuggestion> suggestions;
  final ValueChanged<FoodSearchSuggestion> onSelect;

  const FoodSearchSuggestionsList({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      constraints: const BoxConstraints(maxHeight: 125),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border(context)),
        itemBuilder: (ctx, i) {
          final s = suggestions[i];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            title: Text(
              s.brand != null && s.brand!.isNotEmpty ? '${s.name} (${s.brand})' : s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${s.caloriesPer100g.toInt()} kcal (100g base)',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context)),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                s.sourceBadgeLabel,
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            onTap: () => onSelect(s),
          );
        },
      ),
    );
  }
}
