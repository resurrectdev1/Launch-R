import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/launch_r_sheet.dart';

const _presets = <Color>[
  LaunchRTheme.defaultAccent,
  Color(0xFFFF5B5B),
  Color(0xFFFFB020),
  Color(0xFFFFD23F),
  Color(0xFF4CD27A),
  Color(0xFF2CC4C4),
  Color(0xFF42A5F5),
  Color(0xFF3E91FF),
  Color(0xFF9A6BFF),
  Color(0xFFFF6FB1),
  Color(0xFFC77B93),
  Color(0xFF9AA4AD),
];

String hexOfColor(Color c) =>
    (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

Future<bool> showAccentPicker(BuildContext context) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AccentSheet(),
  );
  return changed ?? false;
}

class _AccentSheet extends StatefulWidget {
  const _AccentSheet();

  @override
  State<_AccentSheet> createState() => _AccentSheetState();
}

class _AccentSheetState extends State<_AccentSheet> {
  late final TextEditingController _hex;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = context.read<LauncherSettings>().accent;
    _hex = TextEditingController(text: hexOfColor(_color));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  bool get _complete => _hex.text.length == 6;
  bool get _showError => !_complete && _hex.text.isNotEmpty;

  static final _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  );

  void _pick(Color c) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _color = c;
      _hex.text = hexOfColor(c);
    });
  }

  void _onHex(String text) {
    final v = text.length == 6 ? int.tryParse(text, radix: 16) : null;
    setState(() {
      if (v != null) _color = Color(0xFF000000 | v);
    });
  }

  Future<void> _apply() async {
    final settings = context.read<LauncherSettings>();
    unawaited(HapticFeedback.lightImpact());
    final navigator = Navigator.of(context);
    await settings.setCustomAccent(
      _color == LaunchRTheme.defaultAccent ? null : _color,
    );
    navigator.pop(true);
  }

  Future<void> _reset() async {
    final settings = context.read<LauncherSettings>();
    final navigator = Navigator.of(context);
    unawaited(HapticFeedback.lightImpact());
    await settings.setCustomAccent(null);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final hasCustom = context.watch<LauncherSettings>().customAccent != null;
    final onColor = LaunchRTheme.onColor(_color);

    return LaunchRSheet(
      title: 'Accent color',
      size: SheetSize.tall,
      scrollable: true,
      keyboardAware: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Used for highlights, drop targets and switches',
            style: TextStyle(color: t.drawerTextMuted, fontSize: 14),
          ),
          const SizedBox(height: 22),
          Text(
            'Preset colors',
            style: TextStyle(
              color: t.drawerTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final c in _presets)
                _Swatch(
                  color: c,
                  selected: c == _color,
                  ring: t.drawerText,
                  onTap: () => _pick(c),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Custom hex code',
            style: TextStyle(
              color: t.drawerTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _hex,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                    LengthLimitingTextInputFormatter(6),
                    TextInputFormatter.withFunction(
                      (old, v) => v.copyWith(text: v.text.toUpperCase()),
                    ),
                  ],
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    color: t.drawerText,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                  cursorColor: _color,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: t.searchBg,
                    labelText: 'Hex code',
                    labelStyle: TextStyle(color: t.drawerTextMuted),
                    floatingLabelStyle: TextStyle(color: _color),
                    prefixIcon: Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: t.drawerTextMuted,
                    ),
                    prefixText: '#',
                    prefixStyle: TextStyle(
                      color: t.drawerTextMuted,
                      fontSize: 16,
                    ),
                    hintText: 'F26A27',
                    hintStyle: TextStyle(color: t.drawerTextMuted),
                    errorText: _showError ? 'Invalid hex' : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: _fieldBorder,
                    enabledBorder: _fieldBorder,
                    focusedBorder: _fieldBorder,
                    errorBorder: _fieldBorder,
                    focusedErrorBorder: _fieldBorder,
                  ),
                  onChanged: _onHex,
                  onSubmitted: _onHex,
                ),
              ),
              const SizedBox(width: 14),
              AnimatedContainer(
                duration: Motion.fast,
                curve: Motion.standard,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _color,
                  border: Border.all(
                    color: t.drawerTextMuted.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _complete ? _apply : null,
            style: FilledButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: onColor,
              disabledBackgroundColor: t.searchBg,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Apply accent',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (hasCustom)
            Center(
              child: TextButton(
                onPressed: _reset,
                child: Text(
                  'Reset to orange',
                  style: TextStyle(color: t.drawerTextMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.ring,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final Color ring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '#${hexOfColor(color)}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.standard,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected ? ring : Colors.transparent,
              width: 3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ]
                : const [],
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: LaunchRTheme.onColor(color),
                )
              : null,
        ),
      ),
    );
  }
}
