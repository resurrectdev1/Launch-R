import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/theme/motion.dart';

class HoldAnimator extends StatefulWidget {
  const HoldAnimator({
    super.key,
    required this.style,
    required this.child,
    this.intensity = 1.0,
  });

  final HoldAnimation style;
  final Widget child;

  final double intensity;

  @override
  State<HoldAnimator> createState() => _HoldAnimatorState();
}

class _HoldAnimatorState extends State<HoldAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  static Duration _period(HoldAnimation a) => switch (a) {
    HoldAnimation.sway => const Duration(milliseconds: 900),
    HoldAnimation.wiggle => const Duration(milliseconds: 280),
    HoldAnimation.pulse => const Duration(milliseconds: 800),
    HoldAnimation.bounce => const Duration(milliseconds: 600),
    HoldAnimation.tilt => const Duration(milliseconds: 1400),
  };

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _c.duration = _period(widget.style);
    if (!Motion.reduced) _c.repeat();
  }

  @override
  void didUpdateWidget(HoldAnimator old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) {
      _c.stop();
      _start();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _apply(Widget child, double t, double k) {
    const tau = 2 * math.pi;
    switch (widget.style) {
      case HoldAnimation.sway:
        return Transform.rotate(
          angle: math.sin(t * tau) * 0.07 * k,
          alignment: Alignment.topCenter,
          child: child,
        );
      case HoldAnimation.wiggle:
        return Transform.rotate(
          angle: math.sin(t * tau) * 0.05 * k,
          child: child,
        );
      case HoldAnimation.pulse:
        return Transform.scale(
          scale: 1 + math.sin(t * tau) * 0.07 * k,
          child: child,
        );
      case HoldAnimation.bounce:
        return Transform.translate(
          offset: Offset(0, -(math.sin(t * math.pi).abs()) * 8 * k),
          child: child,
        );
      case HoldAnimation.tilt:
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX(math.sin(t * tau) * 0.28 * k)
            ..rotateY(math.cos(t * tau) * 0.28 * k),
          child: child,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced) return widget.child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Motion.slow,
      curve: Motion.standard,
      child: widget.child,
      builder: (context, amp, child) => AnimatedBuilder(
        animation: _c,
        child: child,
        builder: (context, child) =>
            _apply(child!, _c.value, amp * widget.intensity),
      ),
    );
  }
}
