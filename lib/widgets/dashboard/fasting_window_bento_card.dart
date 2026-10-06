import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/fasting_controller.dart';
import '../../services/theme_manager.dart';
import '../common/ve_loading_ring.dart';

/// Bento Card displaying real-time intermittent fasting progress and interactive controls.
/// Supports a compact collapsible state (~44px) when inactive and full expansion during fasting or on tap.
class FastingWindowBentoCard extends StatefulWidget {
  final FastingController? controller;

  const FastingWindowBentoCard({super.key, this.controller});

  @override
  State<FastingWindowBentoCard> createState() => _FastingWindowBentoCardState();
}

class _FastingWindowBentoCardState extends State<FastingWindowBentoCard> {
  late final FastingController _controller;
  double _selectedTargetHours = 16.0;
  bool _isManuallyExpanded = false;

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
          builder: (dialogCtx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border(context))),
            title: Text('Iniciar Ayuno Intermitente', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selecciona tu protocolo de ayuno:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))),
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
                      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? Colors.white : AppColors.textPrimary(context)),
                      onSelected: (_) => setDialogState(() => hours = h),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() { _selectedTargetHours = hours; _isManuallyExpanded = true; });
                  _controller.startFast(targetHours: hours);
                  Navigator.pop(ctx);
                },
                child: const Text('Comenzar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmStopFast() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border(context))),
        title: Text('¿Terminar Ayuno?', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Llevas ${_controller.fastingDurationFormatted} de ayuno. Se registrará la sesión en tu historial.', style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _isManuallyExpanded = false);
              _controller.stopActiveFast();
              Navigator.pop(ctx);
            },
            child: const Text('Terminar sesión'),
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
        final isExpanded = isActive || _isManuallyExpanded;
        return AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          child: isExpanded ? _buildExpandedCard(context, isActive) : _buildCompactCard(context),
        );
      },
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return InkWell(
      key: const Key('fasting_bento_compact_pill'),
      onTap: () => setState(() => _isManuallyExpanded = true),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AYUNO INTERMITENTE',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textSecondary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text('• Sin ayuno activo', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              key: const Key('fasting_compact_start_button'),
              onTap: _showStartFastDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Iniciar', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCard(BuildContext context, bool isActive) {
    final progress = _controller.progressRatio;
    final isGoalReached = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? (isGoalReached ? AppColors.success.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.35)) : AppColors.border(context),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: isActive ? AppColors.primary : AppColors.textSecondary(context)),
              const SizedBox(width: 6),
              Text('AYUNO INTERMITENTE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isActive ? AppColors.primary : AppColors.textSecondary(context))),
              if (isActive) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: (isGoalReached ? AppColors.success : AppColors.primary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(isGoalReached ? '¡Meta Lograda!' : 'En curso', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: isGoalReached ? AppColors.success : AppColors.primary)),
                ),
              ],
              const Spacer(),
              if (!isActive && _isManuallyExpanded)
                InkWell(
                  onTap: () => setState(() => _isManuallyExpanded = false),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Colapsar', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted(context))),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: AppColors.textMuted(context)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  VeLoadingRing(size: 52, strokeWidth: 4.5, progress: isActive ? progress : 0.0, color: isGoalReached ? AppColors.success : AppColors.primary, trackColor: AppColors.border(context).withValues(alpha: 0.4)),
                  Icon(isActive ? Icons.timer_outlined : Icons.hourglass_empty_rounded, color: isActive ? (isGoalReached ? AppColors.success : AppColors.primary) : AppColors.textMuted(context), size: 22),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isActive ? _controller.fastingDurationFormatted : 'Sin ayuno activo', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? (isGoalReached ? 'Meta superada (+${(progress * 100).toInt()}%)' : 'Restan ${_controller.remainingDurationFormatted} de ${_controller.targetHours.toInt()}h')
                          : 'Inicia para dar seguimiento a tu ventana de comida',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppColors.surface(context) : AppColors.primary,
                  foregroundColor: isActive ? AppColors.primary : Colors.white,
                  side: isActive ? const BorderSide(color: AppColors.primary, width: 1.2) : BorderSide.none,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isActive ? _confirmStopFast : _showStartFastDialog,
                child: Text(isActive ? 'Terminar' : 'Iniciar', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
