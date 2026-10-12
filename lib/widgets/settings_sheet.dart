import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/icon_shapes.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/accent_picker_sheet.dart';
import 'package:launch_r/widgets/font_sheet.dart';
import 'package:launch_r/widgets/hidden_apps_sheet.dart';
import 'package:launch_r/widgets/icon_pack_sheet.dart';
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
    final materialYou = s.materialYou && s.dynamicAvailable;

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
              RadioGroup<AppearanceMode>(
                groupValue: s.appearance,
                onChanged: (m) {
                  if (m == null) return;
                  HapticFeedback.selectionClick();
                  unawaited(s.setAppearance(m));
                },
                child: Column(
                  children: [
                    for (final m in AppearanceMode.values)
                      RadioListTile<AppearanceMode>(
                        value: m,
                        activeColor: t.accent,
                        fillColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? t.accent
                              : t.drawerTextMuted,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        title: Text(
                          m.label,
                          style: TextStyle(color: t.drawerText),
                        ),
                      ),
                  ],
                ),
              ),
              if (s.dynamicAvailable || s.materialYou)
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    'Material You',
                    style: TextStyle(color: t.drawerText),
                  ),
                  subtitle: Text(
                    'Use your wallpaper colors',
                    style: TextStyle(color: t.drawerTextMuted),
                  ),
                  value: s.materialYou,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    unawaited(s.setMaterialYou(v));
                  },
                ),
              const SizedBox(height: 6),
              ListTile(
                enabled: !materialYou,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: t.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.drawerTextMuted, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: t.accent.withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                title: Text(
                  'Accent color',
                  style: TextStyle(
                    color: materialYou ? t.drawerTextMuted : t.drawerText,
                  ),
                ),
                subtitle: Text(
                  materialYou
                      ? 'Following your wallpaper'
                      : s.customAccent == null
                      ? 'Orange (default)'
                      : '#${hexOfColor(s.customAccent!)}',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                trailing: materialYou
                    ? null
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: t.drawerTextMuted,
                      ),
                onTap: materialYou
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final changed = await showAccentPicker(context);
                        if (changed && navigator.mounted) navigator.pop();
                      },
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
              header('Background'),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Fix black flash on app close',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  s.ownBackground
                      ? 'Using your own background instead of the system wallpaper'
                      : 'Draws its own background from an image you pick instead of the system wallpaper',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: s.ownBackground,
                onChanged: s.setOwnBackground,
              ),
              if (s.ownBackground) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.wallpaper_rounded, color: t.drawerText),
                  title: Text(
                    'Choose background image',
                    style: TextStyle(color: t.drawerText),
                  ),
                  subtitle: Text(
                    s.backgroundPath == null ? 'None selected' : 'Custom image',
                    style: TextStyle(color: t.drawerTextMuted),
                  ),
                  onTap: () async {
                    final path = await LauncherChannel.instance.pickBackground();
                    if (path != null) await s.setBackgroundPath(path);
                  },
                ),
                if (s.backgroundPath != null)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: t.drawerText,
                    ),
                    title: Text(
                      'Remove background image',
                      style: TextStyle(color: t.drawerText),
                    ),
                    onTap: () => s.setBackgroundPath(null),
                  ),
              ],
              header('Text'),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(Icons.text_fields_rounded, color: t.drawerText),
                title: Text('Font', style: TextStyle(color: t.drawerText)),
                subtitle: Text(
                  s.fontLabel,
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: t.drawerTextMuted,
                ),
                onTap: () => showFontPicker(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Text size',
                        style: TextStyle(color: t.drawerText),
                      ),
                    ),
                    Text(
                      '${(s.textScale * 100).round()}%',
                      style: TextStyle(color: t.drawerTextMuted),
                    ),
                    if ((s.textScale - 1.0).abs() > 0.001)
                      IconButton(
                        tooltip: 'Reset text size',
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.restart_alt_rounded,
                          color: t.drawerTextMuted,
                        ),
                        onPressed: () => s.setTextScale(1.0),
                      ),
                  ],
                ),
              ),
              Slider(
                value: s.textScale,
                min: LauncherSettings.minTextScale,
                max: LauncherSettings.maxTextScale,
                divisions: 9,
                activeColor: t.accent,
                label: '${(s.textScale * 100).round()}%',
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  unawaited(s.setTextScale(v));
                },
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text('Bold text', style: TextStyle(color: t.drawerText)),
                subtitle: Text(
                  'Makes labels and menus easier to read',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: s.boldText,
                onChanged: s.setBoldText,
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
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Add new apps to home',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  model.autoAddNew
                      ? 'Newly installed apps are placed on your home screen'
                      : 'New apps only appear in the apps screen',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: model.autoAddNew,
                onChanged: model.setAutoAddNew,
              ),
              header('Icons'),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(Icons.palette_outlined, color: t.drawerText),
                title: Text('Icon pack', style: TextStyle(color: t.drawerText)),
                subtitle: Text(
                  s.iconPack == null
                      ? 'System default'
                      : (s.iconPackLabel ?? s.iconPack!),
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: t.drawerTextMuted,
                ),
                onTap: () => showIconPackPicker(context),
              ),
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
                  'Themed icons',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  s.themedIcons
                      ? 'Icons are tinted to match your theme'
                      : 'Use each app\'s own colors',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: s.themedIcons,
                onChanged: s.setThemedIcons,
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
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Search on open',
                  style: TextStyle(color: t.drawerText),
                ),
                subtitle: Text(
                  'Opens the keyboard when the app drawer opens',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                value: s.drawerAutoSearch,
                onChanged: s.setDrawerAutoSearch,
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
