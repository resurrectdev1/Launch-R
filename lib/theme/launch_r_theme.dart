import 'package:flutter/material.dart';

class LaunchRTheme {
  final Brightness brightness;
  const LaunchRTheme(this.brightness);

  factory LaunchRTheme.of(BuildContext context) =>
      LaunchRTheme(Theme.of(context).brightness);

  bool get dark => brightness == Brightness.dark;

  static const accent = Color(0xFF3E91FF);
  static const badge = Color(0xFFFF5B22);

  Color get drawerScrim =>
      dark ? const Color(0xD9101014) : const Color(0xE6F3F3F8);
  Color get drawerText => dark ? Colors.white : const Color(0xFF1B1B1F);
  Color get drawerTextMuted =>
      dark ? const Color(0xB3FFFFFF) : const Color(0x991B1B1F);
  Color get searchBg =>
      dark ? const Color(0x26FFFFFF) : const Color(0x14000000);
  Color get folderBgDrawer =>
      dark ? const Color(0x59FFFFFF) : const Color(0x1F000000);
  Color get menuBg => dark ? const Color(0xFF2B2B31) : const Color(0xFFF7F7FB);
  Color get popupBg => dark ? const Color(0xF2303036) : const Color(0xF2F5F5F9);
  Color get dragBarBg => const Color(0xEE1D1D22);
}

class CellStyle {
  final Color label;
  final List<Shadow> shadows;
  final Color folderBg;
  const CellStyle({
    required this.label,
    required this.shadows,
    required this.folderBg,
  });
}
