import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/theme/launch_r_theme.dart';

const _palette = <Color>[
  Color(0xCCFF5B5B),
  Color(0xCCFF9A3D),
  Color(0xCCFFD23F),
  Color(0xCC4CD27A),
  Color(0xCC2CC4C4),
  Color(0xCC3E91FF),
  Color(0xCC9A6BFF),
  Color(0xCCFF6FB1),
  Color(0xCC4A4A55),
  Color(0xCCFFFFFF),
];

void showFolderColorPicker(BuildContext context, Zone zone, String fid) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FolderColorSheet(zone: zone, fid: fid),
  );
}

const _customAlpha = 0xCC000000;

String _hexOf(int argb) =>
    (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

class _HexFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var t = newValue.text.replaceAll(RegExp('[^0-9a-fA-F]'), '').toUpperCase();
    if (t.length > 6) t = t.substring(0, 6);
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _FolderColorSheet extends StatefulWidget {
  const _FolderColorSheet({required this.zone, required this.fid});
  final Zone zone;
  final String fid;

  @override
  State<_FolderColorSheet> createState() => _FolderColorSheetState();
}

class _FolderColorSheetState extends State<_FolderColorSheet> {
  late final TextEditingController _hex;

  Zone get zone => widget.zone;
  String get fid => widget.fid;

  bool _isPalette(int? c) =>
      c != null && _palette.any((p) => p.toARGB32() == c);

  @override
  void initState() {
    super.initState();
    final current = context.read<LauncherModel>().folderOf(zone, fid)?.color;
    _hex = TextEditingController(
      text: current != null && !_isPalette(current) ? _hexOf(current) : '',
    );
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _applyHex(String text) {
    if (text.length != 6) return;
    final v = int.tryParse(text, radix: 16);
    if (v == null) return;
    context.read<LauncherModel>().recolorFolder(
      zone,
      fid,
      Color(_customAlpha | v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final current = model.folderOf(zone, fid)?.color;
    final customColor = current != null && !_isPalette(current)
        ? Color(current)
        : null;
    final custom = customColor != null;

    Widget swatch({
      required Color? color,
      required String label,
      required bool selected,
    }) {
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: () => model.recolorFolder(zone, fid, color),
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color ?? t.folderBgDrawer,
              border: Border.all(
                color: selected ? LaunchRTheme.accent : t.drawerTextMuted,
                width: selected ? 3 : 1,
              ),
            ),
            child: color == null
                ? Icon(
                    Icons.format_color_reset_rounded,
                    size: 22,
                    color: t.drawerText,
                  )
                : null,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: t.menuBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.drawerTextMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Folder color',
                  style: TextStyle(
                    color: t.drawerText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    swatch(
                      color: null,
                      label: 'Default',
                      selected: current == null,
                    ),
                    for (final c in _palette)
                      swatch(
                        color: c,
                        label: 'Folder color',
                        selected: current == c.toARGB32(),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Custom color',
                  style: TextStyle(
                    color: t.drawerTextMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: customColor ?? t.folderBgDrawer,
                        border: Border.all(
                          color: custom
                              ? LaunchRTheme.accent
                              : t.drawerTextMuted,
                          width: custom ? 3 : 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _hex,
                        inputFormatters: [_HexFormatter()],
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(
                          color: t.drawerText,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                        cursorColor: LaunchRTheme.accent,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: t.searchBg,
                          prefixText: '#',
                          prefixStyle: TextStyle(
                            color: t.drawerTextMuted,
                            fontSize: 16,
                          ),
                          hintText: '3E91FF',
                          hintStyle: TextStyle(color: t.drawerTextMuted),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: _applyHex,
                        onSubmitted: _applyHex,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
