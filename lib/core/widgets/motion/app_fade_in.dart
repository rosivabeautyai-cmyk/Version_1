import 'dart:async';

import 'package:flutter/material.dart';

import 'package:rosivia/core/styles/app_dimens.dart';

/// A subtle entrance animation: the child fades in while rising a few
/// pixels. Use it for screen content that should "settle" on open
/// rather than pop in.
///
/// * No bounce, ~240ms, `fastOutSlowIn` — quick and calm.
/// * [delay] lets a list of these run as a gentle stagger — use
///   [AppFadeIn.stagger] to build one.
/// * Respects the OS "reduce motion" setting (renders the child
///   immediately).
/// * The single [AnimationController] is disposed properly; the delay
///   timer is cancelled on dispose.
class AppFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const AppFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDuration.short,
    this.offsetY = 10,
  });

  /// Wraps each of [children] in an [AppFadeIn] with an increasing
  /// [delay] so a column/list settles top-to-bottom.
  static List<Widget> stagger(
    List<Widget> children, {
    Duration initialDelay = Duration.zero,
    Duration step = const Duration(milliseconds: 55),
    Duration duration = AppDuration.short,
    double offsetY = 12,
  }) {
    return [
      for (var i = 0; i < children.length; i++)
        AppFadeIn(
          key: ValueKey('fade_$i'),
          delay: initialDelay + step * i,
          duration: duration,
          offsetY: offsetY,
          child: children[i],
        ),
    ];
  }

  @override
  State<AppFadeIn> createState() => _AppFadeInState();
}

class _AppFadeInState extends State<AppFadeIn>
    with SingleTickerProviderStateMixin {
  // Constructed eagerly in initState. With a delayed start, initState
  // would otherwise never touch a lazily-initialized controller, and a
  // dispose before the delay elapsed (or under "reduce motion") would
  // build it on a deactivated element.
  late final AnimationController _controller;
  late final Animation<double> _t;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _t = CurvedAnimation(parent: _controller, curve: AppCurve.enter);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose(); // also tears down the CurvedAnimation _t
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return widget.child;

    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        return Opacity(
          opacity: _t.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - _t.value) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
