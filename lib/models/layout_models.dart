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
