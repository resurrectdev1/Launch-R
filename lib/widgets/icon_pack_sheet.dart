import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/launch_r_sheet.dart';
import 'package:launch_r/theme/motion.dart';

void showIconPackPicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _IconPackSheet(),
  );
}

class _IconPackSheet extends StatefulWidget {
  const _IconPackSheet();

  @override
  State<_IconPackSheet> createState() => _IconPackSheetState();
}

class _IconPackSheetState extends State<_IconPackSheet> {
  List<IconPackInfo>? _packs;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final packs = await LauncherChannel.instance.getIconPacks();
    if (mounted) setState(() => _packs = packs);
  }

  Future<void> _choose(IconPackInfo? pack) async {
    if (_busy) return;
    final settings = context.read<LauncherSettings>();
    final model = context.read<LauncherModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final ok = await model.applyIconPack(pack?.package);
    if (ok) {
      await settings.setIconPack(pack?.package, pack?.label);
      if (navigator.mounted) navigator.pop();
    } else {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't load ${pack?.label ?? 'that pack'}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final current = context.select<LauncherSettings, String?>(
      (s) => s.iconPack,
    );
    final packs = _packs;

    Widget radio(bool selected) => Icon(
      selected
          ? Icons.radio_button_checked_rounded
          : Icons.radio_button_unchecked_rounded,
      color: selected ? t.accent : t.drawerTextMuted,
    );

    return LaunchRSheet(
      title: 'Icon pack',
      size: SheetSize.standard,
      child: packs == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          : SheetScrollbar(
              builder: (controller) => ListView(
                controller: controller,
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Icon(
                      Icons.phone_android_rounded,
                      color: t.drawerText,
                    ),
                    title: Text(
                      'System default',
                      style: TextStyle(color: t.drawerText),
                    ),
                    subtitle: Text(
                      'Original app icons, in your chosen shape',
                      style: TextStyle(color: t.drawerTextMuted),
                    ),
                    trailing: radio(current == null),
                    onTap: _busy ? null : () => _choose(null),
                  ),
                  for (final p in packs)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.palette_outlined, color: t.drawerText),
                          AppIconImage(pkg: p.package, size: 40),
                        ],
                      ),
                      title: Text(
                        p.label,
                        style: TextStyle(color: t.drawerText),
                      ),
                      trailing: radio(current == p.package),
                      onTap: _busy ? null : () => _choose(p),
                    ),
                  if (packs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Text(
                        'No icon packs found. Install one that supports '
                        'Nova, ADW or Apex launchers and it will show up here.',
                        style: TextStyle(
                          color: t.drawerTextMuted,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                      child: Text(
                        "Apps the pack doesn't cover keep their original "
                        'icon, in your chosen shape.',
                        style: TextStyle(
                          color: t.drawerTextMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
