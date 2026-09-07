import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/weight_log.dart';
import '../../services/theme_manager.dart';

/// Hardware-accelerated CustomPainter for smooth 60/120 FPS weight trend visualization.
class WeightLineChartPainter extends CustomPainter {
  final List<WeightLog> logs;
  final Color lineColor;
  final Color gradientColor;
  final Color gridColor;
  final TextStyle labelStyle;

  const WeightLineChartPainter({
    required this.logs,
    this.lineColor = AppColors.primary,
    this.gradientColor = AppColors.primary,
    this.gridColor = const Color(0xFF27272A),
    this.labelStyle = const TextStyle(
      fontSize: 10,
      color: Color(0xFFA1A1AA),
      fontWeight: FontWeight.w500,
    ),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Edge Case: 0 logs (draws subtle empty placeholder/text)
    if (logs.isEmpty) {
      _paintEmptyState(canvas, size);
      return;
    }

    // Edge Case: 1 log (draws single distinct marker and baseline)
    if (logs.length == 1) {
      _paintSingleLogState(canvas, size, logs.first);
      return;
    }

    // Standard Case: 2+ logs (smooth cubic Bézier trend chart)
    _paintMultiLogChart(canvas, size);
  }

  void _paintEmptyState(Canvas canvas, Size size) {
    const placeholder = 'Sin registros de peso en este rango';
    final textSpan = TextSpan(
      text: placeholder,
      style: labelStyle.copyWith(
        fontSize: 12,
        color: const Color(0xFF71717A),
        fontStyle: FontStyle.italic,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 32);

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  void _paintSingleLogState(Canvas canvas, Size size, WeightLog log) {
    const paddingLeft = 46.0;
    final paddingRight = 16.0;
    final baselineY = size.height * 0.55;

    // Subtle horizontal baseline
    final baselinePaint = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(paddingLeft, baselineY),
      Offset(size.width - paddingRight, baselineY),
      baselinePaint,
    );

    final centerPoint = Offset(
      paddingLeft + (size.width - paddingLeft - paddingRight) / 2,
      baselineY,
    );

    // Outer glow halo
    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerPoint, 10.0, glowPaint);

    // Primary marker dot
    final markerPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerPoint, 5.0, markerPaint);

    // Center core dot
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerPoint, 2.0, corePaint);

    // Text label above marker
    final labelSpan = TextSpan(
      text: '${log.weight.toStringAsFixed(1)} kg',
      style: labelStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: lineColor,
      ),
    );
    final textPainter = TextPainter(
      text: labelSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        centerPoint.dx - (textPainter.width / 2),
        centerPoint.dy - textPainter.height - 8,
      ),
    );

    // Date text below marker
    final dateStr = '${log.date.day.toString().padLeft(2, '0')}/${log.date.month.toString().padLeft(2, '0')}';
    final dateSpan = TextSpan(
      text: dateStr,
      style: labelStyle.copyWith(fontSize: 10),
    );
    final datePainter = TextPainter(
      text: dateSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    datePainter.paint(
      canvas,
      Offset(
        centerPoint.dx - (datePainter.width / 2),
        centerPoint.dy + 8,
      ),
    );
  }

  void _paintMultiLogChart(Canvas canvas, Size size) {
    const paddingLeft = 44.0;
    const paddingRight = 16.0;
    const paddingTop = 18.0;
    const paddingBottom = 24.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Sort ascending by date to guarantee chronological monotonicity
    final sorted = List<WeightLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    double minWeight = sorted.first.weight;
    double maxWeight = sorted.first.weight;
    for (final log in sorted) {
      if (log.weight < minWeight) minWeight = log.weight;
      if (log.weight > maxWeight) maxWeight = log.weight;
    }

    // Apply safe padding to vertical bounds (prevent division by zero or edge clamping)
    if ((maxWeight - minWeight).abs() < 0.001) {
      minWeight = math.max(0.0, minWeight - 1.5);
      maxWeight = maxWeight + 1.5;
    } else {
      final pad = (maxWeight - minWeight) * 0.15;
      minWeight = math.max(0.0, minWeight - pad);
      maxWeight = maxWeight + pad;
    }

    final weightRange = maxWeight - minWeight;

    // Draw horizontal grid lines and Y-axis labels at min, mid, and max
    final gridLevels = [
      maxWeight,
      (minWeight + maxWeight) / 2,
      minWeight,
    ];

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final level in gridLevels) {
      final yFraction = (level - minWeight) / weightRange;
      final yPos = paddingTop + chartHeight * (1.0 - yFraction);

      // Grid line across chart
      canvas.drawLine(
        Offset(paddingLeft, yPos),
        Offset(size.width - paddingRight, yPos),
        gridPaint,
      );

      // Y-axis label
      final labelText = '${level.toStringAsFixed(1)} kg';
      final textPainter = TextPainter(
        text: TextSpan(text: labelText, style: labelStyle),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 4, yPos - (textPainter.height / 2)),
      );
    }

    // Map log points to canvas coordinates
    final points = <Offset>[];
    for (int i = 0; i < sorted.length; i++) {
      final log = sorted[i];
      final xFraction = i / (sorted.length - 1);
      final yFraction = (log.weight - minWeight) / weightRange;

      final x = paddingLeft + (chartWidth * xFraction);
      final y = paddingTop + (chartHeight * (1.0 - yFraction));
      if (x.isFinite && y.isFinite) {
        points.add(Offset(x, y));
      }
    }

    if (points.length < 2) return;

    // Build smooth cubic Bézier line path
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final dxHalf = (p1.dx - p0.dx) / 2;
      final cp1 = Offset(p0.dx + dxHalf, p0.dy);
      final cp2 = Offset(p0.dx + dxHalf, p1.dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    // Draw gradient fill beneath the curve
    final baselineY = paddingTop + chartHeight;
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, baselineY)
      ..lineTo(points.first.dx, baselineY)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          gradientColor.withValues(alpha: 0.18),
          gradientColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw the main trend curve line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw points along the curve
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], 2.5, pointPaint);
    }

    // Accent the latest point with halo and white core
    final lastPoint = points.last;
    final haloPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 7.0, haloPaint);
    canvas.drawCircle(lastPoint, 4.0, pointPaint);
    canvas.drawCircle(lastPoint, 1.5, Paint()..color = Colors.white);

    // Draw date labels on X-axis (first and last dates)
    final firstDateStr =
        '${sorted.first.date.day.toString().padLeft(2, '0')}/${sorted.first.date.month.toString().padLeft(2, '0')}';
    final lastDateStr =
        '${sorted.last.date.day.toString().padLeft(2, '0')}/${sorted.last.date.month.toString().padLeft(2, '0')}';

    final firstDatePainter = TextPainter(
      text: TextSpan(text: firstDateStr, style: labelStyle),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout();
    firstDatePainter.paint(
      canvas,
      Offset(points.first.dx, baselineY + 6),
    );

    final lastDatePainter = TextPainter(
      text: TextSpan(text: lastDateStr, style: labelStyle),
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    )..layout();
    lastDatePainter.paint(
      canvas,
      Offset(points.last.dx - lastDatePainter.width, baselineY + 6),
    );
  }

  @override
  bool shouldRepaint(covariant WeightLineChartPainter oldDelegate) {
    if (oldDelegate.logs.length != logs.length) return true;
    if (oldDelegate.lineColor != lineColor) return true;
    if (oldDelegate.gradientColor != gradientColor) return true;
    if (oldDelegate.gridColor != gridColor) return true;
    if (oldDelegate.labelStyle != labelStyle) return true;
    for (int i = 0; i < logs.length; i++) {
      if (oldDelegate.logs[i].id != logs[i].id ||
          oldDelegate.logs[i].weight != logs[i].weight ||
          oldDelegate.logs[i].date != logs[i].date) {
        return true;
      }
    }
    return false;
  }
}
