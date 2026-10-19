import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/services/launcher_channel.dart';

class IconCache {
  IconCache._();
  static final instance = IconCache._();

  final Map<String, Uint8List> _bytes = {};
  final Map<String, Future<Uint8List?>> _pending = {};

  IconShape shape = IconShape.squircle;
  ThemedIconStyle? themed;

  int _gen = 0;

  int get count => _bytes.length;

  static const _scPrefix = '\u0001';
  static String _scKey(String pkg, String id) => '$_scPrefix$pkg/$id';

  Uint8List? peek(String pkg, {String? shortcutId}) =>
      _bytes[shortcutId == null ? pkg : _scKey(pkg, shortcutId)];

  Future<Uint8List?> load(String pkg, {String? shortcutId}) {
    final key = shortcutId == null ? pkg : _scKey(pkg, shortcutId);
    final hit = _bytes[key];
    if (hit != null) return Future.value(hit);
    return _pending.putIfAbsent(key, () async {
      final gen = _gen;
      final b = shortcutId == null
          ? await LauncherChannel.instance.getIcon(
              pkg,
              shape: shape,
              themed: themed,
            )
          : await LauncherChannel.instance.getShortcutIcon(
              pkg,
              shortcutId,
              shape: shape,
            );
      if (gen != _gen) {
        return load(pkg, shortcutId: shortcutId);
      }
      unawaited(_pending.remove(key));
      if (b != null) {
        _bytes[key] = b;
      } else {
        debugPrint('Launch-R: icon failed for $key');
      }
      return b;
    });
  }

  void clear() {
    _gen++;
    _bytes.clear();
    _pending.clear();
  }

  void invalidate(String pkg) {
    _bytes.remove(pkg);
    _pending.remove(pkg);
    final prefix = '$_scPrefix$pkg/';
    _bytes.removeWhere((k, _) => k.startsWith(prefix));
    _pending.removeWhere((k, _) => k.startsWith(prefix));
  }
}
