import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/draggable_item.dart';
import 'package:launch_r/widgets/item_actions.dart';

enum Hover { none, merge, before, after }

class LauncherCell extends StatefulWidget {
  const LauncherCell({
    super.key,
    required this.zone,
    required this.item,
    required this.label,
    required this.badge,
    required this.iconSize,
    required this.width,
    required this.style,
    required this.locked,
    required this.onDrop,
    this.showLabel = true,
    this.canDrop,
    this.dot = false,
    this.slotKey,
  });

  final Zone zone;
  final LItem? item;
  final String label;
  final int badge;
  final double iconSize;
  final double width;
  final CellStyle style;
  final bool locked;
  final bool showLabel;

  final bool dot;

  final String? slotKey;
  final void Function(DragData data, Hover hover) onDrop;

  final bool Function(DragData data)? canDrop;

  @override
  State<LauncherCell> createState() => _LauncherCellState();
}

class _LauncherCellState extends State<LauncherCell> {
  Hover _hover = Hover.none;
  bool _pop = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _pop = context.read<ShellController>().takeDropped(
        widget.slotKey,
        item.id,
      );
    }
  }

  bool _accepts(DragData d) {
    final veto = widget.canDrop;
    if (veto != null && !veto(d)) return false;
    if (d.item is WidgetItem) return widget.zone == Zone.home;
    final inDrawer = widget.zone == Zone.drawer;
    final fromDrawer = d.zone == Zone.drawer;
    if (fromDrawer && !inDrawer) return true;
    if (inDrawer != fromDrawer) return false;
    final it = widget.item;
    if (it != null && it.id == d.item.id) return false;
    if (d.fromFolder != null && it is FolderItem && it.fid == d.fromFolder) {
      return false;
    }
    return true;
  }

  Hover _calc(DragData d, Offset global) {
    if (widget.item == null) return Hover.none;
    final it = widget.item;
    final canMerge = d.item is AppItem && (it is AppItem || it is FolderItem);
    if (widget.zone != Zone.drawer) {
      final model = context.read<LauncherModel>();
      final fromDrawer = d.zone == Zone.drawer;
      final mergeOk =
          canMerge && (!fromDrawer || model.canCopyToHome(d.item, widget.item));
      final insertOk =
          d.item is! WidgetItem &&
          (!fromDrawer || model.canCopyToHome(d.item, null));
      final fx = _fx(global);
      final lo = _hover == Hover.merge ? 0.20 : 0.28;
      if (mergeOk && fx > lo && fx < 1 - lo) return Hover.merge;
      if (insertOk && (fx <= lo || fx >= 1 - lo)) {
        return fx < 0.5 ? Hover.before : Hover.after;
      }
      return Hover.none;
    }
    final fx = _fx(global);
    final lo = _hover == Hover.merge ? 0.20 : 0.30;
    final hi = 1 - lo;
    if (canMerge && fx > lo && fx < hi) return Hover.merge;
    return fx < 0.5 ? Hover.before : Hover.after;
  }

  double _fx(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || box.size.width <= 0) return 0.5;
    final local = box.globalToLocal(global);
    return (local.dx / box.size.width).clamp(0.0, 1.0);
  }

  Hover _side(Offset global) => _fx(global) < 0.5 ? Hover.before : Hover.after;

  void _setHover(Hover h) {
    if (h != _hover && mounted) setState(() => _hover = h);
  }

  static const _mergeDwell = Duration(milliseconds: 160);

  static const _openDwell = Duration(milliseconds: 450);
  Timer? _dwell;
  Timer? _openTimer;
  bool _mergeArmed = false;

  void _resetDwell() {
    _dwell?.cancel();
    _dwell = null;
    _openTimer?.cancel();
    _openTimer = null;
    _mergeArmed = false;
  }

  void _armOpen(DragData d) {
    final item = widget.item;
    if (item is! FolderItem || d.item is! AppItem || d.fromFolder != null) {
      return;
    }
    if ((widget.zone == Zone.drawer) != (d.zone == Zone.drawer)) return;
    final zone = widget.zone;
    _openTimer ??= Timer(_openDwell, () {
      _openTimer = null;
      if (!mounted || _hover != Hover.merge) return;
      final shell = context.read<ShellController>();
      if (shell.folder != null || shell.drag == null) return;
      Rect? from;
      final box = context.findRenderObject();
      if (box is RenderBox && box.attached) {
        from = box.localToGlobal(Offset.zero) & box.size;
      }
      shell.openFolder(zone, item.fid, from: from, peek: true);
    });
  }

  void _onMove(DragData d, Offset pos) {
    final raw = _calc(d, pos);
    if (raw == Hover.merge && !_mergeArmed) {
      _setHover(widget.zone == Zone.drawer ? _side(pos) : Hover.none);
      _dwell ??= Timer(_mergeDwell, () {
        _dwell = null;
        if (!mounted) return;
        _mergeArmed = true;
        unawaited(HapticFeedback.selectionClick());
        _setHover(Hover.merge);
        _armOpen(d);
      });
      return;
    }
    if (raw != Hover.merge) _resetDwell();
    _setHover(raw);
  }

  void _onEnter(DragData d) {
    if (widget.item == null) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _onLeave() {
    _resetDwell();
    _setHover(Hover.none);
  }

  void _onAccept(DragData d, Offset pos) {
    var h = _hover;
    if (h == Hover.none) {
      h = _calc(d, pos);
      if (widget.zone == Zone.drawer && h == Hover.merge) h = _side(pos);
    }
    _resetDwell();
    _setHover(Hover.none);
    context.read<ShellController>().markDropped(widget.slotKey, d.item.id);
    widget.onDrop(d, h);
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _openTimer?.cancel();
    super.dispose();
  }

  bool _gridOn(ShellController s) {
    final d = s.drag;
    if (d == null) return false;
    if (d.fromFolder != null && !s.leftFolder) return false;
    final fromDrawer = d.zone == Zone.drawer;
    if (widget.zone == Zone.drawer) return fromDrawer && !s.dragToHome;
    return !fromDrawer || s.dragToHome;
  }

  @override
  Widget build(BuildContext context) {
    final gridOn = context.select<ShellController, bool>(_gridOn);
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (d) {
        final ok = _accepts(d.data);
        if (ok) _onEnter(d.data);
        return ok;
      },
      onMove: (d) => _onMove(d.data, d.offset),
      onLeave: (_) => _onLeave(),
      onAcceptWithDetails: (d) => _onAccept(d.data, d.offset),
      builder: (context, candidate, rejected) {
        final item = widget.item;
        final widgetDrag = candidate.any((c) => c?.item is WidgetItem);
        final active =
            candidate.isNotEmpty && _hover == Hover.none && !widgetDrag;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _slot(visible: gridOn, active: active),
            if (item != null && item is! WidgetItem && item is! WidgetCover)
              Positioned.fill(child: _tile(context, item)),
          ],
        );
      },
    );
  }

  Widget _slot({required bool visible, required bool active}) {
    final fg = widget.style.label;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Motion.base,
          curve: Motion.standard,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    curve: Motion.standard,
                    decoration: BoxDecoration(
                      color: active
                          ? fg.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              if (widget.dot)
                Positioned.fill(
                  child: CustomPaint(
                    painter: IntersectionDotPainter(fg.withValues(alpha: 0.22)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, LItem item) {
    final visual = ItemVisual(
      item: item,
      label: widget.label,
      badge: widget.badge,
      iconSize: widget.iconSize,
      width: widget.width,
      style: widget.style,
      showLabel: widget.showLabel,
    );
    final merging = _hover == Hover.merge;
    final nudge = _hover == Hover.before
        ? 0.07
        : _hover == Hover.after
        ? -0.07
        : 0.0;
    final accent = LaunchRTheme.of(context).accent;
    final resting = SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedSlide(
              offset: Offset(nudge, 0),
              duration: Motion.fast,
              curve: Motion.standard,
              child: Center(
                child: AnimatedScale(
                  scale: merging ? 1.08 : 1,
                  duration: Motion.fast,
                  curve: Motion.standard,
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    curve: Motion.standard,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: merging
                          ? accent.withValues(alpha: 0.18)
                          : Colors.transparent,
                      border: Border.all(
                        color: merging ? accent : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: visual,
                  ),
                ),
              ),
            ),
          ),
          _bar(left: true, on: _hover == Hover.before),
          _bar(left: false, on: _hover == Hover.after),
        ],
      ),
    );
    final draggable = DraggableItem(
      item: item,
      zone: widget.zone,
      locked: widget.locked,
      feedbackSize: Size(widget.width, widget.iconSize + 34),
      feedback: visual,
      onTap: () => openItem(context, item, widget.zone),
      onMenu: (pos) => showItemMenu(context, pos, item, widget.zone),
      child: resting,
    );
    if (!_pop) return draggable;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.78, end: 1),
      duration: Motion.emphasized,
      curve: Motion.emphasizedCurve,
      child: draggable,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
    );
  }
}

extension on _LauncherCellState {
  Widget _bar({required bool left, required bool on}) {
    final accent = LaunchRTheme.of(context).accent;
    return Positioned(
      left: left ? 2 : null,
      right: left ? null : 2,
      top: 8,
      bottom: 22,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: on ? 1 : 0,
          duration: Motion.fast,
          curve: Motion.standard,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IntersectionDotPainter extends CustomPainter {
  const IntersectionDotPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width, size.height),
      1.8,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(IntersectionDotPainter old) => old.color != color;
}
