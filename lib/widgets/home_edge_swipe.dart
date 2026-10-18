import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/gesture_models.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/home_gestures.dart';

class HomeEdgeSwipe extends StatefulWidget {
  const HomeEdgeSwipe({super.key, required this.child});

  final Widget child;

  @override
  State<HomeEdgeSwipe> createState() => _HomeEdgeSwipeState();
}

class _HomeEdgeSwipeState extends State<HomeEdgeSwipe> {
  static const _distance = 36.0;

  static const _flickVelocity = 800.0;
  static const _flickMinDistance = 6.0;

  bool _byUser = false;
  double _over = 0;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics is! PageMetrics) return false;

    if (n is ScrollStartNotification) {
      _byUser = n.dragDetails != null;
      _over = 0;
    } else if (n is OverscrollNotification) {
      if (_byUser && n.dragDetails != null) _over += n.overscroll;
    } else if (n is ScrollEndNotification) {
      final over = _over;
      final velocity = n.dragDetails?.primaryVelocity?.abs() ?? 0;
      _byUser = false;
      _over = 0;
      final far = over.abs() >= _distance;
      final flick =
          over.abs() >= _flickMinDistance && velocity >= _flickVelocity;
      if (far || flick) {
        _fire(over > 0 ? GestureSide.left : GestureSide.right);
      }
    }
    return false;
  }

  void _fire(GestureSide side) {
    final shell = context.read<ShellController>();
    final busy =
        shell.drawer.value > 0 ||
        shell.folder != null ||
        shell.drag != null ||
        shell.menuOpen ||
        shell.isResizing;
    if (busy) return;

    final gesture = context.read<LauncherSettings>().gestureFor(side);
    if (gesture.action == GestureAction.none) return;

    unawaited(HapticFeedback.mediumImpact());
    unawaited(runHomeGesture(context, gesture));
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
  }
}
