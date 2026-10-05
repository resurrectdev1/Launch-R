import 'dart:async';
import 'package:flutter/material.dart';
import 'package:launch_r/models/launcher_models.dart';

class EdgeFlipper extends StatelessWidget {
  const EdgeFlipper({super.key, required this.onPrev, required this.onNext});
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Strip(onTick: onPrev),
        const Spacer(),
        _Strip(onTick: onNext),
      ],
    );
  }
}

class _Strip extends StatefulWidget {
  const _Strip({required this.onTick});
  final VoidCallback onTick;

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  Timer? _timer;

  void _start() {
    if (_timer != null) return;
    _timer = Timer(const Duration(milliseconds: 550), () {
      widget.onTick();
      _timer = Timer.periodic(
        const Duration(milliseconds: 950),
        (_) => widget.onTick(),
      );
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      child: DragTarget<DragData>(
        onWillAcceptWithDetails: (_) {
          _start();
          return true;
        },
        onLeave: (_) => _stop(),
        onAcceptWithDetails: (_) => _stop(),
        builder: (context, candidate, rejected) => const SizedBox.expand(),
      ),
    );
  }
}
