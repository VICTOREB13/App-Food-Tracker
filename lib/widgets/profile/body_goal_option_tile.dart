import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

class BodyGoalOptionTile extends StatelessWidget {
  final String title;
  final String delta;
  final String desc;
  final bool isSelected;
  final VoidCallback onTap;

  const BodyGoalOptionTile({
    super.key,
    required this.title,
    required this.delta,
    required this.desc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border(context);
    final bgColor = isSelected ? AppColors.primary.withValues(alpha: 0.10) : AppColors.surfaceSubtle(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.20) : AppColors.border(context).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          delta,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondary(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
