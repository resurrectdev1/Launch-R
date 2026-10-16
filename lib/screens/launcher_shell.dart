import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/drag_bar.dart';
import 'package:launch_r/widgets/drawer_view.dart';
import 'package:launch_r/widgets/folder_popup.dart';
import 'package:launch_r/widgets/home_drop_hint.dart';
import 'package:launch_r/widgets/home_menu.dart';
import 'package:launch_r/widgets/home_view.dart';
import 'package:launch_r/widgets/item_actions.dart';

class LauncherShell extends StatefulWidget {
  const LauncherShell({super.key});

  @override
  State<LauncherShell> createState() => _LauncherShellState();
}

class _LauncherShellState extends State<LauncherShell>
    with SingleTickerProviderStateMixin {
  late final ShellController _shell = ShellController(vsync: this);
  final _homePages = PageController();
  late final Listenable _drawerLayer = Listenable.merge([
    _shell.drawer,
    _shell,
  ]);

  bool _opening = false;
  double _pull = 0;
  bool _defaultPageApplied = false;
  bool _drawerWasFull = false;
  double _drawerUp = 0;

  @override
  void initState() {
    super.initState();
    LauncherChannel.instance.onHome = _onHome;
  }

  @override
  void dispose() {
    LauncherChannel.instance.onHome = null;
    _homePages.dispose();
    _shell.dispose();
    super.dispose();
  }

  void _onHome() {
    dismissItemMenu();
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.popUntil((r) => r.isFirst);
    if (_shell.menuOpen) {
      _shell.closeMenu();
    } else if (_shell.folder != null) {
      _shell.closeFolder();
    } else if (_shell.drawer.value > 0) {
      _shell.closeDrawer();
    } else {
      final target = context.read<LauncherModel>().defaultPage;
      if (_homePages.hasClients && (_homePages.page?.round() ?? 0) != target) {
        unawaited(
          _homePages.animateToPage(
            target,
            duration: Motion.slow,
            curve: Motion.standard,
          ),
        );
      }
    }
  }

  void _onHomeLongPress() {
    if (_shell.drawer.value > 0 ||
        _shell.folder != null ||
        _shell.drag != null ||
        _shell.menuOpen) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    _shell.openMenu();
  }

  void _back() {
    if (itemMenuOpen) {
      dismissItemMenu();
    } else if (_shell.menuOpen) {
      _shell.closeMenu();
    } else if (_shell.folder != null) {
      _shell.closeFolder();
    } else if (_shell.drawer.value > 0) {
      _shell.closeDrawer();
    }
  }

  void _vStart(DragStartDetails d) {
    _opening = false;
    _pull = 0;
  }

  void _vUpdate(DragUpdateDetails d) {
    final h = MediaQuery.sizeOf(context).height;
    if (!_opening && _pull <= 0 && d.delta.dy < 0) _opening = true;
    if (_opening) {
      _shell.drawer.value = (_shell.drawer.value - d.delta.dy / (h * 0.55))
          .clamp(0.0, 1.0);
    } else if (d.delta.dy > 0) {
      _pull += d.delta.dy;
    }
  }

  void _vEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    if (_opening) {
      final open = v < -300
          ? true
          : (v > 300 ? false : _shell.drawer.value > 0.4);
      open ? _shell.openDrawer() : _shell.closeDrawer();
    } else if (_pull > 70 || v > 700) {
      unawaited(LauncherChannel.instance.expandNotifications());
    }
    _opening = false;
    _pull = 0;
  }

  void _dStart(DragStartDetails d) {
    _drawerWasFull = _shell.drawer.value >= 0.99;
    _drawerUp = 0;
  }

  void _dUpdate(DragUpdateDetails d) {
    if (d.delta.dy < 0) {
      _drawerUp -= d.delta.dy;
    } else {
      _drawerUp = 0;
    }
    final h = MediaQuery.sizeOf(context).height;
    _shell.drawer.value = (_shell.drawer.value - d.delta.dy / (h * 0.55)).clamp(
      0.0,
      1.0,
    );
  }

  void _dEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    final swipedUp = _drawerWasFull && (v < -300 || _drawerUp > 60);
    _drawerWasFull = false;
    _drawerUp = 0;
    if (swipedUp) {
      final s = context.read<LauncherSettings>();
      if (s.swipeUpHome) {
        _shell.closeDrawer();
        return;
      }
      if (s.swipeUpSearch) {
        _shell.requestSearch();
        return;
      }
    }
    final open = v > 300
        ? false
        : (v < -300 ? true : _shell.drawer.value > 0.6);
    open ? _shell.openDrawer() : _shell.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final settings = context.watch<LauncherSettings>();
    _shell.homeBandTop =
        MediaQuery.sizeOf(context).height -
        ShellController.bandHeight(MediaQuery.viewPaddingOf(context).bottom);

    final ready = context.select<LauncherModel, bool>((m) => m.ready);
    if (ready && !_defaultPageApplied) {
      _defaultPageApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final page = context.read<LauncherModel>().defaultPage;
        if (page > 0 && _homePages.hasClients) _homePages.jumpToPage(page);
      });
    }

    return ChangeNotifierProvider<ShellController>.value(
      value: _shell,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: AnimatedBuilder(
          animation: _shell.drawer,
          builder: (context, child) {
            final lightIcons = _shell.drawerOpen
                ? t.dark
                : !settings.darkHomeText;
            final b = lightIcons ? Brightness.light : Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: b,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: b,
                systemNavigationBarContrastEnforced: false,
              ),
              child: child!,
            );
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(child: _WallpaperLayer()),

                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: _vStart,
                    onVerticalDragUpdate: _vUpdate,
                    onVerticalDragEnd: _vEnd,
                    onLongPress: _onHomeLongPress,
                    child: AnimatedBuilder(
                      animation: _shell.drawer,
                      builder: (context, child) {
                        final v = _shell.drawer.value;
                        return Opacity(
                          opacity: 1 - v,
                          child: Transform.scale(
                            scale: 1 - 0.06 * v,
                            child: child,
                          ),
                        );
                      },
                      child: HomeView(controller: _homePages),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _drawerLayer,
                    builder: (context, child) {
                      final v = _shell.drawer.value;
                      final carrying = _shell.dragToHome;
                      if (v == 0 && !carrying) return const SizedBox.shrink();
                      return IgnorePointer(
                        ignoring: carrying,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragStart: _dStart,
                          onVerticalDragUpdate: _dUpdate,
                          onVerticalDragEnd: _dEnd,
                          child: ColoredBox(
                            color: t.drawerScrim.withValues(
                              alpha: t.drawerScrim.a * v,
                            ),
                            child: Opacity(
                              opacity: v,
                              child: Transform.translate(
                                offset: Offset(0, (1 - v) * 70),
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: DrawerView(drawer: _shell.drawer),
                  ),
                ),

                const FolderPopup(),

                HomeMenu(homePages: _homePages),

                const HomeDropHint(),

                const DragActionBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WallpaperLayer extends StatelessWidget {
  const _WallpaperLayer();

  static const _tint = ColoredBox(color: Color(0x1F000000));

  @override
  Widget build(BuildContext context) {
    final own = context.select<LauncherSettings, bool>((s) => s.ownBackground);
    if (!own) return _tint;
    final path = context.select<LauncherSettings, String?>(
      (s) => s.backgroundPath,
    );
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF14161A)),
        if (path != null)
          Image.file(
            File(path),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: (size.width * dpr).round(),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        _tint,
      ],
    );
  }
}
