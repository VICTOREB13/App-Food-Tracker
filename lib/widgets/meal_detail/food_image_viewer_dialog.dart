import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Opens a full-screen interactive inspection view of a meal photograph.
void showFoodImageViewer(
  BuildContext context, {
  required String imagePath,
  String? dishName,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => FoodImageViewerScreen(
        imagePath: imagePath,
        dishName: dishName,
      ),
    ),
  );
}

class FoodImageViewerScreen extends StatelessWidget {
  final String imagePath;
  final String? dishName;

  const FoodImageViewerScreen({
    super.key,
    required this.imagePath,
    this.dishName,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final exists = file.existsSync();
    final displayName = (dishName != null && dishName!.trim().isNotEmpty)
        ? dishName!.trim()
        : 'Inspeccionar Comida';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Interactive Pan & Zoom Area
            Positioned.fill(
              child: exists
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      clipBehavior: Clip.none,
                      child: Center(
                        child: Hero(
                          tag: 'meal_image_inspect_$imagePath',
                          child: Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _buildErrorWidget(),
                          ),
                        ),
                      ),
                    )
                  : _buildErrorWidget(),
            ),

            // Top Bar with translucent background and close button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Inspeccionar comida',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom zoom / interaction hint pill
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pinch_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Pellizca para ampliar y explorar detalles',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 54, color: Colors.white54),
          const SizedBox(height: 12),
          Text(
            'No se pudo cargar la imagen para inspección.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
