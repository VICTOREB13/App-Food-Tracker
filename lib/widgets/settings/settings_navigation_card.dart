import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/dishware_settings_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/pantry_screen.dart';
import '../../screens/user_profile_screen.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

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
              MaterialPageRoute(builder: (_) => const UserProfileScreen()),
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
              MaterialPageRoute(builder: (_) => const PantryScreen()),
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
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context))),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
