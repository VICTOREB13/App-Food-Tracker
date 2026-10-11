import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../services/recommendations/recommendation_filter_engine.dart';
import '../../services/theme_manager.dart';

/// Interactive category selector chips and refresh button for recommendation browsing.
class CategorySelectorBar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const CategorySelectorBar({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  static const List<Map<String, dynamic>> categories = [
    {'key': 'Todos', 'icon': Icons.apps_rounded},
    {'key': 'Desayuno', 'icon': Icons.wb_sunny_outlined},
    {'key': 'Almuerzo', 'icon': Icons.lunch_dining_rounded},
    {'key': 'Cena', 'icon': Icons.nightlight_outlined},
    {'key': 'Snack', 'icon': Icons.cookie_outlined},
  ];

  String _getCategoryLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'Todos':
        return l10n.categoryAll;
      case 'Desayuno':
        return l10n.breakfast;
      case 'Almuerzo':
        return l10n.lunch;
      case 'Cena':
        return l10n.dinner;
      case 'Snack':
        return l10n.snack;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final normalizedSelected = RecommendationFilterEngine.normalizeCategory(selectedCategory);

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final key = cat['key'] as String;
                final icon = cat['icon'] as IconData;
                final label = _getCategoryLabel(key, l10n);
                final isSelected = normalizedSelected == key;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    key: Key('category_chip_${key.toLowerCase()}'),
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      icon,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.textSecondary(context),
                    ),
                    label: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary(context),
                      ),
                    ),
                    backgroundColor: AppColors.surfaceSubtle(context),
                    selectedColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border(context),
                      ),
                    ),
                    onSelected: (_) => onSelected(key),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          key: const Key('recommendations_refresh_button'),
          icon: isRefreshing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primary),
          tooltip: l10n.refreshIdeasAction,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
          onPressed: isRefreshing ? null : onRefresh,
        ),
      ],
    );
  }
}
