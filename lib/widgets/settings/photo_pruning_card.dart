import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/meal_controller.dart';
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

  static const List<Map<String, dynamic>> _retentionOptions = [
    {'label': 'Para siempre', 'days': 0},
    {'label': '90 días', 'days': 90},
    {'label': '30 días', 'days': 30},
    {'label': '15 días', 'days': 15},
  ];

  Future<void> _prunePhotos() async {
    if (_selectedRetentionDays == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Con "Para siempre" todas las fotos se conservan intactas.'),
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
              'Se depuraron $prunedCount fotos antiguas. Tus calorías y macronutrientes permanecen intactos.',
            ),
            backgroundColor: AppColors.protein,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron fotos anteriores al período seleccionado.'),
            backgroundColor: AppColors.protein,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al depurar fotos: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPruning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'DEPURACIÓN DE FOTOS Y ALMACENAMIENTO',
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
            'Optimiza el almacenamiento local liberando espacio ocupado por fotos de platos anteriores al período seleccionado. Las comidas, calorías, ingredientes y macronutrientes permanecen 100% intactos en la base de datos local SQLite.',
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
            decoration: const InputDecoration(
              labelText: 'Retención de fotos de comidas',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _retentionOptions
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
                _isPruning ? 'Depurando fotos...' : 'Depurar fotos antiguas ahora',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
