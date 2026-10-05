enum Zone { home, dock, drawer }

enum DropOutcome { done, alreadyOnHome, rejected }

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

class DragData {
  final LItem item;
  final Zone zone;

  final String? fromFolder;

  const DragData({required this.item, required this.zone, this.fromFolder});
}
