import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/screens/launcher_shell.dart';
import 'package:launch_r/theme/launch_r_theme.dart';

class LaunchRApp extends StatelessWidget {
  const LaunchRApp({super.key});

  ThemeData _theme(Brightness b) => ThemeData(
    useMaterial3: true,
    brightness: b,
    colorSchemeSeed: LaunchRTheme.accent,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<LauncherSettings>();
    return MaterialApp(
      title: 'Launch-R',
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      themeMode: settings.themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const LauncherShell(),
    );
  }
}
