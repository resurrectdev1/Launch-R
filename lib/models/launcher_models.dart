import 'dart:typed_data';

enum Zone { home, dock, drawer }

enum DropOutcome { done, alreadyOnHome, rejected, noRoom }

enum IconShape {
  squircle('Squircle'),
  circle('Circle'),
  hexagon('Hexagon'),
  teardrop('Teardrop'),
  square('Square');

  const IconShape(this.label);
  final String label;

  static IconShape fromName(String? name) => IconShape.values.firstWhere(
    (s) => s.name == name,
    orElse: () => IconShape.squircle,
  );
}

enum HoldAnimation {
  sway('Sway'),
  wiggle('Wiggle'),
  pulse('Pulse'),
  bounce('Bounce'),
  tilt('Tilt');

  const HoldAnimation(this.label);
  final String label;

  static HoldAnimation fromName(String? name) => HoldAnimation.values
      .firstWhere((a) => a.name == name, orElse: () => HoldAnimation.sway);
}

class ThemedIconStyle {
  const ThemedIconStyle({required this.bg, required this.fg});
  final int bg;
  final int fg;

  @override
  bool operator ==(Object other) =>
      other is ThemedIconStyle && other.bg == bg && other.fg == fg;

  @override
  int get hashCode => Object.hash(bg, fg);
}

class LauncherApp {
  final String package;
  final String label;
  const LauncherApp({required this.package, required this.label});

  factory LauncherApp.fromMap(Map<dynamic, dynamic> m) =>
      LauncherApp(package: m['package'] as String, label: m['label'] as String);
}

class AppShortcut {
  final String id;
  final String label;
  final Uint8List? icon;
  const AppShortcut({required this.id, required this.label, this.icon});

  factory AppShortcut.fromMap(Map<dynamic, dynamic> m) => AppShortcut(
    id: m['id'] as String,
    label: m['label'] as String,
    icon: m['icon'] as Uint8List?,
  );
}

class IconPackInfo {
  final String package;
  final String label;
  const IconPackInfo({required this.package, required this.label});

  factory IconPackInfo.fromMap(Map<dynamic, dynamic> m) => IconPackInfo(
    package: m['package'] as String,
    label: m['label'] as String,
  );
}

class PickedFont {
  final String path;
  final String label;
  const PickedFont({required this.path, required this.label});
}

sealed class LItem {
  const LItem();
  String get id;
  Map<String, dynamic> toJson();

  static LItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    switch (raw['t']) {
      case 'a':
        final p = raw['p'];
        return p is String ? AppItem(p) : null;
      case 'w':
        final w = raw['w'];
        final cp = raw['cp'];
        if (w is int && cp is String) {
          int n(String k, int d) => raw[k] is int ? raw[k] as int : d;
          return WidgetItem(
            wid: w,
            component: cp,
            label: raw['n'] is String ? raw['n'] as String : 'Widget',
            cols: n('c', 2).clamp(1, 12),
            rows: n('r', 2).clamp(1, 12),
            minCols: n('mc', 1),
            minRows: n('mr', 1),
            maxCols: n('xc', 0),
            maxRows: n('xr', 0),
            canH: raw['h'] != false,
            canV: raw['v'] != false,
          );
        }
      case 's':
        final sid = raw['id'];
        final p = raw['p'];
        final k = raw['k'];
        if (sid is String && p is String && k is String) {
          return ShortcutItem(
            sid: sid,
            pkg: p,
            shortcutId: k,
            label: raw['n'] is String ? raw['n'] as String : 'Shortcut',
          );
        }
      case 'f':
        final id = raw['id'];
        final n = raw['n'];
        final p = raw['p'];
        final c = raw['c'];
        if (id is String && p is List) {
          return FolderItem(
            fid: id,
            name: n is String ? n : 'Folder',
            pkgs: p.whereType<String>().toList(),
            color: c is int ? c : null,
          );
        }
    }
    return null;
  }
}

class AppItem extends LItem {
  final String pkg;
  const AppItem(this.pkg);

  @override
  String get id => 'a:$pkg';

  @override
  Map<String, dynamic> toJson() => {'t': 'a', 'p': pkg};
}

class ShortcutItem extends LItem {
  final String sid;
  final String pkg;
  final String shortcutId;
  final String label;
  const ShortcutItem({
    required this.sid,
    required this.pkg,
    required this.shortcutId,
    required this.label,
  });

  @override
  String get id => 's:$sid';

  @override
  Map<String, dynamic> toJson() => {
    't': 's',
    'id': sid,
    'p': pkg,
    'k': shortcutId,
    'n': label,
  };
}

class PinRequest {
  final String package;
  final String id;
  final String label;
  const PinRequest({
    required this.package,
    required this.id,
    required this.label,
  });

  factory PinRequest.fromMap(Map<dynamic, dynamic> m) => PinRequest(
    package: m['package'] as String,
    id: m['id'] as String,
    label: (m['label'] as String?) ?? '',
  );
}

class FolderItem extends LItem {
  final String fid;
  final String name;
  final List<String> pkgs;

  final int? color;
  const FolderItem({
    required this.fid,
    required this.name,
    required this.pkgs,
    this.color,
  });

  @override
  String get id => 'f:$fid';

  FolderItem copyWith({
    String? name,
    List<String>? pkgs,
    int? color,
    bool clearColor = false,
  }) => FolderItem(
    fid: fid,
    name: name ?? this.name,
    pkgs: pkgs ?? this.pkgs,
    color: clearColor ? null : (color ?? this.color),
  );

  @override
  Map<String, dynamic> toJson() => {
    't': 'f',
    'id': fid,
    'n': name,
    'p': pkgs,
    if (color != null) 'c': color,
  };
}

class WidgetProvider {
  final String component;
  final String package;
  final String label;
  final String appLabel;
  final int minW;
  final int minH;
  final int minResizeW;
  final int minResizeH;
  final int maxResizeW;
  final int maxResizeH;
  final int resizeMode;
  final int targetCellW;
  final int targetCellH;

  const WidgetProvider({
    required this.component,
    required this.package,
    required this.label,
    required this.appLabel,
    required this.minW,
    required this.minH,
    this.minResizeW = 0,
    this.minResizeH = 0,
    this.maxResizeW = 0,
    this.maxResizeH = 0,
    this.resizeMode = 3,
    this.targetCellW = 0,
    this.targetCellH = 0,
  });

  factory WidgetProvider.fromMap(Map<dynamic, dynamic> m) {
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    return WidgetProvider(
      component: m['component'] as String,
      package: m['package'] as String,
      label: m['label'] as String,
      appLabel: (m['appLabel'] as String?) ?? (m['package'] as String),
      minW: n('minW'),
      minH: n('minH'),
      minResizeW: n('minResizeW'),
      minResizeH: n('minResizeH'),
      maxResizeW: n('maxResizeW'),
      maxResizeH: n('maxResizeH'),
      resizeMode: m['resizeMode'] == null ? 3 : n('resizeMode'),
      targetCellW: n('targetCellW'),
      targetCellH: n('targetCellH'),
    );
  }
}

class WidgetItem extends LItem {
  final int wid;
  final String component;
  final String label;
  final int cols;
  final int rows;
  final int minCols;
  final int minRows;
  final int maxCols;
  final int maxRows;
  final bool canH;
  final bool canV;

  const WidgetItem({
    required this.wid,
    required this.component,
    required this.label,
    required this.cols,
    required this.rows,
    this.minCols = 1,
    this.minRows = 1,
    this.maxCols = 0,
    this.maxRows = 0,
    this.canH = true,
    this.canV = true,
  });

  @override
  String get id => 'w:$wid';

  bool get resizable => canH || canV;

  WidgetItem copyWith({int? cols, int? rows}) => WidgetItem(
    wid: wid,
    component: component,
    label: label,
    cols: cols ?? this.cols,
    rows: rows ?? this.rows,
    minCols: minCols,
    minRows: minRows,
    maxCols: maxCols,
    maxRows: maxRows,
    canH: canH,
    canV: canV,
  );

  @override
  Map<String, dynamic> toJson() => {
    't': 'w',
    'w': wid,
    'cp': component,
    'n': label,
    'c': cols,
    'r': rows,
    'mc': minCols,
    'mr': minRows,
    'xc': maxCols,
    'xr': maxRows,
    'h': canH,
    'v': canV,
  };
}

class WidgetCover extends LItem {
  final int owner;
  const WidgetCover(this.owner);

  @override
  String get id => 'wc:$owner';

  @override
  Map<String, dynamic> toJson() => {'t': 'wc', 'o': owner};
}

class DragData {
  final LItem item;
  final Zone zone;

  final String? fromFolder;

  const DragData({required this.item, required this.zone, this.fromFolder});
}
