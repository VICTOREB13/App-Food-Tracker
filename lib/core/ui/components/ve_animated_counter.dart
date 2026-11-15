import 'package:flutter/material.dart';

/// Smooth animated rolling counter widget using [TweenAnimationBuilder].
class VeAnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String Function(num)? formatter;
  final Duration duration;
  final Curve curve;

  const VeAnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.formatter,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, animValue, child) {
        final text = formatter != null
            ? formatter!(animValue)
            : animValue.toInt().toString();
        return Text(text, style: style);
      },
    );
  }
}
