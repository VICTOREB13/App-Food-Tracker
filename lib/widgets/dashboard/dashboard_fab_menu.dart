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
  final VoidCallback? onVoiceDictation;
  final VoidCallback? onVideoScan;
  final VoidCallback? onWhatToEat;

  const DashboardFabMenu({
    super.key,
    required this.onAiPhotoScan,
    this.onGalleryScan,
    required this.onBarcodeScan,
    required this.onManualEntry,
    this.onQuickWater,
    this.onQuickMeal,
    this.onVoiceDictation,
    this.onVideoScan,
    this.onWhatToEat,
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
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
        final actions = <_FabItem>[
          _FabItem(Icons.camera_alt_outlined, AppColors.primary, 'Foto con IA', 'Cámara Gemini 2.5', () {
            Navigator.of(sheetContext).pop();
            widget.onAiPhotoScan();
          }),
          _FabItem(Icons.photo_library_outlined, AppColors.caloriesFlame, 'Galería', 'Elegir del carrete', () {
            Navigator.of(sheetContext).pop();
            (widget.onGalleryScan ?? widget.onAiPhotoScan)();
          }),
          _FabItem(Icons.qr_code_scanner, AppColors.carbs, 'Código Barras', 'Open Food Facts', () {
            Navigator.of(sheetContext).pop();
            widget.onBarcodeScan();
          }),
          _FabItem(Icons.edit_note, AppColors.protein, 'Manual', 'Despensa y macros', () {
            Navigator.of(sheetContext).pop();
            widget.onManualEntry();
          }),
          _FabItem(Icons.water_drop_outlined, AppColors.water, '+250ml Agua', 'Hidratación rápida', () {
            Navigator.of(sheetContext).pop();
            widget.onQuickWater?.call();
          }),
          _FabItem(Icons.bolt, AppColors.carbsAmber, 'Rápida', 'Calorías directas', () {
            Navigator.of(sheetContext).pop();
            widget.onQuickMeal?.call();
          }),
          if (widget.onVoiceDictation != null)
            _FabItem(Icons.mic_none_rounded, const Color(0xFF8B5CF6), 'Voz / Audio', 'Dictado natural', () {
              Navigator.of(sheetContext).pop();
              widget.onVoiceDictation!();
            }),
          if (widget.onVideoScan != null)
            _FabItem(Icons.videocam_outlined, const Color(0xFF06B6D4), 'Video Pan', 'Muestreo 3D', () {
              Navigator.of(sheetContext).pop();
              widget.onVideoScan!();
            }),
        ];

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'REGISTRAR COMIDA O ACTIVIDAD',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondary(context)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (widget.onWhatToEat != null) ...[
                      InkWell(
                        key: const Key('what_to_eat_fab_button'),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          widget.onWhatToEat!();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.protein.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.protein.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.protein, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('¿Qué debería comer hoy?', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                                    Text('Sugerencias inteligentes según tus macros', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.protein),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.85,
                      children: actions.map(_buildGridAction).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) _controller.reverse();
    });
  }

  Widget _buildGridAction(_FabItem item) {
    return InkWell(
      onTap: item.onTap,
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
              decoration: BoxDecoration(color: item.iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                  Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
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

class _FabItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FabItem(this.icon, this.iconColor, this.title, this.subtitle, this.onTap);
}
