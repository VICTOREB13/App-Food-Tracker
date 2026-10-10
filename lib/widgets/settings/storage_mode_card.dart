import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/storage_mode.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

/// Bento card enabling users to choose between public media gallery storage and private app storage.
class StorageModeCard extends StatelessWidget {
  const StorageModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SettingsController.instance;
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final currentMode = controller.storageMode;
        return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sd_storage_outlined, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.storageModeTitle.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.storageModeSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModeOption(
                  context: context,
                  title: l10n.storageModePublic,
                  description: l10n.storageModePublicDesc,
                  icon: Icons.photo_library_outlined,
                  isSelected: currentMode == StorageMode.public,
                  onTap: () async {
                    if (currentMode != StorageMode.public) {
                      await controller.saveStorageMode(StorageMode.public);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.storageModePublicSnackBar),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeOption(
                  context: context,
                  title: l10n.storageModePrivate,
                  description: l10n.storageModePrivateDesc,
                  icon: Icons.lock_outline,
                  isSelected: currentMode == StorageMode.private,
                  onTap: () async {
                    if (currentMode != StorageMode.private) {
                      await controller.saveStorageMode(StorageMode.private);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.storageModePrivateSnackBar),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border(context);
    final bgColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.surfaceSubtle(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted(context),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
