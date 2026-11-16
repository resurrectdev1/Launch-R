import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';

class DragActionBar extends StatefulWidget {
  const DragActionBar({super.key});

  @override
  State<DragActionBar> createState() => _DragActionBarState();
}

class _DragActionBarState extends State<DragActionBar> {
  static const _revealStrip = 24.0;
  static const _barTop = 10.0;
  static const _barHeight = 70.0;
  static const _hideMargin = 14.0;

  late final ShellController _shell;
  bool _revealed = false;
  double _inset = 0;

  @override
  void initState() {
    super.initState();
    _shell = context.read<ShellController>();
    _shell.dragPos.addListener(_onPos);
  }

  @override
  void dispose() {
    _shell.dragPos.removeListener(_onPos);
    super.dispose();
  }

  void _onPos() {
    if (!mounted) return;
    final pos = _shell.dragPos.value;
    if (pos == null) {
      if (_revealed) setState(() => _revealed = false);
      return;
    }
    if (!_revealed && pos.dy <= _inset + _revealStrip) {
      unawaited(HapticFeedback.selectionClick());
      setState(() => _revealed = true);
    } else if (_revealed &&
        pos.dy > _inset + _barTop + _barHeight + _hideMargin) {
      setState(() => _revealed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final d = shell.drag;
    final eligible = d != null && (d.fromFolder == null || shell.leftFolder);
    final show = eligible && _revealed;
    _inset = MediaQuery.paddingOf(context).top;
    final top = _inset + _barTop;
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: _inset + 5,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: eligible && !show ? 1 : 0,
                duration: Motion.fast,
                curve: Motion.standard,
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55000000), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: top),
            child: AnimatedSwitcher(
              duration: Motion.fast,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: show
                  ? _Bar(key: const ValueKey('bar'), data: d)
                  : const SizedBox.shrink(key: ValueKey('none')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({super.key, required this.data});
  final DragData data;

  @override
  Widget build(BuildContext context) {
    final model = context.read<LauncherModel>();
    final ch = LauncherChannel.instance;
    final item = data.item;
    final fromHome = data.zone != Zone.drawer;

    final actions = <Widget>[
      if (fromHome)
        _Action(
          icon: Icons.remove_circle_outline_rounded,
          label: 'Remove',
          onDrop: (d) => model.removeDragged(d),
        ),
      if (item is AppItem) ...[
        _Action(
          icon: Icons.info_outline_rounded,
          label: 'App info',
          onDrop: (_) => ch.openAppInfo(item.pkg),
        ),
        _Action(
          icon: Icons.delete_outline_rounded,
          label: 'Uninstall',
          onDrop: (_) => ch.uninstallApp(item.pkg),
        ),
      ],
      if (item is FolderItem && !fromHome)
        _Action(
          icon: Icons.folder_off_outlined,
          label: 'Ungroup',
          onDrop: (_) => model.dissolveFolder(Zone.drawer, item.fid),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: LaunchRTheme.of(context).dragBarBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(children: actions.map((a) => Expanded(child: a)).toList()),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onDrop,
  });

  final IconData icon;
  final String label;
  final void Function(DragData data) onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (_) {
        unawaited(HapticFeedback.selectionClick());
        return true;
      },
      onAcceptWithDetails: (d) {
        unawaited(HapticFeedback.mediumImpact());
        onDrop(d.data);
      },
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.standard,
          height: 58,
          decoration: BoxDecoration(
            color: active ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11.5),
              ),
            ],
          ),
        );
      },
    );
  }
}
