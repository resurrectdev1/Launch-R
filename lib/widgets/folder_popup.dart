import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/draggable_item.dart';
import 'package:launch_r/widgets/folder_color_picker.dart';
import 'package:launch_r/widgets/item_actions.dart';
import 'package:launch_r/widgets/page_dots.dart';

class FolderPopup extends StatelessWidget {
  const FolderPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final model = context.watch<LauncherModel>();
    final open = shell.folder;
    if (open == null) return const SizedBox.shrink();

    final folder = model.folderOf(open.zone, open.fid);
    if (folder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => shell.closeFolder());
      return const SizedBox.shrink();
    }

    final hidden = shell.leftFolder;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: hidden,
        child: AnimatedOpacity(
          opacity: hidden ? 0 : 1,
          duration: const Duration(milliseconds: 120),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: shell.closeFolder,
                  child: const ColoredBox(color: Color(0x59000000)),
                ),
              ),
              Center(
                child: _Panel(
                  key: ValueKey(folder.fid),
                  zone: open.zone,
                  folder: folder,
                  autofocusTitle: shell.renameRequested,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatefulWidget {
  const _Panel({
    super.key,
    required this.zone,
    required this.folder,
    required this.autofocusTitle,
  });

  final Zone zone;
  final FolderItem folder;
  final bool autofocusTitle;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  static const _cols = 4;
  static const _perPage = 16;
  static const _cellH = 98.0;

  final _pages = PageController();
  late final TextEditingController _title;
  late final LauncherModel _model;

  @override
  void initState() {
    super.initState();
    _model = context.read<LauncherModel>();
    _title = TextEditingController(text: widget.folder.name);
  }

  String get _name =>
      _title.text.trim().isEmpty ? 'Folder' : _title.text.trim();

  void _commit() => _model.renameFolder(widget.zone, widget.folder.fid, _name);

  @override
  void dispose() {
    final name = _name;
    final model = _model;
    final zone = widget.zone;
    final fid = widget.folder.fid;
    scheduleMicrotask(() => model.renameFolder(zone, fid, name));
    _title.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final shell = context.read<ShellController>();
    final w = MediaQuery.sizeOf(context).width;
    final panelW = w - 36;
    final cellW = (panelW - 24) / _cols;
    final pkgs = widget.folder.pkgs;
    final pageCount = math.max(1, (pkgs.length / _perPage).ceil());
    final rows = math.min(
      4,
      math.max(1, (math.min(pkgs.length, _perPage) / _cols).ceil()),
    );
    final style = CellStyle(
      label: t.drawerText,
      shadows: const [],
      folderBg: t.folderBgDrawer,
    );
    final tint = widget.folder.color;
    final panelBg = tint == null
        ? t.popupBg
        : Color.alphaBlend(Color(tint).withValues(alpha: 0.28), t.popupBg);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: ((v - 0.9) / 0.1).clamp(0.0, 1.0),
        child: Transform.scale(scale: v, child: child),
      ),
      child: Container(
        key: shell.folderPanelKey,
        width: panelW,
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
        decoration: ShapeDecoration(
          color: panelBg,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(58),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: TextField(
                    controller: _title,
                    autofocus: widget.autofocusTitle,
                    textAlign: TextAlign.center,
                    maxLength: 24,
                    style: TextStyle(
                      color: t.drawerText,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: t.accent,
                    decoration: InputDecoration(
                      counterText: '',
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Folder name',
                      hintStyle: TextStyle(color: t.drawerTextMuted),
                    ),
                    onSubmitted: (_) => _commit(),
                    onTapOutside: (_) {
                      _commit();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Folder color',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _commit();
                      FocusManager.instance.primaryFocus?.unfocus();
                      showFolderColorPicker(
                        context,
                        widget.zone,
                        widget.folder.fid,
                      );
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tint != null
                                ? Color(tint)
                                : t.folderBgDrawer,
                            border: Border.all(
                              color: t.drawerTextMuted,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: rows * _cellH,
              child: PageView.builder(
                controller: _pages,
                itemCount: pageCount,
                itemBuilder: (context, p) {
                  final slice = pkgs.skip(p * _perPage).take(_perPage).toList();
                  return Column(
                    children: [
                      for (var r = 0; r < rows; r++)
                        SizedBox(
                          height: _cellH,
                          child: Row(
                            children: [
                              for (var c = 0; c < _cols; c++)
                                SizedBox(
                                  width: cellW,
                                  child: r * _cols + c < slice.length
                                      ? _PopupCell(
                                          key: ValueKey(slice[r * _cols + c]),
                                          pkg: slice[r * _cols + c],
                                          zone: widget.zone,
                                          fid: widget.folder.fid,
                                          width: cellW,
                                          style: style,
                                        )
                                      : null,
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (pageCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: PageDots(
                  controller: _pages,
                  count: pageCount,
                  color: t.drawerText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PopupCell extends StatelessWidget {
  const _PopupCell({
    super.key,
    required this.pkg,
    required this.zone,
    required this.fid,
    required this.width,
    required this.style,
  });

  final String pkg;
  final Zone zone;
  final String fid;
  final double width;
  final CellStyle style;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LauncherModel>();
    final locked = context.watch<LauncherSettings>().lockLayout;
    final item = AppItem(pkg);
    final visual = ItemVisual(
      item: item,
      label: model.labelForPkg(pkg),
      badge: model.badgeOf(item),
      iconSize: 54,
      width: width,
      style: style,
    );

    return DragTarget<DragData>(
      onWillAcceptWithDetails: (d) =>
          d.data.fromFolder == fid && d.data.item.id != item.id,
      onAcceptWithDetails: (d) {
        final dragged = d.data.item;
        if (dragged is AppItem) {
          model.reorderInFolder(zone, fid, dragged.pkg, pkg);
        }
      },
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        final resting = SizedBox.expand(
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: active
                    ? LaunchRTheme.of(context).accent.withValues(alpha: 0.25)
                    : null,
                borderRadius: BorderRadius.circular(22),
              ),
              child: visual,
            ),
          ),
        );
        return DraggableItem(
          item: item,
          zone: zone,
          fromFolder: fid,
          locked: locked,
          feedbackSize: Size(width, 88),
          feedback: visual,
          onTap: () => launchFrom(context, pkg),
          onMenu: (pos) =>
              showItemMenu(context, pos, item, zone, fromFolder: fid),
          child: resting,
        );
      },
    );
  }
}
