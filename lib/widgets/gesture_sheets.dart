import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/gesture_models.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/launch_r_sheet.dart';
import 'package:launch_r/theme/motion.dart';

IconData gestureIcon(GestureAction a) => switch (a) {
  GestureAction.none => Icons.block_rounded,
  GestureAction.openApp => Icons.open_in_new_rounded,
  GestureAction.recents => Icons.filter_none_rounded,
  GestureAction.settings => Icons.settings_outlined,
  GestureAction.drawer => Icons.apps_rounded,
  GestureAction.drawerSearch => Icons.search_rounded,
  GestureAction.notifications => Icons.notifications_none_rounded,
};

void showGesturePicker(BuildContext context, GestureSide side) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GestureSheet(side: side),
  );
}

Future<LauncherApp?> showAppPicker(BuildContext context) {
  return showModalBottomSheet<LauncherApp>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AppPickerSheet(),
  );
}

Future<void> explainAccessibilityAccess(
  BuildContext context, {
  required String title,
  required String doWhat,
  required String usedFor,
}) {
  final t = LaunchRTheme.of(context);
  return showDialog<void>(
    context: context,
    animationStyle: Motion.routeStyle,
    builder: (ctx) => AlertDialog(
      backgroundColor: t.menuBg,
      title: Text(
        title,
        style: TextStyle(color: t.drawerText, fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Android only lets a launcher $doWhat through an '
        'accessibility service. Turn on “Launch-R” in the list that opens. '
        'It is only used to $usedFor; it can’t read your screen.\n\n'
        'If the switch is greyed out, open Launch-R’s App info, tap ⋮ and '
        'choose “Allow restricted settings”, then try again.',
        style: TextStyle(color: t.drawerTextMuted, height: 1.35),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: t.drawerTextMuted),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Not now'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: t.accentText),
          onPressed: () {
            unawaited(LauncherChannel.instance.openAccessibilitySettings());
            Navigator.of(ctx).pop();
          },
          child: const Text('Open settings'),
        ),
      ],
    ),
  );
}

Future<void> _explainRecentsAccess(BuildContext context) =>
    explainAccessibilityAccess(
      context,
      title: 'Allow recent apps',
      doWhat: 'open the recent apps screen',
      usedFor: 'open recents',
    );

class _GestureSheet extends StatelessWidget {
  const _GestureSheet({required this.side});

  final GestureSide side;

  Future<void> _choose(BuildContext context, GestureAction action) async {
    final s = context.read<LauncherSettings>();
    final navigator = Navigator.of(context);
    unawaited(HapticFeedback.selectionClick());

    if (action == GestureAction.openApp) {
      final app = await showAppPicker(context);
      if (app == null) return;
      await s.setGesture(
        side,
        action: action,
        pkg: app.package,
        label: app.label,
      );
      if (navigator.mounted) navigator.pop();
      return;
    }

    await s.setGesture(side, action: action);
    if (action == GestureAction.recents) {
      final ok = await LauncherChannel.instance.hasRecentsAccess();
      if (!ok && context.mounted) await _explainRecentsAccess(context);
    }
    if (navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final current = context.watch<LauncherSettings>().gestureFor(side);

    return LaunchRSheet(
      title: side.label,
      size: SheetSize.standard,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          for (final a in GestureAction.values)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(
                gestureIcon(a),
                color: current.action == a ? t.accent : t.drawerText,
              ),
              title: Text(
                a.label,
                style: TextStyle(
                  color: t.drawerText,
                  fontWeight: current.action == a
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
              subtitle: a == GestureAction.openApp && current.pkg != null
                  ? Text(
                      current.label ?? current.pkg!,
                      style: TextStyle(color: t.drawerTextMuted),
                    )
                  : null,
              trailing: current.action == a
                  ? Icon(Icons.check_rounded, color: t.accent)
                  : null,
              onTap: () => unawaited(_choose(context, a)),
            ),
        ],
      ),
    );
  }
}

class _AppPickerSheet extends StatefulWidget {
  const _AppPickerSheet();

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final query = _controller.text.trim();
    final apps = query.isEmpty ? model.selectableApps : model.search(query);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: LaunchRSheet(
        title: 'Choose an app',
        size: SheetSize.tall,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: t.drawerText),
                cursorColor: t.accent,
                decoration: InputDecoration(
                  hintText: 'Search apps',
                  hintStyle: TextStyle(color: t.drawerTextMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: t.drawerTextMuted,
                  ),
                  filled: true,
                  fillColor: t.folderBgDrawer,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Flexible(
              child: apps.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Text(
                        'No matching apps',
                        style: TextStyle(
                          color: t.drawerTextMuted,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: apps.length,
                      itemBuilder: (context, i) {
                        final app = apps[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          leading: AppIconImage(pkg: app.package, size: 40),
                          title: Text(
                            app.label,
                            style: TextStyle(color: t.drawerText),
                          ),
                          onTap: () => Navigator.of(context).pop(app),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
