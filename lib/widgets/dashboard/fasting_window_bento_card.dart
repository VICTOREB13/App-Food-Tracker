import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/fasting_controller.dart';
import '../../services/theme_manager.dart';
import '../common/ve_loading_ring.dart';

/// Bento Card displaying real-time intermittent fasting progress and interactive controls.
class FastingWindowBentoCard extends StatefulWidget {
  final FastingController? controller;

  const FastingWindowBentoCard({super.key, this.controller});

  @override
  State<FastingWindowBentoCard> createState() => _FastingWindowBentoCardState();
}

class _FastingWindowBentoCardState extends State<FastingWindowBentoCard> {
  late final FastingController _controller;
  double _selectedTargetHours = 16.0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? FastingController.instance;
    _controller.loadActiveFast();
  }

  void _showStartFastDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        double hours = _selectedTargetHours;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.border(context)),
              ),
              title: Text(
                'Iniciar Ayuno Intermitente',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona tu protocolo de ayuno:',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [14.0, 16.0, 18.0, 20.0].map((h) {
                      final isSel = hours == h;
                      return ChoiceChip(
                        label: Text('${h.toInt()}:${(24 - h).toInt()}'),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface(context),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : AppColors.textPrimary(context),
                        ),
                        side: BorderSide(
                          color: isSel ? AppColors.primary : AppColors.border(context),
                        ),
                        onSelected: (_) => setDialogState(() => hours = h),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() => _selectedTargetHours = hours);
                    _controller.startFast(targetHours: hours);
                    Navigator.pop(ctx);
                  },
                  child: Text('Comenzar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmStopFast() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border(context)),
        ),
        title: Text(
          '¿Terminar Ayuno?',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
        ),
        content: Text(
          'Llevas ${_controller.fastingDurationFormatted} de ayuno. Se registrará la sesión en tu historial.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Continuar ayunando', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              _controller.stopActiveFast();
              Navigator.pop(ctx);
            },
            child: Text('Terminar sesión', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isActive = _controller.isFastingActive;
        final progress = _controller.progressRatio;
        final isGoalReached = progress >= 1.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? (isGoalReached ? AppColors.success.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.35))
                  : AppColors.border(context),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ring Progress / Timer Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  VeLoadingRing(
                    size: 56,
                    strokeWidth: 4.5,
                    progress: isActive ? progress : 0.0,
                    color: isGoalReached ? AppColors.success : AppColors.primary,
                    backgroundColor: AppColors.border(context).withValues(alpha: 0.4),
                  ),
                  Icon(
                    isActive ? Icons.timer_outlined : Icons.hourglass_empty_rounded,
                    color: isActive
                        ? (isGoalReached ? AppColors.success : AppColors.primary)
                        : AppColors.textMuted(context),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Fasting Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AYUNO INTERMITENTE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isActive ? AppColors.primary : AppColors.textSecondary(context),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isGoalReached ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isGoalReached ? '¡Meta Lograda!' : 'En curso',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isGoalReached ? AppColors.success : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isActive ? _controller.fastingDurationFormatted : 'Sin ayuno activo',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? (isGoalReached
                              ? 'Meta superada (+${(progress * 100).toInt()}%)'
                              : 'Restan ${_controller.remainingDurationFormatted} de ${_controller.targetHours.toInt()}h')
                          : 'Inicia para dar seguimiento a tu ventana de comida',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action Button
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppColors.surface(context) : AppColors.primary,
                  foregroundColor: isActive ? AppColors.primary : Colors.white,
                  side: isActive ? const BorderSide(color: AppColors.primary, width: 1.2) : BorderSide.none,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isActive ? _confirmStopFast : _showStartFastDialog,
                child: Text(
                  isActive ? 'Terminar' : 'Iniciar',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
