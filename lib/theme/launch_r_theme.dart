import 'package:flutter/material.dart';
import 'package:launch_r/models/launcher_models.dart';

enum AppearanceMode {
  orangeFactory('Orange Factory', Brightness.dark),
  amoledBlack('AMOLED Black', Brightness.dark),
  whiteMinimal('White Minimal', Brightness.light);

  const AppearanceMode(this.label, this.brightness);
  final String label;
  final Brightness brightness;

  static AppearanceMode fromName(String? name) =>
      AppearanceMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => AppearanceMode.orangeFactory,
      );
}

class LaunchRTheme extends ThemeExtension<LaunchRTheme> {
  const LaunchRTheme(
    this.brightness, {
    this.amoled = false,
    this.accent = defaultAccent,
    this.dynamicScheme,
  });

  factory LaunchRTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<LaunchRTheme>() ?? LaunchRTheme(theme.brightness);
  }

  factory LaunchRTheme.forMode(
    AppearanceMode mode,
    Color accent, {
    ColorScheme? dynamicScheme,
  }) {
    if (dynamicScheme != null) {
      final amoled = mode == AppearanceMode.amoledBlack;
      return LaunchRTheme(
        amoled ? mode.brightness : dynamicScheme.brightness,
        amoled: amoled,
        accent: dynamicScheme.primary,
        dynamicScheme: amoled ? null : dynamicScheme,
      );
    }
    return LaunchRTheme(
      mode.brightness,
      amoled: mode == AppearanceMode.amoledBlack,
      accent: accent,
    );
  }

  final Brightness brightness;
  final bool amoled;
  final Color accent;
  final ColorScheme? dynamicScheme;

  static const defaultAccent = Color(0xFFF26A27);
  static const badge = Color(0xFFFF5B22);

  bool get dark => brightness == Brightness.dark;

  Color get onAccent => onColor(accent);

  Color get accentText => readableOn(accent, menuBg);

  Color get drawerScrim {
    if (amoled) return const Color(0xFF000000);
    return dark ? const Color(0xD9101014) : const Color(0xE6F3F3F8);
  }

  Color get drawerText => dark ? Colors.white : const Color(0xFF1B1B1F);
  Color get drawerTextMuted =>
      dark ? const Color(0xB3FFFFFF) : const Color(0x991B1B1F);
  Color get searchBg =>
      dark ? const Color(0x26FFFFFF) : const Color(0x14000000);
  bool get _neutralSurface => dynamicScheme == null && (amoled || !dark);

  Color get folderBgDrawer {
    if (amoled) return accent.withValues(alpha: 0.35);
    if (!dark && dynamicScheme == null) return accent.withValues(alpha: 0.22);
    return dark ? const Color(0x59FFFFFF) : const Color(0x1F000000);
  }

  Color get folderPanelBg => _neutralSurface
      ? Color.alphaBlend(accent.withValues(alpha: 0.16), popupBg)
      : popupBg;

  Color get menuBg {
    final d = dynamicScheme;
    if (d != null) return d.surfaceContainerHigh;
    if (amoled) return const Color(0xFF000000);
    return dark ? const Color(0xFF2B2B31) : const Color(0xFFF7F7FB);
  }

  Color get popupBg {
    final d = dynamicScheme;
    if (d != null) return d.surfaceContainerHighest.withValues(alpha: 0.95);
    if (amoled) return const Color(0xFF0D0D0D);
    return dark ? const Color(0xF2303036) : const Color(0xF2F5F5F9);
  }

  Color get dragBarBg =>
      amoled ? const Color(0xEE1A1A1A) : const Color(0xEE1D1D22);

  ThemedIconStyle get themedIconStyle {
    final d = dynamicScheme;
    if (d != null) {
      return ThemedIconStyle(
        bg: d.primaryContainer.toARGB32(),
        fg: d.onPrimaryContainer.toARGB32(),
      );
    }
    final hsl = HSLColor.fromColor(accent);
    final tone = (hsl.saturation * 0.5).clamp(0.0, 0.5).toDouble();
    final bg = hsl
        .withSaturation(tone)
        .withLightness(dark ? (amoled ? 0.14 : 0.2) : 0.88);
    final fg = hsl.withLightness(dark ? 0.82 : 0.26);
    return ThemedIconStyle(
      bg: bg.toColor().toARGB32(),
      fg: fg.toColor().toARGB32(),
    );
  }

  static Color onColor(Color background) => background.computeLuminance() > 0.55
      ? const Color(0xFF1B1B1F)
      : Colors.white;

  static Color readableOn(Color color, Color bg, {double minRatio = 4.5}) {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    final lighten = bg.computeLuminance() < 0.5;
    var hsl = HSLColor.fromColor(color.withValues(alpha: 1));
    for (var i = 0; i < 25 && ratio(hsl.toColor(), bg) < minRatio; i++) {
      final l = hsl.lightness + (lighten ? 0.04 : -0.04);
      hsl = hsl.withLightness(l.clamp(0.0, 1.0));
    }
    return hsl.toColor();
  }

  @override
  LaunchRTheme copyWith({
    Brightness? brightness,
    bool? amoled,
    Color? accent,
    ColorScheme? dynamicScheme,
  }) => LaunchRTheme(
    brightness ?? this.brightness,
    amoled: amoled ?? this.amoled,
    accent: accent ?? this.accent,
    dynamicScheme: dynamicScheme ?? this.dynamicScheme,
  );

  @override
  LaunchRTheme lerp(ThemeExtension<LaunchRTheme>? other, double t) {
    if (other is! LaunchRTheme) return this;
    final to = t < 0.5 ? this : other;
    return LaunchRTheme(
      to.brightness,
      amoled: to.amoled,
      accent: Color.lerp(accent, other.accent, t) ?? other.accent,
      dynamicScheme: to.dynamicScheme,
    );
  }
}

class CellStyle {
  final Color label;
  final List<Shadow> shadows;
  final Color folderBg;
  const CellStyle({
    required this.label,
    required this.shadows,
    required this.folderBg,
  });
}
