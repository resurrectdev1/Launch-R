enum Zone { home, dock, drawer }

enum DropOutcome { done, alreadyOnHome, rejected, noRoom }

enum IconShape {
  squircle('Squircle'),
  circle('Circle'),
  rounded('Rounded'),
  teardrop('Teardrop'),
  square('Square');

  const IconShape(this.label);
  final String label;

  static IconShape fromName(String? name) => IconShape.values.firstWhere(
    (s) => s.name == name,
    orElse: () => IconShape.squircle,
  );
}

class LauncherApp {
  final String package;
  final String label;
  const LauncherApp({required this.package, required this.label});

  factory LauncherApp.fromMap(Map<dynamic, dynamic> m) =>
      LauncherApp(package: m['package'] as String, label: m['label'] as String);
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
