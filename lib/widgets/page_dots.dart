import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launch_r/models/layout_models.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/home_page_controller.dart';

class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.controller,
    required this.count,
    required this.color,
    this.defaultIndex,
    this.style = PageIndicatorStyle.dots,
  });

  final PageController controller;
  final int count;
  final Color color;

  final int? defaultIndex;
  final PageIndicatorStyle style;

  void _go(int i) {
    if (!controller.hasClients) return;
    unawaited(HapticFeedback.selectionClick());
    final c = controller;
    if (c is HomePageController) {
      unawaited(
        c.goToLogical(i, duration: Motion.slow, curve: Motion.standard),
      );
    } else {
      unawaited(
        c.animateToPage(i, duration: Motion.slow, curve: Motion.standard),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (count < 2 || style == PageIndicatorStyle.hidden) {
      return const SizedBox.shrink();
    }
    final c = controller;
    final looping = c is HomePageController && c.loop;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        var page = controller.hasClients && controller.position.hasPixels
            ? (controller.page ?? 0.0)
            : controller.initialPage.toDouble();
        if (c is HomePageController) page = c.logicalFraction(page);

        double near(int i) {
          var d = (page - i).abs();
          if (looping) d = math.min(d, count - d);
          return 1 - d.clamp(0.0, 1.0);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _go(i),
                child: style == PageIndicatorStyle.line
                    ? _segment(near(i))
                    : _dot(i, near(i)),
              ),
          ],
        );
      },
    );
  }

  Widget _dot(int i, double near) {
    final c = color.withValues(alpha: 0.35 + 0.65 * near);
    if (i == defaultIndex) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Icon(Icons.home_rounded, size: 11 + near * 2, color: c),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Container(
        width: 6 + near * 2,
        height: 6 + near * 2,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      ),
    );
  }

  Widget _segment(double near) {
    final base = count > 8 ? 12.0 : 18.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
      child: Container(
        width: base + near * 8,
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: color.withValues(alpha: 0.3 + 0.7 * near),
        ),
      ),
    );
  }
}
