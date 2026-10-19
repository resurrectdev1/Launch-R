import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/launch_history.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/folder_color_picker.dart';
import 'package:launch_r/widgets/tag_editor_sheet.dart';

void launchFrom(BuildContext context, String pkg) {
  Rect? from;
  final box = context.findRenderObject();
  if (box is RenderBox && box.attached) {
    from = box.localToGlobal(Offset.zero) & box.size;
  }
  context.read<ShellController>().closeFolder();
  context.read<LaunchHistory>().recordLaunch(pkg);
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
      Rect? from;
      final box = context.findRenderObject();
      if (box is RenderBox && box.attached) {
        from = box.localToGlobal(Offset.zero) & box.size;
      }
      context.read<ShellController>().openFolder(zone, fid, from: from);
    case ShortcutItem(:final pkg, :final shortcutId):
      Rect? from;
      final box = context.findRenderObject();
      if (box is RenderBox && box.attached) {
        from = box.localToGlobal(Offset.zero) & box.size;
      }
      context.read<ShellController>().closeFolder();
      unawaited(
        LauncherChannel.instance.startShortcut(
          pkg,
          shortcutId,
          from: from,
          dpr: MediaQuery.devicePixelRatioOf(context),
        ),
      );
    case WidgetItem() || WidgetCover():
      break;
  }
}

int _menuToken = 0;
OverlayEntry? _menuEntry;
Completer<String?>? _menuDone;

bool get itemMenuOpen => _menuEntry != null;

void dismissItemMenu() {
  _menuToken++;
  _closeItemMenu(null);
}

void _closeItemMenu(String? choice) {
  final entry = _menuEntry;
  final done = _menuDone;
  _menuEntry = null;
  _menuDone = null;
  if (entry != null) {
    entry.remove();
    entry.dispose();
  }
  if (done != null && !done.isCompleted) done.complete(choice);
}

class _MenuOption {
  const _MenuOption(
    this.value,
    this.icon,
    this.label, {
    this.iconBytes,
    this.dividerAbove = false,
  });
  final String value;
  final IconData icon;
  final String label;

  final Uint8List? iconBytes;
  final bool dividerAbove;
}

Future<String?> _showOverlayMenu(
  BuildContext context,
  Offset pos,
  LaunchRTheme t,
  List<_MenuOption> options,
) {
  _closeItemMenu(null);
  final done = Completer<String?>();
  final entry = OverlayEntry(
    builder: (_) => _ItemMenu(
      anchor: pos,
      theme: t,
      options: options,
      onChoose: _closeItemMenu,
    ),
  );
  _menuEntry = entry;
  _menuDone = done;
  Overlay.of(context, rootOverlay: true).insert(entry);
  return done.future;
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.anchor,
    required this.theme,
    required this.options,
    required this.onChoose,
  });

  final Offset anchor;
  final LaunchRTheme theme;
  final List<_MenuOption> options;
  final void Function(String? choice) onChoose;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final pad = MediaQuery.paddingOf(context) + const EdgeInsets.all(8);
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => onChoose(null),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _MenuLayout(anchor, pad),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: ((v - 0.9) / 0.1).clamp(0.0, 1.0).toDouble(),
                  child: Transform.scale(
                    scale: v,
                    alignment: Alignment.topLeft,
                    child: child,
                  ),
                ),
                child: Material(
                  color: t.menuBg,
                  elevation: 8,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 168,
                      maxWidth: 280,
                    ),
                    child: IntrinsicWidth(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final o in options) ...[
                              if (o.dividerAbove)
                                Divider(
                                  height: 9,
                                  thickness: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: t.drawerText.withValues(alpha: 0.12),
                                ),
                              InkWell(
                                onTap: () => onChoose(o.value),
                                child: SizedBox(
                                  height: 48,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        if (o.iconBytes != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.memory(
                                              o.iconBytes!,
                                              width: 21,
                                              height: 21,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                            ),
                                          )
                                        else
                                          Icon(
                                            o.icon,
                                            size: 21,
                                            color: t.drawerText,
                                          ),
                                        const SizedBox(width: 14),
                                        Text(
                                          o.label,
                                          style: TextStyle(
                                            color: t.drawerText,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout(this.anchor, this.padding);
  final Offset anchor;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) => BoxConstraints(
    maxWidth: math.max(0.0, c.maxWidth - padding.horizontal),
    maxHeight: math.max(0.0, c.maxHeight - padding.vertical),
  );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxX = size.width - padding.right - childSize.width;
    final x = (anchor.dx - 24)
        .clamp(padding.left, math.max(padding.left, maxX))
        .toDouble();
    const gap = 14.0;
    var y = anchor.dy + gap;
    if (y + childSize.height > size.height - padding.bottom) {
      y = anchor.dy - gap - childSize.height;
    }
    final maxY = size.height - padding.bottom - childSize.height;
    y = y.clamp(padding.top, math.max(padding.top, maxY)).toDouble();
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      anchor != old.anchor || padding != old.padding;
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
  final inDrawer = zone == Zone.drawer;
  final token = ++_menuToken;

  var canEdit = false;
  if (item is WidgetItem) {
    canEdit = await LauncherChannel.instance.canConfigureWidget(item.wid);
    if (token != _menuToken || !context.mounted) return;
  }

  Rect? iconRect;
  final iconBox = context.findRenderObject();
  if (iconBox is RenderBox && iconBox.attached) {
    iconRect = iconBox.localToGlobal(Offset.zero) & iconBox.size;
  }
  final dpr = MediaQuery.devicePixelRatioOf(context);

  var shortcuts = const <AppShortcut>[];
  if (item is AppItem) {
    shortcuts = await LauncherChannel.instance
        .getShortcuts(item.pkg)
        .timeout(
          const Duration(milliseconds: 800),
          onTimeout: () => const <AppShortcut>[],
        );
    if (token != _menuToken || !context.mounted) return;
  }

  final entries = <_MenuOption>[
    if (item is AppItem) ...[
      for (final sc in shortcuts)
        _MenuOption(
          'shortcut:${sc.id}',
          Icons.bolt_rounded,
          sc.label,
          iconBytes: sc.icon,
        ),
      if (fromFolder == null)
        inDrawer
            ? _MenuOption(
                'add',
                Icons.add_to_home_screen_rounded,
                'Add to Home',
                dividerAbove: shortcuts.isNotEmpty,
              )
            : _MenuOption(
                'remove',
                Icons.remove_circle_outline_rounded,
                'Remove',
                dividerAbove: shortcuts.isNotEmpty,
              ),
      _MenuOption(
        'tags',
        Icons.sell_outlined,
        'Tags',
        dividerAbove: shortcuts.isNotEmpty && fromFolder != null,
      ),
      const _MenuOption('hide', Icons.visibility_off_outlined, 'Hide app'),
      const _MenuOption('info', Icons.info_outline_rounded, 'App info'),
      const _MenuOption('uninstall', Icons.delete_outline_rounded, 'Uninstall'),
    ],
    if (item is ShortcutItem)
      const _MenuOption(
        'remove',
        Icons.remove_circle_outline_rounded,
        'Remove',
      ),
    if (item is FolderItem) ...[
      const _MenuOption('rename', Icons.edit_outlined, 'Rename'),
      const _MenuOption('color', Icons.palette_outlined, 'Color'),
      inDrawer
          ? const _MenuOption(
              'dissolve',
              Icons.folder_off_outlined,
              'Ungroup folder',
            )
          : const _MenuOption(
              'remove',
              Icons.remove_circle_outline_rounded,
              'Remove',
            ),
    ],
    if (item is WidgetItem) ...[
      if (canEdit) const _MenuOption('edit', Icons.tune_rounded, 'Edit'),
      if (item.resizable)
        const _MenuOption('resize', Icons.open_in_full_rounded, 'Resize'),
      const _MenuOption(
        'remove',
        Icons.remove_circle_outline_rounded,
        'Remove',
      ),
    ],
  ];

  final choice = await _showOverlayMenu(context, pos, t, entries);
  if (choice == null) return;

  if (choice.startsWith('shortcut:') && item is AppItem) {
    if (context.mounted) context.read<ShellController>().closeFolder();
    unawaited(
      LauncherChannel.instance.startShortcut(
        item.pkg,
        choice.substring('shortcut:'.length),
        from: iconRect,
        dpr: dpr,
      ),
    );
    return;
  }

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
    case 'tags':
      if (context.mounted) showTagEditor(context, (item as AppItem).pkg);
    case 'info':
      unawaited(LauncherChannel.instance.openAppInfo((item as AppItem).pkg));
    case 'uninstall':
      unawaited(LauncherChannel.instance.uninstallApp((item as AppItem).pkg));
    case 'rename':
      shell.openFolder(zone, (item as FolderItem).fid, rename: true);
    case 'color':
      if (context.mounted) {
        showFolderColorPicker(context, zone, (item as FolderItem).fid);
      }
    case 'dissolve':
      model.dissolveFolder(zone, (item as FolderItem).fid);
    case 'edit':
      unawaited(
        LauncherChannel.instance.configureWidget((item as WidgetItem).wid),
      );
    case 'resize':
      shell.startResize((item as WidgetItem).wid);
  }
}
