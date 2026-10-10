import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/interfaces/app_installer_service_interface.dart';
import '../../core/interfaces/app_update_service_interface.dart';
import '../../l10n/app_localizations.dart';
import '../../services/theme_manager.dart';
import '../../services/app_update_service.dart';
import '../common/ve_card.dart';
import 'in_app_update_dialog.dart';

/// Bento card in Settings allowing users to check for GitHub Releases.
class AppUpdateCard extends StatefulWidget {
  final String currentVersion;
  final IAppUpdateService? updateService;
  final IAppInstallerService? installerService;

  const AppUpdateCard({
    super.key,
    this.currentVersion = AppConstants.appVersion,
    this.updateService,
    this.installerService,
  });

  @override
  State<AppUpdateCard> createState() => _AppUpdateCardState();
}

class _AppUpdateCardState extends State<AppUpdateCard> {
  late final IAppUpdateService _updateService;
  bool _isChecking = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _updateService = widget.updateService ??
        (getIt.isRegistered<IAppUpdateService>()
            ? getIt<IAppUpdateService>()
            : AppUpdateService.instance);
  }

  Future<void> _handleCheckUpdates() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    try {
      final release = await _updateService.checkLatestRelease();
      if (!mounted) return;
      setState(() => _isChecking = false);

      if (release != null && _updateService.isUpdateAvailable(widget.currentVersion, release.tagName)) {
        await showInAppUpdateDialog(
          context,
          release: release,
          updateService: _updateService,
          installerService: widget.installerService,
        );
      } else {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        setState(() => _statusMessage = l10n.versionUpToDateStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.versionUpToDateMessage(widget.currentVersion)),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isChecking = false;
          _statusMessage = l10n.errorCheckingUpdates;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.updateCheckError(e.toString())),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appUpdatesTitle,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      '${l10n.installedVersionLabel(widget.currentVersion)}${_statusMessage != null ? ' • $_statusMessage' : ''}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('check_updates_button'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: _isChecking ? null : _handleCheckUpdates,
              icon: _isChecking
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                _isChecking ? l10n.checkingUpdates : l10n.checkUpdatesAction,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
