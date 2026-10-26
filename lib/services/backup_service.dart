import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/launch_history.dart';
import 'package:launch_r/theme/app_fonts.dart';

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LauncherBackup {
  const LauncherBackup({
    required this.appVersion,
    required this.created,
    required this.prefs,
  });

  final String? appVersion;
  final DateTime? created;
  final Map<String, Object> prefs;
}

class BackupService {
  BackupService._();

  static const _magic = 'launch_r';
  static const _format = 1;
  static const maxBytes = 2 * 1024 * 1024;
  static const _maxStringLength = 1024 * 1024;

  static const _homeKey = 'launch_r_home';
  static const _slotListKeys = {'launch_r_drawer', 'launch_r_dock'};
  static const _fontIdKey = 'font_id';

  static const _deviceKeys = {
    'custom_font_path',
    'custom_font_label',
    'background_path',
  };

  static final _keyPattern = RegExp(r'^[A-Za-z0-9_.\-]{1,80}$');

  static String suggestedFileName([DateTime? now]) {
    final d = now ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'launch-r-backup-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  static Future<String> create({required LauncherModel model}) async {
    await model.flushPersist();
    final p = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    final out = <String, Object>{};
    final keys = p.getKeys().toList()..sort();
    for (final key in keys) {
      if (_deviceKeys.contains(key)) continue;
      final value = p.get(key);
      if (value == null) continue;
      if (key == _fontIdKey && value == AppFont.customId) continue;
      if (value is String) {
        out[key] = _portable(key, value);
      } else if (value is bool || value is int || value is double) {
        out[key] = value;
      } else if (value is List) {
        out[key] = value.whereType<String>().toList();
      }
    }
    return jsonEncode({
      'app': _magic,
      'format': _format,
      'version': '${info.version}+${info.buildNumber}',
      'created': DateTime.now().toUtc().toIso8601String(),
      'prefs': out,
    });
  }

  static LauncherBackup parse(String raw) {
    const notABackup = BackupException('That isn’t a Launch-R backup file.');
    if (raw.length > maxBytes) throw notABackup;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      throw notABackup;
    }
    if (json is! Map || json['app'] != _magic) throw notABackup;

    final format = json['format'];
    if (format is! int || format < 1) throw notABackup;
    if (format > _format) {
      throw const BackupException(
        'This backup was made by a newer version of Launch-R. '
        'Update the app and try again.',
      );
    }

    final rawPrefs = json['prefs'];
    if (rawPrefs is! Map) throw notABackup;

    final prefs = <String, Object>{};
    for (final e in rawPrefs.entries) {
      final key = e.key;
      final value = e.value;
      if (key is! String || !_keyPattern.hasMatch(key)) continue;
      if (_deviceKeys.contains(key)) continue;
      if (value is bool || value is int) {
        prefs[key] = value as Object;
      } else if (value is double) {
        if (value.isFinite) prefs[key] = value;
      } else if (value is String) {
        if (value.length <= _maxStringLength) prefs[key] = value;
      } else if (value is List && value.every((v) => v is String)) {
        prefs[key] = value.cast<String>().toList();
      }
    }
    if (prefs.isEmpty) {
      throw const BackupException('That backup doesn’t contain any settings.');
    }

    final created = json['created'];
    final version = json['version'];
    return LauncherBackup(
      appVersion: version is String ? version : null,
      created: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      prefs: prefs,
    );
  }

  static Future<void> restore(
    LauncherBackup backup, {
    required LauncherSettings settings,
    required LauncherModel model,
    required LaunchHistory history,
  }) async {
    final p = await SharedPreferences.getInstance();
    await model.flushPersist();
    final snapshot = _snapshot(p);
    try {
      await _write(p, backup.prefs, snapshot);
      await _reload(settings, model, history);
    } catch (e, s) {
      debugPrint('Launch-R: restore failed, rolling back: $e\n$s');
      try {
        await _rollback(p, snapshot);
        await _reload(settings, model, history);
      } catch (e2, s2) {
        debugPrint('Launch-R: rollback failed: $e2\n$s2');
      }
      throw const BackupException(
        'Couldn’t restore that backup. Your settings were left as they were.',
      );
    }
  }

  static Future<void> _reload(
    LauncherSettings settings,
    LauncherModel model,
    LaunchHistory history,
  ) async {
    await settings.reload();
    await history.reload();
    await model.reloadFromPrefs();
    model.applyIconShape(settings.iconShape);
    final pack = settings.iconPack;
    final ok = await model.applyIconPack(pack);
    if (!ok && pack != null) await settings.setIconPack(null, null);
  }

  static Map<String, Object> _snapshot(SharedPreferences p) => {
    for (final key in p.getKeys())
      if (p.get(key) case final Object v)
        key: v is List ? v.whereType<String>().toList() : v,
  };

  static Future<void> _write(
    SharedPreferences p,
    Map<String, Object> values,
    Map<String, Object> current,
  ) async {
    final keep = {..._deviceKeys};
    if (!values.containsKey(_fontIdKey) &&
        current[_fontIdKey] == AppFont.customId) {
      keep.add(_fontIdKey);
    }
    for (final key in current.keys) {
      if (!keep.contains(key)) await p.remove(key);
    }
    for (final e in values.entries) {
      await _set(p, e.key, e.value);
    }
  }

  static Future<void> _rollback(
    SharedPreferences p,
    Map<String, Object> snapshot,
  ) async {
    for (final key in p.getKeys().toList()) {
      await p.remove(key);
    }
    for (final e in snapshot.entries) {
      await _set(p, e.key, e.value);
    }
  }

  static Future<void> _set(SharedPreferences p, String key, Object v) async {
    final bool ok;
    if (v is bool) {
      ok = await p.setBool(key, v);
    } else if (v is int) {
      ok = await p.setInt(key, v);
    } else if (v is double) {
      ok = await p.setDouble(key, v);
    } else if (v is String) {
      ok = await p.setString(key, v);
    } else if (v is List<String>) {
      ok = await p.setStringList(key, v);
    } else {
      return;
    }
    if (!ok) throw StateError('Could not write $key');
  }

  static String _portable(String key, String raw) {
    if (key == _homeKey) return _stripHome(raw);
    if (_slotListKeys.contains(key)) return _stripSlots(raw);
    return raw;
  }

  static bool _isDeviceBound(Object? slot) =>
      slot is Map &&
      (slot['t'] == 'w' || slot['t'] == 's' || slot['t'] == 'wc');

  static List<Object?> _cleanSlots(List<Object?> slots) => [
    for (final s in slots) _isDeviceBound(s) ? null : s,
  ];

  static String _stripSlots(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is List) return jsonEncode(_cleanSlots(j.cast<Object?>()));
    } catch (_) {}
    return raw;
  }

  static String _stripHome(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is List) {
        return jsonEncode([
          for (final page in j)
            if (page is List) _cleanSlots(page.cast<Object?>()) else page,
        ]);
      }
    } catch (_) {}
    return raw;
  }
}
