import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/app_fonts.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/launch_r_sheet.dart';
import 'package:launch_r/theme/motion.dart';

void showFontPicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FontSheet(),
  );
}

class _FontSheet extends StatefulWidget {
  const _FontSheet();

  @override
  State<_FontSheet> createState() => _FontSheetState();
}

class _FontSheetState extends State<_FontSheet> {
  static const _sample = 'Find your space.';
  bool _busy = false;

  Future<void> _import() async {
    if (_busy) return;
    final settings = context.read<LauncherSettings>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    String? error;
    try {
      final picked = await LauncherChannel.instance.pickFont();
      if (picked != null) {
        final ok = await settings.setCustomFont(picked.path, picked.label);
        if (!ok) error = 'That file isn\'t a usable .ttf or .otf font';
      }
    } on PlatformException {
      error = "Couldn't import that file";
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final s = context.watch<LauncherSettings>();

    Widget radio(bool selected) => Icon(
      selected
          ? Icons.radio_button_checked_rounded
          : Icons.radio_button_unchecked_rounded,
      color: selected ? t.accent : t.drawerTextMuted,
    );

    Widget option({
      required String title,
      required String? family,
      required bool selected,
      required VoidCallback onTap,
      Widget? trailing,
    }) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        title,
        style: TextStyle(color: t.drawerText, fontFamily: family, fontSize: 17),
      ),
      subtitle: Text(
        _sample,
        style: TextStyle(color: t.drawerTextMuted, fontFamily: family),
      ),
      trailing: trailing ?? radio(selected),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );

    return LaunchRSheet(
      title: 'Font',
      size: SheetSize.standard,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          option(
            title: 'System default',
            family: 'Roboto',
            selected: s.fontId == null,
            onTap: () => unawaited(s.setFont(null)),
          ),
          for (final f in AppFont.bundled)
            option(
              title: f.label,
              family: f.family,
              selected: s.fontId == f.id,
              onTap: () => unawaited(s.setFont(f.id)),
            ),
          if (s.hasCustomFont)
            option(
              title: s.customFontLabel ?? 'Custom font',
              family: s.fontId == AppFont.customId ? s.fontFamily : null,
              selected: s.fontId == AppFont.customId,
              onTap: () => unawaited(s.setFont(AppFont.customId)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Remove imported font',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: t.drawerTextMuted,
                    ),
                    onPressed: () => unawaited(s.removeCustomFont()),
                  ),
                  radio(s.fontId == AppFont.customId),
                ],
              ),
            ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: _busy
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: t.accent,
                    ),
                  )
                : Icon(Icons.upload_file_rounded, color: t.drawerText),
            title: Text(
              s.hasCustomFont
                  ? 'Import a different font'
                  : 'Import your own font',
              style: TextStyle(color: t.drawerText),
            ),
            subtitle: Text(
              'Choose a .ttf or .otf file from your device',
              style: TextStyle(color: t.drawerTextMuted),
            ),
            onTap: _busy ? null : _import,
          ),
        ],
      ),
    );
  }
}
