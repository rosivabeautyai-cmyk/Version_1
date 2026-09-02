/// The single source of truth for every bundled image path in ROSIVA.
///
/// All files live in `assets/image/` (declared as a folder glob in
/// pubspec.yaml, so new files here need no pubspec edit). A missing
/// file must degrade to a branded placeholder at the call site — never
/// a broken-image glyph.
abstract class AppImages {
  static const String splash = 'assets/image/splash.png';
  static const String onboarding1 = 'assets/image/1.jpg';
  static const String onboarding2 = 'assets/image/2.jpg';
  static const String onboarding3 = 'assets/image/3.jpg';
  static const String google = 'assets/image/SVG.png';

  /// Default profile avatar (square model portrait). Used until the
  /// user uploads their own photo.
  static const String profileAvatar = 'assets/image/model_profile.jpg';

  // Portrait model photos for the three ROSIVA category cards.
  static const String categorySkincare = 'assets/image/category_1.jpg';
  static const String categoryMakeup = 'assets/image/category_2.jpg';
  static const String categoryPerfume = 'assets/image/category_3.jpg';

  /// The ONE place the category → image mapping lives. Accepts a raw
  /// or canonical slug; returns `null` for anything outside ROSIVA's
  /// three categories so the caller can fall back to a branded tile.
  static String? categoryImage(String? slug) {
    switch ((slug ?? '').trim().toLowerCase()) {
      case 'skincare':
        return categorySkincare;
      case 'makeup':
        return categoryMakeup;
      case 'perfume':
      case 'perfumes':
      case 'fragrance':
        return categoryPerfume;
      default:
        return null;
    }
  }
}
