import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/models/layout_models.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/app_icon.dart';

class HomePagePreview extends StatelessWidget {
  const HomePagePreview({
    super.key,
    required this.items,
    required this.dock,
    required this.cols,
    required this.rows,
    this.highlightIds = const {},
    this.highlightColor = const Color(0xFFFFFFFF),
    this.showLabels = false,
    this.showDockLabels = false,
  });

  final List<LItem?> items;
  final List<LItem?> dock;
  final int cols;
  final int rows;
  final Set<String> highlightIds;
  final Color highlightColor;

  final bool showLabels;

  final bool showDockLabels;

  static const _dockGap = 6.0;
  static const _barGap = 2.5;

  static double _barFrac(int i) => 0.5 + ((i * 37) % 4) * 0.1;

  static double _barHeight(double cellH) =>
      math.max(2.5, math.min(4.0, cellH * 0.07));

  static Widget _bar(double cellW, double h, int i) => Container(
    width: cellW * 0.8 * _barFrac(i),
    height: h,
    decoration: BoxDecoration(
      color: const Color(0x8CFFFFFF),
      borderRadius: BorderRadius.circular(h),
    ),
  );

  static Widget _withLabel(Widget icon, double cellW, double barH, int i) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: _barGap),
          _bar(cellW, barH, i),
        ],
      );

  static Widget mini(LItem? it, double s) => switch (it) {
    null => const SizedBox.shrink(),
    AppItem(:final pkg) => AppIconImage(pkg: pkg, size: s),
    ShortcutItem(:final pkg, :final shortcutId) => AppIconImage(
      pkg: pkg,
      shortcutId: shortcutId,
      size: s,
    ),
    FolderItem(:final pkgs, :final shortcuts, :final color) => FolderGlyph(
      pkgs: pkgs,
      shortcuts: shortcuts,
      size: s,
      bg: color != null ? Color(color) : const Color(0x59FFFFFF),
    ),
    WidgetItem() => Icon(
      Icons.widgets_rounded,
      size: s,
      color: const Color(0xCCFFFFFF),
    ),
    WidgetCover() => const SizedBox.shrink(),
  };

  static _PreviewLayout _layout(
    BoxConstraints c, {
    required int cols,
    required int rows,
    required bool showLabels,
    required bool showDockLabels,
    double extra = 0,
  }) {
    final cw = c.maxWidth / cols;
    final dockH = showDockLabels
        ? math.min(cw * 1.1, c.maxHeight * 0.23)
        : math.min(cw * 0.95, c.maxHeight * 0.2);
    final gridH = math.max(0.0, c.maxHeight - dockH - _dockGap - extra);
    final ch = gridH / rows;
    final barH = _barHeight(ch);
    final labelRoom = showLabels ? barH + _barGap : 0.0;
    final s = math.min(
      math.min(cw, ch) * 0.64,
      math.max(4.0, (ch - labelRoom) * 0.86),
    );
    final dockIcon = showDockLabels
        ? math.min(
            s,
            math.max(4.0, (dockH - _barHeight(dockH) - _barGap) * 0.72),
          )
        : math.min(s, dockH * 0.8);
    return _PreviewLayout(
      cw: cw,
      ch: ch,
      gridH: gridH,
      dockH: dockH,
      barH: barH,
      iconSize: s,
      dockIconSize: dockIcon,
    );
  }

  static List<Widget> _cells(
    _PreviewLayout l, {
    required List<LItem?> items,
    required int cols,
    required int rows,
    required bool showLabels,
    required Set<String> highlightIds,
    required Color highlightColor,
  }) {
    Widget marked(LItem? it, double s) {
      final icon = mini(it, s);
      if (it == null || !highlightIds.contains(it.id)) return icon;
      return Container(
        width: s + 4,
        height: s + 4,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(s * 0.34),
          border: Border.all(color: highlightColor, width: 1.5),
        ),
        child: icon,
      );
    }

    final cells = <Widget>[];
    final n = math.min(items.length, cols * rows);
    for (var i = 0; i < n; i++) {
      final it = items[i];
      if (it == null || it is WidgetCover) continue;
      final col = i % cols;
      final row = i ~/ cols;
      if (it is WidgetItem) {
        final spanC = math.max(1, math.min(it.cols, cols - col));
        final spanR = math.max(1, math.min(it.rows, rows - row));
        cells.add(
          Positioned(
            left: col * l.cw,
            top: row * l.ch,
            width: spanC * l.cw,
            height: spanR * l.ch,
            child: _WidgetMini(
              label: it.label,
              outline: highlightIds.contains(it.id) ? highlightColor : null,
            ),
          ),
        );
      } else {
        cells.add(
          Positioned(
            left: col * l.cw,
            top: row * l.ch,
            width: l.cw,
            height: l.ch,
            child: Center(
              child: showLabels
                  ? _withLabel(marked(it, l.iconSize), l.cw, l.barH, i)
                  : marked(it, l.iconSize),
            ),
          ),
        );
      }
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final l = _layout(
          c,
          cols: cols,
          rows: rows,
          showLabels: showLabels,
          showDockLabels: showDockLabels,
        );
        return Column(
          children: [
            SizedBox(
              width: c.maxWidth,
              height: l.gridH,
              child: Stack(
                children: _cells(
                  l,
                  items: items,
                  cols: cols,
                  rows: rows,
                  showLabels: showLabels,
                  highlightIds: highlightIds,
                  highlightColor: highlightColor,
                ),
              ),
            ),
            const SizedBox(height: _dockGap),
            _DockStrip(
              items: dock,
              cols: cols,
              height: l.dockH,
              iconSize: l.dockIconSize,
              showLabels: showDockLabels,
            ),
          ],
        );
      },
    );
  }
}

class _PreviewLayout {
  const _PreviewLayout({
    required this.cw,
    required this.ch,
    required this.gridH,
    required this.dockH,
    required this.barH,
    required this.iconSize,
    required this.dockIconSize,
  });
  final double cw;
  final double ch;
  final double gridH;
  final double dockH;
  final double barH;
  final double iconSize;
  final double dockIconSize;
}

class HomePagesPreview extends StatefulWidget {
  const HomePagesPreview({
    super.key,
    required this.pages,
    required this.dock,
    required this.cols,
    required this.rows,
    this.highlightIds = const {},
    this.highlightColor = const Color(0xFFFFFFFF),
    this.showLabels = false,
    this.showDockLabels = false,
    this.indicator = PageIndicatorStyle.dots,
    this.loop = false,
    this.defaultPage,
    this.animationTag = '',
  });

  final List<List<LItem?>> pages;
  final List<LItem?> dock;
  final int cols;
  final int rows;
  final Set<String> highlightIds;
  final Color highlightColor;
  final bool showLabels;
  final bool showDockLabels;
  final PageIndicatorStyle indicator;
  final bool loop;
  final int? defaultPage;

  final String animationTag;

  @override
  State<HomePagesPreview> createState() => _HomePagesPreviewState();
}

class _HomePagesPreviewState extends State<HomePagesPreview> {
  static const _loops = 1000;

  late PageController _c;
  int _logical = 0;

  bool get _looping => widget.loop && widget.pages.length > 1;

  PageController _make() => PageController(
    initialPage: _looping ? widget.pages.length * _loops + _logical : _logical,
  );

  @override
  void initState() {
    super.initState();
    _c = _make();
  }

  @override
  void didUpdateWidget(HomePagesPreview old) {
    super.didUpdateWidget(old);
    final wasLooping = old.loop && old.pages.length > 1;
    if (wasLooping != _looping || old.pages.length != widget.pages.length) {
      _logical = _logical.clamp(0, math.max(0, widget.pages.length - 1));
      final stale = _c;
      _c = _make();
      WidgetsBinding.instance.addPostFrameCallback((_) => stale.dispose());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.pages.length;
    final looping = _looping;
    final dotsH = widget.indicator == PageIndicatorStyle.hidden ? 4.0 : 12.0;

    return LayoutBuilder(
      builder: (context, c) {
        final l = HomePagePreview._layout(
          c,
          cols: widget.cols,
          rows: widget.rows,
          showLabels: widget.showLabels,
          showDockLabels: widget.showDockLabels,
          extra: dotsH,
        );
        return Column(
          children: [
            SizedBox(
              width: c.maxWidth,
              height: l.gridH,
              child: PageView.builder(
                key: ValueKey('$looping:$n'),
                controller: _c,
                itemCount: looping ? null : n,
                onPageChanged: (v) => _logical = looping ? v % n : v,
                itemBuilder: (context, v) {
                  final i = looping ? v % n : v;
                  return AnimatedSwitcher(
                    duration: Motion.base,
                    switchInCurve: Motion.standard,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                        child: child,
                      ),
                    ),
                    child: SizedBox(
                      key: ValueKey(
                        '${widget.cols}×${widget.rows}:$i:${widget.animationTag}',
                      ),
                      width: c.maxWidth,
                      height: l.gridH,
                      child: Stack(
                        children: HomePagePreview._cells(
                          l,
                          items: widget.pages[i],
                          cols: widget.cols,
                          rows: widget.rows,
                          showLabels: widget.showLabels,
                          highlightIds: widget.highlightIds,
                          highlightColor: widget.highlightColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: dotsH,
              child: Center(
                child: _PreviewDots(
                  controller: _c,
                  count: n,
                  looping: looping,
                  style: widget.indicator,
                  defaultIndex: widget.defaultPage,
                ),
              ),
            ),
            const SizedBox(height: HomePagePreview._dockGap),
            _DockStrip(
              items: widget.dock,
              cols: widget.cols,
              height: l.dockH,
              iconSize: l.dockIconSize,
              showLabels: widget.showDockLabels,
            ),
          ],
        );
      },
    );
  }
}

class _PreviewDots extends StatelessWidget {
  const _PreviewDots({
    required this.controller,
    required this.count,
    required this.looping,
    required this.style,
    this.defaultIndex,
  });

  final PageController controller;
  final int count;
  final bool looping;
  final PageIndicatorStyle style;
  final int? defaultIndex;

  @override
  Widget build(BuildContext context) {
    if (count < 2 || style == PageIndicatorStyle.hidden) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        var page = controller.hasClients && controller.position.hasPixels
            ? (controller.page ?? 0.0)
            : controller.initialPage.toDouble();
        if (looping) page = page % count;

        double near(int i) {
          var d = (page - i).abs();
          if (looping) d = math.min(d, count - d);
          return 1 - d.clamp(0.0, 1.0);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < count; i++) _mark(i, near(i))],
        );
      },
    );
  }

  Widget _mark(int i, double near) {
    final color = Colors.white.withValues(alpha: 0.35 + 0.65 * near);
    if (style == PageIndicatorStyle.line) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Container(
          width: (count > 8 ? 6.0 : 9.0) + near * 5,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: color,
          ),
        ),
      );
    }
    if (i == defaultIndex) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Icon(Icons.home_rounded, size: 7 + near * 1.5, color: color),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Container(
        width: 4 + near * 1.5,
        height: 4 + near * 1.5,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _WidgetMini extends StatelessWidget {
  const _WidgetMini({required this.label, this.outline});
  final String label;
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: LayoutBuilder(
        builder: (context, c) {
          final showLabel = c.maxHeight >= 30 && c.maxWidth >= 40;
          final showIcon = c.maxHeight >= 44 && c.maxWidth >= 28;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: outline ?? const Color(0x40FFFFFF),
                width: outline != null ? 1.5 : 1,
              ),
            ),
            child: ClipRect(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIcon || !showLabel)
                        Icon(
                          Icons.widgets_rounded,
                          size: math.min(
                            18.0,
                            math.min(c.maxWidth, c.maxHeight) * 0.6,
                          ),
                          color: const Color(0xB3FFFFFF),
                        ),
                      if (showLabel) ...[
                        if (showIcon) const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 9,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DockStrip extends StatelessWidget {
  const _DockStrip({
    required this.items,
    required this.cols,
    required this.height,
    required this.iconSize,
    required this.showLabels,
  });

  final List<LItem?> items;
  final int cols;
  final double height;
  final double iconSize;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(math.min(14.0, height / 2)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cols; i++)
            Expanded(child: Center(child: _slot(i, context))),
        ],
      ),
    );
  }

  Widget _slot(int i, BuildContext context) {
    final it = i < items.length ? items[i] : null;
    final icon = HomePagePreview.mini(it, iconSize);
    if (!showLabels || it == null || it is WidgetItem) return icon;
    return LayoutBuilder(
      builder: (context, c) => HomePagePreview._withLabel(
        icon,
        c.maxWidth,
        HomePagePreview._barHeight(height),
        i,
      ),
    );
  }
}
