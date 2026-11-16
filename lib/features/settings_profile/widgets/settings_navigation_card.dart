import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/features/food_entry/food_entry.dart';
import 'package:food_tracker/features/pantry_inventory/pantry_inventory.dart';
import 'package:food_tracker/features/settings_profile/settings_profile.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'package:food_tracker/core/ui/components/ve_card.dart';

class SettingsNavigationCard extends StatelessWidget {
  const SettingsNavigationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return VeCard(
      child: Column(
        children: [
          _buildTile(
            context,
            icon: Icons.person_outline,
            iconColor: AppColors.primary,
            title: l10n.navProfileTitle,
            subtitle: l10n.navProfileSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserProfileView()),
            ),
          ),
          Divider(color: AppColors.border(context), height: 1),
          _buildTile(
            context,
            icon: Icons.straighten_rounded,
            iconColor: AppColors.calories,
            title: l10n.navDishwareTitle,
            subtitle: l10n.navDishwareSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DishwareSettingsScreen()),
            ),
          ),
          Divider(color: AppColors.border(context), height: 1),
          _buildTile(
            context,
            icon: Icons.kitchen_outlined,
            iconColor: AppColors.protein,
            title: l10n.navPantryTitle,
            subtitle: l10n.navPantrySubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PantryInventoryView()),
            ),
          ),
          Divider(color: AppColors.border(context), height: 1),
          _buildTile(
            context,
            icon: Icons.auto_fix_high_rounded,
            iconColor: AppColors.carbs,
            title: l10n.navOnboardingTitle,
            subtitle: l10n.navOnboardingSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OnboardingView()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
