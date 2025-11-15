import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';

class CustomLoadingSpinner extends StatelessWidget {
  final Color? color;
  final double size;
  final Duration animationDuration;

  const CustomLoadingSpinner({
    super.key,
    this.color,
    this.size = 50.0,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicatorM3E(
        trackColor: color ?? Colors.green,
        activeColor: color ?? Colors.green,
      ),
    );
  }
}
