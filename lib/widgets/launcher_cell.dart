import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
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
  final void Function(DragData data, Hover hover) onDrop;

  @override
  State<LauncherCell> createState() => _LauncherCellState();
}

class _LauncherCellState extends State<LauncherCell> {
  Hover _hover = Hover.none;

  bool _accepts(DragData d) {
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
    final canMerge = d.item is AppItem;
    if (widget.zone != Zone.drawer) {
      if (d.zone == Zone.drawer &&
          !context.read<LauncherModel>().canCopyToHome(d.item, widget.item)) {
        return Hover.none;
      }
      return canMerge ? Hover.merge : Hover.none;
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
  Timer? _dwell;
  bool _mergeArmed = false;

  void _resetDwell() {
    _dwell?.cancel();
    _dwell = null;
    _mergeArmed = false;
  }

  void _onMove(DragData d, Offset pos) {
    final raw = _calc(d, pos);
    if (widget.zone == Zone.drawer && raw == Hover.merge && !_mergeArmed) {
      _setHover(_side(pos));
      _dwell ??= Timer(_mergeDwell, () {
        _dwell = null;
        if (!mounted) return;
        _mergeArmed = true;
        unawaited(HapticFeedback.selectionClick());
        _setHover(Hover.merge);
      });
      return;
    }
    if (raw != Hover.merge) _resetDwell();
    _setHover(raw);
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
    widget.onDrop(d, h);
  }

  @override
  void dispose() {
    _dwell?.cancel();
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
      onWillAcceptWithDetails: (d) => _accepts(d.data),
      onMove: (d) => _onMove(d.data, d.offset),
      onLeave: (_) => _onLeave(),
      onAcceptWithDetails: (d) => _onAccept(d.data, d.offset),
      builder: (context, candidate, rejected) {
        final item = widget.item;
        final active = candidate.isNotEmpty && _hover == Hover.none;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _slot(visible: gridOn, active: active),
            if (item != null) Positioned.fill(child: _tile(context, item)),
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: active
                          ? fg.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _CornerDotsPainter(fg.withValues(alpha: 0.22)),
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
    final resting = SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedSlide(
              offset: Offset(nudge, 0),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: Center(
                child: AnimatedScale(
                  scale: merging ? 1.08 : 1,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: merging
                          ? LaunchRTheme.accent.withValues(alpha: 0.18)
                          : Colors.transparent,
                      border: Border.all(
                        color: merging
                            ? LaunchRTheme.accent
                            : Colors.transparent,
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
    return DraggableItem(
      item: item,
      zone: widget.zone,
      locked: widget.locked,
      feedbackSize: Size(widget.width, widget.iconSize + 34),
      feedback: visual,
      onTap: () => openItem(context, item, widget.zone),
      onMenu: (pos) => showItemMenu(context, pos, item, widget.zone),
      child: resting,
    );
  }
}

extension on _LauncherCellState {
  Widget _bar({required bool left, required bool on}) {
    return Positioned(
      left: left ? 2 : null,
      right: left ? null : 2,
      top: 8,
      bottom: 22,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: on ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: LaunchRTheme.accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: LaunchRTheme.accent.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerDotsPainter extends CustomPainter {
  const _CornerDotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const r = 1.8;
    for (final dx in [0.0, size.width]) {
      for (final dy in [0.0, size.height]) {
        canvas.drawCircle(Offset(dx, dy), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CornerDotsPainter old) => old.color != color;
}
