import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/theme_manager.dart';

class VeLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showShadow;

  static const String iconSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
  <rect width="32" height="32" rx="8" fill="#dc2626"/>
  <text x="16" y="21.5" font-family="system-ui, -apple-system, sans-serif" font-weight="900" font-size="13" fill="#ffffff" text-anchor="middle" letter-spacing="-0.5">VE</text>
</svg>''';

  const VeLogo({
    super.key,
    this.size = 32,
    this.borderRadius = 8,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.string(
        iconSvg,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
