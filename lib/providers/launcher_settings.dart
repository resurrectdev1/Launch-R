import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_r/models/launcher_models.dart';

class LauncherSettings extends ChangeNotifier {
  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  bool _darkHomeText = false;
  int _drawerCols = 4;
  bool _lockLayout = false;
  bool _showBadges = true;
  IconShape _iconShape = IconShape.squircle;

  ThemeMode get themeMode => _themeMode;
  bool get darkHomeText => _darkHomeText;
  int get drawerCols => _drawerCols;
  bool get lockLayout => _lockLayout;
  bool get showBadges => _showBadges;
  IconShape get iconShape => _iconShape;

  Future<void> init() async {
    final p = _prefs = await SharedPreferences.getInstance();
    final t = p.getInt('theme_mode') ?? 0;
    if (t >= 0 && t < ThemeMode.values.length) _themeMode = ThemeMode.values[t];
    _darkHomeText = p.getBool('dark_home_text') ?? false;
    _drawerCols = p.getInt('drawer_cols') ?? 4;
    _lockLayout = p.getBool('lock_layout') ?? false;
    _showBadges = p.getBool('show_badges') ?? true;
    _iconShape = IconShape.fromName(p.getString('icon_shape'));
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    notifyListeners();
    await _prefs?.setInt('theme_mode', m.index);
  }

  Future<void> setDarkHomeText(bool v) async {
    _darkHomeText = v;
    notifyListeners();
    await _prefs?.setBool('dark_home_text', v);
  }

  Future<void> setDrawerCols(int v) async {
    _drawerCols = v;
    notifyListeners();
    await _prefs?.setInt('drawer_cols', v);
  }

  Future<void> setLockLayout(bool v) async {
    _lockLayout = v;
    notifyListeners();
    await _prefs?.setBool('lock_layout', v);
  }

  Future<void> setShowBadges(bool v) async {
    _showBadges = v;
    notifyListeners();
    await _prefs?.setBool('show_badges', v);
  }

  Future<void> setIconShape(IconShape v) async {
    if (v == _iconShape) return;
    _iconShape = v;
    notifyListeners();
    await _prefs?.setString('icon_shape', v.name);
  }
}
