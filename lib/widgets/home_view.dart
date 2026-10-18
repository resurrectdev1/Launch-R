import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/edge_flipper.dart';
import 'package:launch_r/widgets/keep_alive.dart';
import 'package:launch_r/widgets/launcher_cell.dart';
import 'package:launch_r/widgets/page_dots.dart';
import 'package:launch_r/widgets/home_widget_frame.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.controller});
  final PageController controller;

  void _prev() {
    if (!controller.hasClients) return;
    unawaited(
      controller.previousPage(duration: Motion.slow, curve: Motion.standard),
    );
  }

  void _next(LauncherModel model) {
    if (!controller.hasClients) return;
    final cur = controller.page?.round() ?? 0;
    void go() => unawaited(
      controller.nextPage(duration: Motion.slow, curve: Motion.standard),
    );
    if (cur >= model.home.length - 1) {
      if (model.addHomePage()) {
        WidgetsBinding.instance.addPostFrameCallback((_) => go());
      }
    } else {
      go();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LauncherModel>();
    final settings = context.watch<LauncherSettings>();
    final pad = MediaQuery.paddingOf(context);
    final navBottom = MediaQuery.viewPaddingOf(context).bottom;
    final dark = settings.darkHomeText;
    final t = LaunchRTheme.of(context);

    final style = CellStyle(
      label: dark ? const Color(0xFF111111) : Colors.white,
      shadows: dark
          ? const []
          : const [Shadow(color: Color(0x99000000), blurRadius: 6)],
      folderBg: settings.solidHomeFolders
          ? t.folderPanelBg
          : (dark ? const Color(0x33000000) : const Color(0x59FFFFFF)),
      folderBase: settings.solidHomeFolders ? t.popupBg : null,
    );
    final dotColor = dark ? const Color(0xFF111111) : Colors.white;

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(height: pad.top + 10),
            Expanded(
              child: _PageHaptics(
                child: PageView.builder(
                  controller: controller,
                  itemCount: model.home.length,
                  itemBuilder: (context, p) => PageKeepAlive(
                    child: _HomePage(page: p, style: style),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 26,
              child: Center(
                child: PageDots(
                  controller: controller,
                  count: model.home.length,
                  color: dotColor,
                  defaultIndex: model.defaultPage,
                ),
              ),
            ),
            _Dock(style: style),
            SizedBox(height: math.max(navBottom, 10) + 4),
          ],
        ),
        if (model.isHomeEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Swipe up to open your apps.\nLong-press an app and choose “Add to Home”.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: style.label.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.4,
                      shadows: style.shadows,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: EdgeFlipper(onPrev: _prev, onNext: () => _next(model)),
        ),
      ],
    );
  }
}

void _announce(BuildContext context, DropOutcome outcome) {
  final text = switch (outcome) {
    DropOutcome.done => null,
    DropOutcome.alreadyOnHome => 'Already on Home',
    DropOutcome.rejected => 'Drop folders on an empty spot',
    DropOutcome.noRoom => 'Not enough room for this widget',
  };
  if (text == null) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
  );
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.page, required this.style});
  final int page;
  final CellStyle style;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LauncherModel>();
    final settings = context.watch<LauncherSettings>();
    if (page >= model.home.length) return const SizedBox.shrink();
    final cols = model.homeCols;
    final rows = model.homeRows;
    final items = model.home[page];
    final resizing = context.select<ShellController, int?>(
      (s) => s.resizingWid,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: LayoutBuilder(
        builder: (context, c) {
          final cw = c.maxWidth / cols;
          final ch = c.maxHeight / rows;
          final iconSize = math.min(cw * 0.6, 58.0);
          return Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    for (var r = 0; r < rows; r++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var col = 0; col < cols; col++)
                              Expanded(
                                child: _cell(
                                  context,
                                  model,
                                  settings,
                                  items[r * cols + col],
                                  r * cols + col,
                                  cw,
                                  iconSize,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              for (var i = 0; i < items.length; i++)
                if (items[i] case final WidgetItem w when w.wid != resizing)
                  _frame(w, i, cols, cw, ch, settings.lockLayout),
              if (resizing != null)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: context.read<ShellController>().endResize,
                    child: _ResizeScrim(cols: cols, rows: rows),
                  ),
                ),
              for (var i = 0; i < items.length; i++)
                if (items[i] case final WidgetItem w when w.wid == resizing)
                  _frame(w, i, cols, cw, ch, settings.lockLayout),
              Positioned.fill(
                child: _WidgetDropPreview(
                  page: page,
                  gridCols: cols,
                  gridRows: rows,
                  cellWidth: cw,
                  cellHeight: ch,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _frame(
    WidgetItem w,
    int i,
    int gridCols,
    double cw,
    double ch,
    bool locked,
  ) {
    return Positioned(
      key: ValueKey('widget-${w.wid}'),
      left: (i % gridCols) * cw,
      top: (i ~/ gridCols) * ch,
      width: w.cols * cw,
      height: w.rows * ch,
      child: HomeWidgetFrame(
        item: w,
        index: i,
        cellWidth: cw,
        cellHeight: ch,
        locked: locked,
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    LauncherModel model,
    LauncherSettings settings,
    LItem? item,
    int index,
    double width,
    double iconSize,
  ) {
    return LauncherCell(
      key: ValueKey('home-$page-$index-${item?.id}'),
      zone: Zone.home,
      item: item,
      label: item == null ? '' : model.labelOf(item),
      badge: item == null || !settings.showBadges ? 0 : model.badgeOf(item),
      iconSize: iconSize,
      width: width,
      style: style,
      locked: settings.lockLayout,
      dot:
          index % model.homeCols < model.homeCols - 1 &&
          index ~/ model.homeCols < model.homeRows - 1,
      canDrop: (d) {
        final dragged = d.item;
        if (dragged is WidgetItem) {
          return model.canPlaceWidget(dragged, page, index);
        }
        return !model.slotIsWidgetPart(page, index);
      },
      onDrop: (d, _) =>
          _announce(context, model.slotDrop(d, Zone.home, page, index)),
    );
  }
}

class _ResizeScrim extends StatelessWidget {
  const _ResizeScrim({required this.cols, required this.rows});
  final int cols;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Motion.fast,
      curve: Motion.standard,
      builder: (context, t, _) => Opacity(
        opacity: t,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x26FFFFFF), width: 1.5),
          ),
          child: CustomPaint(
            painter: _GridDotsPainter(cols: cols, rows: rows),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _GridDotsPainter extends CustomPainter {
  _GridDotsPainter({required this.cols, required this.rows});
  final int cols;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols;
    final ch = size.height / rows;
    final dot = Paint()..color = const Color(0x59FFFFFF);
    for (var r = 1; r < rows; r++) {
      for (var c = 1; c < cols; c++) {
        canvas.drawCircle(Offset(c * cw, r * ch), 1.8, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_GridDotsPainter old) =>
      old.cols != cols || old.rows != rows;
}

class _WidgetDropPreview extends StatefulWidget {
  const _WidgetDropPreview({
    required this.page,
    required this.gridCols,
    required this.gridRows,
    required this.cellWidth,
    required this.cellHeight,
  });

  final int page;
  final int gridCols;
  final int gridRows;
  final double cellWidth;
  final double cellHeight;

  @override
  State<_WidgetDropPreview> createState() => _WidgetDropPreviewState();
}

class _WidgetDropPreviewState extends State<_WidgetDropPreview> {
  static const _invalid = Color(0xFFE5484D);
  final _area = GlobalKey();

  int? _indexAt(Offset global) {
    final box = _area.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    final col = (local.dx / widget.cellWidth).floor();
    final row = (local.dy / widget.cellHeight).floor();
    if (col < 0 || col >= widget.gridCols) return null;
    if (row < 0 || row >= widget.gridRows) return null;
    return row * widget.gridCols + col;
  }

  @override
  Widget build(BuildContext context) {
    final dragged = context.select<ShellController, WidgetItem?>(
      (s) => s.drag?.item is WidgetItem ? s.drag!.item as WidgetItem : null,
    );
    if (dragged == null) return const SizedBox.shrink();

    final shell = context.read<ShellController>();
    final model = context.read<LauncherModel>();
    final accent = LaunchRTheme.of(context).accent;
    const inset = HomeWidgetFrame.inset;

    return IgnorePointer(
      child: ValueListenableBuilder<Offset?>(
        valueListenable: shell.widgetDragPos,
        builder: (context, pos, _) {
          final index = pos == null ? null : _indexAt(pos);
          final fits =
              index != null &&
              model.canPlaceWidget(dragged, widget.page, index);
          final color = fits ? accent : _invalid;

          return SizedBox.expand(
            key: _area,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (index != null)
                  AnimatedPositioned(
                    duration: Motion.fast,
                    curve: Motion.standard,
                    left: (index % widget.gridCols) * widget.cellWidth + inset,
                    top: (index ~/ widget.gridCols) * widget.cellHeight + inset,
                    width: dragged.cols * widget.cellWidth - inset * 2,
                    height: dragged.rows * widget.cellHeight - inset * 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: fits ? 0.18 : 0.14),
                        border: Border.all(color: color, width: 2),
                        borderRadius: BorderRadius.circular(
                          HomeWidgetFrame.radius,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.style});
  final CellStyle style;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LauncherModel>();
    final settings = context.watch<LauncherSettings>();
    final dock = model.dock;
    return SizedBox(
      height: 84,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: LayoutBuilder(
          builder: (context, c) {
            final cw = c.maxWidth / dock.length;
            final iconSize = math.min(cw * 0.6, 58.0);
            return Row(
              children: [
                for (var i = 0; i < dock.length; i++)
                  Expanded(
                    child: LauncherCell(
                      key: ValueKey('dock-$i-${dock[i]?.id}'),
                      zone: Zone.dock,
                      item: dock[i],
                      label: dock[i] == null ? '' : model.labelOf(dock[i]!),
                      badge: dock[i] == null || !settings.showBadges
                          ? 0
                          : model.badgeOf(dock[i]!),
                      iconSize: iconSize,
                      width: cw,
                      style: style,
                      locked: settings.lockLayout,
                      showLabel: false,
                      canDrop: (d) => d.item is! WidgetItem,
                      onDrop: (d, _) => _announce(
                        context,
                        model.slotDrop(d, Zone.dock, 0, i),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PageHaptics extends StatefulWidget {
  const _PageHaptics({required this.child});

  final Widget child;

  @override
  State<_PageHaptics> createState() => _PageHapticsState();
}

class _PageHapticsState extends State<_PageHaptics> {
  bool _byUser = false;
  int? _last;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final m = n.metrics;
    if (m is! PageMetrics) return false;

    if (n is ScrollStartNotification) {
      _byUser = n.dragDetails != null;
      _last = m.page?.round();
    } else if (n is ScrollUpdateNotification && _byUser) {
      final p = m.page?.round();
      if (p != null && p != _last) {
        _last = p;
        unawaited(HapticFeedback.selectionClick());
      }
    } else if (n is ScrollEndNotification) {
      _byUser = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
  }
}
