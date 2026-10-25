import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/app_icon.dart';
import 'package:launch_r/widgets/launch_r_sheet.dart';
import 'package:launch_r/theme/motion.dart';

void showHiddenApps(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HiddenAppsSheet(),
  );
}

class _HiddenAppsSheet extends StatelessWidget {
  const _HiddenAppsSheet();

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final apps = model.hiddenApps;

    return LaunchRSheet(
      title: 'Hidden apps',
      size: SheetSize.compact,
      child: apps.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Text(
                'No hidden apps. Long-press an app and choose Hide app.',
                style: TextStyle(color: t.drawerTextMuted, fontSize: 15),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: apps.length,
              itemBuilder: (context, i) {
                final app = apps[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: AppIconImage(pkg: app.package, size: 40),
                  title: Text(app.label, style: TextStyle(color: t.drawerText)),
                  trailing: TextButton(
                    style: TextButton.styleFrom(foregroundColor: t.accentText),
                    onPressed: () => model.unhideApp(app.package),
                    child: const Text('Unhide'),
                  ),
                );
              },
            ),
    );
  }
}
