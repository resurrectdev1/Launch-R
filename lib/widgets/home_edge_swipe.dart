import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/gesture_models.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/home_gestures.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/gesture_sheets.dart';

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
  bool _armed = false;

  final _pull = ValueNotifier<double>(0);

  double get _k => context.read<LauncherSettings>().gestureSensitivity;

  double get _threshold => _distance / _k;

  bool _usable(GestureSide side) {
    final shell = context.read<ShellController>();
    final busy =
        shell.drawer.value > 0 ||
        shell.folder != null ||
        shell.drag != null ||
        shell.menuOpen ||
        shell.isResizing;
    if (busy) return false;
    return context.read<LauncherSettings>().gestureFor(side).action !=
        GestureAction.none;
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics is! PageMetrics) return false;

    if (n is ScrollStartNotification) {
      _byUser = n.dragDetails != null;
      _over = 0;
      _armed = false;
      _pull.value = 0;
    } else if (n is OverscrollNotification) {
      if (_byUser && n.dragDetails != null) {
        _over += n.overscroll;
        final side = _over > 0 ? GestureSide.left : GestureSide.right;
        _pull.value = _usable(side) ? _over : 0;
        final armed = _pull.value.abs() >= _threshold;
        if (armed && !_armed) unawaited(HapticFeedback.selectionClick());
        _armed = armed;
      }
    } else if (n is ScrollEndNotification) {
      final over = _over;
      final velocity = n.dragDetails?.primaryVelocity?.abs() ?? 0;
      _byUser = false;
      _over = 0;
      _armed = false;
      _pull.value = 0;
      final far = over.abs() >= _threshold;
      final flick =
          over.abs() >= _flickMinDistance / _k &&
          velocity >= _flickVelocity / _k;
      if (far || flick) {
        _fire(over > 0 ? GestureSide.left : GestureSide.right);
      }
    }
    return false;
  }

  void _fire(GestureSide side) {
    if (!_usable(side)) return;
    final gesture = context.read<LauncherSettings>().gestureFor(side);

    unawaited(HapticFeedback.mediumImpact());
    unawaited(runHomeGesture(context, gesture));
  }

  @override
  void dispose() {
    _pull.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LauncherSettings>();
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<double>(
              valueListenable: _pull,
              builder: (context, pull, _) {
                if (pull == 0) return const SizedBox.shrink();
                final side = pull > 0 ? GestureSide.left : GestureSide.right;
                return _EdgeCue(
                  alignRight: pull > 0,
                  progress: (pull.abs() / (_distance / s.gestureSensitivity))
                      .clamp(0.0, 1.0),
                  icon: gestureIcon(s.gestureFor(side).action),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _EdgeCue extends StatelessWidget {
  const _EdgeCue({
    required this.alignRight,
    required this.progress,
    required this.icon,
  });

  final bool alignRight;
  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final ready = progress >= 1.0;
    const size = 44.0;
    final slide = (1 - progress) * 24;
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Transform.translate(
        offset: Offset(alignRight ? slide : -slide, 0),
        child: Opacity(
          opacity: 0.35 + 0.65 * progress,
          child: Container(
            width: size,
            height: size * (0.9 + 0.5 * progress),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: ready ? t.accent : t.menuBg,
              borderRadius: BorderRadius.circular(size / 2),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 10),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: ready ? t.onAccent : t.drawerText,
            ),
          ),
        ),
      ),
    );
  }
}
