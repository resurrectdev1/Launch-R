import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/draggable_item.dart';
import 'package:launch_r/widgets/edge_flipper.dart';
import 'package:launch_r/widgets/folder_color_picker.dart';
import 'package:launch_r/widgets/item_actions.dart';
import 'package:launch_r/widgets/keep_alive.dart';
import 'package:launch_r/widgets/launcher_cell.dart';
import 'package:launch_r/widgets/page_dots.dart';

const _panelRadius = 58.0;

class FolderPopup extends StatefulWidget {
  const FolderPopup({super.key});

  @override
  State<FolderPopup> createState() => _FolderPopupState();
}

class _FolderPopupState extends State<FolderPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: Motion.emphasized,
    reverseDuration: Motion.emphasizedReverse,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _anim,
    curve: Motion.emphasizedCurve,
    reverseCurve: Motion.exit,
  );
  late final ShellController _shell;
  bool _open = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _shell = context.read<ShellController>();
    _shell.addListener(_onShell);
    _onShell();
  }

  void _onShell() {
    final open = _shell.folder != null;
    if (open && !_open) {
      _open = true;
      _closing = false;
      unawaited(_anim.forward(from: 0));
    } else if (!open && _open) {
      _open = false;
      _closing = false;
      _anim.stop();
      _anim.value = 0;
    }
    if (open && _shell.folderClosing && !_closing) {
      _closing = true;
      unawaited(
        _anim.reverse().then((_) {
          if (mounted && _shell.folderClosing) _shell.finishCloseFolder();
        }),
      );
    }
  }

  @override
  void dispose() {
    _shell.removeListener(_onShell);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final model = context.watch<LauncherModel>();
    final open = shell.folder;
    if (open == null) return const SizedBox.shrink();

    final folder = model.folderOf(open.zone, open.fid);
    if (folder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) shell.finishCloseFolder();
      });
      return const SizedBox.shrink();
    }

    final t = LaunchRTheme.of(context);
    final screen = MediaQuery.sizeOf(context);
    final panelW = screen.width - 36;
    final from = open.from;
    final iconSize = from == null
        ? panelW * 0.4
        : math.min(from.width * 0.6, 60.0);
    final s0 = (iconSize / panelW).clamp(0.08, 0.9);
    final origin = from == null
        ? screen.center(Offset.zero)
        : Offset(
            from.center.dx,
            from.center.dy + (from.height > iconSize * 1.35 ? -9 : 0),
          );
    final tint = folder.color;
    final panelBg = tint == null
        ? t.popupBg
        : Color.alphaBlend(Color(tint), t.popupBg);

    final hidden = shell.leftFolder;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: hidden,
        child: AnimatedOpacity(
          opacity: hidden ? 0 : 1,
          duration: Motion.fast,
          curve: Motion.standard,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _t,
                  builder: (context, _) {
                    final v = _t.value.clamp(0.0, 1.0);
                    Widget fill = ColoredBox(
                      color: Color.fromRGBO(0, 0, 0, 0.35 * v),
                    );
                    final sigma = 9.0 * v;
                    if (sigma > 0.1) {
                      fill = BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: sigma,
                          sigmaY: sigma,
                        ),
                        child: fill,
                      );
                    }
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: shell.closeFolder,
                      child: fill,
                    );
                  },
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _t,
                  builder: (context, child) {
                    final v = _t.value;
                    final scale = s0 + (1 - s0) * v;
                    final shift =
                        (origin - screen.center(Offset.zero)) * (1 - v);
                    return Opacity(
                      opacity: (v / 0.3).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: shift,
                        child: Transform.scale(scale: scale, child: child),
                      ),
                    );
                  },
                  child: _PanelDecor(
                    shellKey: shell.folderPanelKey,
                    t: _t,
                    s0: s0,
                    iconRadius: iconSize * 0.62,
                    width: panelW,
                    color: panelBg,
                    folderFid: folder.fid,
                    child: _FolderPage(
                      key: ValueKey(folder.fid),
                      zone: open.zone,
                      folder: folder,
                      panelColor: panelBg,
                      autofocusTitle: shell.renameRequested,
                      panelW: panelW,
                      reveal: _t,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelDecor extends StatelessWidget {
  const _PanelDecor({
    required this.shellKey,
    required this.t,
    required this.s0,
    required this.iconRadius,
    required this.width,
    required this.color,
    required this.folderFid,
    required this.child,
  });

  final GlobalKey shellKey;
  final Animation<double> t;
  final double s0;
  final double iconRadius;
  final double width;
  final Color color;
  final String folderFid;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (d) => d.data.fromFolder == folderFid,
      onAcceptWithDetails: (_) {},
      builder: (context, _, _) => AnimatedBuilder(
        animation: t,
        builder: (context, child) {
          final v = t.value;
          final k = v.clamp(0.0, 1.0);
          final scale = math.max(0.05, s0 + (1 - s0) * v);
          final rendered = iconRadius + (_panelRadius - iconRadius) * k;
          return Container(
            key: shellKey,
            width: width,
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
            decoration: ShapeDecoration(
              color: color,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(rendered / scale),
              ),
            ),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

class _FolderPage extends StatefulWidget {
  const _FolderPage({
    super.key,
    required this.zone,
    required this.folder,
    required this.autofocusTitle,
    required this.panelW,
    required this.reveal,
    required this.panelColor,
  });

  final Zone zone;
  final FolderItem folder;
  final Color panelColor;
  final bool autofocusTitle;
  final double panelW;
  final Animation<double> reveal;

  @override
  State<_FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<_FolderPage> {
  static const _cols = 4;
  static const _perPage = 16;
  static const _cellH = 98.0;

  final _pages = PageController();
  late final TextEditingController _title;
  late final LauncherModel _model;
  int _pageCount = 1;

  @override
  void initState() {
    super.initState();
    _model = context.read<LauncherModel>();
    _title = TextEditingController(text: widget.folder.name);
  }

  String get _name =>
      _title.text.trim().isEmpty ? 'Folder' : _title.text.trim();

  void _commit() => _model.renameFolder(widget.zone, widget.folder.fid, _name);

  void _flip(int delta) {
    if (!_pages.hasClients) return;
    final cur = _pages.page?.round() ?? 0;
    final next = cur + delta;
    if (next < 0 || next >= _pageCount) return;
    unawaited(
      _pages.animateToPage(next, duration: Motion.slow, curve: Motion.standard),
    );
  }

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
    final cellW = (widget.panelW - 24) / _cols;
    final pkgs = widget.folder.pkgs;
    final pageCount = math.max(1, (pkgs.length / _perPage).ceil());
    _pageCount = pageCount;
    final rows = math.min(
      4,
      math.max(1, (math.min(pkgs.length, _perPage) / _cols).ceil()),
    );
    final tint = widget.folder.color;
    final fg = tint == null
        ? t.drawerText
        : LaunchRTheme.onColor(widget.panelColor);
    final fgMuted = tint == null
        ? t.drawerTextMuted
        : fg.withValues(alpha: 0.7);
    final style = CellStyle(
      label: fg,
      shadows: const [],
      folderBg: t.folderBgDrawer,
    );

    return Column(
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
                  color: fg,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: tint == null ? t.accent : fg,
                decoration: InputDecoration(
                  counterText: '',
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Folder name',
                  hintStyle: TextStyle(color: fgMuted),
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
                        color: tint != null ? Color(tint) : t.folderBgDrawer,
                        border: Border.all(color: fgMuted, width: 1.5),
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
          child: Stack(
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: pageCount,
                itemBuilder: (context, p) {
                  final slice = pkgs.skip(p * _perPage).take(_perPage).toList();
                  return PageKeepAlive(
                    child: Column(
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
                                            index: r * _cols + c,
                                            zone: widget.zone,
                                            fid: widget.folder.fid,
                                            width: cellW,
                                            style: style,
                                            reveal: widget.reveal,
                                            dot: c < _cols - 1 && r < rows - 1,
                                          )
                                        : _EndSlot(
                                            zone: widget.zone,
                                            fid: widget.folder.fid,
                                            fg: style.label,
                                            dot: c < _cols - 1 && r < rows - 1,
                                          ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (pageCount > 1)
                Positioned.fill(
                  child: EdgeFlipper(
                    onPrev: () => _flip(-1),
                    onNext: () => _flip(1),
                  ),
                ),
            ],
          ),
        ),
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: PageDots(
              controller: _pages,
              count: pageCount,
              color: fg,
            ),
          ),
      ],
    );
  }
}

bool _folderGridOn(ShellController s, String fid) {
  final d = s.drag;
  return d != null && d.fromFolder == fid && !s.leftFolder;
}

class _SlotGuide extends StatelessWidget {
  const _SlotGuide({
    required this.visible,
    required this.active,
    required this.fg,
    required this.dot,
  });

  final bool visible;
  final bool active;
  final Color fg;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Motion.base,
          curve: Motion.standard,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    curve: Motion.standard,
                    decoration: BoxDecoration(
                      color: active
                          ? fg.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              if (dot)
                Positioned.fill(
                  child: CustomPaint(
                    painter: IntersectionDotPainter(fg.withValues(alpha: 0.22)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndSlot extends StatelessWidget {
  const _EndSlot({
    required this.zone,
    required this.fid,
    required this.fg,
    required this.dot,
  });

  final Zone zone;
  final String fid;
  final Color fg;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final model = context.read<LauncherModel>();
    final gridOn = context.select<ShellController, bool>(
      (s) => _folderGridOn(s, fid),
    );
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (d) => d.data.fromFolder == fid,
      onAcceptWithDetails: (d) {
        final dragged = d.data.item;
        if (dragged is AppItem) model.moveToEndInFolder(zone, fid, dragged.pkg);
      },
      builder: (context, candidate, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          _SlotGuide(
            visible: gridOn,
            active: candidate.isNotEmpty,
            fg: fg,
            dot: dot,
          ),
        ],
      ),
    );
  }
}

class _PopupCell extends StatefulWidget {
  const _PopupCell({
    super.key,
    required this.pkg,
    required this.index,
    required this.zone,
    required this.fid,
    required this.width,
    required this.style,
    required this.reveal,
    required this.dot,
  });

  final bool dot;
  final String pkg;
  final int index;
  final Zone zone;
  final String fid;
  final double width;
  final CellStyle style;
  final Animation<double> reveal;

  @override
  State<_PopupCell> createState() => _PopupCellState();
}

class _PopupCellState extends State<_PopupCell> {
  Hover _hover = Hover.none;

  Hover _side(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || box.size.width <= 0) return Hover.after;
    final local = box.globalToLocal(global);
    return local.dx / box.size.width < 0.5 ? Hover.before : Hover.after;
  }

  void _setHover(Hover h) {
    if (h != _hover && mounted) setState(() => _hover = h);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LauncherModel>();
    final locked = context.watch<LauncherSettings>().lockLayout;
    final accent = LaunchRTheme.of(context).accent;
    final gridOn = context.select<ShellController, bool>(
      (s) => _folderGridOn(s, widget.fid),
    );
    final pkg = widget.pkg;
    final item = AppItem(pkg);
    final visual = ItemVisual(
      item: item,
      label: model.labelForPkg(pkg),
      badge: model.badgeOf(item),
      iconSize: 54,
      width: widget.width,
      style: widget.style,
    );

    final cell = DragTarget<DragData>(
      onWillAcceptWithDetails: (d) =>
          d.data.fromFolder == widget.fid && d.data.item.id != item.id,
      onMove: (d) => _setHover(_side(d.offset)),
      onLeave: (_) => _setHover(Hover.none),
      onAcceptWithDetails: (d) {
        final dragged = d.data.item;
        final h = _hover == Hover.none ? _side(d.offset) : _hover;
        _setHover(Hover.none);
        if (dragged is AppItem) {
          model.insertInFolder(
            widget.zone,
            widget.fid,
            dragged.pkg,
            pkg,
            after: h == Hover.after,
          );
        }
      },
      builder: (context, candidate, rejected) {
        final nudge = _hover == Hover.before
            ? 0.07
            : _hover == Hover.after
            ? -0.07
            : 0.0;
        final resting = SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedSlide(
                  offset: Offset(nudge, 0),
                  duration: Motion.fast,
                  curve: Motion.standard,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: visual,
                    ),
                  ),
                ),
              ),
              _bar(accent, left: true, on: _hover == Hover.before),
              _bar(accent, left: false, on: _hover == Hover.after),
            ],
          ),
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _SlotGuide(
              visible: gridOn,
              active: false,
              fg: widget.style.label,
              dot: widget.dot,
            ),
            Positioned.fill(
              child: DraggableItem(
                item: item,
                zone: widget.zone,
                fromFolder: widget.fid,
                locked: locked,
                feedbackSize: Size(widget.width, 88),
                feedback: visual,
                onTap: () => launchFrom(context, pkg),
                onMenu: (pos) => showItemMenu(
                  context,
                  pos,
                  item,
                  widget.zone,
                  fromFolder: widget.fid,
                ),
                child: resting,
              ),
            ),
          ],
        );
      },
    );

    final start = (0.22 + 0.025 * widget.index).clamp(0.0, 0.7);
    final stagger = Interval(start, 1, curve: Motion.standard);
    return AnimatedBuilder(
      animation: widget.reveal,
      child: cell,
      builder: (context, child) {
        final p = stagger.transform(widget.reveal.value.clamp(0.0, 1.0));
        if (p >= 1) return child!;
        return Opacity(
          opacity: p,
          child: Transform.scale(scale: 0.7 + 0.3 * p, child: child),
        );
      },
    );
  }

  Widget _bar(Color accent, {required bool left, required bool on}) {
    return Positioned(
      left: left ? 2 : null,
      right: left ? null : 2,
      top: 8,
      bottom: 22,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: on ? 1 : 0,
          duration: Motion.fast,
          curve: Motion.standard,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
