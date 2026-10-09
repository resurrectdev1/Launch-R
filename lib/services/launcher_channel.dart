import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:launch_r/models/launcher_models.dart';

class LauncherChannel {
  LauncherChannel._();
  static final instance = LauncherChannel._();

  static const _ch = MethodChannel('com.resurrect.launch_r/launcher');

  VoidCallback? onPackagesChanged;
  VoidCallback? onHome;
  void Function(Map<String, int> badges)? onBadges;

  void init() {
    _ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPackagesChanged':
          onPackagesChanged?.call();
        case 'onHome':
          onHome?.call();
        case 'onBadges':
          onBadges?.call(_toBadges(call.arguments));
      }
      return null;
    });
  }

  Map<String, int> _toBadges(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k as String, (v as num).toInt()));
  }

  Future<T?> _safe<T>(Future<T?> Function() call) async {
    try {
      return await call().timeout(const Duration(seconds: 8));
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('Launch-R channel error: ${e.code} ${e.message}');
      return null;
    } on TimeoutException {
      debugPrint('Launch-R channel call timed out');
      return null;
    }
  }

  Future<List<LauncherApp>> getApps() async {
    final r = await _safe(() => _ch.invokeListMethod<Map>('getApps'));
    return r?.map(LauncherApp.fromMap).toList() ?? [];
  }

  Future<Uint8List?> getIcon(
    String pkg, {
    int size = 192,
    IconShape shape = IconShape.squircle,
  }) => _safe(
    () => _ch.invokeMethod<Uint8List>('getIcon', {
      'package': pkg,
      'size': size,
      'shape': shape.name,
    }),
  );

  Future<List<IconPackInfo>> getIconPacks() async {
    final r = await _safe(() => _ch.invokeListMethod<Map>('getIconPacks'));
    return r?.map(IconPackInfo.fromMap).toList() ?? [];
  }

  Future<bool?> setIconPack(String? pkg) =>
      _safe(() => _ch.invokeMethod<bool>('setIconPack', {'package': pkg}));

  Future<bool> launchApp(String pkg, {Rect? from, double dpr = 1}) async {
    final args = <String, dynamic>{'package': pkg};
    if (from != null) {
      args['left'] = (from.left * dpr).round();
      args['top'] = (from.top * dpr).round();
      args['width'] = (from.width * dpr).round();
      args['height'] = (from.height * dpr).round();
    }
    return await _safe(() => _ch.invokeMethod<bool>('launchApp', args)) ??
        false;
  }

  Future<void> openAppInfo(String pkg) =>
      _safe(() => _ch.invokeMethod<void>('openAppInfo', {'package': pkg}));

  Future<void> uninstallApp(String pkg) =>
      _safe(() => _ch.invokeMethod<void>('uninstallApp', {'package': pkg}));

  Future<List<String>> getDefaultDock() async {
    final r = await _safe(() => _ch.invokeListMethod<String>('getDefaultDock'));
    return r ?? [];
  }

  Future<Map<String, int>> getBadges() async {
    final r = await _safe(() => _ch.invokeMethod<Map>('getBadges'));
    return _toBadges(r);
  }

  Future<bool> hasNotificationAccess() async =>
      await _safe(() => _ch.invokeMethod<bool>('hasNotificationAccess')) ??
      false;

  Future<void> openNotificationAccessSettings() =>
      _safe(() => _ch.invokeMethod<void>('openNotificationAccessSettings'));

  Future<void> openHomeSettings() =>
      _safe(() => _ch.invokeMethod<void>('openHomeSettings'));

  Future<void> openWallpaperPicker() =>
      _safe(() => _ch.invokeMethod<void>('openWallpaperPicker'));

  Future<void> expandNotifications() =>
      _safe(() => _ch.invokeMethod<void>('expandNotifications'));

  static const widgetViewType = 'com.resurrect.launch_r/widget';

  Future<List<WidgetProvider>> getWidgetProviders() async {
    final r = await _safe(
      () => _ch.invokeListMethod<Map>('getWidgetProviders'),
    );
    return r?.map(WidgetProvider.fromMap).toList() ?? [];
  }

  Future<Uint8List?> getWidgetPreview(String component, {int size = 256}) =>
      _safe(
        () => _ch.invokeMethod<Uint8List>('getWidgetPreview', {
          'component': component,
          'size': size,
        }),
      );

  Future<int?> addWidget(String component) async {
    try {
      return await _ch.invokeMethod<int>('addWidget', {'component': component});
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('Launch-R addWidget error: ${e.code} ${e.message}');
      return null;
    }
  }

  Future<void> deleteWidget(int id) =>
      _safe(() => _ch.invokeMethod<void>('deleteWidget', {'id': id}));
}
