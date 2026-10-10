import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/screens/launcher_shell.dart';
import 'package:launch_r/theme/launch_r_theme.dart';

class LaunchRApp extends StatefulWidget {
  const LaunchRApp({super.key});

  @override
  State<LaunchRApp> createState() => _LaunchRAppState();
}

class _LaunchRAppState extends State<LaunchRApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  ThemeData _theme(
    AppearanceMode mode,
    Color accent,
    ColorScheme? dyn,
    String? fontFamily,
  ) {
    final lt = LaunchRTheme.forMode(mode, accent, dynamicScheme: dyn);
    var scheme = lt.dynamicScheme != null
        ? lt.dynamicScheme!.copyWith(primary: lt.accent, onPrimary: lt.onAccent)
        : ColorScheme.fromSeed(
            seedColor: lt.accent,
            brightness: lt.brightness,
          ).copyWith(primary: lt.accent, onPrimary: lt.onAccent);
    if (lt.amoled) scheme = scheme.copyWith(surface: Colors.black);
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: lt.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      dialogTheme: lt.amoled
          ? const DialogThemeData(backgroundColor: Color(0xFF121212))
          : null,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      extensions: [lt],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<LauncherSettings>().applyDynamicColors(
            lightDynamic,
            darkDynamic,
          );
        });
        return Consumer<LauncherSettings>(
          builder: (_, settings, _) {
            final dyn = settings.materialYou
                ? settings.dynamicSchemeFor(settings.appearance.brightness)
                : null;
            return MaterialApp(
              title: 'Launch-R',
              debugShowCheckedModeBanner: false,
              color: Colors.transparent,
              themeMode: ThemeMode.light,
              theme: _theme(
                settings.appearance,
                settings.accent,
                dyn,
                settings.fontFamily,
              ),
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: TextScaler.linear(
                      mq.textScaler.scale(1) * settings.textScale,
                    ),
                    boldText: mq.boldText || settings.boldText,
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const LauncherShell(),
            );
          },
        );
      },
    );
  }
}
