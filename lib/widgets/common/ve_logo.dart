import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/theme_manager.dart';

class VeLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showShadow;

  static const String iconSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <rect x="2" y="2" width="96" height="96" rx="22" fill="#C31723" stroke="#910E17" stroke-width="3"/>
  <g fill="#FFFFFF">
    <path d="M 40 25 C 38 21, 41 18, 39 14" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>
    <path d="M 50 22 C 48 18, 51 15, 49 11" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>
    <path d="M 60 25 C 58 21, 61 18, 59 14" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>
    <ellipse cx="49" cy="74" rx="33" ry="5"/>
    <path d="M 21 73 Q 49 78 77 73" fill="none" stroke="#C31723" stroke-width="1.5"/>
    <ellipse cx="45" cy="58" rx="20" ry="13"/>
    <ellipse cx="43" cy="50" rx="14" ry="12"/>
    <ellipse cx="32" cy="57" rx="9" ry="10"/>
    <path d="M 36 53 Q 43 47 50 54" fill="none" stroke="#C31723" stroke-width="1.8" stroke-linecap="round"/>
    <ellipse cx="63" cy="57" rx="10.5" ry="9.5"/>
    <line x1="68" y1="54" x2="79" y2="44" stroke="#FFFFFF" stroke-width="3.2" stroke-linecap="round"/>
    <circle cx="77.5" cy="42" r="2.2"/>
    <circle cx="80.5" cy="45" r="2.2"/>
  </g>
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
      child: Image.asset(
        'assets/images/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => SvgPicture.string(
          iconSvg,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
