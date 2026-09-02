import 'package:flutter/material.dart';

import 'package:rosivia/core/styles/app_dimens.dart';

/// Drives a shimmer sheen for every [AppSkeletonBox] beneath it from a
/// **single** repeating [AnimationController] — so a whole loading
/// grid animates from one ticker, not one per box.
///
/// ```dart
/// AppShimmer(child: GridView(... AppSkeletonBox(...) ...))
/// ```
///
/// If a skeleton box has no [AppShimmer] ancestor it just renders a
/// flat placeholder (no animation, no cost).
class AppShimmer extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AppShimmer({super.key, required this.child, this.enabled = true});

  /// The shared sweep animation (0→1, repeating) provided by the
  /// nearest [AppShimmer], or `null` if there isn't one / motion is
  /// reduced.
  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDuration.shimmer,
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(AppShimmer old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return _ShimmerScope(
      animation: (widget.enabled && !reduceMotion) ? _controller : null,
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  final Animation<double>? animation;

  const _ShimmerScope({required this.animation, required super.child});

  @override
  bool updateShouldNotify(_ShimmerScope old) => animation != old.animation;
}
