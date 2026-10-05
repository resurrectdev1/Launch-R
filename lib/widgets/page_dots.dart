import 'package:flutter/material.dart';

class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.controller,
    required this.count,
    required this.color,
    this.defaultIndex,
  });

  final PageController controller;
  final int count;
  final Color color;

  final int? defaultIndex;

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients && controller.position.hasPixels
            ? (controller.page ?? 0.0)
            : controller.initialPage.toDouble();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Builder(
                builder: (_) {
                  final near = 1 - (page - i).abs().clamp(0.0, 1.0);
                  final c = color.withValues(alpha: 0.35 + 0.65 * near);
                  if (i == defaultIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.home_rounded,
                        size: 11 + near * 2,
                        color: c,
                      ),
                    );
                  }
                  return Container(
                    width: 6 + near * 2,
                    height: 6 + near * 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
