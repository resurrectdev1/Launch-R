import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/theme/motion.dart';

class OpenFolder {
  final Zone zone;
  final String fid;

  final Rect? from;
  const OpenFolder(this.zone, this.fid, {this.from});
}

class ShellController extends ChangeNotifier {
  ShellController({required TickerProvider vsync})
    : drawer = AnimationController(
        vsync: vsync,
        duration: Motion.slow,
        reverseDuration: Motion.drawerClose,
      );

  final AnimationController drawer;

  OpenFolder? folder;
  bool renameRequested = false;
  DragData? drag;

  final ValueNotifier<Offset?> widgetDragPos = ValueNotifier<Offset?>(null);

  bool leftFolder = false;

  bool dragToHome = false;

  bool inHomeBand = false;

  double homeBandTop = double.infinity;

  Timer? _dwell;

  bool menuOpen = false;

  int? resizingWid;

  bool get isResizing => resizingWid != null;

  void startResize(int wid) {
    if (resizingWid == wid) return;
    resizingWid = wid;
    notifyListeners();
  }

  void endResize() {
    if (resizingWid == null) return;
    resizingWid = null;
    notifyListeners();
  }

  static double bandHeight(double navBottom) => math.max(56, navBottom + 40);

  final GlobalKey folderPanelKey = GlobalKey();

  bool get drawerOpen => drawer.value > 0.5;

  void openDrawer() => unawaited(drawer.animateTo(1, curve: Motion.standard));

  void closeDrawer() {
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(drawer.animateBack(0, curve: Motion.exit));
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

  bool folderClosing = false;

  void openFolder(Zone zone, String fid, {bool rename = false, Rect? from}) {
    folder = OpenFolder(zone, fid, from: from);
    folderClosing = false;
    renameRequested = rename;
    notifyListeners();
  }

  void closeFolder() {
    if (folder == null || folderClosing) return;
    folderClosing = true;
    notifyListeners();
  }

  void finishCloseFolder() {
    if (folder == null) return;
    folder = null;
    folderClosing = false;
    renameRequested = false;
    leftFolder = false;
    notifyListeners();
  }

  void dragStart(DragData d) {
    drag = d;
    resizingWid = null;
    leftFolder = false;
    dragToHome = false;
    widgetDragPos.value = null;
    _setInBand(false, notify: false);
    notifyListeners();
  }

  void dragMove(DragData d, Offset pos) {
    if (d.item is WidgetItem) widgetDragPos.value = pos;
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
      drawer.animateBack(0, duration: Motion.base, curve: Motion.standard),
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
    widgetDragPos.value = null;
    leftFolder = false;
    if (wasOut) {
      folder = null;
      folderClosing = false;
      renameRequested = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _dwell?.cancel();
    widgetDragPos.dispose();
    drawer.dispose();
    super.dispose();
  }
}
