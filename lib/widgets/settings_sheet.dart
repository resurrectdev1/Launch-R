import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/icon_shapes.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/hidden_apps_sheet.dart';

void showLaunchRSettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();
    final model = context.watch<LauncherModel>();
    final ch = LauncherChannel.instance;
    final grid = '${model.homeCols}x${model.homeRows}';

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: LaunchRTheme.accent,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: t.menuBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.drawerTextMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  'Launcher settings',
                  style: TextStyle(
                    color: t.drawerText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              header('Appearance'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => s.setThemeMode(v.first),
                ),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Dark home text',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  'For light wallpapers',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: s.darkHomeText,
                onChanged: s.setDarkHomeText,
              ),
              header('Layout'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final g in const [
                      [4, 5],
                      [4, 6],
                      [5, 5],
                      [5, 6],
                    ])
                      ChoiceChip(
                        label: Text('Home ${g[0]}×${g[1]}'),
                        selected: grid == '${g[0]}x${g[1]}',
                        onSelected: (_) => model.setHomeGrid(g[0], g[1]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final c in const [4, 5])
                      ChoiceChip(
                        label: Text('Apps screen $c columns'),
                        selected: s.drawerCols == c,
                        onSelected: (_) => s.setDrawerCols(c),
                      ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Lock layout',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  'Prevent dragging and rearranging',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: s.lockLayout,
                onChanged: s.setLockLayout,
              ),
              header('Icons'),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  children: [
                    for (final shape in IconShape.values)
                      _ShapeChoice(
                        shape: shape,
                        selected: s.iconShape == shape,
                        onTap: () {
                          unawaited(s.setIconShape(shape));
                          model.applyIconShape(shape);
                        },
                      ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Icon badges',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  model.notificationAccess
                      ? 'Shows notification counts on icons'
                      : 'Needs notification access',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: s.showBadges,
                onChanged: (v) {
                  s.setShowBadges(v);
                  if (v && !model.notificationAccess) {
                    ch.openNotificationAccessSettings();
                  }
                },
              ),
              header('System'),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(
                  Icons.visibility_off_outlined,
                  color: t.drawerText,
                ),
                title: Text(
                  'Hidden apps',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  model.hiddenCount == 0
                      ? 'None'
                      : '${model.hiddenCount} hidden',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                onTap: () => showHiddenApps(context),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(Icons.wallpaper_rounded, color: t.drawerText),
                title: Text(
                  'Change wallpaper',
                  style: TextStyle(color: t.drawerText),
                ),
                onTap: ch.openWallpaperPicker,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(Icons.home_rounded, color: t.drawerText),
                title: Text(
                  'Default home app',
                  style: TextStyle(color: t.drawerText),
                ),
                onTap: ch.openHomeSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeChoice extends StatelessWidget {
  const _ShapeChoice({
    required this.shape,
    required this.selected,
    required this.onTap,
  });

  final IconShape shape;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${shape.label} icons',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 56,
          child: Column(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: ClipPath(
                  clipper: IconShapeClipper(shape),
                  child: ColoredBox(
                    color: selected ? LaunchRTheme.accent : t.folderBgDrawer,
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                shape.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? t.drawerText : t.drawerTextMuted,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
