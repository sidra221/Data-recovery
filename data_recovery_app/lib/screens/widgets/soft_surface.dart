import 'package:flutter/material.dart';

class SoftSurface extends StatelessWidget {
  const SoftSurface({
    super.key,
    required this.child,
    this.radius = 16,
    this.color = Colors.white,
    this.shadowColor = const Color(0x14000000),
  });

  final Widget child;
  final double radius;
  final Color color;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Material(
          color: color,
          child: child,
        ),
      ),
    );
  }
}
