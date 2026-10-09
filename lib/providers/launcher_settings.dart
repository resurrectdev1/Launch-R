import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/theme/launch_r_theme.dart';

class LauncherSettings extends ChangeNotifier {
  SharedPreferences? _prefs;

  AppearanceMode _appearance = AppearanceMode.orangeFactory;
  Color? _customAccent;
  bool _darkHomeText = false;
  int _drawerCols = 4;
  bool _lockLayout = false;
  bool _showBadges = true;
  bool _fuzzySearch = true;
  double _textScale = 1.0;
  String? _iconPack;
  String? _iconPackLabel;
  bool _boldText = false;
  IconShape _iconShape = IconShape.squircle;
  ColorScheme? _dynamicLight;
  ColorScheme? _dynamicDark;

  AppearanceMode get appearance => _appearance;

  Color? get customAccent => _customAccent;
  Color get accent => _customAccent ?? LaunchRTheme.defaultAccent;

  bool get dynamicAvailable => _dynamicLight != null || _dynamicDark != null;
  ColorScheme? dynamicSchemeFor(Brightness b) => b == Brightness.dark
      ? (_dynamicDark ?? _dynamicLight)
      : (_dynamicLight ?? _dynamicDark);
  bool get darkHomeText => _darkHomeText;
  int get drawerCols => _drawerCols;
  bool get lockLayout => _lockLayout;
  bool get showBadges => _showBadges;
  bool get fuzzySearch => _fuzzySearch;
  double get textScale => _textScale;
  String? get iconPack => _iconPack;
  String? get iconPackLabel => _iconPackLabel;
  bool get boldText => _boldText;

  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.3;
  IconShape get iconShape => _iconShape;

  Future<void> init() async {
    final p = _prefs = await SharedPreferences.getInstance();
    final saved = p.getString('appearance');
    if (saved != null) {
      _appearance = AppearanceMode.fromName(saved);
    } else if (p.getInt('theme_mode') == 1) {
      _appearance = AppearanceMode.whiteMinimal;
    }
    final accentArgb = p.getInt('custom_accent');
    if (accentArgb != null) _customAccent = Color(accentArgb | 0xFF000000);
    _darkHomeText = p.getBool('dark_home_text') ?? false;
    _drawerCols = p.getInt('drawer_cols') ?? 4;
    _lockLayout = p.getBool('lock_layout') ?? false;
    _showBadges = p.getBool('show_badges') ?? true;
    _fuzzySearch = p.getBool('fuzzy_search') ?? true;
    _iconShape = IconShape.fromName(p.getString('icon_shape'));
    _textScale = (p.getDouble('text_scale') ?? 1.0)
        .clamp(minTextScale, maxTextScale)
        .toDouble();
    _boldText = p.getBool('bold_text') ?? false;
    _iconPack = p.getString('icon_pack');
    _iconPackLabel = p.getString('icon_pack_label');
  }

  void applyDynamicColors(ColorScheme? light, ColorScheme? dark) {
    if (light == _dynamicLight && dark == _dynamicDark) return;
    _dynamicLight = light;
    _dynamicDark = dark;
    notifyListeners();
  }

  Future<void> setAppearance(AppearanceMode m) async {
    if (m == _appearance) return;
    _appearance = m;
    notifyListeners();
    await _prefs?.setString('appearance', m.name);
  }

  Future<void> setCustomAccent(Color? c) async {
    final opaque = c == null ? null : Color(c.toARGB32() | 0xFF000000);
    if (opaque == _customAccent) return;
    _customAccent = opaque;
    notifyListeners();
    if (opaque == null) {
      await _prefs?.remove('custom_accent');
    } else {
      await _prefs?.setInt('custom_accent', opaque.toARGB32());
    }
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

  Future<void> setFuzzySearch(bool v) async {
    if (v == _fuzzySearch) return;
    _fuzzySearch = v;
    notifyListeners();
    await _prefs?.setBool('fuzzy_search', v);
  }

  Future<void> setIconShape(IconShape v) async {
    if (v == _iconShape) return;
    _iconShape = v;
    notifyListeners();
    await _prefs?.setString('icon_shape', v.name);
  }

  Future<void> setTextScale(double v) async {
    final next = v.clamp(minTextScale, maxTextScale).toDouble();
    if (next == _textScale) return;
    _textScale = next;
    notifyListeners();
    await _prefs?.setDouble('text_scale', next);
  }

  Future<void> setBoldText(bool v) async {
    if (v == _boldText) return;
    _boldText = v;
    notifyListeners();
    await _prefs?.setBool('bold_text', v);
  }

  Future<void> setIconPack(String? pkg, String? label) async {
    if (pkg == _iconPack && label == _iconPackLabel) return;
    _iconPack = pkg;
    _iconPackLabel = pkg == null ? null : label;
    notifyListeners();
    if (pkg == null) {
      await _prefs?.remove('icon_pack');
      await _prefs?.remove('icon_pack_label');
    } else {
      await _prefs?.setString('icon_pack', pkg);
      await _prefs?.setString('icon_pack_label', label ?? pkg);
    }
  }
}
