// ignore_for_file: avoid_print
//
// One-shot helper: turns the ROSIVA logo (assets/image/splash.png, an
// RGBA badge on a faint low-alpha halo) into two CLEAN sources for
// flutter_launcher_icons. It does NOT redesign the logo — it only
// composites the existing pixels onto a solid background / masks the
// halo so the OS icon pipeline has junk-free input (the raw file has
// stray RGB in its near-transparent pixels, which broke iOS alpha
// removal). Run: dart run tool/make_app_icon.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  final src = img.decodePng(File('assets/image/splash.png').readAsBytesSync())!;
  final w = src.width, h = src.height;
  final cx = (w - 1) / 2.0, cy = (h - 1) / 2.0;

  // --- 1. Opaque icon: badge composited over solid black -------------
  // out = fg*a + black*(1-a). The halo alpha is <=8/255, so it collapses
  // to black; the badge (opaque) is untouched. Used for iOS AppIcon,
  // legacy Android mipmap and the web favicon / PWA icons.
  final flat = img.Image(width: w, height: h, numChannels: 3);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      final a = p.a / 255.0;
      flat.setPixelRgb(x, y, (p.r * a).round(), (p.g * a).round(), (p.b * a).round());
    }
  }
  // Trim the excess black margin (the source has ~23% dead space around
  // the badge) so the mark fills the icon like a real app icon — a
  // symmetric centre crop, so the logo is neither cropped nor rescaled.
  const cropSide = 1120;
  final off = ((w - cropSide) / 2).round();
  final opaque = img.copyCrop(flat, x: off, y: off, width: cropSide, height: cropSide);
  File('assets/branding/rosiva_app_icon.png')
      .writeAsBytesSync(img.encodePng(opaque));

  // --- 2. Adaptive foreground: badge only, clean transparency -------
  // Keep pixels inside the badge circle (opaque disc, r~432) plus a 16px
  // feathered rim; force everything else fully transparent so Android's
  // adaptive background + parallax shows through.
  const rKeep = 452.0; // a little beyond the opaque badge edge
  const feather = 10.0;
  final fg = img.Image(width: w, height: h, numChannels: 4);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final d = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
      final p = src.getPixel(x, y);
      double keep;
      if (d <= rKeep) {
        keep = 1.0;
      } else if (d >= rKeep + feather) {
        keep = 0.0;
      } else {
        keep = 1.0 - (d - rKeep) / feather;
      }
      final a = (p.a * keep).round().clamp(0, 255);
      if (a == 0) {
        fg.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        fg.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), a);
      }
    }
  }
  File('assets/branding/rosiva_app_icon_fg.png')
      .writeAsBytesSync(img.encodePng(fg));

  print('wrote assets/branding/rosiva_app_icon.png (opaque, ${w}x$h)');
  print('wrote assets/branding/rosiva_app_icon_fg.png (circular alpha, ${w}x$h)');
}
