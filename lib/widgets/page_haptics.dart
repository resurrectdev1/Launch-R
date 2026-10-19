import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PageHaptics extends StatefulWidget {
  const PageHaptics({super.key, required this.child});

  final Widget child;

  @override
  State<PageHaptics> createState() => _PageHapticsState();
}

class _PageHapticsState extends State<PageHaptics> {
  bool _byUser = false;
  int? _last;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final m = n.metrics;
    if (m is! PageMetrics) return false;

    if (n is ScrollStartNotification) {
      _byUser = n.dragDetails != null;
      _last = m.page?.round();
    } else if (n is ScrollUpdateNotification && _byUser) {
      final p = m.page?.round();
      if (p != null && p != _last) {
        _last = p;
        unawaited(HapticFeedback.selectionClick());
      }
    } else if (n is ScrollEndNotification) {
      _byUser = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
  }
}
