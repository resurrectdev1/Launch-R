import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/icon_cache.dart';
import 'package:launch_r/theme/icon_shapes.dart';
import 'package:launch_r/theme/launch_r_theme.dart';

class AppIconImage extends StatefulWidget {
  const AppIconImage({super.key, required this.pkg, required this.size});
  final String pkg;
  final double size;

  @override
  State<AppIconImage> createState() => _AppIconImageState();
}

class _AppIconImageState extends State<AppIconImage> {
  Uint8List? _bytes;
  int? _rev;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(AppIconImage old) {
    super.didUpdateWidget(old);
    if (old.pkg != widget.pkg) _resolve();
  }

  void _resolve() {
    final pkg = widget.pkg;
    _bytes = IconCache.instance.peek(pkg);
    if (_bytes == null) _fetch();
  }

  void _fetch() {
    final pkg = widget.pkg;
    IconCache.instance.load(pkg).then((b) {
      if (mounted && b != null && widget.pkg == pkg) {
        setState(() => _bytes = b);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rev = context.select<LauncherModel, int>((m) => m.iconRevision);
    if (_rev != null && _rev != rev) {
      final cached = IconCache.instance.peek(widget.pkg);
      if (cached != null) {
        _bytes = cached;
      } else {
        _fetch();
      }
    }
    _rev = rev;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _bytes == null
          ? null
          : Image.memory(
              _bytes!,
              width: widget.size,
              height: widget.size,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
    );
  }
}

class FolderGlyph extends StatelessWidget {
  const FolderGlyph({
    super.key,
    required this.pkgs,
    required this.size,
    required this.bg,
  });

  final List<String> pkgs;
  final double size;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final shape = context.select<LauncherSettings, IconShape>(
      (s) => s.iconShape,
    );
    final fit = shape == IconShape.circle || shape == IconShape.teardrop
        ? 0.82
        : 1.0;
    final shown = pkgs.take(9).toList();
    final n = shown.length;

    final int cols;
    final double miniFrac;
    final double gapFrac;
    if (n <= 1) {
      cols = 1;
      miniFrac = 0.52;
      gapFrac = 0;
    } else if (n <= 4) {
      cols = 2;
      miniFrac = 0.37;
      gapFrac = 0.07;
    } else {
      cols = 3;
      miniFrac = 0.235;
      gapFrac = 0.045;
    }
    final mini = size * miniFrac * fit;
    final gap = size * gapFrac * fit;

    final rows = <List<String>>[
      for (var i = 0; i < n; i += cols)
        shown.sublist(i, i + cols > n ? n : i + cols),
    ];

    final grid = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++)
          Padding(
            padding: EdgeInsets.only(top: r > 0 ? gap : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var c = 0; c < rows[r].length; c++)
                  Padding(
                    padding: EdgeInsets.only(left: c > 0 ? gap : 0),
                    child: AppIconImage(pkg: rows[r][c], size: mini),
                  ),
              ],
            ),
          ),
      ],
    );

    if (shape == IconShape.squircle) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: bg,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(size * 0.62),
          ),
        ),
        child: grid,
      );
    }
    return ClipPath(
      clipper: IconShapeClipper(shape),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: bg,
        child: grid,
      ),
    );
  }
}

class BadgeDot extends StatelessWidget {
  const BadgeDot({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: LaunchRTheme.badge,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class ItemVisual extends StatelessWidget {
  const ItemVisual({
    super.key,
    required this.item,
    required this.label,
    required this.iconSize,
    required this.width,
    required this.style,
    this.badge = 0,
    this.showLabel = true,
  });

  final LItem item;
  final String label;
  final double iconSize;
  final double width;
  final CellStyle style;
  final int badge;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (item) {
      AppItem(:final pkg) => AppIconImage(pkg: pkg, size: iconSize),
      FolderItem(:final pkgs, :final color) => FolderGlyph(
        pkgs: pkgs,
        size: iconSize,
        bg: color != null ? Color(color) : style.folderBg,
      ),
      WidgetItem() ||
      WidgetCover() => SizedBox(width: iconSize, height: iconSize),
    };
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              glyph,
              if (badge > 0)
                Positioned(top: -6, right: -8, child: BadgeDot(count: badge)),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: style.label,
                  fontSize: 12,
                  height: 1.1,
                  shadows: style.shadows,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
