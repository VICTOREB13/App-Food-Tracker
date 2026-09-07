import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

class DashboardFabMenu extends StatefulWidget {
  final VoidCallback onAiPhotoScan;
  final VoidCallback? onGalleryScan;
  final VoidCallback onBarcodeScan;
  final VoidCallback onManualEntry;
  final VoidCallback? onQuickWater;
  final VoidCallback? onQuickMeal;

  const DashboardFabMenu({
    super.key,
    required this.onAiPhotoScan,
    this.onGalleryScan,
    required this.onBarcodeScan,
    required this.onManualEntry,
    this.onQuickWater,
    this.onQuickMeal,
  });

  @override
  State<DashboardFabMenu> createState() => _DashboardFabMenuState();
}

class _DashboardFabMenuState extends State<DashboardFabMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSpeedDialSheet() {
    _controller.forward(from: 0.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: AppColors.surface(context).withValues(alpha: 0.94),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REGISTRAR COMIDA O ACTIVIDAD',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.85,
                    children: [
                      _buildGridAction(
                        icon: Icons.camera_alt_outlined,
                        iconColor: AppColors.primary,
                        title: 'Foto con IA',
                        subtitle: 'Cámara Gemini 2.5',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          widget.onAiPhotoScan();
                        },
                      ),
                      _buildGridAction(
                        icon: Icons.photo_library_outlined,
                        iconColor: AppColors.caloriesFlame,
                        title: 'Galería',
                        subtitle: 'Elegir del carrete',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          (widget.onGalleryScan ?? widget.onAiPhotoScan)();
                        },
                      ),
                      _buildGridAction(
                        icon: Icons.qr_code_scanner,
                        iconColor: AppColors.carbs,
                        title: 'Código Barras',
                        subtitle: 'Open Food Facts',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          widget.onBarcodeScan();
                        },
                      ),
                      _buildGridAction(
                        icon: Icons.edit_note,
                        iconColor: AppColors.protein,
                        title: 'Manual',
                        subtitle: 'Despensa y macros',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          widget.onManualEntry();
                        },
                      ),
                      _buildGridAction(
                        icon: Icons.water_drop_outlined,
                        iconColor: AppColors.water,
                        title: '+250ml Agua',
                        subtitle: 'Hidratación rápida',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          if (widget.onQuickWater != null) {
                            widget.onQuickWater!();
                          }
                        },
                      ),
                      _buildGridAction(
                        icon: Icons.bolt,
                        iconColor: AppColors.carbsAmber,
                        title: 'Rápida',
                        subtitle: 'Calorías directas',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          if (widget.onQuickMeal != null) {
                            widget.onQuickMeal!();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) _controller.reverse();
    });
  }

  Widget _buildGridAction({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween<double>(begin: 0.0, end: 0.125).animate(
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
      ),
      child: FloatingActionButton(
        onPressed: _openSpeedDialSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
