import 'package:flutter/animation.dart';

abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 140);

  static const Duration base = Duration(milliseconds: 220);

  static const Duration slow = Duration(milliseconds: 300);

  static const Duration emphasized = Duration(milliseconds: 380);
  static const Duration emphasizedReverse = Duration(milliseconds: 250);

  static const Curve standard = Curves.easeOutCubic;

  static const Curve exit = Curves.easeInCubic;

  static const Curve emphasizedCurve = Cubic(0.22, 1.12, 0.36, 1.0);
}
