import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/services/fuzzy_search.dart';
import 'package:launch_r/services/icon_cache.dart';
import 'package:launch_r/services/launcher_channel.dart';

class _Loc {
  final List<LItem?> list;
  final int index;
  _Loc(this.list, this.index);
  LItem? get item => list[index];
}

class LauncherModel extends ChangeNotifier with WidgetsBindingObserver {
  static const _kDrawer = 'launch_r_drawer';
  static const _kHome = 'launch_r_home';
  static const _kDock = 'launch_r_dock';
  static const _kInit = 'launch_r_init';
  static const _kCols = 'launch_r_cols';
  static const _kRows = 'launch_r_rows';
  static const _kDefaultPage = 'launch_r_default_page';
  static const _kPinnedPages = 'launch_r_pinned_pages';
  static const _kHidden = 'launch_r_hidden';
  static const _kDrawerFree = 'launch_r_drawer_free';
  static const _kTags = 'launch_r_tags';
  static const _kKnown = 'launch_r_known_pkgs';
  static const _kAutoAdd = 'launch_r_auto_add_new';
  static const maxTagLength = 24;
  static const maxTagsPerApp = 12;

  static const maxHomePages = 10;

  SharedPreferences? _prefs;
  final Map<String, LauncherApp> _apps = {};
  final Set<String> _hidden = {};
  final Map<String, Set<String>> _tags = {};
  List<LItem?> _drawer = [];
  List<List<LItem?>> _home = [];
  List<LItem?> _dock = [];
  Map<String, int> _badges = {};
  int _homeCols = 4;
  int _homeRows = 6;
  int _defaultPage = 0;
  int _pinnedPages = 1;
  bool _ready = false;
  bool _drawerFree = true;
  bool _autoAddNew = false;
  final Set<String> _known = {};
  bool notificationAccess = false;

  int iconRevision = 0;

  int get appCount => _apps.length;
  int get hiddenCount => _apps.keys.where(_hidden.contains).length;
  List<LauncherApp> get hiddenApps => [
    for (final a in _apps.values)
      if (_hidden.contains(a.package)) a,
  ]..sort(_byLabel);
  int get homeCols => _homeCols;
  int get homeRows => _homeRows;
  int get defaultPage => _defaultPage;
  bool get ready => _ready;
  bool get canAddHomePage => _home.length < maxHomePages;
  bool get canRemoveHomePage => _home.length > 1;

  bool homePageIsEmpty(int page) =>
      page < 0 || page >= _home.length || _home[page].every((e) => e == null);
  List<LItem> get drawer => _drawer.whereType<LItem>().toList();

  List<LItem?> get drawerSlots => List.unmodifiable(_drawer);

  bool get drawerFree => _drawerFree;
  bool get autoAddNew => _autoAddNew;
  bool get drawerHasGaps => _drawer.contains(null);
  List<List<LItem?>> get home => _home;
  List<LItem?> get dock => _dock;
  bool get isHomeEmpty =>
      _home.every((p) => p.every((e) => e == null)) &&
      _dock.every((e) => e == null);

  String labelOf(LItem it) => switch (it) {
    AppItem(:final pkg) => _apps[pkg]?.label ?? pkg,
    FolderItem(:final name) => name,
    WidgetItem(:final label) => label,
    WidgetCover() => '',
  };

  int badgeOf(LItem it) => switch (it) {
    AppItem(:final pkg) => _badges[pkg] ?? 0,
    FolderItem(:final pkgs) => pkgs.fold<int>(
      0,
      (sum, p) => sum + (_badges[p] ?? 0),
    ),
    WidgetItem() || WidgetCover() => 0,
  };

  FolderItem? folderOf(Zone z, String fid) {
    final loc = _findRoot(z, 'f:$fid');
    final it = loc?.item;
    return it is FolderItem ? it : null;
  }

  String labelForPkg(String pkg) => _apps[pkg]?.label ?? pkg;

  LauncherApp? visibleApp(String pkg) =>
      _hidden.contains(pkg) ? null : _apps[pkg];

  static const hiddenSearchPrefix = '/';

  List<LauncherApp> search(String query, {bool fuzzy = true}) {
    var q = query.trim();
    final includeHidden = q.startsWith(hiddenSearchPrefix);
    if (includeHidden) q = q.substring(hiddenSearchPrefix.length).trim();
    if (q.isEmpty) {
      if (!includeHidden) return const [];
      return [
        for (final a in _apps.values)
          if (_hidden.contains(a.package)) a,
      ]..sort(_byLabel);
    }
    final scored = <(int, LauncherApp)>[];
    for (final a in _apps.values) {
      if (!includeHidden && _hidden.contains(a.package)) continue;
      final s = scoreApp(
        q,
        a.label,
        _tags[a.package] ?? const <String>{},
        fuzzy,
      );
      if (s > 0) scored.add((s, a));
    }
    scored.sort((x, y) {
      final c = y.$1.compareTo(x.$1);
      return c != 0 ? c : _byLabel(x.$2, y.$2);
    });
    return [for (final e in scored) e.$2];
  }

  static String normalizeTag(String raw) {
    final t = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return t.length > maxTagLength ? t.substring(0, maxTagLength).trim() : t;
  }

  List<String> tagsOf(String pkg) =>
      (_tags[pkg]?.toList() ?? <String>[])..sort();

  List<MapEntry<String, int>> get tagCounts {
    final counts = <String, int>{};
    for (final e in _tags.entries) {
      if (!_apps.containsKey(e.key)) continue;
      for (final t in e.value) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts.entries.toList()..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  }

  List<LauncherApp> get selectableApps => [
    for (final a in _apps.values)
      if (!_hidden.contains(a.package)) a,
  ]..sort(_byLabel);

  bool hasTag(String pkg, String tag) => _tags[pkg]?.contains(tag) ?? false;

  bool tagIsFull(String pkg) => (_tags[pkg]?.length ?? 0) >= maxTagsPerApp;

  int appCountForTag(String tag) => [
    for (final e in _tags.entries)
      if (_apps.containsKey(e.key) && e.value.contains(tag)) e.key,
  ].length;

  String? renameTag(String from, String to) {
    final next = normalizeTag(to);
    if (next.isEmpty || next == from) return null;
    for (final set in _tags.values) {
      if (set.remove(from)) set.add(next);
    }
    _tags.removeWhere((_, set) => set.isEmpty);
    _commitTags();
    return next;
  }

  void deleteTag(String tag) {
    var changed = false;
    for (final set in _tags.values) {
      if (set.remove(tag)) changed = true;
    }
    if (!changed) return;
    _tags.removeWhere((_, set) => set.isEmpty);
    _commitTags();
  }

  bool addTag(String pkg, String raw) {
    final tag = normalizeTag(raw);
    if (tag.isEmpty) return false;
    final set = _tags.putIfAbsent(pkg, () => <String>{});
    if (set.length >= maxTagsPerApp || !set.add(tag)) {
      if (set.isEmpty) _tags.remove(pkg);
      return false;
    }
    _commitTags();
    return true;
  }

  void removeTag(String pkg, String tag) {
    final set = _tags[pkg];
    if (set == null || !set.remove(tag)) return;
    if (set.isEmpty) _tags.remove(pkg);
    _commitTags();
  }

  void _commitTags() {
    notifyListeners();
    _schedulePersist();
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();

    final ch = LauncherChannel.instance;
    ch.onPackagesChanged = refreshApps;
    ch.onBadges = (b) {
      _badges = b;
      notifyListeners();
    };
    WidgetsBinding.instance.addObserver(this);

    final list = await ch.getApps();
    _applyApps(list);

    final firstRun = !(_prefs!.getBool(_kInit) ?? false);
    if (firstRun && list.isNotEmpty) {
      final defaults = await ch.getDefaultDock();
      var slot = 0;
      for (final pkg in defaults) {
        if (slot >= _dock.length) break;
        if (_apps.containsKey(pkg)) _dock[slot++] = AppItem(pkg);
      }
      await _prefs!.setBool(_kInit, true);
    }

    _badges = await ch.getBadges();
    notificationAccess = await ch.hasNotificationAccess();
    await _persist();
    _ready = true;
    notifyListeners();
    debugPrint(
      'Launch-R: apps=${_apps.length} drawer=${_drawer.length} '
      'dock=${_dock.whereType<LItem>().length}',
    );
    unawaited(_preloadIcons());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAccessAndBadges());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(flushPersist());
    }
  }

  Future<void> _refreshAccessAndBadges() async {
    final ch = LauncherChannel.instance;
    final access = await ch.hasNotificationAccess();
    final badges = await ch.getBadges();
    notificationAccess = access;
    _badges = badges;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(flushPersist());
    super.dispose();
  }

  Future<void> _preloadIcons() async {
    await Future.wait(_apps.keys.map(IconCache.instance.load));
  }

  Future<void> refreshApps() async {
    final list = await LauncherChannel.instance.getApps();
    if (list.isEmpty) return;
    for (final a in list) {
      IconCache.instance.invalidate(a.package);
    }
    _applyApps(list);
    _commit();
    unawaited(_preloadIcons());
  }

  void applyIconShape(IconShape shape) {
    if (IconCache.instance.shape == shape) return;
    IconCache.instance
      ..shape = shape
      ..clear();
    iconRevision++;
    notifyListeners();
    unawaited(_preloadIcons());
  }

  void applyThemedIcons(ThemedIconStyle? style) {
    if (IconCache.instance.themed == style) return;
    IconCache.instance
      ..themed = style
      ..clear();
    iconRevision++;
    notifyListeners();
    unawaited(_preloadIcons());
  }

  Future<bool> applyIconPack(String? pkg) async {
    final ok = await LauncherChannel.instance.setIconPack(pkg);
    if (ok != true) return false;
    IconCache.instance.clear();
    iconRevision++;
    notifyListeners();
    unawaited(_preloadIcons());
    return true;
  }

  Future<int?> reloadApps() async {
    final ch = LauncherChannel.instance;
    final list = await ch.getApps();
    if (list.isEmpty) return null;
    IconCache.instance.clear();
    iconRevision++;
    _applyApps(list);
    _badges = await ch.getBadges();
    _commit();
    unawaited(_preloadIcons());
    return list.length;
  }

  void _load() {
    final p = _prefs!;
    _homeCols = p.getInt(_kCols) ?? 4;
    _homeRows = p.getInt(_kRows) ?? 6;
    _drawerFree = p.getBool(_kDrawerFree) ?? true;
    _autoAddNew = p.getBool(_kAutoAdd) ?? false;
    _known
      ..clear()
      ..addAll(p.getStringList(_kKnown) ?? const <String>[]);
    _hidden
      ..clear()
      ..addAll(p.getStringList(_kHidden) ?? const <String>[]);

    _tags.clear();
    final rawTags = p.getString(_kTags);
    if (rawTags != null) {
      try {
        final j = jsonDecode(rawTags);
        if (j is Map) {
          for (final e in j.entries) {
            final v = e.value;
            if (e.key is! String || v is! List) continue;
            final set = v.whereType<String>().toSet();
            if (set.isNotEmpty) _tags[e.key as String] = set;
          }
        }
      } catch (_) {}
    }

    _drawer = _decodeList(p.getString(_kDrawer));
    _dock = _decodeList(p.getString(_kDock));
    while (_dock.length < _homeCols) {
      _dock.add(null);
    }
    _dock = _dock.sublist(0, _homeCols);

    _home = [];
    final rawHome = p.getString(_kHome);
    if (rawHome != null) {
      try {
        final j = jsonDecode(rawHome);
        if (j is List) {
          for (final page in j) {
            if (page is List) {
              _home.add(_normalizePage(page.map(LItem.fromJson)));
            }
          }
        }
      } catch (_) {}
    }
    if (_home.isEmpty) _home.add(_blankPage());
    _rebuildWidgets();

    _defaultPage = p.getInt(_kDefaultPage) ?? 0;
    _pinnedPages = p.getInt(_kPinnedPages) ?? 1;
    _clampPages();
  }

  void _clampPages() {
    _pinnedPages = _pinnedPages.clamp(1, _home.length);
    _defaultPage = _defaultPage.clamp(0, _home.length - 1);
  }

  List<LItem?> _decodeList(String? s) {
    if (s == null) return <LItem?>[];
    try {
      final j = jsonDecode(s);
      if (j is List) return j.map(LItem.fromJson).toList();
    } catch (_) {}
    return <LItem?>[];
  }

  List<LItem?> _blankPage() => List<LItem?>.filled(_homeCols * _homeRows, null);

  List<LItem?> _normalizePage(Iterable<LItem?> items) {
    final page = _blankPage();
    var i = 0;
    for (final it in items) {
      if (i >= page.length) break;
      page[i++] = it;
    }
    return page;
  }

  String _enc(List<LItem?> l) => jsonEncode(l.map((e) => e?.toJson()).toList());

  static const _persistDelay = Duration(milliseconds: 300);
  Timer? _persistTimer;
  bool _persistDirty = false;
  Future<void> _persistInFlight = Future<void>.value();

  final Map<String, String> _lastWritten = {};

  void _schedulePersist() {
    _persistDirty = true;
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDelay, () => unawaited(flushPersist()));
  }

  Future<void> flushPersist() {
    _persistTimer?.cancel();
    if (!_persistDirty) return _persistInFlight;
    _persistDirty = false;
    return _persistInFlight = _persistInFlight
        .then((_) => _persist())
        .catchError((Object e, StackTrace s) {
          debugPrint('Launch-R: persist failed: $e\n$s');
        });
  }

  Future<void> _put(
    String key,
    String sig,
    Future<bool> Function() write,
  ) async {
    if (_lastWritten[key] == sig) return;
    if (await write()) _lastWritten[key] = sig;
  }

  Future<void> _persist() async {
    final p = _prefs;
    if (p == null) return;

    final hidden = _hidden.toList();
    final known = _known.toList();
    final tags = jsonEncode({
      for (final e in _tags.entries) e.key: e.value.toList(),
    });
    final drawer = _enc(_drawer);
    final dock = _enc(_dock);
    final home = jsonEncode(
      _home
          .map(
            (pg) => pg.map((e) => e is WidgetCover ? null : e?.toJson()).toList(),
          )
          .toList(),
    );
    final cols = _homeCols;
    final rows = _homeRows;
    final defaultPage = _defaultPage;
    final pinnedPages = _pinnedPages;
    final drawerFree = _drawerFree;
    final autoAdd = _autoAddNew;

    await _put(_kCols, '$cols', () => p.setInt(_kCols, cols));
    await _put(_kRows, '$rows', () => p.setInt(_kRows, rows));
    await _put(
      _kDefaultPage,
      '$defaultPage',
      () => p.setInt(_kDefaultPage, defaultPage),
    );
    await _put(
      _kPinnedPages,
      '$pinnedPages',
      () => p.setInt(_kPinnedPages, pinnedPages),
    );
    await _put(
      _kHidden,
      jsonEncode(hidden),
      () => p.setStringList(_kHidden, hidden),
    );
    await _put(
      _kDrawerFree,
      '$drawerFree',
      () => p.setBool(_kDrawerFree, drawerFree),
    );
    await _put(_kAutoAdd, '$autoAdd', () => p.setBool(_kAutoAdd, autoAdd));
    await _put(
      _kKnown,
      jsonEncode(known),
      () => p.setStringList(_kKnown, known),
    );
    await _put(_kTags, tags, () => p.setString(_kTags, tags));
    await _put(_kDrawer, drawer, () => p.setString(_kDrawer, drawer));
    await _put(_kDock, dock, () => p.setString(_kDock, dock));
    await _put(_kHome, home, () => p.setString(_kHome, home));
  }

  void _commit() {
    _normalizeDrawer();
    notifyListeners();
    _schedulePersist();
  }

  int _byLabel(LauncherApp a, LauncherApp b) =>
      a.label.toLowerCase().compareTo(b.label.toLowerCase());

  void _applyApps(List<LauncherApp> list) {
    _apps
      ..clear()
      ..addEntries(list.map((a) => MapEntry(a.package, a)));
    _reconcile();
    _trackNewApps();
  }

  void _trackNewApps() {
    final installed = _apps.keys.toSet();
    final firstRun = !(_prefs?.getBool(_kInit) ?? false);
    if (_known.isEmpty && firstRun) {
      _known.addAll(installed);
      return;
    }
    final fresh = installed.difference(_known).toList()
      ..sort(
        (a, b) => labelForPkg(
          a,
        ).toLowerCase().compareTo(labelForPkg(b).toLowerCase()),
      );
    _known.addAll(installed);
    if (!_autoAddNew) return;
    for (final pkg in fresh) {
      if (_isVisible(pkg) && !_homeContains(pkg)) {
        _placeInFirstEmpty(AppItem(pkg));
      }
    }
  }

  void setAutoAddNew(bool v) {
    if (v == _autoAddNew) return;
    _autoAddNew = v;
    _known.addAll(_apps.keys);
    _commit();
  }

  bool _isVisible(String pkg) =>
      _apps.containsKey(pkg) && !_hidden.contains(pkg);

  void hideApp(String pkg) {
    if (!_hidden.add(pkg)) return;
    _reconcile();
    _commit();
  }

  void unhideApp(String pkg) {
    if (!_hidden.remove(pkg)) return;
    _reconcile();
    _commit();
  }

  void _reconcile() {
    final seen = <String>{};
    final cleaned = <LItem?>[];
    for (final it in _drawer) {
      switch (it) {
        case AppItem(:final pkg):
          if (_isVisible(pkg) && seen.add(pkg)) {
            cleaned.add(it);
          } else if (_drawerFree) {
            cleaned.add(null);
          }
        case final FolderItem f:
          final pk = f.pkgs.where((p) => _isVisible(p) && seen.add(p)).toList();
          if (pk.length >= 2) {
            cleaned.add(f.copyWith(pkgs: pk));
          } else if (pk.length == 1) {
            cleaned.add(AppItem(pk.first));
          } else if (_drawerFree) {
            cleaned.add(null);
          }
        case null:
          if (_drawerFree) cleaned.add(null);
        case WidgetItem():
        case WidgetCover():
          if (_drawerFree) cleaned.add(null);
      }
    }
    while (cleaned.isNotEmpty && cleaned.last == null) {
      cleaned.removeLast();
    }
    final fresh =
        _apps.values
            .where((a) => _isVisible(a.package) && !seen.contains(a.package))
            .toList()
          ..sort(_byLabel);
    cleaned.addAll(fresh.map((a) => AppItem(a.package)));
    _drawer = cleaned;

    for (var p = 0; p < _home.length; p++) {
      for (var i = 0; i < _home[p].length; i++) {
        _home[p][i] = _cleanSlot(_home[p][i]);
      }
    }
    for (var i = 0; i < _dock.length; i++) {
      _dock[i] = _cleanSlot(_dock[i]);
    }
  }

  LItem? _cleanSlot(LItem? it) {
    switch (it) {
      case null:
        return null;
      case AppItem(:final pkg):
        return _isVisible(pkg) ? it : null;
      case final FolderItem f:
        final pk = f.pkgs.where(_isVisible).toList();
        if (pk.length >= 2) return f.copyWith(pkgs: pk);
        if (pk.length == 1) return AppItem(pk.first);
        return null;
      case WidgetItem():
      case WidgetCover():
        return it;
    }
  }

  Iterable<List<LItem?>> _listsOf(Zone z) =>
      z == Zone.drawer ? [_drawer] : [..._home, _dock];

  _Loc? _findRoot(Zone z, String id) {
    for (final list in _listsOf(z)) {
      final i = list.indexWhere((e) => e?.id == id);
      if (i >= 0) return _Loc(list, i);
    }
    return null;
  }

  LItem? _detach(DragData d) {
    final fid = d.fromFolder;
    if (fid != null) {
      final loc = _findRoot(d.zone, 'f:$fid');
      final f = loc?.item;
      if (loc == null || f is! FolderItem) return null;
      final pkg = (d.item as AppItem).pkg;
      final rest = f.pkgs.where((p) => p != pkg).toList();
      if (rest.length == f.pkgs.length) return null;
      if (rest.length >= 2) {
        loc.list[loc.index] = f.copyWith(pkgs: rest);
      } else if (rest.length == 1) {
        loc.list[loc.index] = AppItem(rest.first);
      } else if (d.zone == Zone.drawer) {
        _vacateDrawerSlot(loc.index);
      } else {
        loc.list[loc.index] = null;
      }
      return AppItem(pkg);
    }
    final loc = _findRoot(d.zone, d.item.id);
    if (loc == null) return null;
    final it = loc.item;
    if (it is WidgetItem) {
      _unstampWidget(loc.list, it.wid);
      return it;
    }
    if (d.zone == Zone.drawer) {
      _vacateDrawerSlot(loc.index);
    } else {
      loc.list[loc.index] = null;
    }
    return it;
  }

  String _newFid() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  void _vacateDrawerSlot(int i) {
    if (_drawerFree) {
      _drawer[i] = null;
    } else {
      _drawer.removeAt(i);
    }
  }

  void _normalizeDrawer() {
    if (_drawerFree) {
      while (_drawer.isNotEmpty && _drawer.last == null) {
        _drawer.removeLast();
      }
    } else {
      _drawer.removeWhere((e) => e == null);
    }
  }

  void _insertShift(int at, LItem it) {
    final i = at.clamp(0, _drawer.length);
    _drawer.insert(i, it);
    if (!_drawerFree) return;
    for (var j = i + 1; j < _drawer.length; j++) {
      if (_drawer[j] == null) {
        _drawer.removeAt(j);
        return;
      }
    }
  }

  void setDrawerFree(bool v) {
    if (v == _drawerFree) return;
    _drawerFree = v;
    _commit();
  }

  void tidyDrawer() {
    if (!_drawer.contains(null)) return;
    _drawer.removeWhere((e) => e == null);
    _commit();
  }

  void drawerInsert(DragData d, String targetId, {required bool after}) {
    if (d.item.id == targetId) return;
    final moved = _detach(d);
    if (moved == null) return;
    final i = _drawer.indexWhere((e) => e?.id == targetId);
    if (i < 0) {
      _normalizeDrawer();
      _drawer.add(moved);
    } else {
      _insertShift(after ? i + 1 : i, moved);
    }
    _commit();
  }

  void drawerAppend(DragData d) {
    final moved = _detach(d);
    if (moved == null) return;
    _normalizeDrawer();
    _drawer.add(moved);
    _commit();
  }

  void drawerPlace(DragData d, int index) {
    final moved = _detach(d);
    if (moved == null) return;
    if (!_drawerFree) {
      _drawer.add(moved);
    } else if (index < _drawer.length && _drawer[index] != null) {
      _insertShift(index, moved);
    } else {
      while (_drawer.length < index) {
        _drawer.add(null);
      }
      if (index < _drawer.length) {
        _drawer[index] = moved;
      } else {
        _drawer.add(moved);
      }
    }
    _commit();
  }

  void drawerMerge(DragData d, String targetId) {
    if (d.item.id == targetId) return;
    if (d.item is! AppItem) {
      drawerInsert(d, targetId, after: true);
      return;
    }
    if (d.fromFolder != null && 'f:${d.fromFolder}' == targetId) return;
    final moved = _detach(d);
    if (moved is! AppItem) return;
    final i = _drawer.indexWhere((e) => e?.id == targetId);
    if (i < 0) {
      _drawer.add(moved);
      _commit();
      return;
    }
    final t = _drawer[i];
    if (t is AppItem) {
      _drawer[i] = FolderItem(
        fid: _newFid(),
        name: 'Folder',
        pkgs: [t.pkg, moved.pkg],
      );
    } else if (t is FolderItem) {
      _drawer[i] = t.copyWith(pkgs: [...t.pkgs, moved.pkg]);
    }
    _commit();
  }

  bool canCopyToHome(LItem item, LItem? target) {
    switch (item) {
      case AppItem(:final pkg):
        return !_homeContains(pkg);
      case FolderItem(:final pkgs):
        return target == null && pkgs.any((p) => !_homeContains(p));
      case WidgetItem():
      case WidgetCover():
        return false;
    }
  }

  DropOutcome _copyDrop(DragData d, Zone z, int page, int index) {
    final list = z == Zone.dock ? _dock : _home[page];
    final src = d.item;
    final t = list[index];
    if (t is WidgetItem || t is WidgetCover) return DropOutcome.rejected;

    if (src is FolderItem) {
      if (t != null) return DropOutcome.rejected;
      final fresh = src.pkgs.where((p) => !_homeContains(p)).toList();
      if (fresh.isEmpty) return DropOutcome.alreadyOnHome;
      list[index] = fresh.length == 1
          ? AppItem(fresh.first)
          : FolderItem(
              fid: _newFid(),
              name: src.name,
              pkgs: fresh,
              color: src.color,
            );
      _commit();
      return DropOutcome.done;
    }

    if (src is! AppItem) return DropOutcome.rejected;
    if (_homeContains(src.pkg)) return DropOutcome.alreadyOnHome;

    if (t == null) {
      list[index] = AppItem(src.pkg);
    } else if (t is AppItem) {
      list[index] = FolderItem(
        fid: _newFid(),
        name: 'Folder',
        pkgs: [t.pkg, src.pkg],
      );
    } else if (t is FolderItem) {
      list[index] = t.copyWith(pkgs: [...t.pkgs, src.pkg]);
    }
    _commit();
    return DropOutcome.done;
  }

  DropOutcome slotDrop(DragData d, Zone z, int page, int index) {
    if (d.item is WidgetItem) return _widgetDrop(d, z, page, index);
    if (d.zone == Zone.drawer) return _copyDrop(d, z, page, index);

    final list = z == Zone.dock ? _dock : _home[page];
    final t = list[index];
    if (t != null && t.id == d.item.id) return DropOutcome.done;
    if (t is WidgetItem || t is WidgetCover) return DropOutcome.rejected;

    if (t == null) {
      final moved = _detach(d);
      if (moved == null) return DropOutcome.done;
      list[index] = moved;
      _commit();
      return DropOutcome.done;
    }

    if (d.item is AppItem) {
      if (d.fromFolder != null && t is FolderItem && t.fid == d.fromFolder) {
        return DropOutcome.done;
      }
      final moved = _detach(d);
      if (moved is! AppItem) return DropOutcome.done;
      final cur = list[index];
      if (cur is AppItem) {
        list[index] = FolderItem(
          fid: _newFid(),
          name: 'Folder',
          pkgs: [cur.pkg, moved.pkg],
        );
      } else if (cur is FolderItem) {
        list[index] = cur.copyWith(pkgs: [...cur.pkgs, moved.pkg]);
      }
      _commit();
      return DropOutcome.done;
    }

    final src = _findRoot(d.zone, d.item.id);
    if (src == null) return DropOutcome.done;
    final tmp = list[index];
    list[index] = src.item;
    src.list[src.index] = tmp;
    _commit();
    return DropOutcome.done;
  }

  bool addHomePage() {
    if (_home.last.any((e) => e != null)) {
      _home.add(_blankPage());
      notifyListeners();
      _schedulePersist();
      return true;
    }
    return false;
  }

  void trimHome() {
    var changed = false;
    final keep = math.max(1, _pinnedPages);
    while (_home.length > keep && _home.last.every((e) => e == null)) {
      _home.removeLast();
      changed = true;
    }
    _clampPages();
    if (changed) _commit();
  }

  int addBlankHomePage() {
    if (!canAddHomePage) return -1;
    _home.add(_blankPage());
    _pinnedPages = _home.length;
    _commit();
    return _home.length - 1;
  }

  bool removeHomePage(int index) {
    if (_home.length <= 1 || index < 0 || index >= _home.length) return false;
    for (final it in _home[index]) {
      if (it is WidgetItem) _releaseWidget(it);
    }
    _home.removeAt(index);
    if (index < _pinnedPages) _pinnedPages--;
    if (index == _defaultPage) {
      _defaultPage = 0;
    } else if (index < _defaultPage) {
      _defaultPage--;
    }
    _clampPages();
    _commit();
    return true;
  }

  void setDefaultPage(int index) {
    if (index < 0 || index >= _home.length || index == _defaultPage) return;
    _defaultPage = index;
    _commit();
  }

  bool _homeContains(String pkg) {
    for (final list in _listsOf(Zone.home)) {
      for (final it in list) {
        if (it is AppItem && it.pkg == pkg) return true;
        if (it is FolderItem && it.pkgs.contains(pkg)) return true;
      }
    }
    return false;
  }

  void _placeInFirstEmpty(LItem it, {int fromPage = 0}) {
    for (var p = fromPage; p < _home.length; p++) {
      final i = _home[p].indexWhere((e) => e == null);
      if (i >= 0) {
        _home[p][i] = it;
        return;
      }
    }
    final page = _blankPage();
    page[0] = it;
    _home.add(page);
  }

  bool addToHome(String pkg) {
    if (_homeContains(pkg)) return false;
    _placeInFirstEmpty(AppItem(pkg));
    _commit();
    return true;
  }

  void removeFromHome(String itemId) {
    final loc = _findRoot(Zone.home, itemId);
    if (loc == null) return;
    final it = loc.item;
    if (it is WidgetItem) {
      _unstampWidget(loc.list, it.wid);
      _releaseWidget(it);
    } else {
      loc.list[loc.index] = null;
    }
    _commit();
  }

  void removeDragged(DragData d) {
    final it = _detach(d);
    if (it == null) return;
    if (it is WidgetItem) _releaseWidget(it);
    _commit();
  }

  void renameFolder(Zone z, String fid, String name) {
    final loc = _findRoot(z, 'f:$fid');
    final f = loc?.item;
    if (loc == null || f is! FolderItem || f.name == name) return;
    loc.list[loc.index] = f.copyWith(name: name);
    _commit();
  }

  void recolorFolder(Zone z, String fid, Color? color) {
    final loc = _findRoot(z, 'f:$fid');
    final f = loc?.item;
    if (loc == null || f is! FolderItem) return;
    final v = color?.toARGB32();
    if (f.color == v) return;
    loc.list[loc.index] = f.copyWith(color: v, clearColor: v == null);
    _commit();
  }

  void reorderInFolder(Zone z, String fid, String pkg, String targetPkg) {
    if (pkg == targetPkg) return;
    final loc = _findRoot(z, 'f:$fid');
    final f = loc?.item;
    if (loc == null || f is! FolderItem) return;
    final from = f.pkgs.indexOf(pkg);
    final to = f.pkgs.indexOf(targetPkg);
    if (from < 0 || to < 0) return;
    final pk = [...f.pkgs]
      ..removeAt(from)
      ..insert(to, pkg);
    loc.list[loc.index] = f.copyWith(pkgs: pk);
    _commit();
  }

  void insertInFolder(
    Zone z,
    String fid,
    String pkg,
    String targetPkg, {
    required bool after,
  }) {
    if (pkg == targetPkg) return;
    final loc = _findRoot(z, 'f:$fid');
    final f = loc?.item;
    if (loc == null || f is! FolderItem) return;
    if (!f.pkgs.contains(pkg) || !f.pkgs.contains(targetPkg)) return;
    final pk = [...f.pkgs]..remove(pkg);
    final at = pk.indexOf(targetPkg);
    pk.insert(after ? at + 1 : at, pkg);
    if (pk.join('|') == f.pkgs.join('|')) return;
    loc.list[loc.index] = f.copyWith(pkgs: pk);
    _commit();
  }

  void moveToEndInFolder(Zone z, String fid, String pkg) {
    final loc = _findRoot(z, 'f:$fid');
    final f = loc?.item;
    if (loc == null || f is! FolderItem) return;
    if (!f.pkgs.contains(pkg) || f.pkgs.last == pkg) return;
    final pk = [...f.pkgs]
      ..remove(pkg)
      ..add(pkg);
    loc.list[loc.index] = f.copyWith(pkgs: pk);
    _commit();
  }

  void dissolveFolder(Zone z, String fid) {
    final loc = _findRoot(z, 'f:$fid');
    final f = loc?.item;
    if (loc == null || f is! FolderItem) return;
    final apps = f.pkgs.map(AppItem.new).toList();
    if (z == Zone.drawer) {
      final at = loc.index;
      _drawer[at] = apps.first;
      for (var k = 1; k < apps.length; k++) {
        _insertShift(at + k, apps[k]);
      }
    } else {
      loc.list[loc.index] = apps.first;
      for (final a in apps.skip(1)) {
        _placeInFirstEmpty(a);
      }
    }
    _commit();
  }

  void setHomeGrid(int cols, int rows) {
    if (cols == _homeCols && rows == _homeRows) return;
    final widgets = <WidgetItem>[
      for (final p in _home) ...p.whereType<WidgetItem>(),
    ];
    final flat = <LItem>[
      for (final p in _home)
        ...p.whereType<LItem>().where(
          (e) => e is! WidgetItem && e is! WidgetCover,
        ),
    ];
    final dockItems = _dock.whereType<LItem>().toList();

    _homeCols = cols;
    _homeRows = rows;

    final newDock = List<LItem?>.filled(cols, null);
    for (var i = 0; i < math.min(cols, dockItems.length); i++) {
      newDock[i] = dockItems[i];
    }
    if (dockItems.length > cols) flat.addAll(dockItems.skip(cols));
    _dock = newDock;

    final per = cols * rows;
    _home = [];
    for (var i = 0; i < flat.length; i += per) {
      _home.add(_normalizePage(flat.skip(i).take(per)));
    }
    if (_home.isEmpty) _home.add(_blankPage());
    for (final w in widgets) {
      _placeWidgetAnywhere(w);
    }
    _clampPages();
    _commit();
  }

  WidgetItem? widgetById(int wid) {
    for (final page in _home) {
      for (final it in page) {
        if (it is WidgetItem && it.wid == wid) return it;
      }
    }
    return null;
  }

  ({int minC, int maxC, int minR, int maxR}) widgetLimits(WidgetItem w) {
    final maxC = w.canH
        ? math.min(w.maxCols > 0 ? w.maxCols : _homeCols, _homeCols)
        : w.cols;
    final maxR = w.canV
        ? math.min(w.maxRows > 0 ? w.maxRows : _homeRows, _homeRows)
        : w.rows;
    final minC = w.canH ? math.min(w.minCols, maxC) : w.cols;
    final minR = w.canV ? math.min(w.minRows, maxR) : w.rows;
    return (
      minC: minC,
      maxC: w.canH ? math.max(maxC, w.cols) : maxC,
      minR: minR,
      maxR: w.canV ? math.max(maxR, w.rows) : maxR,
    );
  }

  bool _areaFree(
    List<LItem?> page,
    int index,
    int spanC,
    int spanR, {
    int? ignoreWid,
  }) {
    final r0 = index ~/ _homeCols;
    final c0 = index % _homeCols;
    if (spanC < 1 || spanR < 1) return false;
    if (c0 + spanC > _homeCols || r0 + spanR > _homeRows) return false;
    for (var r = r0; r < r0 + spanR; r++) {
      for (var c = c0; c < c0 + spanC; c++) {
        final i = r * _homeCols + c;
        if (i >= page.length) return false;
        final it = page[i];
        if (it == null) continue;
        if (ignoreWid != null &&
            ((it is WidgetItem && it.wid == ignoreWid) ||
                (it is WidgetCover && it.owner == ignoreWid))) {
          continue;
        }
        return false;
      }
    }
    return true;
  }

  void _stampWidget(List<LItem?> page, WidgetItem w, int index) {
    final r0 = index ~/ _homeCols;
    final c0 = index % _homeCols;
    final cover = WidgetCover(w.wid);
    for (var r = r0; r < r0 + w.rows; r++) {
      for (var c = c0; c < c0 + w.cols; c++) {
        page[r * _homeCols + c] = (r == r0 && c == c0) ? w : cover;
      }
    }
  }

  void _unstampWidget(List<LItem?> page, int wid) {
    for (var i = 0; i < page.length; i++) {
      final it = page[i];
      if ((it is WidgetItem && it.wid == wid) ||
          (it is WidgetCover && it.owner == wid)) {
        page[i] = null;
      }
    }
  }

  void _releaseWidget(WidgetItem w) {
    unawaited(LauncherChannel.instance.deleteWidget(w.wid));
  }

  bool canPlaceWidget(WidgetItem w, int page, int index) {
    if (page < 0 || page >= _home.length) return false;
    return _areaFree(_home[page], index, w.cols, w.rows, ignoreWid: w.wid);
  }

  bool slotIsWidgetPart(int page, int index) {
    if (page < 0 || page >= _home.length) return false;
    final it = _home[page][index];
    return it is WidgetItem || it is WidgetCover;
  }

  DropOutcome _widgetDrop(DragData d, Zone z, int page, int index) {
    if (z != Zone.home) return DropOutcome.rejected;
    final src = _findRoot(Zone.home, d.item.id);
    final cur = src?.item;
    if (cur is! WidgetItem) return DropOutcome.done;
    if (!_areaFree(
      _home[page],
      index,
      cur.cols,
      cur.rows,
      ignoreWid: cur.wid,
    )) {
      return DropOutcome.noRoom;
    }
    for (final p in _home) {
      _unstampWidget(p, cur.wid);
    }
    _stampWidget(_home[page], cur, index);
    _commit();
    return DropOutcome.done;
  }

  bool canResizeWidget(int wid, int cols, int rows) {
    for (final page in _home) {
      final i = page.indexWhere((e) => e is WidgetItem && e.wid == wid);
      if (i < 0) continue;
      return _areaFree(page, i, cols, rows, ignoreWid: wid);
    }
    return false;
  }

  bool resizeWidget(int wid, int cols, int rows) {
    for (final page in _home) {
      final i = page.indexWhere((e) => e is WidgetItem && e.wid == wid);
      if (i < 0) continue;
      final w = page[i] as WidgetItem;
      final lim = widgetLimits(w);
      final c = cols.clamp(lim.minC, lim.maxC);
      final r = rows.clamp(lim.minR, lim.maxR);
      if (c == w.cols && r == w.rows) return true;
      if (!_areaFree(page, i, c, r, ignoreWid: wid)) return false;
      _unstampWidget(page, wid);
      _stampWidget(page, w.copyWith(cols: c, rows: r), i);
      _commit();
      return true;
    }
    return false;
  }

  ({int index, int cols, int rows})? resolveWidgetResize(
    int wid,
    WidgetEdge edge,
    int delta,
  ) {
    for (final page in _home) {
      final i = page.indexWhere((e) => e is WidgetItem && e.wid == wid);
      if (i < 0) continue;
      final w = page[i] as WidgetItem;
      final lim = widgetLimits(w);
      final c0 = i % _homeCols;
      final r0 = i ~/ _homeCols;
      var d = delta;
      while (d != 0) {
        var c = w.cols;
        var r = w.rows;
        var nc0 = c0;
        var nr0 = r0;
        switch (edge) {
          case WidgetEdge.right:
            c += d;
          case WidgetEdge.left:
            c += d;
            nc0 -= d;
          case WidgetEdge.bottom:
            r += d;
          case WidgetEdge.top:
            r += d;
            nr0 -= d;
        }
        final inRange =
            c >= lim.minC &&
            c <= lim.maxC &&
            r >= lim.minR &&
            r <= lim.maxR &&
            nc0 >= 0 &&
            nr0 >= 0;
        final index = nr0 * _homeCols + nc0;
        if (inRange && _areaFree(page, index, c, r, ignoreWid: wid)) {
          return (index: index, cols: c, rows: r);
        }
        d += d > 0 ? -1 : 1;
      }
      return (index: i, cols: w.cols, rows: w.rows);
    }
    return null;
  }

  bool applyWidgetResize(int wid, int index, int cols, int rows) {
    for (final page in _home) {
      final i = page.indexWhere((e) => e is WidgetItem && e.wid == wid);
      if (i < 0) continue;
      final w = page[i] as WidgetItem;
      if (index == i && cols == w.cols && rows == w.rows) return true;
      if (!_areaFree(page, index, cols, rows, ignoreWid: wid)) return false;
      _unstampWidget(page, wid);
      _stampWidget(page, w.copyWith(cols: cols, rows: rows), index);
      _commit();
      return true;
    }
    return false;
  }

  ({int cols, int rows}) defaultWidgetSpan(
    WidgetProvider p, {
    required double cellDpW,
    required double cellDpH,
  }) {
    int span(num dp, double cell, int max, int target) {
      if (target > 0) return math.min(target, max);
      return math.max(1, math.min(max, (dp / cell).ceil()));
    }

    return (
      cols: span(p.minW, cellDpW, _homeCols, p.targetCellW),
      rows: span(p.minH, cellDpH, _homeRows, p.targetCellH),
    );
  }

  ({int page, int index})? _findSpot(int cols, int rows, int startPage) {
    for (var k = 0; k < _home.length; k++) {
      final p = (startPage + k) % _home.length;
      for (var i = 0; i < _home[p].length; i++) {
        if (_areaFree(_home[p], i, cols, rows)) return (page: p, index: i);
      }
    }
    return null;
  }

  void _placeWidgetAnywhere(WidgetItem w) {
    final c = math.min(w.cols, _homeCols);
    final r = math.min(w.rows, _homeRows);
    final fit = (c == w.cols && r == w.rows) ? w : w.copyWith(cols: c, rows: r);
    var spot = _findSpot(c, r, 0);
    if (spot == null && canAddHomePage) {
      _home.add(_blankPage());
      spot = (page: _home.length - 1, index: 0);
    }
    if (spot == null) {
      _releaseWidget(w);
      return;
    }
    _stampWidget(_home[spot.page], fit, spot.index);
  }

  void _rebuildWidgets() {
    final orphans = <WidgetItem>[];
    for (final page in _home) {
      final anchors = <int, WidgetItem>{};
      for (var i = 0; i < page.length; i++) {
        final it = page[i];
        if (it is WidgetItem) {
          anchors[i] = it;
          page[i] = null;
        } else if (it is WidgetCover) {
          page[i] = null;
        }
      }
      for (final e in anchors.entries) {
        final w = e.value;
        final c = math.min(w.cols, _homeCols);
        final r = math.min(w.rows, _homeRows);
        final fit = (c == w.cols && r == w.rows)
            ? w
            : w.copyWith(cols: c, rows: r);
        if (_areaFree(page, e.key, c, r)) {
          _stampWidget(page, fit, e.key);
        } else {
          orphans.add(fit);
        }
      }
    }
    for (final w in orphans) {
      _placeWidgetAnywhere(w);
    }
  }

  Future<WidgetAddResult> addWidget(
    WidgetProvider p, {
    required int page,
    required double cellDpW,
    required double cellDpH,
  }) async {
    final span = defaultWidgetSpan(p, cellDpW: cellDpW, cellDpH: cellDpH);
    if (_findSpot(span.cols, span.rows, page) == null && !canAddHomePage) {
      return const WidgetAddResult(WidgetAddStatus.noRoom);
    }

    final id = await LauncherChannel.instance.addWidget(p.component);
    if (id == null) return const WidgetAddResult(WidgetAddStatus.cancelled);

    int minSpan(num dpA, num dpB, double cell, int max) {
      final dp = dpA > 0 ? dpA : dpB;
      return math.max(1, math.min(max, (dp / cell).ceil()));
    }

    int maxSpan(num dp, double cell, int max) =>
        dp > 0 ? math.max(1, math.min(max, (dp / cell).floor())) : 0;

    final w = WidgetItem(
      wid: id,
      component: p.component,
      label: p.label,
      cols: span.cols,
      rows: span.rows,
      minCols: math.min(
        span.cols,
        minSpan(p.minResizeW, p.minW, cellDpW, _homeCols),
      ),
      minRows: math.min(
        span.rows,
        minSpan(p.minResizeH, p.minH, cellDpH, _homeRows),
      ),
      maxCols: maxSpan(p.maxResizeW.toDouble(), cellDpW, _homeCols),
      maxRows: maxSpan(p.maxResizeH.toDouble(), cellDpH, _homeRows),
      canH: p.resizeMode & 1 != 0,
      canV: p.resizeMode & 2 != 0,
    );

    var spot = _findSpot(w.cols, w.rows, page);
    if (spot == null && canAddHomePage) {
      _home.add(_blankPage());
      spot = (page: _home.length - 1, index: 0);
    }
    if (spot == null) {
      _releaseWidget(w);
      return const WidgetAddResult(WidgetAddStatus.noRoom);
    }
    _stampWidget(_home[spot.page], w, spot.index);
    _commit();
    return WidgetAddResult(WidgetAddStatus.added, page: spot.page);
  }
}

enum WidgetEdge { left, right, top, bottom }

enum WidgetAddStatus { added, cancelled, noRoom }

class WidgetAddResult {
  const WidgetAddResult(this.status, {this.page = 0});
  final WidgetAddStatus status;
  final int page;
}
