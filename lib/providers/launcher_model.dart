import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_r/models/launcher_models.dart';
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

  static const maxHomePages = 10;

  SharedPreferences? _prefs;
  final Map<String, LauncherApp> _apps = {};
  List<LItem?> _drawer = [];
  List<List<LItem?>> _home = [];
  List<LItem?> _dock = [];
  Map<String, int> _badges = {};
  int _homeCols = 4;
  int _homeRows = 6;
  int _defaultPage = 0;
  int _pinnedPages = 1;
  bool _ready = false;
  bool notificationAccess = false;

  int iconRevision = 0;

  int get appCount => _apps.length;
  int get homeCols => _homeCols;
  int get homeRows => _homeRows;
  int get defaultPage => _defaultPage;
  bool get ready => _ready;
  bool get canAddHomePage => _home.length < maxHomePages;
  bool get canRemoveHomePage => _home.length > 1;

  bool homePageIsEmpty(int page) =>
      page < 0 || page >= _home.length || _home[page].every((e) => e == null);
  List<LItem> get drawer => _drawer.cast<LItem>();
  List<List<LItem?>> get home => _home;
  List<LItem?> get dock => _dock;
  bool get isHomeEmpty =>
      _home.every((p) => p.every((e) => e == null)) &&
      _dock.every((e) => e == null);

  String labelOf(LItem it) => switch (it) {
    AppItem(:final pkg) => _apps[pkg]?.label ?? pkg,
    FolderItem(:final name) => name,
  };

  int badgeOf(LItem it) => switch (it) {
    AppItem(:final pkg) => _badges[pkg] ?? 0,
    FolderItem(:final pkgs) => pkgs.fold<int>(
      0,
      (sum, p) => sum + (_badges[p] ?? 0),
    ),
  };

  FolderItem? folderOf(Zone z, String fid) {
    final loc = _findRoot(z, 'f:$fid');
    final it = loc?.item;
    return it is FolderItem ? it : null;
  }

  String labelForPkg(String pkg) => _apps[pkg]?.label ?? pkg;

  List<LauncherApp> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final starts = <LauncherApp>[];
    final contains = <LauncherApp>[];
    for (final a in _apps.values) {
      final l = a.label.toLowerCase();
      if (l.startsWith(q)) {
        starts.add(a);
      } else if (l.contains(q)) {
        contains.add(a);
      }
    }
    starts.sort(_byLabel);
    contains.sort(_byLabel);
    return [...starts, ...contains];
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
            if (page is List)
              _home.add(_normalizePage(page.map(LItem.fromJson)));
          }
        }
      } catch (_) {}
    }
    if (_home.isEmpty) _home.add(_blankPage());

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

  Future<void> _persist() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt(_kCols, _homeCols);
    await p.setInt(_kRows, _homeRows);
    await p.setInt(_kDefaultPage, _defaultPage);
    await p.setInt(_kPinnedPages, _pinnedPages);
    await p.setString(_kDrawer, _enc(_drawer));
    await p.setString(_kDock, _enc(_dock));
    await p.setString(
      _kHome,
      jsonEncode(
        _home.map((pg) => pg.map((e) => e?.toJson()).toList()).toList(),
      ),
    );
  }

  void _commit() {
    notifyListeners();
    unawaited(_persist());
  }

  int _byLabel(LauncherApp a, LauncherApp b) =>
      a.label.toLowerCase().compareTo(b.label.toLowerCase());

  void _applyApps(List<LauncherApp> list) {
    _apps
      ..clear()
      ..addEntries(list.map((a) => MapEntry(a.package, a)));

    final seen = <String>{};
    final cleaned = <LItem?>[];
    for (final it in _drawer) {
      switch (it) {
        case AppItem(:final pkg):
          if (_apps.containsKey(pkg) && seen.add(pkg)) cleaned.add(it);
        case FolderItem f:
          final pk = f.pkgs
              .where((p) => _apps.containsKey(p) && seen.add(p))
              .toList();
          if (pk.length >= 2) {
            cleaned.add(f.copyWith(pkgs: pk));
          } else if (pk.length == 1) {
            cleaned.add(AppItem(pk.first));
          }
        case null:
          break;
      }
    }
    final fresh = list.where((a) => !seen.contains(a.package)).toList()
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
        return _apps.containsKey(pkg) ? it : null;
      case FolderItem f:
        final pk = f.pkgs.where(_apps.containsKey).toList();
        if (pk.length >= 2) return f.copyWith(pkgs: pk);
        if (pk.length == 1) return AppItem(pk.first);
        return null;
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
        loc.list.removeAt(loc.index);
      } else {
        loc.list[loc.index] = null;
      }
      return AppItem(pkg);
    }
    final loc = _findRoot(d.zone, d.item.id);
    if (loc == null) return null;
    final it = loc.item;
    if (d.zone == Zone.drawer) {
      loc.list.removeAt(loc.index);
    } else {
      loc.list[loc.index] = null;
    }
    return it;
  }

  String _newFid() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  void drawerInsert(DragData d, String targetId, {required bool after}) {
    if (d.item.id == targetId) return;
    final moved = _detach(d);
    if (moved == null) return;
    final i = _drawer.indexWhere((e) => e?.id == targetId);
    if (i < 0) {
      _drawer.add(moved);
    } else {
      _drawer.insert(after ? i + 1 : i, moved);
    }
    _commit();
  }

  void drawerAppend(DragData d) {
    final moved = _detach(d);
    if (moved == null) return;
    _drawer.add(moved);
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
    }
  }

  DropOutcome _copyDrop(DragData d, Zone z, int page, int index) {
    final list = z == Zone.dock ? _dock : _home[page];
    final src = d.item;
    final t = list[index];

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
    if (d.zone == Zone.drawer) return _copyDrop(d, z, page, index);

    final list = z == Zone.dock ? _dock : _home[page];
    final t = list[index];
    if (t != null && t.id == d.item.id) return DropOutcome.done;

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
      unawaited(_persist());
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
    loc.list[loc.index] = null;
    _commit();
  }

  void removeDragged(DragData d) {
    if (_detach(d) != null) _commit();
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

  void reorderInFolder(Zone z, String fid, String pkg, String beforePkg) {
    if (pkg == beforePkg) return;
    final loc = _findRoot(z, 'f:$fid');
    final f = loc?.item;
    if (loc == null || f is! FolderItem) return;
    final pk = [...f.pkgs]..remove(pkg);
    final i = pk.indexOf(beforePkg);
    if (i < 0) return;
    pk.insert(i, pkg);
    loc.list[loc.index] = f.copyWith(pkgs: pk);
    _commit();
  }

  void dissolveFolder(Zone z, String fid) {
    final loc = _findRoot(z, 'f:$fid');
    final f = loc?.item;
    if (loc == null || f is! FolderItem) return;
    final apps = f.pkgs.map(AppItem.new).toList();
    if (z == Zone.drawer) {
      loc.list.removeAt(loc.index);
      loc.list.insertAll(loc.index, apps);
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
    final flat = <LItem>[for (final p in _home) ...p.whereType<LItem>()];
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
    _clampPages();
    _commit();
  }
}
