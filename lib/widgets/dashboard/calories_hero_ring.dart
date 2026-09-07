import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

class CaloriesHeroRing extends StatelessWidget {
  final double current;
  final double goal;
  final double size;
  final double strokeWidth;

  const CaloriesHeroRing({
    super.key,
    required this.current,
    required this.goal,
    this.size = 96,
    this.strokeWidth = 9,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final isDark = AppColors.isDark(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CaloriesRingPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              trackColor: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
              gradientStart: AppColors.primary,
              gradientEnd: AppColors.caloriesFlame,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaloriesRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color gradientStart;
  final Color gradientEnd;

  _CaloriesRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        colors: [gradientStart, gradientEnd, gradientStart],
        transform: const GradientRotation(startAngle),
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CaloriesRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.gradientStart != gradientStart ||
        oldDelegate.gradientEnd != gradientEnd;
  }
}
