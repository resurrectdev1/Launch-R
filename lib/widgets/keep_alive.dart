import 'package:flutter/widgets.dart';

class PageKeepAlive extends StatefulWidget {
  const PageKeepAlive({super.key, required this.child, this.keep = true});
  final Widget child;
  final bool keep;

  @override
  State<PageKeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<PageKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keep;

  @override
  void didUpdateWidget(PageKeepAlive old) {
    super.didUpdateWidget(old);
    if (old.keep != widget.keep) updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
