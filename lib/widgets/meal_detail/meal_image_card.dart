import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import 'food_image_viewer_dialog.dart';

class MealImageCard extends StatelessWidget {
  final String? imagePath;
  final String? dishName;
  final VoidCallback onPickImage;

  const MealImageCard({
    super.key,
    required this.imagePath,
    this.dishName,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && File(imagePath!).existsSync();

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              GestureDetector(
                onTap: () => showFoodImageViewer(
                  context,
                  imagePath: imagePath!,
                  dishName: dishName,
                ),
                child: Hero(
                  tag: 'meal_image_inspect_${imagePath!}',
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                  ),
                ),
              )
            else
              _buildPlaceholder(context),
            if (hasImage)
              Positioned(
                left: 12,
                bottom: 12,
                child: ElevatedButton.icon(
                  onPressed: () => showFoodImageViewer(
                    context,
                    imagePath: imagePath!,
                    dishName: dishName,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface(context).withValues(alpha: 0.90),
                    foregroundColor: AppColors.textPrimary(context),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: Text(
                    'Inspeccionar comida',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: ElevatedButton.icon(
                onPressed: onPickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface(context).withValues(alpha: 0.90),
                  foregroundColor: AppColors.textPrimary(context),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.border(context)),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: Text(
                  hasImage ? 'Cambiar foto' : 'Tomar foto',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_enhance_outlined,
            size: 44,
            color: AppColors.textMuted(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Sin imagen del plato',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
