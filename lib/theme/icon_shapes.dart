import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:launch_r/models/launcher_models.dart';

Path iconShapePath(IconShape shape, Size size) {
  final rect = Offset.zero & size;
  final w = size.width;
  switch (shape) {
    case IconShape.circle:
      return Path()..addOval(rect);
    case IconShape.rounded:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.24)));
    case IconShape.square:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.08)));
    case IconShape.teardrop:
      final big = Radius.circular(w / 2);
      return Path()..addRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: big,
          topRight: big,
          bottomLeft: big,
          bottomRight: Radius.circular(w * 0.12),
        ),
      );
    case IconShape.squircle:
      const n = 4.6;
      const steps = 160;
      final rx = size.width / 2;
      final ry = size.height / 2;
      final path = Path();
      for (var i = 0; i <= steps; i++) {
        final t = 2 * math.pi * i / steps;
        final c = math.cos(t);
        final s = math.sin(t);
        final x = rx + rx * c.sign * math.pow(c.abs(), 2 / n).toDouble();
        final y = ry + ry * s.sign * math.pow(s.abs(), 2 / n).toDouble();
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path..close();
  }
}

class IconShapeClipper extends CustomClipper<Path> {
  const IconShapeClipper(this.shape);
  final IconShape shape;

  @override
  Path getClip(Size size) => iconShapePath(shape, size);

  @override
  bool shouldReclip(IconShapeClipper old) => old.shape != shape;
}
