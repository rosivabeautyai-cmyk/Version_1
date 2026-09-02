import 'package:flutter/material.dart';

import 'package:rosivia/core/styles/app_dimens.dart';

/// The heart toggle used on product cards and the details screen.
///
/// * Cross-fades ♡ → ♥ with a small scale (no layout shift).
/// * Gives a single gentle "pop" the moment it becomes a favorite —
///   the tiny reward premium apps have. Un-favoriting is silent.
/// * Respects the OS "reduce motion" setting.
/// * The [AnimationController] is disposed properly.
class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onTap;
  final double size;
  final Color color;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    required this.size,
    required this.color,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: AppDuration.short,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: _pop, curve: AppCurve.standard));

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didUpdateWidget(FavoriteButton old) {
    super.didUpdateWidget(old);
    if (widget.isFavorite && !old.isFavorite && !_reduceMotion) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      widget.isFavorite
          ? Icons.favorite_rounded
          : Icons.favorite_border_rounded,
      key: ValueKey(widget.isFavorite),
      size: widget.size,
      color: widget.color,
    );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedSwitcher(
          duration: AppDuration.micro,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: icon,
        ),
      ),
    );
  }
}
