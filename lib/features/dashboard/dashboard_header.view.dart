import 'package:material_ui/material_ui.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/core/ui/components/ve_app_bar.dart';
import 'package:food_tracker/features/dashboard/widgets/streak_badge.dart';

/// Top app bar header for the Dashboard slice.
class DashboardHeaderView extends StatelessWidget implements PreferredSizeWidget {
  final int streakDays;
  final VoidCallback? onMetricsTap;
  final VoidCallback? onSettingsTap;

  const DashboardHeaderView({
    super.key,
    this.streakDays = 0,
    this.onMetricsTap,
    this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return VeAppBar(
      automaticallyImplyLeading: false,
      title: l10n.dashboardTitle,
      subtitle: l10n.dashboardSubtitle,
      actions: [
        Center(child: StreakBadge(streakDays: streakDays)),
        IconButton(
          icon: const Icon(Icons.insights_outlined),
          tooltip: l10n.metrics,
          onPressed: onMetricsTap,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: l10n.settings,
          onPressed: onSettingsTap,
        ),
      ],
    );
  }
}
