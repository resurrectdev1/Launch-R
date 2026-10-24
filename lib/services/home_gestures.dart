import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/gesture_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
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

Future<void> lockScreenFromHome(BuildContext context) async {
  final ch = LauncherChannel.instance;
  final ok = await ch.lockScreen();
  if (ok || !context.mounted) return;
  _toast(
    context,
    'Double tap to lock needs the Launch-R accessibility service '
    'and Android 9 or newer',
    action: SnackBarAction(
      label: 'Turn on',
      onPressed: () => unawaited(ch.openAccessibilitySettings()),
    ),
  );
}

class HomeDoubleTap {
  HomeDoubleTap._();

  static const _maxGap = Duration(milliseconds: 320);
  static const _maxTapTime = Duration(milliseconds: 250);
  static const _maxApart = 100.0;
  static const _slop = 18.0;

  static Offset? _downAt;
  static DateTime? _downTime;
  static Offset? _lastTapAt;
  static DateTime? _lastTapTime;

  static void down(Offset pos) {
    _downAt = pos;
    _downTime = DateTime.now();
  }

  static bool up(Offset pos) {
    final start = _downAt;
    final startTime = _downTime;
    _downAt = null;
    _downTime = null;
    if (start == null || startTime == null) return false;

    final now = DateTime.now();
    final isTap =
        (pos - start).distance <= _slop &&
        now.difference(startTime) <= _maxTapTime;
    if (!isTap) {
      _lastTapAt = null;
      _lastTapTime = null;
      return false;
    }

    final prevAt = _lastTapAt;
    final prevTime = _lastTapTime;
    if (prevAt != null &&
        prevTime != null &&
        now.difference(prevTime) <= _maxGap &&
        (pos - prevAt).distance <= _maxApart) {
      _lastTapAt = null;
      _lastTapTime = null;
      return true;
    }
    _lastTapAt = pos;
    _lastTapTime = now;
    return false;
  }

  static void cancel() {
    _downAt = null;
    _downTime = null;
    _lastTapAt = null;
    _lastTapTime = null;
  }

  static void handleUp(BuildContext context, Offset pos) {
    if (!up(pos)) return;
    final settings = context.read<LauncherSettings>();
    if (!settings.doubleTapLock) return;
    final shell = context.read<ShellController>();
    if (shell.drag != null ||
        shell.folder != null ||
        shell.menuOpen ||
        shell.isResizing ||
        shell.drawer.value > 0) {
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    unawaited(lockScreenFromHome(context));
  }
}
