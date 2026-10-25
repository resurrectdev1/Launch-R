import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/services/fuzzy_search.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';
import 'package:launch_r/widgets/app_icon.dart';

void showTagManager(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TagManagerSheet(),
  );
}

class _TagManagerSheet extends StatefulWidget {
  const _TagManagerSheet();

  @override
  State<_TagManagerSheet> createState() => _TagManagerSheetState();
}

class _TagManagerSheetState extends State<_TagManagerSheet> {
  String? _openTag;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.85;
    final detail = _openTag != null;

    return AnimatedPadding(
      duration: Motion.fast,
      curve: Motion.standard,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxH,
          minHeight: detail ? maxH : 0,
        ),
        decoration: BoxDecoration(
          color: t.menuBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: detail
              ? _TagDetail(
                  key: ValueKey(_openTag),
                  tag: _openTag!,
                  onBack: () => setState(() => _openTag = null),
                  onRenamed: (name) => setState(() => _openTag = name),
                )
              : _TagList(onOpen: (tag) => setState(() => _openTag = tag)),
        ),
      ),
    );
  }
}

Widget _grabber(LaunchRTheme t) => Center(
  child: Container(
    margin: const EdgeInsets.only(top: 10),
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: t.drawerTextMuted,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

class _TagList extends StatelessWidget {
  const _TagList({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final tags = model.tagCounts;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grabber(t),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tags',
                  style: TextStyle(
                    color: t.drawerText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: t.accentText),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New tag'),
                onPressed: () async {
                  final name = await showDialog<String>(
                    context: context,
                    animationStyle: Motion.routeStyle,
                    builder: (_) => _NameDialog(
                      title: 'New tag',
                      confirm: 'Create',
                      theme: t,
                    ),
                  );
                  if (!context.mounted) return;
                  final tag = LauncherModel.normalizeTag(name ?? '');
                  if (tag.isNotEmpty) onOpen(tag);
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 2, 24, 8),
          child: Text(
            'Search a tag in the app drawer to find every app that has it.',
            style: TextStyle(color: t.drawerTextMuted, fontSize: 13),
          ),
        ),
        if (tags.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Text(
              'No tags yet. Tap New tag, or long-press an app and choose Tags.',
              style: TextStyle(color: t.drawerTextMuted, fontSize: 15),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: tags.length,
              itemBuilder: (context, i) {
                final e = tags[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.sell_outlined, color: t.drawerText),
                  title: Text(e.key, style: TextStyle(color: t.drawerText)),
                  subtitle: Text(
                    e.value == 1 ? '1 app' : '${e.value} apps',
                    style: TextStyle(color: t.drawerTextMuted),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: t.drawerTextMuted,
                  ),
                  onTap: () => onOpen(e.key),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TagDetail extends StatefulWidget {
  const _TagDetail({
    super.key,
    required this.tag,
    required this.onBack,
    required this.onRenamed,
  });

  final String tag;
  final VoidCallback onBack;
  final ValueChanged<String> onRenamed;

  @override
  State<_TagDetail> createState() => _TagDetailState();
}

class _TagDetailState extends State<_TagDetail> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _rename(LauncherModel model, LaunchRTheme t) async {
    final name = await showDialog<String>(
      context: context,
      animationStyle: Motion.routeStyle,
      builder: (_) => _NameDialog(
        title: 'Rename tag',
        confirm: 'Rename',
        initial: widget.tag,
        theme: t,
      ),
    );
    if (name == null || !mounted) return;
    final renamed = model.appCountForTag(widget.tag) == 0
        ? LauncherModel.normalizeTag(name)
        : model.renameTag(widget.tag, name);
    if (renamed != null && renamed.isNotEmpty) widget.onRenamed(renamed);
  }

  Future<void> _delete(LauncherModel model, LaunchRTheme t) async {
    final count = model.appCountForTag(widget.tag);
    final ok = await showDialog<bool>(
      context: context,
      animationStyle: Motion.routeStyle,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.menuBg,
        title: Text('Delete tag?', style: TextStyle(color: t.drawerText)),
        content: Text(
          'Removes "${widget.tag}" from $count '
          '${count == 1 ? 'app' : 'apps'}.',
          style: TextStyle(color: t.drawerTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: t.drawerTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: t.accentText)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    model.deleteTag(widget.tag);
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final count = model.appCountForTag(widget.tag);
    final q = normalizeSearch(_filter.text);
    final apps = [
      for (final a in model.selectableApps)
        if (q.isEmpty || normalizeSearch(a.label).contains(q)) a,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grabber(t),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: t.drawerText),
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.drawerText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      count == 0
                          ? 'Select apps to create this tag'
                          : (count == 1 ? '1 app' : '$count apps'),
                      style: TextStyle(color: t.drawerTextMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Rename',
                icon: Icon(Icons.edit_outlined, color: t.drawerText),
                onPressed: () => _rename(model, t),
              ),
              if (count > 0)
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline_rounded, color: t.drawerText),
                  onPressed: () => _delete(model, t),
                ),
            ],
          ),
        ),
        Container(
          height: 44,
          margin: const EdgeInsets.fromLTRB(24, 8, 24, 6),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: t.searchBg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _filter,
                  onChanged: (_) => setState(() {}),
                  cursorColor: t.accent,
                  style: TextStyle(color: t.drawerText, fontSize: 16),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Filter apps',
                    hintStyle: TextStyle(
                      color: t.drawerTextMuted,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (_filter.text.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(_filter.clear),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: t.drawerTextMuted,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: apps.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Text(
                    'No apps found',
                    style: TextStyle(color: t.drawerTextMuted, fontSize: 15),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: apps.length,
                  itemBuilder: (context, i) {
                    final app = apps[i];
                    final has = model.hasTag(app.package, widget.tag);
                    final blocked = !has && model.tagIsFull(app.package);
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      activeColor: t.accent,
                      checkColor: t.onAccent,
                      controlAffinity: ListTileControlAffinity.trailing,
                      secondary: AppIconImage(pkg: app.package, size: 40),
                      title: Text(
                        app.label,
                        style: TextStyle(color: t.drawerText),
                      ),
                      subtitle: blocked
                          ? Text(
                              'Tag limit reached',
                              style: TextStyle(
                                color: t.drawerTextMuted,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      value: has,
                      onChanged: blocked
                          ? null
                          : (v) {
                              if (v == true) {
                                model.addTag(app.package, widget.tag);
                              } else {
                                model.removeTag(app.package, widget.tag);
                              }
                            },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.confirm,
    required this.theme,
    this.initial = '',
  });

  final String title;
  final String confirm;
  final String initial;
  final LaunchRTheme theme;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return AlertDialog(
      backgroundColor: t.menuBg,
      title: Text(widget.title, style: TextStyle(color: t.drawerText)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: LauncherModel.maxTagLength,
        cursorColor: t.accent,
        style: TextStyle(color: t.drawerText),
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.pop(context, v),
        decoration: InputDecoration(
          hintText: 'Tag name',
          hintStyle: TextStyle(color: t.drawerTextMuted),
          counterStyle: TextStyle(color: t.drawerTextMuted),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: t.drawerTextMuted),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: t.accent),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: t.drawerTextMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirm, style: TextStyle(color: t.accentText)),
        ),
      ],
    );
  }
}
