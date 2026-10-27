import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/models/layout_models.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/drawer_view.dart';

class DrawerPagePreview extends StatefulWidget {
  const DrawerPagePreview({
    super.key,
    required this.items,
    required this.cols,
    required this.rows,
    required this.deviceWidth,
    required this.topInset,
    required this.bottomInset,
    required this.showLabels,
    required this.iconScale,
    required this.indicator,
    required this.showVoice,
    this.loop = false,
    required this.folderBg,
    this.folderBase,
  });

  final List<LItem?> items;
  final int cols;
  final int rows;

  final double deviceWidth;
  final double topInset;
  final double bottomInset;

  final bool showLabels;
  final double iconScale;
  final PageIndicatorStyle indicator;
  final bool showVoice;
  final bool loop;

  final Color folderBg;
  final Color? folderBase;

  @override
  State<DrawerPagePreview> createState() => _DrawerPagePreviewState();
}

class _DrawerPagePreviewState extends State<DrawerPagePreview> {
  static const _loops = 1000;

  PageController _controller = PageController();
  int _page = 0;
  bool _looping = false;
  int _count = 1;

  void _sync(int pages) {
    final looping = widget.loop && pages > 1;
    if (looping == _looping && pages == _count) return;
    _looping = looping;
    _count = pages;
    _page = _page.clamp(0, pages - 1).toInt();
    final stale = _controller;
    _controller = PageController(
      initialPage: looping ? pages * _loops + _page : _page,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => stale.dispose());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _glyph(LItem? it, double s) => switch (it) {
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
      bg: color == null
          ? widget.folderBg
          : (widget.folderBase != null
                ? Color.alphaBlend(Color(color), widget.folderBase!)
                : Color(color)),
    ),
    WidgetItem() || WidgetCover() => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final cols = widget.cols;
    final rows = widget.rows;
    final perPage = cols * rows;
    final pages = math.max(1, (widget.items.length / perPage).ceil());
    _sync(pages);
    final looping = _looping;
    final page = _page.clamp(0, pages - 1).toInt();

    final surface = Color.alphaBlend(
      t.drawerScrim,
      t.dark ? const Color(0xFF3A3A44) : const Color(0xFFFFFFFF),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final k = c.maxWidth / widget.deviceWidth;
        final dotsH = drawerDotsHeight(widget.indicator) * k;
        final top = (widget.topInset + 12) * k;
        final pillH = 52 * k;
        final gap = 14 * k;
        final bottom = widget.bottomInset * k;
        final gridH = math.max(
          0.0,
          c.maxHeight - top - pillH - gap - bottom - dotsH,
        );
        final cw = (widget.deviceWidth - 16) / cols;
        final iconReal = drawerIconSize(cw, widget.iconScale);
        final icon = iconReal * k;
        final labelGap = 7 * k;
        final labelH = math.max(2.5, 4.2 * k * 2.2);

        Widget cell(int i) {
          final it = i < widget.items.length ? widget.items[i] : null;
          if (it == null) return const SizedBox.shrink();
          final frac = 0.5 + ((i * 37) % 4) * 0.1;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _glyph(it, icon),
                if (widget.showLabels) ...[
                  SizedBox(height: labelGap),
                  Container(
                    width: cw * k * frac,
                    height: labelH,
                    decoration: BoxDecoration(
                      color: t.drawerTextMuted.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(labelH),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(color: surface),
          child: Column(
            children: [
              SizedBox(height: top),
              _pill(t, k, pillH),
              SizedBox(height: gap),
              SizedBox(
                height: gridH,
                child: PageView.builder(
                  key: ValueKey('$looping:$pages'),
                  controller: _controller,
                  itemCount: looping ? null : pages,
                  onPageChanged: (v) =>
                      setState(() => _page = looping ? v % pages : v),
                  itemBuilder: (context, v) {
                    final p = looping ? v % pages : v;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8 * k),
                      child: Column(
                        children: [
                          for (var r = 0; r < rows; r++)
                            Expanded(
                              child: Row(
                                children: [
                                  for (var col = 0; col < cols; col++)
                                    Expanded(
                                      child: cell(p * perPage + r * cols + col),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: dotsH,
                child: Center(child: _indicator(t, k, pages, page)),
              ),
              SizedBox(height: bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(LaunchRTheme t, double k, double h) {
    final iconSize = math.max(8.0, 24 * k);
    return Container(
      height: h,
      margin: EdgeInsets.symmetric(horizontal: 16 * k),
      padding: EdgeInsets.only(left: 22 * k, right: 13 * k),
      decoration: BoxDecoration(
        color: t.searchBg,
        borderRadius: BorderRadius.circular(26 * k),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 46 * k,
                height: math.max(2.5, 8 * k),
                decoration: BoxDecoration(
                  color: t.drawerTextMuted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8 * k),
                ),
              ),
            ),
          ),
          if (widget.showVoice)
            Icon(Icons.mic_rounded, size: iconSize, color: t.drawerText),
          Icon(Icons.more_vert_rounded, size: iconSize, color: t.drawerText),
        ],
      ),
    );
  }

  Widget _indicator(LaunchRTheme t, double k, int pages, int page) {
    if (pages < 2 || widget.indicator == PageIndicatorStyle.hidden) {
      return const SizedBox.shrink();
    }
    final shown = math.min(pages, 8);
    final active = page.clamp(0, shown - 1).toInt();
    final line = widget.indicator == PageIndicatorStyle.line;
    final dot = math.max(3.0, 7 * k);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown; i++)
          Container(
            margin: EdgeInsets.symmetric(horizontal: math.max(1.5, 4 * k)),
            width: line ? (i == active ? dot * 3.2 : dot * 2.2) : dot,
            height: line ? math.max(1.5, 3 * k) : dot,
            decoration: BoxDecoration(
              shape: line ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: line ? BorderRadius.circular(2) : null,
              color: t.drawerText.withValues(alpha: i == active ? 1 : 0.35),
            ),
          ),
      ],
    );
  }
}
