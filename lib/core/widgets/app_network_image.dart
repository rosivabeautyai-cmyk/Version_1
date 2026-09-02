import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Wraps [Image.network] with a consistent loading skeleton and a
/// graceful fallback icon, so product/profile imagery never shows a
/// broken-image icon.
///
/// ### Why the web needs help
/// Product `imageUrl`s come straight from the Awin datafeed
/// (`large_image` / `merchant_image_url` — see
/// `scripts/awin-sync/awinSync.mjs`), i.e. arbitrary **merchant CDNs**
/// (`cdn.plusshop.com`, `productserve.com`, …). On the web many of those
/// fail two ways at once:
///
///  1. **No `Access-Control-Allow-Origin`** — CanvasKit decodes
///     `Image.network` from a CORS `fetch()`, which the browser blocks.
///  2. **Hot-link protection** — some merchants 403 an `<img>` whose
///     `Referer` isn't their own site, which also kills
///     `WebHtmlElementStrategy.fallback` (`img.decode()` throws).
///
/// So on the web the request is routed through **wsrv.nl**, a keyless,
/// Cloudflare-backed image resizer/proxy that fetches the source
/// server-side and re-serves it with `Access-Control-Allow-Origin: *`.
/// That restores the normal on-canvas decode path (correct
/// `ClipRRect` / `BoxFit`, no platform-view fragility) and shrinks
/// payloads via server-side resizing. If the proxied request itself
/// fails, the widget retries the **raw** URL once (letting the `<img>`
/// fallback have a go) before finally showing the placeholder — so a
/// wsrv.nl outage degrades, it doesn't black out.
///
/// Android / iOS are completely untouched — they load the raw merchant
/// URL directly (no CORS concept, no proxy).
class AppNetworkImage extends StatefulWidget {
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

  static const _proxyHosts = ['wsrv.nl', 'images.weserv.nl'];

  /// On the web, wraps an absolute http(s) image URL in the wsrv.nl
  /// CORS proxy (optionally asking it to resize to [targetPx] so the
  /// grid downloads thumbnails, not full-res photos). No-op on mobile,
  /// for non-http URLs, and for URLs already pointing at the proxy.
  static String resolveSrc(String raw, {int? targetPx}) {
    if (!kIsWeb) return raw;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return raw;
    if (uri.scheme != 'http' && uri.scheme != 'https') return raw;
    if (_proxyHosts.contains(uri.host)) return raw;

    final encoded = Uri.encodeComponent(raw);
    final size = (targetPx != null && targetPx > 0)
        ? '&w=${targetPx.clamp(96, 1200)}'
        : '';
    // output=webp -> smaller; we -> never enlarge; n=-1 -> follow redirects.
    return 'https://wsrv.nl/?url=$encoded$size&output=webp&we&n=-1';
  }

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  /// Set once the proxied URL has failed, so the next build tries the
  /// raw URL (with the `<img>` fallback) before giving up.
  bool _useRaw = false;

  @override
  void didUpdateWidget(AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _useRaw = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(16.r);

    final trimmed = widget.url?.trim();
    if (trimmed == null || trimmed.isEmpty || Uri.tryParse(trimmed) == null) {
      return ClipRRect(borderRadius: radius, child: _placeholder(theme));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final targetWidth =
            widget.width ?? _finiteOrNull(constraints.maxWidth);
        final targetHeight =
            widget.height ?? _finiteOrNull(constraints.maxHeight);
        final targetPx =
            targetWidth == null ? null : (targetWidth * dpr).round();

        final src = _useRaw
            ? trimmed
            : AppNetworkImage.resolveSrc(trimmed, targetPx: targetPx);

        return ClipRRect(
          borderRadius: radius,
          child: Image.network(
            src,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            // `cacheWidth/Height` are skipped on the web: there they wrap
            // the provider in a `ResizeImage` that can't operate on the
            // `<img>`-element fallback path (wsrv already resized).
            cacheWidth: kIsWeb || targetWidth == null
                ? null
                : (targetWidth * dpr).round(),
            cacheHeight: kIsWeb || targetHeight == null
                ? null
                : (targetHeight * dpr).round(),
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            // Cross-fade from the loading tile to the photo once its
            // first frame decodes, instead of a hard pop. Cached frames
            // appear instantly.
            frameBuilder: (context, child, frame, wasSyncLoaded) {
              if (wasSyncLoaded) return child;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                child: frame == null
                    ? _loading(theme)
                    : KeyedSubtree(
                        key: const ValueKey('img'),
                        child: child,
                      ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // First failure on the web + we were using the proxy →
              // fall back to the raw URL once (post-frame to avoid a
              // setState-during-build).
              if (kIsWeb && !_useRaw && src != trimmed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _useRaw = true);
                });
                return _loading(theme);
              }
              return _placeholder(theme);
            },
          ),
        );
      },
    );
  }

  static double? _finiteOrNull(double value) => value.isFinite ? value : null;

  Widget _placeholder(ThemeData theme) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: Icon(
        widget.fallbackIcon,
        size: (widget.width ?? 60.w) * 0.3,
        color: theme.colorScheme.primary.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _loading(ThemeData theme) {
    return Container(
      width: widget.width,
      height: widget.height,
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
