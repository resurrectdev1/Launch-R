import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/gesture_models.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/models/layout_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/icon_shapes.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/about_sheet.dart';
import 'package:launch_r/widgets/accent_picker_sheet.dart';
import 'package:launch_r/widgets/drawer_preview.dart';
import 'package:launch_r/widgets/drawer_view.dart';
import 'package:launch_r/widgets/font_sheet.dart';
import 'package:launch_r/widgets/gesture_sheets.dart';
import 'package:launch_r/widgets/hidden_apps_sheet.dart';
import 'package:launch_r/widgets/home_preview.dart';
import 'package:launch_r/widgets/icon_pack_sheet.dart';
import 'package:launch_r/widgets/tag_manager_sheet.dart';

void showLaunchRSettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

void showLaunchRDrawerSettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DrawerPage(),
  );
}

Future<bool?> _openPage(BuildContext context, Widget page) {
  return showModalBottomSheet<bool>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => page,
  );
}

const _rowPadding = EdgeInsets.symmetric(horizontal: 24);

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.title,
    required this.children,
    this.showBack = true,
  });

  final String title;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final titleText = Text(
      title,
      style: TextStyle(
        color: t.drawerText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
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
              if (showBack)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: t.drawerText,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(child: titleText),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: titleText,
                ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

Widget _subHeader(LaunchRTheme t, String text) => Padding(
  padding: const EdgeInsets.fromLTRB(24, 12, 24, 2),
  child: Text(
    text,
    style: TextStyle(
      color: t.drawerTextMuted,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: 0.4,
    ),
  ),
);

Widget _hint(LaunchRTheme t, String text) => Padding(
  padding: const EdgeInsets.fromLTRB(24, 2, 24, 6),
  child: Text(
    text,
    style: TextStyle(color: t.drawerTextMuted, fontSize: 12, height: 1.35),
  ),
);

Widget _switchRow(
  LaunchRTheme t, {
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool>? onChanged,
}) => SwitchListTile(
  contentPadding: _rowPadding,
  title: Text(title, style: TextStyle(color: t.drawerText)),
  subtitle: Text(subtitle, style: TextStyle(color: t.drawerTextMuted)),
  value: value,
  onChanged: onChanged,
);

Widget _tile(
  LaunchRTheme t, {
  required String title,
  required VoidCallback? onTap,
  IconData? icon,
  String? subtitle,
  bool chevron = false,
}) => ListTile(
  contentPadding: _rowPadding,
  leading: icon == null ? null : Icon(icon, color: t.drawerText),
  title: Text(title, style: TextStyle(color: t.drawerText)),
  subtitle: subtitle == null
      ? null
      : Text(subtitle, style: TextStyle(color: t.drawerTextMuted)),
  trailing: chevron
      ? Icon(Icons.chevron_right_rounded, color: t.drawerTextMuted)
      : null,
  onTap: onTap,
);

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();
    final model = context.watch<LauncherModel>();

    Widget category({
      required IconData icon,
      required String title,
      required String subtitle,
      required Future<void> Function() onTap,
    }) => ListTile(
      contentPadding: _rowPadding,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: t.accent.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: t.accentText, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(color: t.drawerText, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: t.drawerTextMuted)),
      trailing: Icon(Icons.chevron_right_rounded, color: t.drawerTextMuted),
      onTap: onTap,
    );

    final materialYou = s.materialYou && s.dynamicAvailable;
    final grid = '${model.homeCols}×${model.homeRows}';

    return _SettingsPage(
      title: 'Launcher settings',
      showBack: false,
      children: [
        category(
          icon: Icons.color_lens_outlined,
          title: 'Appearance',
          subtitle: materialYou
              ? '${s.appearance.label} · Material You'
              : s.appearance.label,
          onTap: () async {
            final navigator = Navigator.of(context);
            final closeAll = await _openPage(context, const _AppearancePage());
            if (closeAll == true && navigator.mounted) navigator.pop();
          },
        ),
        category(
          icon: Icons.text_fields_rounded,
          title: 'Text',
          subtitle: '${s.fontLabel} · ${(s.textScale * 100).round()}%',
          onTap: () => _openPage(context, const _TextPage()),
        ),
        category(
          icon: Icons.space_dashboard_outlined,
          title: 'Layout',
          subtitle: 'Home $grid · labels, pages, lock',
          onTap: () => _openPage(context, const _LayoutPage()),
        ),
        category(
          icon: Icons.keyboard_double_arrow_up_rounded,
          title: 'App drawer',
          subtitle:
              '${s.drawerCols} columns · '
              '${s.showDrawerLabels ? 'labels on' : 'labels off'} · search, swipes',
          onTap: () => _openPage(context, const _DrawerPage()),
        ),
        category(
          icon: Icons.interests_outlined,
          title: 'Icons',
          subtitle: s.iconPack == null
              ? '${s.iconShape.label} · System default'
              : '${s.iconShape.label} · ${s.iconPackLabel ?? s.iconPack!}',
          onTap: () => _openPage(context, const _IconsPage()),
        ),
        category(
          icon: Icons.search_rounded,
          title: 'Search',
          subtitle: 'Fuzzy search, hidden app search, tags',
          onTap: () => _openPage(context, const _SearchPage()),
        ),
        category(
          icon: Icons.swipe_rounded,
          title: 'Gestures',
          subtitle: 'Home screen swipes and double tap',
          onTap: () => _openPage(context, const _GesturesPage()),
        ),
        category(
          icon: Icons.tune_rounded,
          title: 'System',
          subtitle: 'Hidden apps, wallpaper, default home app, animations',
          onTap: () => _openPage(context, const _SystemPage()),
        ),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: _rowPadding,
          leading: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Icon(
                Icons.info_outline_rounded,
                color: t.drawerText,
                size: 22,
              ),
            ),
          ),
          title: Text('About', style: TextStyle(color: t.drawerText)),
          onTap: () => showLaunchRAbout(context),
        ),
      ],
    );
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();
    final materialYou = s.materialYou && s.dynamicAvailable;

    return _SettingsPage(
      title: 'Appearance',
      children: [
        _subHeader(t, 'THEME'),
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
                  contentPadding: _rowPadding,
                  title: Text(m.label, style: TextStyle(color: t.drawerText)),
                ),
            ],
          ),
        ),
        _subHeader(t, 'COLORS'),
        if (s.dynamicAvailable || s.materialYou)
          _switchRow(
            t,
            title: 'Material You',
            subtitle: 'Use your wallpaper accent color',
            value: s.materialYou,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              unawaited(s.setMaterialYou(v));
            },
          ),
        ListTile(
          enabled: !materialYou,
          contentPadding: _rowPadding,
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
              : Icon(Icons.chevron_right_rounded, color: t.drawerTextMuted),
          onTap: materialYou
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  final changed = await showAccentPicker(context);
                  if (changed && navigator.mounted) navigator.pop(true);
                },
        ),
        _switchRow(
          t,
          title: 'Dark home text',
          subtitle: 'For light wallpapers',
          value: s.darkHomeText,
          onChanged: s.setDarkHomeText,
        ),
        _switchRow(
          t,
          title: 'Hide status bar',
          subtitle:
              'Hide the clock, battery and signal icons on the home screen',
          value: s.hideStatusBar,
          onChanged: s.setHideStatusBar,
        ),
        _subHeader(t, 'FOLDERS'),
        _switchRow(
          t,
          title: 'Match folder popup color',
          subtitle: s.solidHomeFolders
              ? 'Home screen and app drawer folders use the open folder color'
              : 'Home folders are see-through over your wallpaper',
          value: s.solidHomeFolders,
          onChanged: s.setSolidHomeFolders,
        ),
        _switchRow(
          t,
          title: 'See-through drawer folders',
          subtitle: s.solidHomeFolders
              ? 'Turn off "Match folder popup color" to use this'
              : (s.homeLookDrawerFolders
                    ? 'App drawer folders look like home screen folders'
                    : 'App drawer folders use the folder popup color'),
          value: s.homeLookDrawerFolders && !s.solidHomeFolders,
          onChanged: s.solidHomeFolders ? null : s.setHomeLookDrawerFolders,
        ),
        _subHeader(t, 'BACKGROUND'),
        _switchRow(
          t,
          title: 'Fix black flash on app close',
          subtitle: s.ownBackground
              ? 'Using your own background instead of the system wallpaper'
              : 'Draws its own background from an image you pick instead of the system wallpaper',
          value: s.ownBackground,
          onChanged: s.setOwnBackground,
        ),
        if (s.ownBackground) ...[
          _tile(
            t,
            icon: Icons.wallpaper_rounded,
            title: 'Choose background image',
            subtitle: s.backgroundPath == null
                ? 'None selected'
                : 'Custom image',
            onTap: () async {
              final path = await LauncherChannel.instance.pickBackground();
              if (path != null) await s.setBackgroundPath(path);
            },
          ),
          if (s.backgroundPath != null)
            _tile(
              t,
              icon: Icons.delete_outline_rounded,
              title: 'Remove background image',
              onTap: () => s.setBackgroundPath(null),
            ),
        ],
      ],
    );
  }
}

class _TextPage extends StatelessWidget {
  const _TextPage();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();

    return _SettingsPage(
      title: 'Text',
      children: [
        _tile(
          t,
          icon: Icons.text_fields_rounded,
          title: 'Font',
          subtitle: s.fontLabel,
          chevron: true,
          onTap: () => showFontPicker(context),
        ),
        Padding(
          padding: _rowPadding,
          child: SizedBox(
            height: 40,
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
                SizedBox(
                  width: 40,
                  child: (s.textScale - 1.0).abs() > 0.001
                      ? IconButton(
                          tooltip: 'Reset text size',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.restart_alt_rounded,
                            color: t.drawerTextMuted,
                          ),
                          onPressed: () => s.setTextScale(1.0),
                        )
                      : null,
                ),
              ],
            ),
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
        _switchRow(
          t,
          title: 'Bold text',
          subtitle: 'Makes labels and menus easier to read',
          value: s.boldText,
          onChanged: s.setBoldText,
        ),
      ],
    );
  }
}

class _LayoutPage extends StatelessWidget {
  const _LayoutPage();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();
    final model = context.watch<LauncherModel>();

    return _SettingsPage(
      title: 'Layout',
      children: [
        _subHeader(t, 'HOME GRID'),
        const _HomeGridEditor(),
        _hint(
          t,
          'Icon size and shape are in Icons. '
          'Folder colors are in Appearance.',
        ),
        _subHeader(t, 'LABELS'),
        _switchRow(
          t,
          title: 'Home screen labels',
          subtitle: 'Show app names under icons on the home screen',
          value: s.showHomeLabels,
          onChanged: s.setShowHomeLabels,
        ),
        _switchRow(
          t,
          title: 'Dock labels',
          subtitle: 'Show app names under the dock icons',
          value: s.showDockLabels,
          onChanged: s.setShowDockLabels,
        ),
        _subHeader(t, 'PAGES'),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: Text(
            'Page indicator',
            style: TextStyle(color: t.drawerText, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Wrap(
            spacing: 8,
            children: [
              for (final style in PageIndicatorStyle.values)
                ChoiceChip(
                  label: Text(style.label),
                  selected: s.pageIndicator == style,
                  onSelected: (_) => s.setPageIndicator(style),
                ),
            ],
          ),
        ),
        _hint(
          t,
          'Home screen only. Tap the dots or line to jump to a page. '
          'The app drawer has its own option in App drawer.',
        ),
        _switchRow(
          t,
          title: 'Loop home screen pages',
          subtitle:
              'Home screen only: swiping past the last home page wraps '
              'around to the first. The app drawer has its own option',
          value: s.loopPages,
          onChanged: s.setLoopPages,
        ),
        _subHeader(t, 'BEHAVIOR'),
        _switchRow(
          t,
          title: 'Lock layout',
          subtitle:
              'Prevent dragging and rearranging on the home screen and '
              'in the app drawer',
          value: s.lockLayout,
          onChanged: s.setLockLayout,
        ),
        _switchRow(
          t,
          title: 'Add new apps to home',
          subtitle: model.autoAddNew
              ? 'Newly installed apps are placed on your home screen'
              : 'New apps only appear in the app drawer',
          value: model.autoAddNew,
          onChanged: model.setAutoAddNew,
        ),
      ],
    );
  }
}

class _DrawerPage extends StatelessWidget {
  const _DrawerPage();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();
    final model = context.watch<LauncherModel>();

    return _SettingsPage(
      title: 'App drawer',
      children: [
        const _DrawerPreviewCard(),
        _subHeader(t, 'GRID'),
        _StepperRow(
          label: 'Columns',
          value: s.drawerCols,
          min: GridLimits.minDrawerCols,
          max: GridLimits.maxDrawerCols,
          onChanged: s.setDrawerCols,
        ),
        _hint(
          t,
          'Icon size and shape are in Icons. '
          'Folder colors are in Appearance.',
        ),
        _subHeader(t, 'LABELS'),
        _switchRow(
          t,
          title: 'App labels',
          subtitle: 'Show app names under icons in the app drawer',
          value: s.showDrawerLabels,
          onChanged: s.setShowDrawerLabels,
        ),
        _subHeader(t, 'PAGES'),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: Text(
            'Page indicator',
            style: TextStyle(color: t.drawerText, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Wrap(
            spacing: 8,
            children: [
              for (final style in PageIndicatorStyle.values)
                ChoiceChip(
                  label: Text(style.label),
                  selected: s.drawerPageIndicator == style,
                  onSelected: (_) => s.setDrawerPageIndicator(style),
                ),
            ],
          ),
        ),
        _hint(
          t,
          'App drawer only. Doesn’t affect the home screen, which has '
          'its own option in Layout.',
        ),
        _switchRow(
          t,
          title: 'Loop app drawer pages',
          subtitle:
              'App drawer only: swiping past the last page wraps around '
              'to the first. Doesn’t affect the home screen, which has its '
              'own option in Layout',
          value: s.loopDrawerPages,
          onChanged: s.setLoopDrawerPages,
        ),
        _subHeader(t, 'ORGANIZING'),
        _switchRow(
          t,
          title: 'Remember app positions',
          subtitle: model.drawerFree
              ? 'The app drawer keeps empty spots where you leave them'
              : 'Apps always fill in from the start',
          value: model.drawerFree,
          onChanged: model.setDrawerFree,
        ),
        if (model.drawerHasGaps)
          _tile(
            t,
            icon: Icons.auto_fix_high_rounded,
            title: 'Tidy up apps',
            subtitle: 'Close the empty spots in the app drawer',
            onTap: model.tidyDrawer,
          ),
        _subHeader(t, 'SEARCH BAR'),
        _switchRow(
          t,
          title: 'Search on open',
          subtitle: 'Opens the keyboard when the app drawer opens',
          value: s.drawerAutoSearch,
          onChanged: s.setDrawerAutoSearch,
        ),
        _switchRow(
          t,
          title: 'Suggestions & recent searches',
          subtitle: s.drawerSuggestions
              ? 'Shows your usual apps and past searches when you tap the search bar'
              : 'Search bar stays empty until you type',
          value: s.drawerSuggestions,
          onChanged: s.setDrawerSuggestions,
        ),
        _switchRow(
          t,
          title: 'Voice search button',
          subtitle: 'Shows a mic in the search bar',
          value: s.showVoiceButton,
          onChanged: s.setShowVoiceButton,
        ),
        _switchRow(
          t,
          title: 'Clear button',
          subtitle: 'Shows an ✕ in the search bar once you type',
          value: s.showClearButton,
          onChanged: s.setShowClearButton,
        ),
        _hint(t, 'Fuzzy search and tags are in Search.'),
        _subHeader(t, 'SWIPES'),
        _switchRow(
          t,
          title: 'Swipe up again to go home',
          subtitle:
              'Swiping up on the open app drawer closes it and returns to the home screen',
          value: s.swipeUpHome,
          onChanged: s.setSwipeUpHome,
        ),
        _switchRow(
          t,
          title: 'Swipe up again to search',
          subtitle:
              'Swiping up on the open app drawer opens the keyboard so you can search',
          value: s.swipeUpSearch,
          onChanged: s.setSwipeUpSearch,
        ),
      ],
    );
  }
}

class _DrawerPreviewCard extends StatelessWidget {
  const _DrawerPreviewCard();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();
    final model = context.watch<LauncherModel>();

    final device = MediaQueryData.fromView(View.of(context));
    final screen = device.size;
    final rows = drawerRowsForScreen(
      screenHeight: screen.height,
      topInset: device.padding.top,
      bottomInset: device.viewPadding.bottom,
      labels: s.showDrawerLabels,
      indicator: s.drawerPageIndicator,
    );
    final cols = s.drawerCols;
    final items = model.drawerSlots;
    final perPage = cols * rows;
    final pages = items.isEmpty ? 1 : (items.length / perPage).ceil();

    final aspect = (screen.width / screen.height).clamp(0.4, 0.6).toDouble();
    final previewH = (screen.height * 0.38).clamp(240.0, 360.0).toDouble();
    final previewW = previewH * aspect;

    final homeLook = s.homeLookDrawerFolders && !s.solidHomeFolders;
    final folderBg = homeLook
        ? (s.darkHomeText ? const Color(0x33000000) : const Color(0x59FFFFFF))
        : t.folderPanelBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: previewW + 16,
            height: previewH + 16,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF15171B),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: t.drawerTextMuted.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DrawerPagePreview(
                items: items,
                cols: cols,
                rows: rows,
                deviceWidth: screen.width,
                topInset: device.padding.top,
                bottomInset: device.viewPadding.bottom,
                showLabels: s.showDrawerLabels,
                iconScale: s.iconScale,
                indicator: s.drawerPageIndicator,
                showVoice: s.showVoiceButton,
                folderBg: folderBg,
                folderBase: homeLook ? null : t.popupBg,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Center(
            child: Text(
              '$cols columns × $rows rows · '
              '$pages ${pages == 1 ? 'page' : 'pages'}',
              style: TextStyle(color: t.drawerTextMuted, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 12, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: t.drawerText, fontSize: 16),
            ),
          ),
          IconButton(
            tooltip: 'Decrease $label',
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: t.drawerText,
            disabledColor: t.drawerTextMuted.withValues(alpha: 0.4),
            onPressed: value > min
                ? () {
                    unawaited(HapticFeedback.selectionClick());
                    onChanged(value - 1);
                  }
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.drawerText,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase $label',
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: t.drawerText,
            disabledColor: t.drawerTextMuted.withValues(alpha: 0.4),
            onPressed: value < max
                ? () {
                    unawaited(HapticFeedback.selectionClick());
                    onChanged(value + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _HomeGridEditor extends StatefulWidget {
  const _HomeGridEditor();

  @override
  State<_HomeGridEditor> createState() => _HomeGridEditorState();
}

class _HomeGridEditorState extends State<_HomeGridEditor> {
  static const _warn = Color(0xFFFFB74D);

  late int _cols;
  late int _rows;
  final _pages = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final model = context.read<LauncherModel>();
    _cols = model.homeCols;
    _rows = model.homeRows;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _setGrid({int? cols, int? rows}) {
    setState(() {
      _cols = cols ?? _cols;
      _rows = rows ?? _rows;
    });
  }

  String _plural(int n, String one, [String? many]) =>
      '$n ${n == 1 ? one : (many ?? '${one}s')}';

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final changed = _cols != model.homeCols || _rows != model.homeRows;

    final plan = changed ? model.planHomeGrid(_cols, _rows) : null;
    final pages = plan?.pages ?? model.home;
    final dock = plan?.dock ?? model.dock;
    final marked = plan?.movedIds ?? const <String>{};
    final lost = plan?.lostWidgets.length ?? 0;
    final resized = plan?.resizedWidgets ?? 0;
    final current = _page.clamp(0, pages.length - 1).toInt();

    final screen = MediaQuery.sizeOf(context);
    final aspect = (screen.width / screen.height).clamp(0.4, 0.6).toDouble();
    final previewH = (screen.height * 0.38).clamp(240.0, 360.0).toDouble();
    final previewW = previewH * aspect;

    final notes = <(String, Color)>[
      if (!changed)
        (
          'Current grid: ${model.homeCols}×${model.homeRows}'
              ' · ${_plural(model.home.length, 'page')}',
          t.drawerTextMuted,
        )
      else ...[
        (
          '${_plural(model.home.length, 'page')} -> ${pages.length}',
          t.drawerTextMuted,
        ),
        if (marked.isNotEmpty)
          (
            '${_plural(marked.length, 'item')} outlined will move to another page',
            t.accentText,
          ),
        if (resized > 0)
          (
            '${_plural(resized, 'widget')} will shrink to fit',
            t.drawerTextMuted,
          ),
        if (lost > 0)
          ('${_plural(lost, 'widget')} won’t fit and will be removed', _warn),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: previewW + 16,
            height: previewH + 16,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF15171B),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: changed
                    ? t.accent
                    : t.drawerTextMuted.withValues(alpha: 0.5),
                width: changed ? 2 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: PageView.builder(
                controller: _pages,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: AnimatedSwitcher(
                    duration: Motion.base,
                    switchInCurve: Motion.standard,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                        child: child,
                      ),
                    ),
                    child: HomePagePreview(
                      key: ValueKey('$_cols×$_rows:$i:$changed'),
                      items: pages[i],
                      dock: dock,
                      cols: changed ? _cols : model.homeCols,
                      rows: changed ? _rows : model.homeRows,
                      highlightIds: marked,
                      highlightColor: t.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (pages.length > 1)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: Motion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == current ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == current
                          ? t.accent
                          : t.drawerTextMuted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        _StepperRow(
          label: 'Columns',
          value: _cols,
          min: GridLimits.minHomeCols,
          max: GridLimits.maxHomeCols,
          onChanged: (v) => _setGrid(cols: v),
        ),
        _StepperRow(
          label: 'Rows',
          value: _rows,
          min: GridLimits.minHomeRows,
          max: GridLimits.maxHomeRows,
          onChanged: (v) => _setGrid(rows: v),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (text, color) in notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: color,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: changed
                    ? () {
                        unawaited(HapticFeedback.mediumImpact());
                        model.setHomeGrid(_cols, _rows);
                        setState(() => _page = 0);
                      }
                    : null,
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _IconsPage extends StatelessWidget {
  const _IconsPage();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();
    final model = context.watch<LauncherModel>();
    final ch = LauncherChannel.instance;

    return _SettingsPage(
      title: 'Icons',
      children: [
        _tile(
          t,
          icon: Icons.palette_outlined,
          title: 'Icon pack',
          subtitle: s.iconPack == null
              ? 'System default'
              : (s.iconPackLabel ?? s.iconPack!),
          chevron: true,
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
        Padding(
          padding: _rowPadding,
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Icon size',
                    style: TextStyle(color: t.drawerText),
                  ),
                ),
                Text(
                  '${(s.iconScale * 100).round()}%',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                SizedBox(
                  width: 40,
                  child: (s.iconScale - 1.0).abs() > 0.001
                      ? IconButton(
                          tooltip: 'Reset icon size',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.restart_alt_rounded,
                            color: t.drawerTextMuted,
                          ),
                          onPressed: () => s.setIconScale(1.0),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        Slider(
          value: s.iconScale,
          min: LauncherSettings.minIconScale,
          max: LauncherSettings.maxIconScale,
          divisions: 9,
          activeColor: t.accent,
          label: '${(s.iconScale * 100).round()}%',
          onChanged: (v) {
            HapticFeedback.selectionClick();
            unawaited(s.setIconScale(v));
          },
        ),
        _switchRow(
          t,
          title: 'Themed icons',
          subtitle: s.themedIcons
              ? 'Icons are tinted to match your theme'
              : 'Use each app\'s own colors',
          value: s.themedIcons,
          onChanged: s.setThemedIcons,
        ),
        _switchRow(
          t,
          title: 'Icon badges',
          subtitle: model.notificationAccess
              ? 'Shows notification counts on icons'
              : 'Needs notification access',
          value: s.showBadges,
          onChanged: (v) {
            s.setShowBadges(v);
            if (v && !model.notificationAccess) {
              ch.openNotificationAccessSettings();
            }
          },
        ),
      ],
    );
  }
}

class _SearchPage extends StatelessWidget {
  const _SearchPage();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();
    final model = context.watch<LauncherModel>();

    return _SettingsPage(
      title: 'Search',
      children: [
        _switchRow(
          t,
          title: 'Fuzzy search',
          subtitle: s.fuzzySearch
              ? 'Finds apps despite typos and abbreviations'
              : 'Only names that start with or contain your text',
          value: s.fuzzySearch,
          onChanged: s.setFuzzySearch,
        ),
        _hint(
          t,
          'Tip: start a search with "${LauncherModel.hiddenSearchPrefix}" '
          'to include hidden apps. For example, '
          '"${LauncherModel.hiddenSearchPrefix}bank" searches everything, '
          'and a lone "${LauncherModel.hiddenSearchPrefix}" lists every '
          'hidden app.',
        ),
        _tile(
          t,
          icon: Icons.sell_outlined,
          title: 'Tags',
          subtitle: model.tagCounts.isEmpty
              ? 'None yet'
              : '${model.tagCounts.length} '
                    '${model.tagCounts.length == 1 ? 'tag' : 'tags'}',
          chevron: true,
          onTap: () => showTagManager(context),
        ),
      ],
    );
  }
}

class _GesturesPage extends StatelessWidget {
  const _GesturesPage();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();

    return _SettingsPage(
      title: 'Gestures',
      children: [
        _subHeader(t, 'HOME SCREEN'),
        for (final side in GestureSide.values)
          _tile(
            t,
            icon: side == GestureSide.left
                ? Icons.arrow_back_rounded
                : Icons.arrow_forward_rounded,
            title: side.label,
            subtitle: s.gestureFor(side).summary,
            chevron: true,
            onTap: () => showGesturePicker(context, side),
          ),
        _hint(
          t,
          'Swipe left works on your last home page and swipe right on '
          'your first, when there is no page left to swipe to.',
        ),
        _switchRow(
          t,
          title: 'Double tap to lock',
          subtitle:
              'Double tap an empty spot on the home screen to turn the screen off. '
              'Needs the Launch-R accessibility service and Android 9 or newer',
          value: s.doubleTapLock,
          onChanged: (v) async {
            await s.setDoubleTapLock(v);
            if (!v) return;
            final ok = await LauncherChannel.instance.hasRecentsAccess();
            if (!ok && context.mounted) {
              await explainAccessibilityAccess(
                context,
                title: 'Allow double tap to lock',
                doWhat: 'lock the screen',
                usedFor: 'lock your screen',
              );
            }
          },
        ),
        Padding(
          padding: _rowPadding,
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Gesture sensitivity',
                    style: TextStyle(color: t.drawerText),
                  ),
                ),
                Text(
                  '${(s.gestureSensitivity * 100).round()}%',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
                SizedBox(
                  width: 40,
                  child: (s.gestureSensitivity - 1.0).abs() > 0.001
                      ? IconButton(
                          tooltip: 'Reset sensitivity',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.restart_alt_rounded,
                            color: t.drawerTextMuted,
                          ),
                          onPressed: () => s.setGestureSensitivity(1.0),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        Slider(
          value: s.gestureSensitivity,
          min: LauncherSettings.minGestureSensitivity,
          max: LauncherSettings.maxGestureSensitivity,
          divisions: 10,
          activeColor: t.accent,
          label: '${(s.gestureSensitivity * 100).round()}%',
          onChanged: (v) {
            HapticFeedback.selectionClick();
            unawaited(s.setGestureSensitivity(v));
          },
        ),
        _hint(
          t,
          'Higher means a shorter, lighter swipe triggers the gesture. '
          'Lower means you need to swipe further or faster.',
        ),
        _subHeader(t, 'APP DRAWER'),
        _tile(
          t,
          icon: Icons.swipe_vertical_rounded,
          title: 'Swipes in the app drawer',
          subtitle: s.swipeUpHome
              ? 'Swipe up again goes home'
              : s.swipeUpSearch
              ? 'Swipe up again opens search'
              : 'Off',
          chevron: true,
          onTap: () => _openPage(context, const _DrawerPage()),
        ),
      ],
    );
  }
}

class _SystemPage extends StatelessWidget {
  const _SystemPage();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();
    final model = context.watch<LauncherModel>();
    final ch = LauncherChannel.instance;

    return _SettingsPage(
      title: 'System',
      children: [
        _tile(
          t,
          icon: Icons.visibility_off_outlined,
          title: 'Hidden apps',
          subtitle: model.hiddenCount == 0
              ? 'None'
              : '${model.hiddenCount} hidden',
          onTap: () => showHiddenApps(context),
        ),
        _tile(
          t,
          icon: Icons.wallpaper_rounded,
          title: 'Change wallpaper',
          onTap: ch.openWallpaperPicker,
        ),
        _tile(
          t,
          icon: Icons.home_rounded,
          title: 'Default home app',
          onTap: ch.openHomeSettings,
        ),
        _subHeader(t, 'PERFORMANCE'),
        _switchRow(
          t,
          title: 'Reduce animations',
          subtitle:
              'Skip transitions and the folder blur. Helps on slower devices',
          value: s.reduceAnimations,
          onChanged: s.setReduceAnimations,
        ),
      ],
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
