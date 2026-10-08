import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/shell_controller.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/widgets/draggable_item.dart';
import 'package:launch_r/widgets/item_actions.dart';

class HomeWidgetFrame extends StatelessWidget {
  const HomeWidgetFrame({
    super.key,
    required this.item,
    required this.cellWidth,
    required this.cellHeight,
    required this.locked,
  });

  final WidgetItem item;
  final double cellWidth;
  final double cellHeight;
  final bool locked;

  static const _inset = 4.0;
  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final dragging = context.select<ShellController, bool>(
      (s) => s.drag?.item.id == item.id,
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
    );
  }
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
