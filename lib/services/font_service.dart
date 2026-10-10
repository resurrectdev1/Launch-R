import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FontService {
  FontService._();

  static String familyFor(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    return 'LaunchRCustom_${dot > 0 ? name.substring(0, dot) : name}';
  }

  static bool _looksLikeFont(Uint8List b) {
    if (b.length < 12) return false;
    final tag = String.fromCharCodes(b.sublist(0, 4));
    return tag == 'OTTO' ||
        tag == 'true' ||
        (b[0] == 0 && b[1] == 1 && b[2] == 0 && b[3] == 0);
  }

  static Future<String?> load(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (!_looksLikeFont(bytes)) return null;
      final family = familyFor(path);
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      return family;
    } catch (e) {
      debugPrint('Launch-R: font load failed: $e');
      return null;
    }
  }

  static Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('Launch-R: font delete failed: $e');
    }
  }
}
