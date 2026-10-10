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

  Uint8List? peek(String pkg) => _bytes[pkg];

  Future<Uint8List?> load(String pkg) {
    final hit = _bytes[pkg];
    if (hit != null) return Future.value(hit);
    return _pending.putIfAbsent(pkg, () async {
      final gen = _gen;
      final b = await LauncherChannel.instance.getIcon(
        pkg,
        shape: shape,
        themed: themed,
      );
      if (gen != _gen) {
        return load(pkg);
      }
      unawaited(_pending.remove(pkg));
      if (b != null) {
        _bytes[pkg] = b;
      } else {
        debugPrint('Launch-R: icon failed for $pkg');
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
  }
}
