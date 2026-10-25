import 'package:flutter/animation.dart';

abstract final class Motion {

  static bool reduced = false;

  static Duration _d(int ms) =>
      reduced ? Duration.zero : Duration(milliseconds: ms);

  static Duration scale(Duration d) => reduced ? Duration.zero : d;

  static Duration get fast => _d(140);

  static Duration get base => _d(220);

  static Duration get slow => _d(300);

  static Duration get drawerClose => _d(200);

  static Duration get emphasized => _d(380);
  static Duration get emphasizedReverse => _d(250);

  static AnimationStyle? get routeStyle =>
      reduced ? AnimationStyle.noAnimation : null;

  static const Curve standard = Curves.easeOutCubic;

  static const Curve exit = Curves.easeInCubic;

  static const Curve emphasizedCurve = Cubic(0.22, 1.12, 0.36, 1.0);
}
