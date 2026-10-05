import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';

class DragActionBar extends StatelessWidget {
  const DragActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final d = shell.drag;
    final show = d != null && (d.fromFolder == null || shell.leftFolder);
    final top = MediaQuery.paddingOf(context).top + 10;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
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
        color: LaunchRTheme(Brightness.dark).dragBarBg,
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
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
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
