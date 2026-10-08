import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/shell_controller.dart';

class DraggableItem extends StatefulWidget {
  const DraggableItem({
    super.key,
    required this.item,
    required this.zone,
    required this.child,
    required this.feedback,
    required this.feedbackSize,
    required this.onTap,
    required this.onMenu,
    this.fromFolder,
    this.locked = false,
    this.feedbackAnchor,
  });

  final LItem item;
  final Zone zone;
  final String? fromFolder;
  final bool locked;

  final Widget child;

  final Widget feedback;
  final Size feedbackSize;

  final VoidCallback? onTap;
  final void Function(Offset globalPosition) onMenu;

  final Offset? feedbackAnchor;

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> {
  Offset? _first;
  Offset? _last;

  @override
  Widget build(BuildContext context) {
    final shell = context.read<ShellController>();
    final model = context.read<LauncherModel>();
    final data = DragData(
      item: widget.item,
      zone: widget.zone,
      fromFolder: widget.fromFolder,
    );

    if (widget.locked) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPressStart: (d) => widget.onMenu(d.globalPosition),
        child: widget.child,
      );
    }

    final fs = widget.feedbackSize;
    final anchor = widget.feedbackAnchor;
    return LongPressDraggable<DragData>(
      data: data,
      maxSimultaneousDrags: 1,
      delay: const Duration(milliseconds: 320),
      dragAnchorStrategy: anchor == null
          ? pointerDragAnchorStrategy
          : (draggable, context, position) => anchor,
      feedback: IgnorePointer(
        child: anchor != null
            ? Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  width: fs.width,
                  height: fs.height,
                  child: widget.feedback,
                ),
              )
            : Transform.translate(
                offset: Offset(-fs.width / 2, -fs.height / 2 - 6),
                child: Transform.scale(
                  scale: 1.12,
                  child: Material(
                    type: MaterialType.transparency,
                    child: SizedBox(
                      width: fs.width,
                      height: fs.height,
                      child: Center(child: widget.feedback),
                    ),
                  ),
                ),
              ),
      ),
      childWhenDragging: Opacity(opacity: 0, child: widget.child),
      onDragStarted: () {
        _first = null;
        _last = null;
        shell.dragStart(data);
      },
      onDragUpdate: (d) {
        _first ??= d.globalPosition;
        _last = d.globalPosition;
        shell.dragMove(data, d.globalPosition);
      },
      onDragEnd: (d) {
        final moved = (_first == null || _last == null)
            ? 0.0
            : (_last! - _first!).distance;
        shell.dragEnd();
        model.trimHome();
        if (moved < 16) widget.onMenu(d.offset);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }
}
