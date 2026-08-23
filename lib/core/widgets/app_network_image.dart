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

    Widget child;

    if (url == null || url!.isEmpty) {
      child = _placeholder(theme);
    } else {
      child = Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) return widget;
          return _loading(theme);
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(theme),
      );
    }

    return ClipRRect(borderRadius: radius, child: child);
  }

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
