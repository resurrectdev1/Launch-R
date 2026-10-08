import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/theme/launch_r_theme.dart';

void showWidgetResizeSheet(BuildContext context, int wid) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ResizeSheet(wid: wid),
  );
}

class _ResizeSheet extends StatelessWidget {
  const _ResizeSheet({required this.wid});
  final int wid;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final w = model.widgetById(wid);

    return Container(
      decoration: BoxDecoration(
        color: t.menuBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: w == null
              ? const SizedBox(height: 80)
              : _Body(model: model, w: w),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.model, required this.w});
  final LauncherModel model;
  final WidgetItem w;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final lim = model.widgetLimits(w);

    bool canSet(int c, int r) {
      if (c < lim.minC || c > lim.maxC || r < lim.minR || r > lim.maxR) {
        return false;
      }
      return model.canResizeWidget(w.wid, c, r);
    }

    void set(int c, int r) {
      if (!model.resizeWidget(w.wid, c, r)) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Not enough room to resize here'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: t.drawerTextMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Resize widget',
          style: TextStyle(
            color: t.drawerText,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${w.label} · ${w.cols} × ${w.rows}',
          style: TextStyle(color: t.drawerTextMuted, fontSize: 14),
        ),
        const SizedBox(height: 18),
        _Stepper(
          label: 'Width',
          value: w.cols,
          enabled: w.canH,
          canDec: canSet(w.cols - 1, w.rows),
          canInc: canSet(w.cols + 1, w.rows),
          onDec: () => set(w.cols - 1, w.rows),
          onInc: () => set(w.cols + 1, w.rows),
        ),
        const SizedBox(height: 10),
        _Stepper(
          label: 'Height',
          value: w.rows,
          enabled: w.canV,
          canDec: canSet(w.cols, w.rows - 1),
          canInc: canSet(w.cols, w.rows + 1),
          onDec: () => set(w.cols, w.rows - 1),
          onInc: () => set(w.cols, w.rows + 1),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: t.accentText),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.enabled,
    required this.canDec,
    required this.canInc,
    required this.onDec,
    required this.onInc,
  });

  final String label;
  final int value;
  final bool enabled;
  final bool canDec;
  final bool canInc;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            enabled ? label : '$label (fixed)',
            style: TextStyle(
              color: enabled ? t.drawerText : t.drawerTextMuted,
              fontSize: 16,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: enabled && canDec ? onDec : null,
          icon: const Icon(Icons.remove_rounded),
          tooltip: 'Smaller',
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.drawerText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: enabled && canInc ? onInc : null,
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Larger',
        ),
      ],
    );
  }
}
