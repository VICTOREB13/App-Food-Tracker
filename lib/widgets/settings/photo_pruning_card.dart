import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/meal_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

/// Bento card for managing photo retention and local image storage cleanup.
class PhotoPruningCard extends StatefulWidget {
  const PhotoPruningCard({super.key});

  @override
  State<PhotoPruningCard> createState() => _PhotoPruningCardState();
}

class _PhotoPruningCardState extends State<PhotoPruningCard> {
  int _selectedRetentionDays = 30;
  bool _isPruning = false;

  Future<void> _prunePhotos() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedRetentionDays == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.foreverRetentionInfo),
          backgroundColor: AppColors.protein,
        ),
      );
      return;
    }

    setState(() => _isPruning = true);
    try {
      final prunedCount = await MealController.instance.pruneOldPhotos(_selectedRetentionDays);
      if (!mounted) return;

      if (prunedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.photosPrunedSuccess(prunedCount.toString()),
            ),
            backgroundColor: AppColors.protein,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noPhotosBeforePeriod),
            backgroundColor: AppColors.protein,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.photoPruneError(e.toString())),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPruning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final retentionOptions = [
      {'label': l10n.retentionForever, 'days': 0},
      {'label': l10n.retentionNinetyDays, 'days': 90},
      {'label': l10n.retentionThirtyDays, 'days': 30},
      {'label': l10n.retentionFifteenDays, 'days': 15},
    ];

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cleaning_services_outlined, size: 20, color: AppColors.carbsAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.photoPruningHeader,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.photoPruningDescription,
            textAlign: TextAlign.justify,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: _selectedRetentionDays,
            menuMaxHeight: 280,
            decoration: InputDecoration(
              labelText: l10n.mealPhotoRetentionLabel,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: retentionOptions
                .map(
                  (opt) => DropdownMenuItem<int>(
                    value: opt['days'] as int,
                    child: Text(
                      opt['label'] as String,
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedRetentionDays = val);
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPruning ? null : _prunePhotos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: _isPruning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.delete_sweep_outlined, size: 18),
              label: Text(
                _isPruning ? l10n.pruningPhotosProgress : l10n.pruneOldPhotosNow,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
