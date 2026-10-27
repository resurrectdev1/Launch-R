import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/launch_r_sheet.dart';

void showLaunchRAbout(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AboutSheet(),
  );
}

class _AboutSheet extends StatefulWidget {
  const _AboutSheet();

  @override
  State<_AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends State<_AboutSheet> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);

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
        child: SheetScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 24),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Launch-R',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: t.drawerText,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'v${_version.isEmpty ? '...' : _version} • Open Source',
                        style: TextStyle(
                          fontSize: 12,
                          color: t.drawerTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Launch-R is a customizable Android home launcher inspired by One UI Home. '
                'Shape your home screen, drawer and gestures exactly how you like, '
                'entirely on your device. Built with love as a free, open-source tool.',
                style: TextStyle(
                  fontSize: 13,
                  color: t.drawerTextMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'LINKS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.drawerTextMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              _LinkTile(
                icon: Icons.code_rounded,
                iconColor: t.drawerText,
                label: 'GitHub',
                sublabel: 'Source code & contributions',
                url: 'https://github.com/resurrectdev1/Launch-R',
                t: t,
              ),
              const SizedBox(height: 10),
              _LinkTile(
                icon: Icons.coffee_rounded,
                iconColor: const Color(0xFFFFDD57),
                label: 'Buy Me a Coffee',
                sublabel: 'Support development',
                url: 'https://buymeacoffee.com/resurrect',
                t: t,
              ),
              const SizedBox(height: 24),
              Text(
                'Made with 🏠 • all data stays on your device.',
                style: TextStyle(fontSize: 10, color: t.drawerTextMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.url,
    required this.t,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final String url;
  final LaunchRTheme t;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: t.drawerText.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.drawerTextMuted.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.drawerText,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 11, color: t.drawerTextMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 16, color: t.drawerTextMuted),
          ],
        ),
      ),
    ),
  );
}
