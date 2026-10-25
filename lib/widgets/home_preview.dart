import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:launch_r/models/launcher_models.dart';
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
    FolderItem(:final pkgs, :final color) => FolderGlyph(
      pkgs: pkgs,
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

  Widget _marked(LItem? it, double s) {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cw = c.maxWidth / cols;
        final dockH = showDockLabels
            ? math.min(cw * 1.1, c.maxHeight * 0.23)
            : math.min(cw * 0.95, c.maxHeight * 0.2);
        final gridH = math.max(0.0, c.maxHeight - dockH - _dockGap);
        final ch = gridH / rows;
        final barH = _barHeight(ch);
        final labelRoom = showLabels ? barH + _barGap : 0.0;
        final s = math.min(
          math.min(cw, ch) * 0.64,
          math.max(4.0, (ch - labelRoom) * 0.86),
        );

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
                left: col * cw,
                top: row * ch,
                width: spanC * cw,
                height: spanR * ch,
                child: _WidgetMini(
                  label: it.label,
                  outline: highlightIds.contains(it.id) ? highlightColor : null,
                ),
              ),
            );
          } else {
            cells.add(
              Positioned(
                left: col * cw,
                top: row * ch,
                width: cw,
                height: ch,
                child: Center(
                  child: showLabels
                      ? _withLabel(_marked(it, s), cw, barH, i)
                      : _marked(it, s),
                ),
              ),
            );
          }
        }

        return Column(
          children: [
            SizedBox(
              width: c.maxWidth,
              height: gridH,
              child: Stack(children: cells),
            ),
            const SizedBox(height: _dockGap),
            _DockStrip(
              items: dock,
              cols: cols,
              height: dockH,
              iconSize: showDockLabels
                  ? math.min(
                      s,
                      math.max(
                        4.0,
                        (dockH - _barHeight(dockH) - _barGap) * 0.72,
                      ),
                    )
                  : math.min(s, dockH * 0.8),
              showLabels: showDockLabels,
            ),
          ],
        );
      },
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
