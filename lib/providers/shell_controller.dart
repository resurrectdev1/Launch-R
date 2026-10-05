import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launch_r/models/launcher_models.dart';

class OpenFolder {
  final Zone zone;
  final String fid;
  const OpenFolder(this.zone, this.fid);
}

class ShellController extends ChangeNotifier {
  ShellController({required TickerProvider vsync})
    : drawer = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 320),
      );

  final AnimationController drawer;

  OpenFolder? folder;
  bool renameRequested = false;
  DragData? drag;

  bool leftFolder = false;

  bool dragToHome = false;

  bool inHomeBand = false;

  double homeBandTop = double.infinity;

  Timer? _dwell;

  bool menuOpen = false;

  static double bandHeight(double navBottom) => math.max(56, navBottom + 30);

  final GlobalKey folderPanelKey = GlobalKey();

  bool get drawerOpen => drawer.value > 0.5;

  void openDrawer() =>
      unawaited(drawer.animateTo(1, curve: Curves.easeOutCubic));

  void closeDrawer() {
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(drawer.animateBack(0, curve: Curves.easeInCubic));
  }

  void openMenu() {
    if (menuOpen) return;
    menuOpen = true;
    notifyListeners();
  }

  void closeMenu() {
    if (!menuOpen) return;
    menuOpen = false;
    notifyListeners();
  }

  void openFolder(Zone zone, String fid, {bool rename = false}) {
    folder = OpenFolder(zone, fid);
    renameRequested = rename;
    notifyListeners();
  }

  void closeFolder() {
    if (folder == null) return;
    folder = null;
    renameRequested = false;
    leftFolder = false;
    notifyListeners();
  }

  void dragStart(DragData d) {
    drag = d;
    leftFolder = false;
    dragToHome = false;
    _setInBand(false, notify: false);
    notifyListeners();
  }

  void dragMove(DragData d, Offset pos) {
    _trackFolderExit(d, pos);
    _trackHomeBand(d, pos);
  }

  void _trackFolderExit(DragData d, Offset pos) {
    if (d.fromFolder == null || leftFolder) return;
    final box = folderPanelKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!rect.contains(pos)) {
      leftFolder = true;
      notifyListeners();
    }
  }

  void _trackHomeBand(DragData d, Offset pos) {
    if (d.zone != Zone.drawer || dragToHome) return;
    final eligible = d.fromFolder == null || leftFolder;
    _setInBand(eligible && pos.dy >= homeBandTop);
  }

  void _setInBand(bool v, {bool notify = true}) {
    if (v == inHomeBand) return;
    inHomeBand = v;
    _dwell?.cancel();
    _dwell = v ? Timer(const Duration(milliseconds: 350), enterHomeDrop) : null;
    if (notify) notifyListeners();
  }

  void enterHomeDrop() {
    final d = drag;
    if (d == null || d.zone != Zone.drawer || dragToHome) return;
    _dwell?.cancel();
    _dwell = null;
    inHomeBand = false;
    dragToHome = true;
    unawaited(HapticFeedback.selectionClick());
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(
      drawer.animateBack(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
    notifyListeners();
  }

  void dragEnd() {
    final wasOut = leftFolder;
    _dwell?.cancel();
    _dwell = null;
    inHomeBand = false;
    dragToHome = false;
    drag = null;
    leftFolder = false;
    if (wasOut) {
      folder = null;
      renameRequested = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _dwell?.cancel();
    drawer.dispose();
    super.dispose();
  }
}
