import 'package:flutter/material.dart';

/// A bundled [Image.asset] with a calm fade-in and a branded fallback
/// tile if the asset is missing from the build — so a forgotten
/// `flutter clean && flutter run` degrades to a rose placeholder, never
/// a broken-image glyph.
class AppAssetImage extends StatelessWidget {
  final String? assetPath;
  final BoxFit fit;
  final Alignment alignment;
  final IconData fallbackIcon;

  const AppAssetImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fallbackIcon = Icons.spa_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final path = assetPath;

    if (path == null || path.isEmpty) return _fallback(primary);

    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, error, stack) => _fallback(primary),
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }

  Widget _fallback(Color primary) => ColoredBox(
        color: primary.withValues(alpha: 0.08),
        child: Center(
          child: Icon(fallbackIcon, color: primary.withValues(alpha: 0.5), size: 28),
        ),
      );
}
