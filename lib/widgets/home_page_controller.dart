import 'package:flutter/widgets.dart';

class HomePageController extends PageController {
  HomePageController();

  static const int _loops = 1000;

  int _count = 1;
  int _origin = 0;
  bool _loop = false;

  int get count => _count;
  bool get loop => _loop;

  int get currentVirtual {
    if (!hasClients) return initialPage;
    return (page ?? initialPage.toDouble()).round();
  }

  int logicalOf(int virtual) => _loop ? (virtual - _origin) % _count : virtual;

  int get logicalPage => logicalOf(currentVirtual);

  double logicalFraction(double virtual) {
    if (!_loop) return virtual;
    return (virtual - _origin) % _count;
  }

  int virtualNear(int logical) {
    if (!_loop) return logical;
    final v = currentVirtual;
    var delta = logical - logicalOf(v);
    if (delta * 2 > _count) {
      delta -= _count;
    } else if (delta * 2 < -_count) {
      delta += _count;
    }
    return v + delta;
  }

  Future<void> goToLogical(
    int logical, {
    required Duration duration,
    required Curve curve,
  }) {
    if (!hasClients) return Future<void>.value();
    return animateToPage(
      virtualNear(logical),
      duration: duration,
      curve: curve,
    );
  }

  void jumpToLogical(int logical) {
    if (!hasClients) return;
    jumpToPage(virtualNear(logical));
  }

  void configure({required int count, required bool loop}) {
    final n = count < 1 ? 1 : count;
    if (loop != _loop) {
      _loop = loop;
      _origin = 0;
    }
    if (n != _count) {
      if (_loop && hasClients) {
        final v = currentVirtual;
        final l = logicalOf(v);
        final kept = l > n - 1 ? n - 1 : l;
        _origin = v - kept;
      }
      _count = n;
    }
  }

  void recenter() {
    if (!hasClients || !_loop) return;
    final l = logicalPage;
    _origin = 0;
    jumpToPage(l + _count * _loops);
  }

  void settleToLogical() {
    if (!hasClients) return;
    jumpToPage(logicalPage);
  }
}
