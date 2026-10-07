import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/icon_shapes.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/accent_picker_sheet.dart';
import 'package:launch_r/widgets/hidden_apps_sheet.dart';
import 'package:launch_r/widgets/tag_manager_sheet.dart';

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
        style: TextStyle(
          color: t.accentText,
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
                child: Row(
                  children: [
                    for (final m in AppearanceMode.values) ...[
                      if (m != AppearanceMode.values.first)
                        const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeCard(
                          mode: m,
                          accent: s.accent,
                          selected: s.appearance == m,
                          onTap: () => s.setAppearance(m),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: s.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.drawerTextMuted, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: s.accent.withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                title: Text(
                  'Accent color',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  s.customAccent == null
                      ? 'Orange (default)'
                      : '#${hexOfColor(s.customAccent!)}',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: t.drawerTextMuted,
                ),
                onTap: () => showAccentPicker(context),
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
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Remember app positions',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  model.drawerFree
                      ? 'Apps screen keeps empty spots where you leave them'
                      : 'Apps always fill in from the start',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: model.drawerFree,
                onChanged: model.setDrawerFree,
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
              header('Search'),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Fuzzy search',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  s.fuzzySearch
                      ? 'Finds apps despite typos and abbreviations'
                      : 'Only names that start with or contain your text',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: s.fuzzySearch,
                onChanged: s.setFuzzySearch,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(Icons.sell_outlined, color: t.drawerText),
                title: Text('Tags', style: TextStyle(color: t.drawerText)),
                subtitle: Text(
                  model.tagCounts.isEmpty
                      ? 'None yet'
                      : '${model.tagCounts.length} '
                            '${model.tagCounts.length == 1 ? 'tag' : 'tags'}',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: t.drawerTextMuted,
                ),
                onTap: () => showTagManager(context),
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
                    color: selected ? t.accent : t.folderBgDrawer,
                    child: selected
                        ? Icon(Icons.check_rounded, color: t.onAccent, size: 22)
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

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.mode,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppearanceMode mode;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final p = LaunchRTheme.forMode(mode, accent);
    return Semantics(
      button: true,
      selected: selected,
      label: '${mode.label} theme',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 72,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: p.menuBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? accent
                      : t.drawerTextMuted.withValues(alpha: 0.35),
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 26,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 38,
                        height: 5,
                        decoration: BoxDecoration(
                          color: p.drawerTextMuted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  if (selected)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: LaunchRTheme.onColor(accent),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mode.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: selected ? t.drawerText : t.drawerTextMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
