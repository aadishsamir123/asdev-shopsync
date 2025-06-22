import 'package:flutter/material.dart';
import 'dart:math';

class CustomLoadingSpinner extends StatefulWidget {
  final Color color;
  final double size;
  final Duration animationDuration;

  const CustomLoadingSpinner({
    super.key,
    this.color = Colors.green,
    this.size = 50.0,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<CustomLoadingSpinner> createState() => _CustomLoadingSpinnerState();
}

class _CustomLoadingSpinnerState extends State<CustomLoadingSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _rotationController.repeat();
  }

  @override
  void didUpdateWidget(CustomLoadingSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress indicator
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: CircularSpinnerPainter(
                    color: widget.color,
                    progress: _rotationAnimation.value,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CircularSpinnerPainter extends CustomPainter {
  final Color color;
  final double progress;

  CircularSpinnerPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Animated progress arc that rotates
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Create a rotating arc
    final startAngle =
        (progress * 2 * pi) - (pi / 2); // Rotate the start position
    final sweepAngle = pi; // Half circle arc

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
