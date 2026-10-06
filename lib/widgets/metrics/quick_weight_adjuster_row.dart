import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

/// Row of quick adjustment chips (-1.0, -0.5, +0.5, +1.0 kg) for weight entries.
class QuickWeightAdjusterRow extends StatelessWidget {
  final ValueChanged<double> onAdjust;

  const QuickWeightAdjusterRow({
    super.key,
    required this.onAdjust,
  });

  static const _deltas = [-1.0, -0.5, 0.5, 1.0];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _deltas.map((delta) {
        final label = '${delta > 0 ? '+' : ''}$delta kg';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: InkWell(
              onTap: () => onAdjust(delta),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context)),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
