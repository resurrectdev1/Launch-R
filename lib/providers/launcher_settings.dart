import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_r/models/gesture_models.dart';
import 'package:launch_r/models/layout_models.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/services/font_service.dart';
import 'package:launch_r/services/icon_cache.dart';
import 'package:launch_r/theme/app_fonts.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';

class LauncherSettings extends ChangeNotifier {
  SharedPreferences? _prefs;

  AppearanceMode _appearance = AppearanceMode.orangeFactory;
  bool _materialYou = false;
  Color? _customAccent;
  bool _darkHomeText = false;
  bool _hideStatusBar = false;
  bool _solidHomeFolders = false;
  bool _homeLookDrawerFolders = true;
  int _drawerCols = 4;
  bool _lockLayout = false;
  bool _showHomeLabels = true;
  bool _showDrawerLabels = true;
  bool _showDockLabels = false;
  PageIndicatorStyle _pageIndicator = PageIndicatorStyle.dots;
  PageIndicatorStyle _drawerPageIndicator = PageIndicatorStyle.dots;
  bool _loopPages = false;
  bool _loopDrawerPages = false;
  bool _showBadges = false;
  bool _reduceAnimations = false;
  bool _legacyRenderer = false;
  bool _drawerAutoSearch = false;
  bool _swipeUpHome = false;
  bool _doubleTapLock = false;
  bool _swipeUpSearch = false;
  HomeGesture _swipeLeft = const HomeGesture();
  HomeGesture _swipeRight = const HomeGesture();
  double _gestureSensitivity = 1.0;
  bool _fuzzySearch = true;
  bool _searchPackageNames = false;
  bool _showVoiceButton = true;
  bool _showClearButton = true;
  bool _drawerSuggestions = true;
  bool _tagBar = false;
  TagBarPosition _tagBarPosition = TagBarPosition.top;
  double _textScale = 1.0;
  double _iconScale = 1.0;
  String? _iconPack;
  String? _iconPackLabel;
  bool _boldText = false;
  IconShape _iconShape = IconShape.squircle;
  HoldAnimation _holdAnimation = HoldAnimation.sway;
  bool _themedIcons = false;
  String? _fontId;
  String? _customFontPath;
  String? _customFontLabel;
  String? _customFontFamily;
  bool _ownBackground = false;
  String? _backgroundPath;
  ColorScheme? _dynamicLight;
  ColorScheme? _dynamicDark;

  AppearanceMode get appearance => _appearance;
  bool get materialYou => _materialYou;

  Color? get customAccent => _customAccent;
  Color get accent => _customAccent ?? LaunchRTheme.defaultAccent;

  bool get dynamicAvailable => _dynamicLight != null || _dynamicDark != null;

  Color? get dynamicAccent => (_dynamicDark ?? _dynamicLight)?.primary;
  bool get darkHomeText => _darkHomeText;
  bool get hideStatusBar => _hideStatusBar;
  bool get solidHomeFolders => _solidHomeFolders;
  bool get homeLookDrawerFolders => _homeLookDrawerFolders;
  int get drawerCols => _drawerCols;
  bool get lockLayout => _lockLayout;
  bool get showHomeLabels => _showHomeLabels;
  bool get showDrawerLabels => _showDrawerLabels;
  bool get showDockLabels => _showDockLabels;
  PageIndicatorStyle get pageIndicator => _pageIndicator;
  PageIndicatorStyle get drawerPageIndicator => _drawerPageIndicator;
  bool get loopPages => _loopPages;
  bool get loopDrawerPages => _loopDrawerPages;
  bool get showBadges => _showBadges;
  bool get reduceAnimations => _reduceAnimations;
  bool get legacyRenderer => _legacyRenderer;
  bool get drawerAutoSearch => _drawerAutoSearch;
  bool get swipeUpHome => _swipeUpHome;
  bool get doubleTapLock => _doubleTapLock;
  bool get swipeUpSearch => _swipeUpSearch;
  HomeGesture get swipeLeft => _swipeLeft;
  HomeGesture get swipeRight => _swipeRight;
  double get gestureSensitivity => _gestureSensitivity;
  HomeGesture gestureFor(GestureSide side) =>
      side == GestureSide.left ? _swipeLeft : _swipeRight;
  bool get fuzzySearch => _fuzzySearch;
  bool get searchPackageNames => _searchPackageNames;
  bool get showVoiceButton => _showVoiceButton;
  bool get showClearButton => _showClearButton;
  bool get drawerSuggestions => _drawerSuggestions;
  bool get tagBar => _tagBar;
  TagBarPosition get tagBarPosition => _tagBarPosition;
  double get textScale => _textScale;
  double get iconScale => _iconScale;
  String? get iconPack => _iconPack;
  String? get iconPackLabel => _iconPackLabel;
  bool get boldText => _boldText;

  String? get fontId => _fontId;
  String? get customFontLabel => _customFontLabel;
  bool get hasCustomFont => _customFontFamily != null;

  String? get fontFamily {
    final id = _fontId;
    if (id == null) return null;
    if (id == AppFont.customId) return _customFontFamily;
    return AppFont.byId(id)?.family;
  }

  String get fontLabel {
    final id = _fontId;
    if (id == AppFont.customId && _customFontFamily != null) {
      return _customFontLabel ?? 'Custom font';
    }
    return AppFont.byId(id)?.label ?? 'System default';
  }

  static const double minGestureSensitivity = 0.5;
  static const double maxGestureSensitivity = 1.5;
  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.3;
  static const double minIconScale = 0.7;
  static const double maxIconScale = 1.15;
  IconShape get iconShape => _iconShape;
  HoldAnimation get holdAnimation => _holdAnimation;
  bool get ownBackground => _ownBackground;
  String? get backgroundPath => _backgroundPath;
  bool get themedIcons => _themedIcons;

  Future<void> init() async {
    final p = _prefs = await SharedPreferences.getInstance();
    _appearance = AppearanceMode.orangeFactory;
    final saved = p.getString('appearance');
    if (saved == 'materialYou') {
      _appearance = AppearanceMode.orangeFactory;
      _materialYou = true;
      await p.setString('appearance', _appearance.name);
      await p.setBool('material_you', true);
    } else {
      if (saved != null) {
        _appearance = AppearanceMode.fromName(saved);
      } else if (p.getInt('theme_mode') == 1) {
        _appearance = AppearanceMode.whiteMinimal;
      }
      _materialYou = p.getBool('material_you') ?? false;
    }
    final accentArgb = p.getInt('custom_accent');
    _customAccent = accentArgb == null ? null : Color(accentArgb | 0xFF000000);
    _darkHomeText = p.getBool('dark_home_text') ?? false;
    _hideStatusBar = p.getBool('hide_status_bar') ?? false;
    _solidHomeFolders = p.getBool('solid_home_folders') ?? false;
    _homeLookDrawerFolders = p.getBool('home_look_drawer_folders') ?? true;
    _drawerCols = (p.getInt('drawer_cols') ?? 4).clamp(
      GridLimits.minDrawerCols,
      GridLimits.maxDrawerCols,
    );
    _showHomeLabels = p.getBool('show_home_labels') ?? true;
    _showDrawerLabels = p.getBool('show_drawer_labels') ?? true;
    _showDockLabels = p.getBool('show_dock_labels') ?? false;
    _pageIndicator = PageIndicatorStyle.fromName(p.getString('page_indicator'));
    _drawerPageIndicator = PageIndicatorStyle.fromName(
      p.getString('drawer_page_indicator') ?? p.getString('page_indicator'),
    );
    _loopPages = p.getBool('loop_pages') ?? false;
    _loopDrawerPages = p.getBool('loop_drawer_pages') ?? false;
    _lockLayout = p.getBool('lock_layout') ?? false;
    _showBadges = p.getBool('show_badges') ?? false;
    _reduceAnimations = p.getBool('reduce_animations') ?? false;
    Motion.reduced = _reduceAnimations;
    _legacyRenderer = p.getBool(legacyRendererKey) ?? false;
    _drawerAutoSearch = p.getBool('drawer_auto_search') ?? false;
    _swipeUpHome = p.getBool('swipe_up_home') ?? false;
    _doubleTapLock = p.getBool('double_tap_lock') ?? false;
    _swipeUpSearch = p.getBool('swipe_up_search') ?? false;
    if (_swipeUpHome && _swipeUpSearch) {
      _swipeUpSearch = false;
      await p.setBool('swipe_up_search', false);
    }
    _swipeLeft = _readGesture(p, 'gesture_left');
    _swipeRight = _readGesture(p, 'gesture_right');
    _gestureSensitivity = (p.getDouble('gesture_sensitivity') ?? 1.0)
        .clamp(minGestureSensitivity, maxGestureSensitivity)
        .toDouble();
    _fuzzySearch = p.getBool('fuzzy_search') ?? true;
    _searchPackageNames = p.getBool('search_package_names') ?? false;
    _showVoiceButton = p.getBool('show_voice_button') ?? true;
    _showClearButton = p.getBool('show_clear_button') ?? true;
    _drawerSuggestions = p.getBool('drawer_suggestions') ?? true;
    _tagBar = p.getBool('tag_bar') ?? false;
    _tagBarPosition = TagBarPosition.fromName(p.getString('tag_bar_position'));
    _iconShape = IconShape.fromName(p.getString('icon_shape'));
    _holdAnimation = HoldAnimation.fromName(p.getString('hold_animation'));
    _themedIcons = p.getBool('themed_icons') ?? false;
    _textScale = (p.getDouble('text_scale') ?? 1.0)
        .clamp(minTextScale, maxTextScale)
        .toDouble();
    _iconScale = (p.getDouble('icon_scale') ?? 1.0)
        .clamp(minIconScale, maxIconScale)
        .toDouble();
    _boldText = p.getBool('bold_text') ?? false;
    _iconPack = p.getString('icon_pack');
    _iconPackLabel = p.getString('icon_pack_label');
    _ownBackground = p.getBool('own_background') ?? false;
    _backgroundPath = p.getString('background_path');
    final bg = _backgroundPath;
    if (bg != null && !File(bg).existsSync()) {
      _backgroundPath = null;
      await p.remove('background_path');
    }
    await _restoreFont(p);
  }

  Future<void> reload() async {
    await init();
    IconCache.instance.shape = _iconShape;
    notifyListeners();
  }

  Future<void> setOwnBackground(bool v) async {
    if (v == _ownBackground) return;
    _ownBackground = v;
    notifyListeners();
    await _prefs?.setBool('own_background', v);
  }

  Future<void> setBackgroundPath(String? path) async {
    final old = _backgroundPath;
    _backgroundPath = path;
    notifyListeners();
    if (path == null) {
      await _prefs?.remove('background_path');
    } else {
      await _prefs?.setString('background_path', path);
    }
    if (old != null && old != path) {
      try {
        final f = File(old);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  Future<void> _restoreFont(SharedPreferences p) async {
    final id = p.getString('font_id');
    _customFontFamily = null;
    _customFontPath = p.getString('custom_font_path');
    _customFontLabel = p.getString('custom_font_label');
    final path = _customFontPath;
    if (path != null) {
      _customFontFamily = await FontService.load(path);
      if (_customFontFamily == null) {
        _customFontPath = null;
        _customFontLabel = null;
        await p.remove('custom_font_path');
        await p.remove('custom_font_label');
        await FontService.delete(path);
      }
    }
    if (id == AppFont.customId) {
      _fontId = _customFontFamily == null ? null : id;
    } else {
      _fontId = AppFont.byId(id) == null ? null : id;
    }
    if (_fontId != id) {
      if (_fontId == null) {
        await p.remove('font_id');
      } else {
        await p.setString('font_id', _fontId!);
      }
    }
  }

  Future<void> setFont(String? id) async {
    if (id == AppFont.customId && _customFontFamily == null) return;
    if (id != null && id != AppFont.customId && AppFont.byId(id) == null) {
      return;
    }
    if (id == _fontId) return;
    _fontId = id;
    notifyListeners();
    if (id == null) {
      await _prefs?.remove('font_id');
    } else {
      await _prefs?.setString('font_id', id);
    }
  }

  Future<bool> setCustomFont(String path, String label) async {
    final family = await FontService.load(path);
    if (family == null) {
      await FontService.delete(path);
      return false;
    }
    final old = _customFontPath;
    _customFontPath = path;
    _customFontLabel = label;
    _customFontFamily = family;
    _fontId = AppFont.customId;
    notifyListeners();
    await _prefs?.setString('custom_font_path', path);
    await _prefs?.setString('custom_font_label', label);
    await _prefs?.setString('font_id', AppFont.customId);
    if (old != null && old != path) await FontService.delete(old);
    return true;
  }

  Future<void> removeCustomFont() async {
    final old = _customFontPath;
    _customFontPath = null;
    _customFontLabel = null;
    _customFontFamily = null;
    if (_fontId == AppFont.customId) _fontId = null;
    notifyListeners();
    await _prefs?.remove('custom_font_path');
    await _prefs?.remove('custom_font_label');
    if (_fontId == null) await _prefs?.remove('font_id');
    await FontService.delete(old);
  }

  void applyDynamicColors(ColorScheme? light, ColorScheme? dark) {
    if (light == _dynamicLight && dark == _dynamicDark) return;
    _dynamicLight = light;
    _dynamicDark = dark;
    notifyListeners();
  }

  Future<void> setMaterialYou(bool value) async {
    if (value == _materialYou) return;
    _materialYou = value;
    notifyListeners();
    await _prefs?.setBool('material_you', value);
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

  Future<void> setHideStatusBar(bool v) async {
    if (v == _hideStatusBar) return;
    _hideStatusBar = v;
    notifyListeners();
    await _prefs?.setBool('hide_status_bar', v);
  }

  Future<void> setSolidHomeFolders(bool v) async {
    if (v == _solidHomeFolders) return;
    _solidHomeFolders = v;
    notifyListeners();
    await _prefs?.setBool('solid_home_folders', v);
  }

  Future<void> setHomeLookDrawerFolders(bool v) async {
    if (v == _homeLookDrawerFolders) return;
    _homeLookDrawerFolders = v;
    notifyListeners();
    await _prefs?.setBool('home_look_drawer_folders', v);
  }

  Future<void> setDrawerCols(int v) async {
    v = v.clamp(GridLimits.minDrawerCols, GridLimits.maxDrawerCols);
    if (v == _drawerCols) return;
    _drawerCols = v;
    notifyListeners();
    await _prefs?.setInt('drawer_cols', v);
  }

  Future<void> setShowHomeLabels(bool v) async {
    if (v == _showHomeLabels) return;
    _showHomeLabels = v;
    notifyListeners();
    await _prefs?.setBool('show_home_labels', v);
  }

  Future<void> setShowDrawerLabels(bool v) async {
    if (v == _showDrawerLabels) return;
    _showDrawerLabels = v;
    notifyListeners();
    await _prefs?.setBool('show_drawer_labels', v);
  }

  Future<void> setShowDockLabels(bool v) async {
    if (v == _showDockLabels) return;
    _showDockLabels = v;
    notifyListeners();
    await _prefs?.setBool('show_dock_labels', v);
  }

  Future<void> setPageIndicator(PageIndicatorStyle v) async {
    if (v == _pageIndicator) return;
    _pageIndicator = v;
    notifyListeners();
    await _prefs?.setString('page_indicator', v.name);
  }

  Future<void> setDrawerPageIndicator(PageIndicatorStyle v) async {
    if (v == _drawerPageIndicator) return;
    _drawerPageIndicator = v;
    notifyListeners();
    await _prefs?.setString('drawer_page_indicator', v.name);
  }

  Future<void> setLoopPages(bool v) async {
    if (v == _loopPages) return;
    _loopPages = v;
    notifyListeners();
    await _prefs?.setBool('loop_pages', v);
  }

  Future<void> setLoopDrawerPages(bool v) async {
    if (v == _loopDrawerPages) return;
    _loopDrawerPages = v;
    notifyListeners();
    await _prefs?.setBool('loop_drawer_pages', v);
  }

  Future<void> setDoubleTapLock(bool v) async {
    if (v == _doubleTapLock) return;
    _doubleTapLock = v;
    notifyListeners();
    await _prefs?.setBool('double_tap_lock', v);
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

  Future<void> setReduceAnimations(bool v) async {
    if (v == _reduceAnimations) return;
    _reduceAnimations = v;
    Motion.reduced = v;
    notifyListeners();
    await _prefs?.setBool('reduce_animations', v);
  }

  static const legacyRendererKey = 'legacy_renderer';

  Future<void> setLegacyRenderer(bool v) async {
    if (v == _legacyRenderer) return;
    _legacyRenderer = v;
    notifyListeners();
    await _prefs?.setBool(legacyRendererKey, v);
  }

  Future<void> setDrawerAutoSearch(bool v) async {
    if (v == _drawerAutoSearch) return;
    _drawerAutoSearch = v;
    notifyListeners();
    await _prefs?.setBool('drawer_auto_search', v);
  }

  Future<void> setSwipeUpHome(bool v) async {
    if (v == _swipeUpHome) return;
    _swipeUpHome = v;
    final turnedOffOther = v && _swipeUpSearch;
    if (turnedOffOther) _swipeUpSearch = false;
    notifyListeners();
    await _prefs?.setBool('swipe_up_home', v);
    if (turnedOffOther) await _prefs?.setBool('swipe_up_search', false);
  }

  Future<void> setSwipeUpSearch(bool v) async {
    if (v == _swipeUpSearch) return;
    _swipeUpSearch = v;
    final turnedOffOther = v && _swipeUpHome;
    if (turnedOffOther) _swipeUpHome = false;
    notifyListeners();
    await _prefs?.setBool('swipe_up_search', v);
    if (turnedOffOther) await _prefs?.setBool('swipe_up_home', false);
  }

  static HomeGesture _readGesture(SharedPreferences p, String key) =>
      HomeGesture(
        action: GestureAction.fromName(p.getString('${key}_action')),
        pkg: p.getString('${key}_app'),
        label: p.getString('${key}_app_label'),
      );

  Future<void> setGesture(
    GestureSide side, {
    GestureAction? action,
    String? pkg,
    String? label,
  }) async {
    final isLeft = side == GestureSide.left;
    final next = (isLeft ? _swipeLeft : _swipeRight).copyWith(
      action: action,
      pkg: pkg,
      label: label,
    );
    if (isLeft) {
      _swipeLeft = next;
    } else {
      _swipeRight = next;
    }
    notifyListeners();
    final p = _prefs;
    if (p == null) return;
    final key = isLeft ? 'gesture_left' : 'gesture_right';
    await p.setString('${key}_action', next.action.name);
    if (next.pkg != null) await p.setString('${key}_app', next.pkg!);
    if (next.label != null) await p.setString('${key}_app_label', next.label!);
  }

  Future<void> setGestureSensitivity(double v) async {
    final next = v
        .clamp(minGestureSensitivity, maxGestureSensitivity)
        .toDouble();
    if (next == _gestureSensitivity) return;
    _gestureSensitivity = next;
    notifyListeners();
    await _prefs?.setDouble('gesture_sensitivity', next);
  }

  Future<void> setFuzzySearch(bool v) async {
    if (v == _fuzzySearch) return;
    _fuzzySearch = v;
    notifyListeners();
    await _prefs?.setBool('fuzzy_search', v);
  }

  Future<void> setSearchPackageNames(bool v) async {
    if (v == _searchPackageNames) return;
    _searchPackageNames = v;
    notifyListeners();
    await _prefs?.setBool('search_package_names', v);
  }

  Future<void> setShowVoiceButton(bool v) async {
    if (v == _showVoiceButton) return;
    _showVoiceButton = v;
    notifyListeners();
    await _prefs?.setBool('show_voice_button', v);
  }

  Future<void> setShowClearButton(bool v) async {
    if (v == _showClearButton) return;
    _showClearButton = v;
    notifyListeners();
    await _prefs?.setBool('show_clear_button', v);
  }

  Future<void> setDrawerSuggestions(bool v) async {
    if (v == _drawerSuggestions) return;
    _drawerSuggestions = v;
    notifyListeners();
    await _prefs?.setBool('drawer_suggestions', v);
  }

  Future<void> setTagBar(bool v) async {
    if (v == _tagBar) return;
    _tagBar = v;
    notifyListeners();
    await _prefs?.setBool('tag_bar', v);
  }

  Future<void> setTagBarPosition(TagBarPosition v) async {
    if (v == _tagBarPosition) return;
    _tagBarPosition = v;
    notifyListeners();
    await _prefs?.setString('tag_bar_position', v.name);
  }

  Future<void> setIconShape(IconShape v) async {
    if (v == _iconShape) return;
    _iconShape = v;
    notifyListeners();
    await _prefs?.setString('icon_shape', v.name);
  }

  Future<void> setHoldAnimation(HoldAnimation v) async {
    if (v == _holdAnimation) return;
    _holdAnimation = v;
    notifyListeners();
    await _prefs?.setString('hold_animation', v.name);
  }

  Future<void> setThemedIcons(bool v) async {
    if (v == _themedIcons) return;
    _themedIcons = v;
    notifyListeners();
    await _prefs?.setBool('themed_icons', v);
  }

  Future<void> setTextScale(double v) async {
    final next = v.clamp(minTextScale, maxTextScale).toDouble();
    if (next == _textScale) return;
    _textScale = next;
    notifyListeners();
    await _prefs?.setDouble('text_scale', next);
  }

  Future<void> setIconScale(double v) async {
    final next = v.clamp(minIconScale, maxIconScale).toDouble();
    if (next == _iconScale) return;
    _iconScale = next;
    notifyListeners();
    await _prefs?.setDouble('icon_scale', next);
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
