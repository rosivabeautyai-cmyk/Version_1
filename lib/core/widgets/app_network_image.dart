import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Wraps [Image.network] with a consistent loading skeleton and a
/// graceful fallback icon on failure, so product/profile imagery
/// coming from the future catalog API never shows a broken-image icon.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.spa_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(16.r);

    if (url == null || url!.isEmpty) {
      return ClipRRect(borderRadius: radius, child: _placeholder(theme));
    }

    // Decode at (roughly) the size the image is actually displayed at
    // rather than its full native resolution — product photos coming
    // from the Awin feed are often much larger than the ~150-180px
    // thumbnail they render at here, and decoding dozens of them at
    // full size while scrolling a grid is a classic cause of dropped
    // frames. When this widget isn't given explicit width/height (the
    // common case — product cards size it via AspectRatio/Expanded
    // instead), LayoutBuilder reads the actual constraints so the
    // cache size still matches real render size.
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final targetWidth = width ?? _finiteOrNull(constraints.maxWidth);
        final targetHeight = height ?? _finiteOrNull(constraints.maxHeight);

        return ClipRRect(
          borderRadius: radius,
          child: Image.network(
            url!,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: targetWidth == null ? null : (targetWidth * dpr).round(),
            cacheHeight: targetHeight == null ? null : (targetHeight * dpr).round(),
            loadingBuilder: (context, widget, progress) {
              if (progress == null) return widget;
              return _loading(theme);
            },
            errorBuilder: (context, error, stackTrace) => _placeholder(theme),
          ),
        );
      },
    );
  }

  static double? _finiteOrNull(double value) => value.isFinite ? value : null;

  Widget _placeholder(ThemeData theme) {
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: (width ?? 60.w) * 0.3,
        color: theme.colorScheme.primary.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _loading(ThemeData theme) {
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.primary.withValues(alpha: 0.04),
      alignment: Alignment.center,
      child: SizedBox(
        width: 22.w,
        height: 22.w,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
