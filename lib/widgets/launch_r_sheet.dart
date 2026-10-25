import 'package:flutter/material.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';

enum SheetSize {
  compact(0.7),

  standard(0.8),

  tall(0.88);

  const SheetSize(this.fraction);
  final double fraction;
}

class LaunchRSheet extends StatelessWidget {
  const LaunchRSheet({
    super.key,
    required this.child,
    this.title,
    this.size = SheetSize.standard,
    this.scrollable = false,
    this.keyboardAware = false,
  });

  final Widget child;

  final String? title;

  final SheetSize size;

  final bool scrollable;

  final bool keyboardAware;

  static const double radius = 32;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * size.fraction;

    final body = scrollable
        ? SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, title == null ? 16 : 0, 24, 20),
            child: child,
          )
        : child;

    final sheet = Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: t.menuBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            if (title != null) SheetTitle(title!),
            Flexible(child: body),
          ],
        ),
      ),
    );

    if (!keyboardAware) return sheet;
    return AnimatedPadding(
      duration: Motion.fast,
      curve: Motion.standard,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: sheet,
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: t.drawerTextMuted,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        text,
        style: TextStyle(
          color: t.drawerText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
