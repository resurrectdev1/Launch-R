import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/folder_color_picker.dart';

void launchFrom(BuildContext context, String pkg) {
  Rect? from;
  final box = context.findRenderObject();
  if (box is RenderBox && box.attached) {
    from = box.localToGlobal(Offset.zero) & box.size;
  }
  context.read<ShellController>().closeFolder();
  unawaited(
    LauncherChannel.instance.launchApp(
      pkg,
      from: from,
      dpr: MediaQuery.devicePixelRatioOf(context),
    ),
  );
}

void openItem(BuildContext context, LItem item, Zone zone) {
  switch (item) {
    case AppItem(:final pkg):
      launchFrom(context, pkg);
    case FolderItem(:final fid):
      context.read<ShellController>().openFolder(zone, fid);
  }
}

PopupMenuItem<String> _entry(
  LaunchRTheme t,
  String value,
  IconData icon,
  String text,
) {
  return PopupMenuItem<String>(
    value: value,
    height: 48,
    child: Row(
      children: [
        Icon(icon, size: 21, color: t.drawerText),
        const SizedBox(width: 14),
        Text(text, style: TextStyle(color: t.drawerText, fontSize: 15)),
      ],
    ),
  );
}

Future<void> showItemMenu(
  BuildContext context,
  Offset pos,
  LItem item,
  Zone zone, {
  String? fromFolder,
}) async {
  final model = context.read<LauncherModel>();
  final shell = context.read<ShellController>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  final t = LaunchRTheme.of(context);
  final size = MediaQuery.sizeOf(context);
  final inDrawer = zone == Zone.drawer;

  final entries = <PopupMenuEntry<String>>[
    if (item is AppItem) ...[
      if (fromFolder == null)
        inDrawer
            ? _entry(t, 'add', Icons.add_to_home_screen_rounded, 'Add to Home')
            : _entry(
                t,
                'remove',
                Icons.remove_circle_outline_rounded,
                'Remove',
              ),
      _entry(t, 'hide', Icons.visibility_off_outlined, 'Hide app'),
      _entry(t, 'info', Icons.info_outline_rounded, 'App info'),
      _entry(t, 'uninstall', Icons.delete_outline_rounded, 'Uninstall'),
    ],
    if (item is FolderItem) ...[
      _entry(t, 'rename', Icons.edit_outlined, 'Rename'),
      _entry(t, 'color', Icons.palette_outlined, 'Color'),
      inDrawer
          ? _entry(t, 'dissolve', Icons.folder_off_outlined, 'Ungroup folder')
          : _entry(t, 'remove', Icons.remove_circle_outline_rounded, 'Remove'),
    ],
  ];

  final choice = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      pos.dx,
      pos.dy,
      size.width - pos.dx,
      size.height - pos.dy,
    ),
    color: t.menuBg,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    items: entries,
  );
  if (choice == null) return;

  switch (choice) {
    case 'add':
      final ok = model.addToHome((item as AppItem).pkg);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(ok ? 'Added to Home' : 'Already on Home'),
          duration: const Duration(seconds: 2),
        ),
      );
    case 'remove':
      model.removeFromHome(item.id);
    case 'hide':
      final pkg = (item as AppItem).pkg;
      final label = model.labelForPkg(pkg);
      model.hideApp(pkg);
      messenger?.showSnackBar(
        SnackBar(
          content: Text('$label hidden. Manage in Launcher settings'),
          duration: const Duration(seconds: 3),
        ),
      );
    case 'info':
      LauncherChannel.instance.openAppInfo((item as AppItem).pkg);
    case 'uninstall':
      LauncherChannel.instance.uninstallApp((item as AppItem).pkg);
    case 'rename':
      shell.openFolder(zone, (item as FolderItem).fid, rename: true);
    case 'color':
      if (context.mounted) {
        showFolderColorPicker(context, zone, (item as FolderItem).fid);
      }
    case 'dissolve':
      model.dissolveFolder(zone, (item as FolderItem).fid);
  }
}
