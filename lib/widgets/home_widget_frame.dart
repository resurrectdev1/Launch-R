import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/widgets/draggable_item.dart';
import 'package:launch_r/widgets/item_actions.dart';

class HomeWidgetFrame extends StatelessWidget {
  const HomeWidgetFrame({
    super.key,
    required this.item,
    required this.index,
    required this.cellWidth,
    required this.cellHeight,
    required this.locked,
  });

  final WidgetItem item;
  final int index;
  final double cellWidth;
  final double cellHeight;
  final bool locked;

  static const inset = 4.0;

  static const radius = 22.0;

  static const _inset = inset;
  static const _radius = radius;

  @override
  Widget build(BuildContext context) {
    final dragging = context.select<ShellController, bool>(
      (s) => s.drag?.item.id == item.id,
    );

    final resizing = context.select<ShellController, bool>(
      (s) => s.resizingWid == item.wid,
    );

    final size = Size(
      item.cols * cellWidth - _inset * 2,
      item.rows * cellHeight - _inset * 2,
    );

    final view = ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: AndroidView(
        key: ValueKey('widget-view-${item.wid}'),
        viewType: LauncherChannel.widgetViewType,
        creationParams: <String, dynamic>{'id': item.wid},
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );

    return IgnorePointer(
      ignoring: dragging,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(_inset),
              child: DraggableItem(
                item: item,
                zone: Zone.home,
                locked: locked,
                feedbackSize: size,
                feedbackAnchor: Offset(
                  cellWidth / 2 - _inset,
                  cellHeight / 2 - _inset,
                ),
                feedback: _DragGhost(label: item.label, radius: _radius),
                onTap: null,
                onMenu: (pos) => showItemMenu(context, pos, item, Zone.home),
                child: view,
              ),
            ),
          ),
          if (resizing)
            Positioned.fill(
              child: _FadeIn(
                child: _ResizeOverlay(
                  item: item,
                  index: index,
                  cellWidth: cellWidth,
                  cellHeight: cellHeight,
                  inset: _inset,
                  radius: _radius,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.97 + 0.03 * t, child: child),
      ),
      child: child,
    );
  }
}

class _ResizeOverlay extends StatefulWidget {
  const _ResizeOverlay({
    required this.item,
    required this.index,
    required this.cellWidth,
    required this.cellHeight,
    required this.inset,
    required this.radius,
  });

  final WidgetItem item;
  final int index;
  final double cellWidth;
  final double cellHeight;
  final double inset;
  final double radius;

  @override
  State<_ResizeOverlay> createState() => _ResizeOverlayState();
}

class _ResizeOverlayState extends State<_ResizeOverlay> {
  static const _hit = 44.0;
  static const _pillLong = 30.0;
  static const _pillShort = 6.0;
  static const _pillInset = 16.0;

  WidgetEdge? _edge;
  ({int index, int cols, int rows})? _target;

  double _cell(WidgetEdge e) => (e == WidgetEdge.left || e == WidgetEdge.right)
      ? widget.cellWidth
      : widget.cellHeight;

  void _start(WidgetEdge e) {
    _dx = 0;
    _dy = 0;
    setState(() {
      _edge = e;
      _target = (
        index: widget.index,
        cols: widget.item.cols,
        rows: widget.item.rows,
      );
    });
  }

  void _cancel() {
    _dx = 0;
    _dy = 0;
    setState(() {
      _edge = null;
      _target = null;
    });
  }

  void _update(WidgetEdge e, double px) {
    final cells = (px / _cell(e)).round();
    final signed = (e == WidgetEdge.left || e == WidgetEdge.top)
        ? -cells
        : cells;
    final next = context.read<LauncherModel>().resolveWidgetResize(
      widget.item.wid,
      e,
      signed,
    );
    if (next == null) return;
    final prev = _target;
    if (prev == null ||
        prev.index != next.index ||
        prev.cols != next.cols ||
        prev.rows != next.rows) {
      unawaited(HapticFeedback.selectionClick());
      setState(() => _target = next);
    }
  }

  void _end() {
    final t = _target;
    if (t != null) {
      context.read<LauncherModel>().applyWidgetResize(
        widget.item.wid,
        t.index,
        t.cols,
        t.rows,
      );
    }
    _cancel();
  }

  Rect _previewRect() {
    final w = widget.item;
    final t = _target;
    if (t == null) {
      return Rect.fromLTWH(
        widget.inset,
        widget.inset,
        w.cols * widget.cellWidth - widget.inset * 2,
        w.rows * widget.cellHeight - widget.inset * 2,
      );
    }
    final grid = context.read<LauncherModel>().homeCols;
    final dCol = (t.index % grid) - (widget.index % grid);
    final dRow = (t.index ~/ grid) - (widget.index ~/ grid);
    return Rect.fromLTWH(
      dCol * widget.cellWidth + widget.inset,
      dRow * widget.cellHeight + widget.inset,
      t.cols * widget.cellWidth - widget.inset * 2,
      t.rows * widget.cellHeight - widget.inset * 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = LaunchRTheme.of(context);
    final w = widget.item;
    final active = _edge != null;
    final rect = _previewRect();

    Widget handle(WidgetEdge e) {
      final horizontalEdge = e == WidgetEdge.left || e == WidgetEdge.right;
      final mine = _edge == e;
      final dimmed = active && !mine;
      final long = mine ? _pillLong + 8 : _pillLong;
      final pill = AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: horizontalEdge ? _pillShort : long,
        height: horizontalEdge ? long : _pillShort,
        decoration: BoxDecoration(
          color: mine ? th.accent : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: mine ? Colors.white : th.accent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: mine
                  ? th.accent.withValues(alpha: 0.6)
                  : const Color(0x66000000),
              blurRadius: mine ? 12 : 4,
            ),
          ],
        ),
      );
      final target = SizedBox(
        width: horizontalEdge ? _hit : _hit * 1.4,
        height: horizontalEdge ? _hit * 1.4 : _hit,
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: dimmed ? 0.35 : 1,
            child: pill,
          ),
        ),
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: horizontalEdge ? (_) => _start(e) : null,
        onHorizontalDragUpdate: horizontalEdge
            ? (d) => _update(e, _dx += d.delta.dx)
            : null,
        onHorizontalDragEnd: horizontalEdge ? (_) => _end() : null,
        onHorizontalDragCancel: horizontalEdge ? _cancel : null,
        onVerticalDragStart: horizontalEdge ? null : (_) => _start(e),
        onVerticalDragUpdate: horizontalEdge
            ? null
            : (d) => _update(e, _dy += d.delta.dy),
        onVerticalDragEnd: horizontalEdge ? null : (_) => _end(),
        onVerticalDragCancel: horizontalEdge ? null : _cancel,
        child: target,
      );
    }

    final cols = _target?.cols ?? w.cols;
    final rows = _target?.rows ?? w.rows;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedPositioned.fromRect(
          duration: active ? const Duration(milliseconds: 110) : Duration.zero,
          curve: Curves.easeOutCubic,
          rect: rect,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                color: active ? th.accent.withValues(alpha: 0.2) : null,
                border: Border.all(color: th.accent, width: active ? 2.5 : 2),
                boxShadow: [
                  BoxShadow(
                    color: th.accent.withValues(alpha: active ? 0.45 : 0.25),
                    blurRadius: active ? 22 : 14,
                    spreadRadius: active ? 1 : 0,
                  ),
                ],
              ),
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutBack,
                  scale: active ? 1 : 0.8,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: active ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: th.accent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55000000), blurRadius: 8),
                        ],
                      ),
                      child: Text(
                        '$cols × $rows',
                        style: TextStyle(
                          color: th.onAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (w.canH)
          Positioned(
            left: widget.inset + _pillInset - _hit / 2 + _pillShort / 2,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [handle(WidgetEdge.left)],
            ),
          ),
        if (w.canH)
          Positioned(
            right: widget.inset + _pillInset - _hit / 2 + _pillShort / 2,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [handle(WidgetEdge.right)],
            ),
          ),
        if (w.canV)
          Positioned(
            top: widget.inset + _pillInset - _hit / 2 + _pillShort / 2,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [handle(WidgetEdge.top)],
            ),
          ),
        if (w.canV)
          Positioned(
            bottom: widget.inset + _pillInset - _hit / 2 + _pillShort / 2,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [handle(WidgetEdge.bottom)],
            ),
          ),
      ],
    );
  }

  double _dx = 0;
  double _dy = 0;
}

class _DragGhost extends StatelessWidget {
  const _DragGhost({required this.label, required this.radius});
  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xCCFFFFFF), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.widgets_rounded, color: Colors.white, size: 30),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
