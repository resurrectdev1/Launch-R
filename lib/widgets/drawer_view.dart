import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/edge_flipper.dart';
import 'package:launch_r/widgets/item_actions.dart';
import 'package:launch_r/widgets/keep_alive.dart';
import 'package:launch_r/widgets/launcher_cell.dart';
import 'package:launch_r/widgets/page_dots.dart';
import 'package:launch_r/widgets/settings_sheet.dart';

class DrawerView extends StatefulWidget {
  const DrawerView({super.key});

  @override
  State<DrawerView> createState() => _DrawerViewState();
}

class _DrawerViewState extends State<DrawerView> {
  final _pages = PageController();
  final _search = TextEditingController();
  final _focus = FocusNode();
  int _pageCount = 1;

  @override
  void dispose() {
    _pages.dispose();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _prev() {
    if (_pages.hasClients) {
      unawaited(
        _pages.previousPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  void _next() {
    if (!_pages.hasClients) return;
    if ((_pages.page?.round() ?? 0) >= _pageCount - 1) return;
    unawaited(
      _pages.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _drop(DragData d, Hover h, LItem? target) {
    final model = context.read<LauncherModel>();
    if (target == null) {
      model.drawerAppend(d);
      return;
    }
    if (h == Hover.merge) {
      model.drawerMerge(d, target.id);
      return;
    }
    model.drawerInsert(d, target.id, after: h == Hover.after);
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final pad = MediaQuery.paddingOf(context);
    final navBottom = MediaQuery.viewPaddingOf(context).bottom;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final searching = _search.text.trim().isNotEmpty;

    return Column(
      children: [
        SizedBox(height: pad.top + 12),
        _SearchPill(
          controller: _search,
          focus: _focus,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 14),
        Expanded(child: searching ? _results(t) : _grid(t)),
        SizedBox(height: searching ? math.max(insets, navBottom) : navBottom),
      ],
    );
  }

  Widget _grid(LaunchRTheme t) {
    final model = context.watch<LauncherModel>();
    final settings = context.watch<LauncherSettings>();
    final items = model.drawer;
    final style = CellStyle(
      label: t.drawerText,
      shadows: const [],
      folderBg: t.folderBgDrawer,
    );

    return LayoutBuilder(
      builder: (context, c) {
        const dotsH = 26.0;
        final gridH = c.maxHeight - dotsH;
        final cols = settings.drawerCols;
        final rows = math.max(3, (gridH / 122).floor());
        final perPage = cols * rows;
        final n = items.length;
        final pages = math.max(1, (n / perPage).ceil());
        _pageCount = pages;
        final cw = (c.maxWidth - 16) / cols;
        final iconSize = math.min(cw * 0.62, 60.0);

        Widget cell(int idx) {
          final item = idx < n ? items[idx] : null;
          return LauncherCell(
            key: ValueKey(item?.id ?? 'empty-$idx'),
            zone: Zone.drawer,
            item: item,
            label: item == null ? '' : model.labelOf(item),
            badge: item == null || !settings.showBadges
                ? 0
                : model.badgeOf(item),
            iconSize: iconSize,
            width: cw,
            style: style,
            locked: settings.lockLayout,
            onDrop: (d, h) => _drop(d, h, item),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: gridH,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pages,
                    itemCount: pages,
                    itemBuilder: (context, p) => PageKeepAlive(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            for (var r = 0; r < rows; r++)
                              Expanded(
                                child: Row(
                                  children: [
                                    for (var col = 0; col < cols; col++)
                                      Expanded(
                                        child: cell(
                                          p * perPage + r * cols + col,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: EdgeFlipper(onPrev: _prev, onNext: _next),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: dotsH,
              child: Center(
                child: PageDots(
                  controller: _pages,
                  count: pages,
                  color: t.drawerText,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _results(LaunchRTheme t) {
    final model = context.watch<LauncherModel>();
    final settings = context.watch<LauncherSettings>();
    final results = model.search(_search.text);
    final style = CellStyle(
      label: t.drawerText,
      shadows: const [],
      folderBg: t.folderBgDrawer,
    );
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No apps found',
          style: TextStyle(color: t.drawerTextMuted, fontSize: 15),
        ),
      );
    }
    final cols = settings.drawerCols;
    return LayoutBuilder(
      builder: (context, c) {
        final cw = (c.maxWidth - 16) / cols;
        final iconSize = math.min(cw * 0.62, 60.0);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisExtent: 112,
          ),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final app = results[i];
            final item = AppItem(app.package);
            return Builder(
              builder: (cellContext) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => launchFrom(cellContext, app.package),
                onLongPressStart: (d) => showItemMenu(
                  cellContext,
                  d.globalPosition,
                  item,
                  Zone.drawer,
                ),
                child: Center(
                  child: ItemVisual(
                    item: item,
                    label: app.label,
                    badge: settings.showBadges ? model.badgeOf(item) : 0,
                    iconSize: iconSize,
                    width: cw,
                    style: style,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _reloadApps(BuildContext context) async {
  final model = context.read<LauncherModel>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  final count = await model.reloadApps();
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        count == null ? 'Couldn’t reload apps' : 'Reloaded $count apps',
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.controller,
    required this.focus,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(left: 22, right: 4),
      decoration: BoxDecoration(
        color: t.searchBg,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              onChanged: (_) => onChanged(),
              onSubmitted: (q) {
                final r = context.read<LauncherModel>().search(q);
                if (r.isNotEmpty) launchFrom(context, r.first.package);
              },
              textInputAction: TextInputAction.search,
              cursorColor: LaunchRTheme.accent,
              style: TextStyle(
                color: t.drawerText,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: t.drawerTextMuted,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: t.drawerText),
            color: t.menuBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            onSelected: (v) {
              if (v == 'settings') showLaunchRSettings(context);
              if (v == 'wallpaper') {
                unawaited(LauncherChannel.instance.openWallpaperPicker());
              }
              if (v == 'reload') unawaited(_reloadApps(context));
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'settings',
                child: Text(
                  'Launcher settings',
                  style: TextStyle(color: t.drawerText),
                ),
              ),
              PopupMenuItem(
                value: 'wallpaper',
                child: Text(
                  'Change wallpaper',
                  style: TextStyle(color: t.drawerText),
                ),
              ),
              PopupMenuItem(
                value: 'reload',
                child: Text(
                  'Reload apps',
                  style: TextStyle(color: t.drawerText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
