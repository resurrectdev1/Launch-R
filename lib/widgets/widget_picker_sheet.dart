import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/widgets/launch_r_sheet.dart';
import 'package:launch_r/widgets/home_page_controller.dart';
import 'package:launch_r/models/launcher_models.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/services/launcher_channel.dart';
import 'package:launch_r/theme/launch_r_theme.dart';
import 'package:launch_r/theme/motion.dart';

void showWidgetPicker(
  BuildContext context, {
  required int page,
  required HomePageController homePages,
}) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.routeStyle,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickerSheet(page: page, homePages: homePages),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.page, required this.homePages});
  final int page;
  final HomePageController homePages;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  List<WidgetProvider>? _providers;
  String _query = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final list = await LauncherChannel.instance.getWidgetProviders();
    list.sort((a, b) {
      final c = a.appLabel.toLowerCase().compareTo(b.appLabel.toLowerCase());
      return c != 0
          ? c
          : a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    if (mounted) setState(() => _providers = list);
  }

  ({double w, double h}) _cellDp(LauncherModel model) {
    final mq = MediaQuery.of(context);
    final w = (mq.size.width - 12) / model.homeCols;
    final reserved =
        mq.padding.top + 10 + 26 + 84 + math.max(mq.viewPadding.bottom, 10) + 4;
    final h = (mq.size.height - reserved) / model.homeRows;
    return (w: w, h: math.max(h, 1));
  }

  Future<void> _add(WidgetProvider p) async {
    if (_busy) return;
    final model = context.read<LauncherModel>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);
    final cell = _cellDp(model);

    setState(() => _busy = true);
    final r = await model.addWidget(
      p,
      page: widget.page,
      cellDpW: cell.w,
      cellDpH: cell.h,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (r.status) {
      case WidgetAddStatus.cancelled:
        return;
      case WidgetAddStatus.noRoom:
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('No room on Home for this widget'),
            duration: Duration(seconds: 2),
          ),
        );
      case WidgetAddStatus.added:
        nav.pop();
        final c = widget.homePages;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (c.hasClients) {
            unawaited(
              c.goToLogical(
                r.page,
                duration: Motion.scale(const Duration(milliseconds: 300)),
                curve: Curves.easeOutCubic,
              ),
            );
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    final model = context.watch<LauncherModel>();
    final cell = _cellDp(model);
    final mq = MediaQuery.of(context);

    final all = _providers;
    final q = _query.trim().toLowerCase();
    final shown = all == null
        ? const <WidgetProvider>[]
        : [
            for (final p in all)
              if (q.isEmpty ||
                  p.label.toLowerCase().contains(q) ||
                  p.appLabel.toLowerCase().contains(q))
                p,
          ];

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: mq.size.height * 0.78,
        decoration: BoxDecoration(
          color: t.menuBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.drawerTextMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                child: Text(
                  'Widgets',
                  style: TextStyle(
                    color: t.drawerText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: t.drawerText),
                  decoration: InputDecoration(
                    hintText: 'Search widgets',
                    hintStyle: TextStyle(color: t.drawerTextMuted),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: t.drawerTextMuted,
                    ),
                    filled: true,
                    fillColor: t.searchBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: all == null
                    ? const Center(child: CircularProgressIndicator())
                    : shown.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            all.isEmpty
                                ? 'No widgets are available on this device.'
                                : 'No widgets match your search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: t.drawerTextMuted),
                          ),
                        ),
                      )
                    : SheetScrollbar(
                        builder: (controller) => ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: shown.length,
                          itemBuilder: (context, i) {
                            final p = shown[i];
                            final newApp =
                                i == 0 || shown[i - 1].appLabel != p.appLabel;
                            final span = model.defaultWidgetSpan(
                              p,
                              cellDpW: cell.w,
                              cellDpH: cell.h,
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (newApp)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      16,
                                      24,
                                      4,
                                    ),
                                    child: Text(
                                      p.appLabel,
                                      style: TextStyle(
                                        color: t.accentText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ListTile(
                                  enabled: !_busy,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  leading: _Preview(component: p.component),
                                  title: Text(
                                    p.label,
                                    style: TextStyle(color: t.drawerText),
                                  ),
                                  subtitle: Text(
                                    '${span.cols} × ${span.rows}',
                                    style: TextStyle(color: t.drawerTextMuted),
                                  ),
                                  onTap: () => unawaited(_add(p)),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatefulWidget {
  const _Preview({required this.component});
  final String component;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  late final Future<Uint8List?> _bytes = LauncherChannel.instance
      .getWidgetPreview(widget.component);

  @override
  Widget build(BuildContext context) {
    final t = LaunchRTheme.of(context);
    return SizedBox(
      width: 72,
      height: 56,
      child: FutureBuilder<Uint8List?>(
        future: _bytes,
        builder: (context, snap) {
          final data = snap.data;
          return Container(
            decoration: BoxDecoration(
              color: t.searchBg,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: data == null
                ? Icon(Icons.widgets_outlined, color: t.drawerTextMuted)
                : Image.memory(
                    data,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
          );
        },
      ),
    );
  }
}
