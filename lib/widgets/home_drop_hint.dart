import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';

class HomeDropHint extends StatelessWidget {
  const HomeDropHint({super.key});

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final shell = context.watch<ShellController>();
    final d = shell.drag;
    final show =
        d != null &&
        d.zone == Zone.drawer &&
        !shell.dragToHome &&
        (d.fromFolder == null || shell.leftFolder);
    final active = shell.inHomeBand;
    final navBottom = MediaQuery.viewPaddingOf(context).bottom;
    final band = ShellController.bandHeight(navBottom);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: band,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.only(bottom: navBottom),
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: Motion.fast,
            curve: Motion.standard,
            child: Center(
              child: AnimatedScale(
                scale: active ? 1.08 : 1,
                duration: Motion.fast,
                curve: Motion.standard,
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.standard,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: active ? t.accent : t.dragBarBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_to_home_screen_rounded,
                        color: active ? t.onAccent : Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hold here to add to Home',
                        style: TextStyle(
                          color: active ? t.onAccent : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
