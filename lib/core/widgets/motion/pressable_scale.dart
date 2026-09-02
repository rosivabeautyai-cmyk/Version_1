import 'package:flutter/material.dart';

import 'package:rosivia/core/styles/app_dimens.dart';

/// Wraps a tappable widget so it dips slightly while pressed and
/// springs back — the tactile feedback premium apps have on buttons
/// and cards. No bounce, ~180ms.
///
/// The press state is tracked with a [Listener] (raw pointer events),
/// so the dip still shows even when the child consumes the gesture
/// itself (an `ElevatedButton`, an `InkWell`). Pass [onTap] only if the
/// wrapper itself should also be the tap target (e.g. around a plain
/// `Column`); it is ignored while [enabled] is false.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final VoidCallback? onTap;
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final active = widget.enabled && !reduceMotion;

    Widget result = Listener(
      onPointerDown: active ? (_) => _set(true) : null,
      onPointerUp: active ? (_) => _set(false) : null,
      onPointerCancel: active ? (_) => _set(false) : null,
      child: AnimatedScale(
        scale: (_down && active) ? widget.pressedScale : 1.0,
        duration: AppDuration.button,
        curve: AppCurve.standard,
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: result,
      );
    }

    return result;
  }
}
