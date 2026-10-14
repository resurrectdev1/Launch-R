import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/settings_sheet.dart';
import 'package:launch_r/widgets/widget_picker_sheet.dart';

class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key, required this.homePages});
  final PageController homePages;

  @override
  Widget build(BuildContext context) {
    final open = context.select<ShellController, bool>((s) => s.menuOpen);
    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: Motion.base,
        child: open
            ? _MenuOverlay(key: const ValueKey('menu'), homePages: homePages)
            : const SizedBox.shrink(key: ValueKey('none')),
      ),
    );
  }
}

class _MenuOverlay extends StatefulWidget {
  const _MenuOverlay({super.key, required this.homePages});
  final PageController homePages;

  @override
  State<_MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<_MenuOverlay> {
  static const _gap = 20.0;
  static const _cardFrac = 0.46;
  static const _btn = 52.0;

  PageController? _cardsCtl;
  int _current = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cardsCtl != null) return;
    final w = MediaQuery.sizeOf(context).width;
    final home = widget.homePages;
    _current = home.hasClients ? (home.page?.round() ?? 0) : 0;
    _cardsCtl = PageController(
      initialPage: _current,
      viewportFraction: (w * _cardFrac + _gap) / w,
    );
  }

  @override
  void dispose() {
    _cardsCtl?.dispose();
    super.dispose();
  }

  void _openPage(int i) {
    final home = widget.homePages;
    context.read<ShellController>().closeMenu();
    if (home.hasClients) {
      unawaited(
        home.animateToPage(i, duration: Motion.slow, curve: Motion.standard),
      );
    }
  }

  void _setDefault(int i) {
    context.read<LauncherModel>().setDefaultPage(i);
    unawaited(HapticFeedback.selectionClick());
  }

  void _addPage() {
    final i = context.read<LauncherModel>().addBlankHomePage();
    if (i < 0) return;
    unawaited(HapticFeedback.selectionClick());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _cardsCtl;
      if (!mounted || c == null || !c.hasClients) return;
      unawaited(
        c.animateToPage(i, duration: Motion.slow, curve: Motion.standard),
      );
    });
  }

  Future<void> _removePage(int index) async {
    final model = context.read<LauncherModel>();
    final home = widget.homePages;
    if (!model.canRemoveHomePage) return;
    if (!model.homePageIsEmpty(index)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => const _ConfirmRemove(),
      );
      if (ok != true || !mounted) return;
    }
    final cur = home.hasClients ? (home.page?.round() ?? 0) : 0;
    if (!model.removeHomePage(index)) return;
    final target = math.min(cur > index ? cur - 1 : cur, model.home.length - 1);
    setState(() => _current = target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (home.hasClients) home.jumpToPage(target);
    });
  }

  void _wallpaper() {
    context.read<ShellController>().closeMenu();
    unawaited(LauncherChannel.instance.openWallpaperPicker());
  }

  void _widgets() {
    final home = widget.homePages;
    final page = home.hasClients ? (home.page?.round() ?? 0) : _current;
    context.read<ShellController>().closeMenu();
    showWidgetPicker(context, page: page, homePages: home);
  }

  void _widgetsLocked() {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Unlock the home layout to add widgets'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _settings() {
    context.read<ShellController>().closeMenu();
    showLaunchRSettings(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final locked = context.select<LauncherSettings, bool>((s) => s.lockLayout);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);

    final pages = model.home.length;
    final showAdd = !locked && model.canAddHomePage;
    final cardW = size.width * _cardFrac;
    final idealCardH = cardW * (size.height * 0.8) / size.width;
    final actionsH = locked ? 0.0 : 16.0 + _btn;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: context.read<ShellController>().closeMenu,
      child: ColoredBox(
        color: const Color(0xB3000000),
        child: Column(
          children: [
            SizedBox(height: pad.top),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final cardH = math.max(
                    120.0,
                    math.min(idealCardH, box.maxHeight - actionsH - 8),
                  );
                  final carouselH = cardH + actionsH;
                  return Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.94, end: 1),
                      duration: Motion.base,
                      curve: Motion.standard,
                      builder: (context, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: SizedBox(
                        height: carouselH,
                        child: PageView.builder(
                          controller: _cardsCtl,
                          clipBehavior: Clip.none,
                          itemCount: pages + (showAdd ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= pages) {
                              return Align(
                                alignment: Alignment.topCenter,
                                child: _AddCard(
                                  width: cardW,
                                  height: cardH,
                                  onTap: _addPage,
                                ),
                              );
                            }
                            return Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: cardW,
                                child: Column(
                                  children: [
                                    _PageCard(
                                      height: cardH,
                                      items: model.home[i],
                                      dock: model.dock,
                                      cols: model.homeCols,
                                      rows: model.homeRows,
                                      index: i,
                                      total: pages,
                                      isDefault: i == model.defaultPage,
                                      current: i == _current,
                                      onTap: () => _openPage(i),
                                    ),
                                    if (!locked) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _CircleBtn(
                                            icon: i == model.defaultPage
                                                ? Icons.home_rounded
                                                : Icons.home_outlined,
                                            label: i == model.defaultPage
                                                ? 'Default home page'
                                                : 'Set as default home page',
                                            active: i == model.defaultPage,
                                            onTap: () => _setDefault(i),
                                          ),
                                          const SizedBox(width: 18),
                                          _CircleBtn(
                                            icon: Icons.delete_outline_rounded,
                                            label: 'Remove page',
                                            enabled: model.canRemoveHomePage,
                                            onTap: () =>
                                                unawaited(_removePage(i)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (locked)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Home layout is locked',
                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
                ),
              ),
            Container(
              margin: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                math.max(pad.bottom, 12) + 16,
              ),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: t.dragBarBg,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BarAction(
                    icon: Icons.wallpaper_rounded,
                    label: 'Wallpaper',
                    onTap: _wallpaper,
                  ),
                  _BarAction(
                    icon: Icons.widgets_outlined,
                    label: 'Widgets',
                    dimmed: locked,
                    onTap: locked ? _widgetsLocked : _widgets,
                  ),
                  _BarAction(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: _settings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.height,
    required this.items,
    required this.dock,
    required this.cols,
    required this.rows,
    required this.index,
    required this.total,
    required this.isDefault,
    required this.current,
    required this.onTap,
  });

  final double height;
  final List<LItem?> items;
  final List<LItem?> dock;
  final int cols;
  final int rows;
  final int index;
  final int total;
  final bool isDefault;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return Semantics(
      button: true,
      selected: current,
      label: 'Home page ${index + 1} of $total${isDefault ? ', default' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: current ? t.accent : const Color(0x33FFFFFF),
              width: current ? 2.5 : 1,
            ),
          ),
          child: _PagePreview(items: items, dock: dock, cols: cols, rows: rows),
        ),
      ),
    );
  }
}

class _PagePreview extends StatelessWidget {
  const _PagePreview({
    required this.items,
    required this.dock,
    required this.cols,
    required this.rows,
  });

  final List<LItem?> items;
  final List<LItem?> dock;
  final int cols;
  final int rows;

  static const _dockGap = 6.0;

  static Widget _mini(LItem? it, double s) => switch (it) {
    null => const SizedBox.shrink(),
    AppItem(:final pkg) => AppIconImage(pkg: pkg, size: s),
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
                child: _WidgetMini(label: it.label),
              ),
            );
          } else {
            cells.add(
              Positioned(
                left: col * cw,
                top: row * ch,
                width: cw,
                height: ch,
                child: Center(child: _mini(it, s)),
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
  const _WidgetMini({required this.label});
  final String label;

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
              border: Border.all(color: const Color(0x40FFFFFF)),
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
                child: _PagePreview._mini(
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

class _AddCard extends StatelessWidget {
  const _AddCard({
    required this.width,
    required this.height,
    required this.onTap,
  });

  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add page',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x4DFFFFFF), width: 2),
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 56,
            color: Color(0xB3FFFFFF),
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          width: _MenuOverlayState._btn,
          height: _MenuOverlayState._btn,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? t.accent : const Color(0x33FFFFFF),
          ),
          child: Icon(
            icon,
            size: 27,
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.35),
          ),
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dimmed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: dimmed ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmRemove extends StatelessWidget {
  const _ConfirmRemove();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return AlertDialog(
      backgroundColor: t.menuBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        'Remove this page?',
        style: TextStyle(
          color: t.drawerText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Its shortcuts and folders are removed from Home. '
        'Your apps stay in the app drawer.',
        style: TextStyle(color: t.drawerTextMuted, height: 1.35),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Remove',
            style: TextStyle(color: LaunchRTheme.badge),
          ),
        ),
      ],
    );
  }
}
