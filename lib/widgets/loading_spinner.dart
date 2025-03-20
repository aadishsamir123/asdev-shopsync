import 'package:flutter/material.dart';
import 'dart:math';

class CustomLoadingSpinner extends StatefulWidget {
  final Color color;
  final double size;

  const CustomLoadingSpinner({
    super.key,
    this.color = Colors.green,
    this.size = 50.0,
  });

  @override
  State<CustomLoadingSpinner> createState() => _CustomLoadingSpinnerState();
}

class _CustomLoadingSpinnerState extends State<CustomLoadingSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;
              final phase = (index / 3);
              final animationProgress = ((progress + phase) % 1.0);
              final scale = 0.5 + (0.5 * _computeScaleCurve(animationProgress));
              final opacity =
                  0.25 + (0.75 * _computeOpacityCurve(animationProgress));

              return Container(
                margin: EdgeInsets.symmetric(horizontal: widget.size * 0.05),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: CircleAvatar(
                      backgroundColor: widget.color,
                      radius: widget.size * 0.15,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  double _computeScaleCurve(double progress) {
    return -4 * pow(progress - 0.5, 2) + 1;
  }

  double _computeOpacityCurve(double progress) {
    return -4 * pow(progress - 0.5, 2) + 1;
  }
}
