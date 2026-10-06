import 'package:flutter/material.dart';
import '../../models/weight_log.dart';

/// Auxiliary canvas renderers for empty state and single log state in weight charts.
class WeightChartRenderUtils {
  /// Renders subtle empty placeholder when there are 0 logs.
  static void paintEmptyState(Canvas canvas, Size size, TextStyle labelStyle) {
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

  /// Renders a single distinct marker and baseline when there is exactly 1 log.
  static void paintSingleLogState({
    required Canvas canvas,
    required Size size,
    required WeightLog log,
    required Color lineColor,
    required Color gridColor,
    required TextStyle labelStyle,
  }) {
    const paddingLeft = 46.0;
    const paddingRight = 16.0;
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

    // Halo, primary marker and core dot
    canvas.drawCircle(centerPoint, 10.0, Paint()..color = lineColor.withValues(alpha: 0.25)..style = PaintingStyle.fill);
    canvas.drawCircle(centerPoint, 5.0, Paint()..color = lineColor..style = PaintingStyle.fill);
    canvas.drawCircle(centerPoint, 2.0, Paint()..color = Colors.white..style = PaintingStyle.fill);

    // Text label above marker
    final labelSpan = TextSpan(
      text: '${log.weight.toStringAsFixed(1)} kg',
      style: labelStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: lineColor),
    );
    final textPainter = TextPainter(text: labelSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset(centerPoint.dx - (textPainter.width / 2), centerPoint.dy - textPainter.height - 8));

    // Date text below marker
    final dateStr = '${log.date.day.toString().padLeft(2, '0')}/${log.date.month.toString().padLeft(2, '0')}';
    final dateSpan = TextSpan(text: dateStr, style: labelStyle.copyWith(fontSize: 10));
    final datePainter = TextPainter(text: dateSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
    datePainter.paint(canvas, Offset(centerPoint.dx - (datePainter.width / 2), centerPoint.dy + 8));
  }
}
