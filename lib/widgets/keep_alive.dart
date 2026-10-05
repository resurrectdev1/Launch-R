import 'package:flutter/widgets.dart';

class PageKeepAlive extends StatefulWidget {
  const PageKeepAlive({super.key, required this.child});
  final Widget child;

  @override
  State<PageKeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<PageKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
