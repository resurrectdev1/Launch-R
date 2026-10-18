/// What a home screen edge swipe can do.
enum GestureAction {
  none('Nothing'),
  openApp('Open an app'),
  recents('Recent apps'),
  settings('Launcher settings'),
  drawer('App drawer'),
  drawerSearch('App drawer search'),
  notifications('Notification panel');

  const GestureAction(this.label);
  final String label;

  static GestureAction fromName(String? name) => GestureAction.values
      .firstWhere((a) => a.name == name, orElse: () => GestureAction.none);
}

enum GestureSide {
  left('Swipe left'),
  right('Swipe right');

  const GestureSide(this.label);
  final String label;
}

class HomeGesture {
  const HomeGesture({this.action = GestureAction.none, this.pkg, this.label});

  final GestureAction action;

  final String? pkg;
  final String? label;

  HomeGesture copyWith({GestureAction? action, String? pkg, String? label}) =>
      HomeGesture(
        action: action ?? this.action,
        pkg: pkg ?? this.pkg,
        label: label ?? this.label,
      );

  String get summary {
    if (action != GestureAction.openApp) return action.label;
    if (pkg == null) return 'Open an app (none chosen)';
    return 'Open ${label ?? pkg}';
  }
}
