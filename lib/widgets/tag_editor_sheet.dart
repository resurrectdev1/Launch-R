import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/launch_r_sheet.dart';
import 'package:launch_r/widgets/app_icon.dart';

void showTagEditor(BuildContext context, String pkg) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TagEditorSheet(pkg: pkg),
  );
}

class _TagEditorSheet extends StatefulWidget {
  const _TagEditorSheet({required this.pkg});

  final String pkg;

  @override
  State<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<_TagEditorSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(LauncherModel model) {
    for (final part in _controller.text.split(',')) {
      model.addTag(widget.pkg, part);
    }
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final mine = model.tagsOf(widget.pkg);
    final suggestions = [
      for (final e in model.tagCounts)
        if (!mine.contains(e.key)) e.key,
    ].take(10).toList();
    final full = mine.length >= LauncherModel.maxTagsPerApp;

    return AnimatedPadding(
      duration: Motion.fast,
      curve: Motion.standard,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        decoration: BoxDecoration(
          color: t.menuBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SheetScrollView(
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
                Row(
                  children: [
                    AppIconImage(pkg: widget.pkg, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.labelForPkg(widget.pkg),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.drawerText,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Search any tag to find this app',
                            style: TextStyle(
                              color: t.drawerTextMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (mine.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final tag in mine)
                        InputChip(
                          label: Text(tag),
                          labelStyle: TextStyle(color: t.drawerText),
                          backgroundColor: t.searchBg,
                          side: BorderSide.none,
                          deleteIconColor: t.drawerTextMuted,
                          onDeleted: () => model.removeTag(widget.pkg, tag),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  height: 48,
                  padding: const EdgeInsets.only(left: 18, right: 4),
                  decoration: BoxDecoration(
                    color: t.searchBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          enabled: !full,
                          maxLength: LauncherModel.maxTagLength * 4,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(model),
                          cursorColor: t.accent,
                          style: TextStyle(color: t.drawerText, fontSize: 16),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            counterText: '',
                            border: InputBorder.none,
                            hintText: full
                                ? 'Tag limit reached'
                                : 'Add a tag (e.g. work, social)',
                            hintStyle: TextStyle(
                              color: t.drawerTextMuted,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_rounded, color: t.accentText),
                        onPressed: full ? null : () => _submit(model),
                      ),
                    ],
                  ),
                ),
                if (suggestions.isNotEmpty && !full) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Your tags',
                    style: TextStyle(
                      color: t.drawerTextMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final tag in suggestions)
                        ActionChip(
                          label: Text(tag),
                          labelStyle: TextStyle(color: t.accentText),
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: t.accentText.withValues(alpha: 0.5),
                          ),
                          onPressed: () => model.addTag(widget.pkg, tag),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
