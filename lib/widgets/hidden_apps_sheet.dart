import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/widgets/app_icon.dart';

void showHiddenApps(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        color: t.menuBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Hidden apps',
                style: TextStyle(
                  color: t.drawerText,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (apps.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Text(
                  'No hidden apps. Long-press an app and choose Hide app.',
                  style: TextStyle(color: t.drawerTextMuted, fontSize: 15),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
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
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: LaunchRTheme.accent,
                        ),
                        onPressed: () => model.unhideApp(app.package),
                        child: const Text('Unhide'),
                      ),
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
