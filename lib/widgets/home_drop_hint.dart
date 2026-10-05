import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/theme/launch_r_theme.dart';

class HomeDropHint extends StatelessWidget {
  const HomeDropHint({super.key});

  @override
  Widget build(BuildContext context) {
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
            duration: const Duration(milliseconds: 160),
            child: Center(
              child: AnimatedScale(
                scale: active ? 1.08 : 1,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? LaunchRTheme.accent
                        : LaunchRTheme(Brightness.dark).dragBarBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_to_home_screen_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hold here to add to Home',
                        style: TextStyle(color: Colors.white, fontSize: 13),
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
