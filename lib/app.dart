import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/screens/launcher_shell.dart';
import 'package:launch_r/theme/launch_r_theme.dart';

class LaunchRApp extends StatelessWidget {
  const LaunchRApp({super.key});

  ThemeData _theme(AppearanceMode mode, Color accent) {
    final lt = LaunchRTheme.forMode(mode, accent);
    var scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: lt.brightness,
    ).copyWith(primary: accent, onPrimary: lt.onAccent);
    if (lt.amoled) scheme = scheme.copyWith(surface: Colors.black);
    return ThemeData(
      useMaterial3: true,
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
    final settings = context.watch<LauncherSettings>();
    return MaterialApp(
      title: 'Launch-R',
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      themeMode: ThemeMode.light,
      theme: _theme(settings.appearance, settings.accent),
      home: const LauncherShell(),
    );
  }
}
