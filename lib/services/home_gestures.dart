import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/gesture_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/launch_history.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/widgets/settings_sheet.dart';

void _toast(BuildContext context, String text, {SnackBarAction? action}) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(text),
      action: action,
      duration: const Duration(seconds: 3),
    ),
  );
}

Future<void> runHomeGesture(BuildContext context, HomeGesture gesture) async {
  final shell = context.read<ShellController>();
  final ch = LauncherChannel.instance;

  switch (gesture.action) {
    case GestureAction.none:
      return;

    case GestureAction.openApp:
      final pkg = gesture.pkg;
      final model = context.read<LauncherModel>();
      if (pkg == null) {
        _toast(context, 'Pick an app for this gesture in Launcher settings');
        return;
      }
      if (!model.hasApp(pkg)) {
        _toast(
          context,
          '${gesture.label ?? 'That app'} is no longer installed',
        );
        return;
      }
      context.read<LaunchHistory>().recordLaunch(pkg);
      unawaited(ch.launchApp(pkg, dpr: MediaQuery.devicePixelRatioOf(context)));

    case GestureAction.recents:
      final ok = await ch.openRecents();
      if (!ok && context.mounted) {
        _toast(
          context,
          'Recent apps needs the Launch-R accessibility service',
          action: SnackBarAction(
            label: 'Turn on',
            onPressed: () => unawaited(ch.openAccessibilitySettings()),
          ),
        );
      }

    case GestureAction.settings:
      showLaunchRSettings(context);

    case GestureAction.drawer:
      shell.openDrawer();

    case GestureAction.drawerSearch:
      shell.openDrawerWithSearch();

    case GestureAction.notifications:
      unawaited(ch.expandNotifications());
  }
}
