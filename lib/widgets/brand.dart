import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Logo de StepMind (cabeza con escalera).
class StepMindLogo extends StatelessWidget {
  final double size;

  const StepMindLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Logo de StepMind',
    );
  }
}

/// Fondo con el degradado petróleo de la marca.
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.petrolGradient),
      child: child,
    );
  }
}

/// Tarjeta con degradado y bordes redondeados.
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient = AppColors.petrolGradient,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Anillo de progreso con el valor en el centro.
class ProgressRing extends StatelessWidget {
  /// Entre 0 y 1.
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Widget? center;
  final String semanticsLabel;

  const ProgressRing({
    super.key,
    required this.value,
    required this.semanticsLabel,
    this.size = 96,
    this.stroke = 10,
    this.color = AppColors.orange,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      value: '${(value * 100).round()} %',
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, animated, child) => CustomPaint(
            painter: _RingPainter(animated, stroke, color),
            child: child,
          ),
          child: Center(child: ExcludeSemantics(child: center)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color color;

  _RingPainter(this.value, this.stroke, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, track);
    if (value <= 0) return;
    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * value, false, progress);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.stroke != stroke;
}
