import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/theme_manager.dart';

/// Un anillo de carga estilizado y elegante con terminales redondeadas (StrokeCap.round),
/// rotación suave y arco dinámico, diseñado según las especificaciones de 'anillo de carga.mp4'.
class VeLoadingRing extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final double? progress;
  final Widget? child;

  const VeLoadingRing({
    super.key,
    this.size = 40.0,
    this.strokeWidth = 3.5,
    this.color,
    this.trackColor,
    this.progress,
    this.child,
  });

  @override
  State<VeLoadingRing> createState() => _VeLoadingRingState();
}

class _VeLoadingRingState extends State<VeLoadingRing>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  AnimationController? _progressController;
  Animation<double>? _progressAnimation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.progress != null) {
      _currentProgress = widget.progress!.clamp(0.0, 1.0);
      _setupProgressAnimation(_currentProgress, _currentProgress);
    } else {
      _rotationController.repeat();
    }
  }

  void _setupProgressAnimation(double from, double to) {
    _progressController?.dispose();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _progressAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _progressController!, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _progressController!.forward();
  }

  @override
  void didUpdateWidget(covariant VeLoadingRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress != null) {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
      final newTarget = widget.progress!.clamp(0.0, 1.0);
      final currentVal = _progressAnimation?.value ?? _currentProgress;
      if (oldWidget.progress == null || (newTarget - currentVal).abs() > 0.001) {
        _setupProgressAnimation(currentVal, newTarget);
        _currentProgress = newTarget;
      }
    } else {
      _progressController?.dispose();
      _progressController = null;
      _progressAnimation = null;
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _progressController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.primary;
    final effectiveTrack = widget.trackColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.08));

    final effectiveProgress = widget.progress != null
        ? (_progressAnimation?.value ?? _currentProgress)
        : null;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, _) {
          return CustomPaint(
            painter: _VeLoadingRingPainter(
              progress: effectiveProgress,
              animationValue: _rotationController.value,
              color: effectiveColor,
              trackColor: effectiveTrack,
              strokeWidth: widget.strokeWidth,
            ),
            child: widget.child != null
                ? Center(child: widget.child)
                : null,
          );
        },
      ),
    );
  }
}

class _VeLoadingRingPainter extends CustomPainter {
  final double? progress;
  final double animationValue;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _VeLoadingRingPainter({
    required this.progress,
    required this.animationValue,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) return;

    // 1. Pista circular de fondo
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Arco activo
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    if (progress != null) {
      // Modo determinado: arco que crece suavemente desde la parte superior
      const startAngle = -math.pi / 2;
      final sweepAngle = (progress!.clamp(0.0, 1.0)) * 2 * math.pi;
      if (sweepAngle > 0) {
        canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
      }
    } else {
      // Modo indeterminado: rotación continua fluida inspirada en anillo de carga.mp4
      final startAngle = animationValue * 2 * math.pi;
      final sweepWave = (math.sin(animationValue * 2 * math.pi) + 1.0) / 2.0;
      final sweepAngle = (0.35 * math.pi) + (sweepWave * 0.90 * math.pi);

      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VeLoadingRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
