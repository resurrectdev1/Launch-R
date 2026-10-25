import 'package:launch_r/models/launcher_models.dart';

enum PageIndicatorStyle {
  dots('Dots'),
  line('Line'),
  hidden('Hidden');

  const PageIndicatorStyle(this.label);
  final String label;

  static PageIndicatorStyle fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return PageIndicatorStyle.dots;
  }
}

class GridLimits {
  const GridLimits._();

  static const int minHomeCols = 3;
  static const int maxHomeCols = 6;
  static const int minHomeRows = 4;
  static const int maxHomeRows = 8;
  static const int minDrawerCols = 3;
  static const int maxDrawerCols = 6;
}

class GridPlan {
  const GridPlan({
    required this.cols,
    required this.rows,
    required this.pages,
    required this.dock,
    required this.movedIds,
    required this.resizedWidgets,
    required this.lostWidgets,
  });

  final int cols;
  final int rows;
  final List<List<LItem?>> pages;
  final List<LItem?> dock;

  final Set<String> movedIds;

  final int resizedWidgets;

  final List<WidgetItem> lostWidgets;
}
