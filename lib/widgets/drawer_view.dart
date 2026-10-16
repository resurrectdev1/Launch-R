import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/edge_flipper.dart';
import 'package:launch_r/widgets/item_actions.dart';
import 'package:launch_r/widgets/keep_alive.dart';
import 'package:launch_r/widgets/launcher_cell.dart';
import 'package:launch_r/widgets/page_dots.dart';
import 'package:launch_r/widgets/settings_sheet.dart';

const _kRowPitch = 106.0;

class DrawerView extends StatefulWidget {
  const DrawerView({super.key, required this.drawer});

  final AnimationController drawer;

  @override
  State<DrawerView> createState() => _DrawerViewState();
}

enum _ReloadPhase { loading, done, failed }

class _DrawerViewState extends State<DrawerView> {
  final _pages = PageController();
  final _search = TextEditingController();
  final _focus = FocusNode();
  int _pageCount = 1;
  bool _autoFocused = false;

  @override
  void initState() {
    super.initState();
    widget.drawer.addStatusListener(_onDrawerStatus);
  }

  void _onDrawerStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _autoFocused || !mounted) return;
    if (!context.read<LauncherSettings>().drawerAutoSearch) return;
    _autoFocused = true;
    _focus.requestFocus();
  }

  _ReloadPhase _phase = _ReloadPhase.loading;
  bool _bannerVisible = false;
  int _reloadCount = 0;
  Timer? _hideTimer;

  bool get _reloading => _bannerVisible && _phase == _ReloadPhase.loading;

  Future<void> _reload() async {
    if (_reloading) return;
    _hideTimer?.cancel();
    final model = context.read<LauncherModel>();
    setState(() {
      _phase = _ReloadPhase.loading;
      _bannerVisible = true;
    });
    final minWait = Future<void>.delayed(const Duration(milliseconds: 800));
    final count = await model.reloadApps();
    await minWait;
    if (!mounted) return;
    setState(() {
      _reloadCount = count ?? 0;
      _phase = count == null ? _ReloadPhase.failed : _ReloadPhase.done;
    });
    _hideTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _bannerVisible = false);
    });
  }

  @override
  void dispose() {
    widget.drawer.removeStatusListener(_onDrawerStatus);
    _hideTimer?.cancel();
    _pages.dispose();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _prev() {
    if (_pages.hasClients) {
      unawaited(
        _pages.previousPage(duration: Motion.slow, curve: Motion.standard),
      );
    }
  }

  void _next() {
    if (!_pages.hasClients) return;
    if ((_pages.page?.round() ?? 0) >= _pageCount - 1) return;
    unawaited(_pages.nextPage(duration: Motion.slow, curve: Motion.standard));
  }

  void _drop(DragData d, Hover h, LItem? target, int index) {
    final model = context.read<LauncherModel>();
    if (target == null) {
      model.drawerPlace(d, index);
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

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            SizedBox(height: pad.top + 12),
            _SearchPill(
              controller: _search,
              focus: _focus,
              onChanged: () => setState(() {}),
              onReload: () => unawaited(_reload()),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: searching
                  ? _results(t)
                  : AnimatedOpacity(
                      opacity: _reloading ? 0.35 : 1,
                      duration: Motion.base,
                      curve: Motion.standard,
                      child: _grid(t),
                    ),
            ),
            SizedBox(
              height: searching ? math.max(insets, navBottom) : navBottom,
            ),
          ],
        ),
        Positioned(
          top: pad.top + 12 + 52 + 10,
          left: 0,
          right: 0,
          child: Center(
            child: _ReloadBanner(
              visible: _bannerVisible,
              phase: _phase,
              count: _reloadCount,
            ),
          ),
        ),
      ],
    );
  }

  Widget _grid(LaunchRTheme t) {
    final model = context.watch<LauncherModel>();
    final settings = context.watch<LauncherSettings>();
    final items = model.drawerSlots;
    final homeLook =
        settings.homeLookDrawerFolders && !settings.solidHomeFolders;
    final style = CellStyle(
      label: t.drawerText,
      shadows: const [],
      folderBg: homeLook
          ? (settings.darkHomeText
                ? const Color(0x33000000)
                : const Color(0x59FFFFFF))
          : t.folderPanelBg,
      folderBase: homeLook ? null : t.popupBg,
    );

    return LayoutBuilder(
      builder: (context, c) {
        const dotsH = 26.0;
        final gridH = c.maxHeight - dotsH;
        final cols = settings.drawerCols;
        final rows = math.max(3, (gridH / _kRowPitch).floor());
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
            dot:
                idx % perPage % cols < cols - 1 &&
                idx % perPage ~/ cols < rows - 1,
            onDrop: (d, h) => _drop(d, h, item, idx),
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
    final results = model.search(_search.text, fuzzy: settings.fuzzySearch);
    final homeLook =
        settings.homeLookDrawerFolders && !settings.solidHomeFolders;
    final style = CellStyle(
      label: t.drawerText,
      shadows: const [],
      folderBg: homeLook
          ? (settings.darkHomeText
                ? const Color(0x33000000)
                : const Color(0x59FFFFFF))
          : t.folderPanelBg,
      folderBase: homeLook ? null : t.popupBg,
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
            mainAxisExtent: _kRowPitch,
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

class _ReloadBanner extends StatelessWidget {
  const _ReloadBanner({
    required this.visible,
    required this.phase,
    required this.count,
  });

  final bool visible;
  final _ReloadPhase phase;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final label = switch (phase) {
      _ReloadPhase.loading => 'Reloading apps…',
      _ReloadPhase.done => '$count apps loaded',
      _ReloadPhase.failed => 'Couldn’t reload apps',
    };
    final icon = switch (phase) {
      _ReloadPhase.loading => SizedBox(
        key: const ValueKey('spin'),
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: t.accent),
      ),
      _ReloadPhase.done => Icon(
        Icons.check_circle_rounded,
        key: const ValueKey('ok'),
        color: t.accent,
        size: 20,
      ),
      _ReloadPhase.failed => Icon(
        Icons.error_outline_rounded,
        key: const ValueKey('err'),
        color: t.drawerText,
        size: 20,
      ),
    };

    return IgnorePointer(
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -0.8),
        duration: Motion.base,
        curve: Motion.standard,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Motion.base,
          curve: Motion.standard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: t.menuBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: Motion.base,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: icon,
                ),
                const SizedBox(width: 10),
                AnimatedSize(
                  duration: Motion.base,
                  curve: Motion.standard,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: t.drawerText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.onReload,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onChanged;
  final VoidCallback onReload;

  Future<void> _voice(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final text = await LauncherChannel.instance.startVoiceSearch();
      if (text == null || text.trim().isEmpty) return;
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      onChanged();
    } on VoiceUnavailable {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Voice search isn\'t available on this device'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final settings = context.watch<LauncherSettings>();
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(left: 22, right: 13),
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
                final r = context.read<LauncherModel>().search(
                  q,
                  fuzzy: context.read<LauncherSettings>().fuzzySearch,
                );
                if (r.isNotEmpty) launchFrom(context, r.first.package);
              },
              textInputAction: TextInputAction.search,
              cursorColor: t.accent,
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
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final typed = value.text.isNotEmpty;
              if (typed
                  ? !settings.showClearButton
                  : !settings.showVoiceButton) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: typed ? 'Clear' : 'Voice search',
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 40),
                icon: Icon(
                  typed ? Icons.close_rounded : Icons.mic_rounded,
                  color: t.drawerText,
                ),
                onPressed: typed
                    ? () {
                        controller.clear();
                        onChanged();
                        focus.requestFocus();
                      }
                    : () => unawaited(_voice(context)),
              );
            },
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 30,
              height: 40,
              child: Icon(Icons.more_vert_rounded, color: t.drawerText),
            ),
            color: t.menuBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            onSelected: (v) {
              if (v == 'settings') showLaunchRSettings(context);
              if (v == 'wallpaper') {
                unawaited(LauncherChannel.instance.openWallpaperPicker());
              }
              if (v == 'reload') onReload();
              if (v == 'tidy') context.read<LauncherModel>().tidyDrawer();
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
              if (context.read<LauncherModel>().drawerHasGaps)
                PopupMenuItem(
                  value: 'tidy',
                  child: Text(
                    'Tidy up apps',
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
