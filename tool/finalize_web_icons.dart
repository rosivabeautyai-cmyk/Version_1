// ignore_for_file: avoid_print
//
// Runs AFTER `dart run flutter_launcher_icons`. Two web-only fixes the
// icon package can't do itself:
//   * favicon.png — the package hard-codes 16x16 (an unreadable blob for
//     a detailed logo); regenerate at 64x64.
//   * Icon-maskable-*.png — need extra safe-zone padding (W3C maskable
//     spec keeps only the centre 80%); shrink the mark to ~60%.
// Nothing here touches in-app assets or the splash screen.
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final icon = img.decodeImage(
      File('assets/branding/rosiva_app_icon.png').readAsBytesSync())!;

  // favicon @ 64
  final fav = img.copyResize(icon,
      width: 64, height: 64, interpolation: img.Interpolation.average);
  File('web/favicon.png').writeAsBytesSync(img.encodePng(fav));
  print('web/favicon.png -> 64x64');

  // maskable icons: badge at ~60% on solid black
  for (final size in [192, 512]) {
    final canvas = img.Image(width: size, height: size, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
    final inner = (size * 0.60).round();
    final scaled = img.copyResize(icon,
        width: inner, height: inner, interpolation: img.Interpolation.average);
    final off = ((size - inner) / 2).round();
    img.compositeImage(canvas, scaled, dstX: off, dstY: off);
    File('web/icons/Icon-maskable-$size.png')
        .writeAsBytesSync(img.encodePng(canvas));
    print('web/icons/Icon-maskable-$size.png -> badge ${(inner / size * 100).round()}%');
  }
}
