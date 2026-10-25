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
  });

  final List<LItem?> items;
  final List<LItem?> dock;
  final int cols;
  final int rows;
  final Set<String> highlightIds;
  final Color highlightColor;

  static const _dockGap = 6.0;

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
        final dockH = math.min(cw * 0.95, c.maxHeight * 0.2);
        final gridH = math.max(0.0, c.maxHeight - dockH - _dockGap);
        final ch = gridH / rows;
        final s = math.min(cw, ch) * 0.64;

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
                child: Center(child: _marked(it, s)),
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
              iconSize: math.min(s, dockH * 0.8),
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
  });

  final List<LItem?> items;
  final int cols;
  final double height;
  final double iconSize;

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
            Expanded(
              child: Center(
                child: HomePagePreview.mini(
                  i < items.length ? items[i] : null,
                  iconSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
