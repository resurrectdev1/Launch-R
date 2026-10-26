import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Entry {
  _Entry(this.count, this.lastMs);
  int count;
  int lastMs;
}

class LaunchHistory extends ChangeNotifier {
  static const _kLaunches = 'launch_r_launch_history';
  static const _kSearches = 'launch_r_recent_searches';

  static const _halfLife = Duration(days: 5);
  static const maxSearches = 8;
  static const _maxTracked = 300;

  SharedPreferences? _prefs;
  final Map<String, _Entry> _entries = {};
  final List<String> _searches = [];

  List<String> get recentSearches => List.unmodifiable(_searches);

  bool get isEmpty => _entries.isEmpty && _searches.isEmpty;

  Future<void> reload() async {
    await init();
    notifyListeners();
  }

  Future<void> init() async {
    final p = _prefs = await SharedPreferences.getInstance();
    _entries.clear();
    try {
      final raw = p.getString(_kLaunches);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in map.entries) {
          final v = e.value as Map<String, dynamic>;
          _entries[e.key] = _Entry(
            (v['c'] as num).toInt(),
            (v['t'] as num).toInt(),
          );
        }
      }
    } catch (e) {
      debugPrint('Launch-R: launch history unreadable, starting fresh: $e');
      _entries.clear();
    }
    _searches
      ..clear()
      ..addAll(p.getStringList(_kSearches) ?? const <String>[]);
  }

  double _score(_Entry e, int nowMs) {
    final age = math.max(0, nowMs - e.lastMs);
    return e.count * math.pow(0.5, age / _halfLife.inMilliseconds).toDouble();
  }

  void recordLaunch(String pkg) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final e = _entries[pkg];
    if (e == null) {
      _entries[pkg] = _Entry(1, now);
    } else {
      e.count = _score(e, now).round() + 1;
      e.lastMs = now;
    }
    if (_entries.length > _maxTracked) _prune(now);
    _saveLaunches();
  }

  void _prune(int nowMs) {
    final sorted = _entries.entries.toList()
      ..sort(
        (a, b) => _score(a.value, nowMs).compareTo(_score(b.value, nowMs)),
      );
    for (final e in sorted.take(_entries.length - _maxTracked)) {
      _entries.remove(e.key);
    }
  }

  List<String> topPackages(int limit) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final scored = [
      for (final e in _entries.entries) (e.key, _score(e.value, now)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(limit)) s.$1];
  }

  void recordSearch(String query) {
    final q = query.trim();
    if (q.length < 2 || q.startsWith('/')) return;
    _searches.removeWhere((s) => s.toLowerCase() == q.toLowerCase());
    _searches.insert(0, q);
    if (_searches.length > maxSearches) {
      _searches.removeRange(maxSearches, _searches.length);
    }
    notifyListeners();
    _saveSearches();
  }

  void removeSearch(String query) {
    if (!_searches.remove(query)) return;
    notifyListeners();
    _saveSearches();
  }

  void clearSearches() {
    if (_searches.isEmpty) return;
    _searches.clear();
    notifyListeners();
    _saveSearches();
  }

  void clearAll() {
    if (isEmpty) return;
    _entries.clear();
    _searches.clear();
    notifyListeners();
    final p = _prefs;
    if (p != null) {
      unawaited(p.remove(_kLaunches));
      unawaited(p.remove(_kSearches));
    }
  }

  void _saveLaunches() {
    final map = {
      for (final e in _entries.entries)
        e.key: {'c': e.value.count, 't': e.value.lastMs},
    };
    final p = _prefs;
    if (p != null) unawaited(p.setString(_kLaunches, jsonEncode(map)));
  }

  void _saveSearches() {
    final p = _prefs;
    if (p != null) unawaited(p.setStringList(_kSearches, _searches));
  }
}
