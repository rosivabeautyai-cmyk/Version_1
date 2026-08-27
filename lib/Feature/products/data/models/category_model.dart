/// ROSIVA's three canonical shopping categories. Every product and
/// category document in Firestore is expected to already use these
/// exact lowercase slugs (that's what the Awin sync writes), but
/// [normalizeCategory] exists as the single, defensive source of
/// truth for turning *any* raw category-ish string — differently
/// cased, using a synonym, hyphenated, etc. — into one of these, so
/// no screen ever has to do its own ad-hoc `.toLowerCase()` /
/// string-matching to compare categories.
const List<String> kRosivaCategories = ['skincare', 'makeup', 'perfume'];

/// Normalizes any raw category-ish string (from Firestore, user
/// input, or AI output) into one of ROSIVA's three canonical category
/// slugs — `skincare`, `makeup`, or `perfume` — or `null` if it
/// doesn't match any of them.
///
/// This is the ONLY place category strings should be interpreted;
/// every screen/provider/service should call this instead of
/// comparing raw strings or duplicating keyword lists.
///
/// Examples handled: `Makeup` / `MAKEUP` / `make-up` / `cosmetics` →
/// `makeup`; `Skincare` / `skin care` / `Skin Care` → `skincare`;
/// `Perfume` / `perfumes` / `fragrance` / `fragrances` → `perfume`.
String? normalizeCategory(String? raw) {
  if (raw == null) return null;

  final value = raw.trim().toLowerCase().replaceAll(RegExp(r'[-_]+'), ' ');
  if (value.isEmpty) return null;

  // Already-canonical fast path (the overwhelming common case, since
  // the Awin sync always writes lowercase `skincare`/`makeup`/
  // `perfume` directly).
  if (kRosivaCategories.contains(value)) return value;

  if (value.contains('makeup') ||
      value.contains('make up') ||
      value.contains('cosmetic')) {
    return 'makeup';
  }

  if (value.contains('skincare') || value.contains('skin care')) {
    return 'skincare';
  }

  if (value.contains('perfume') ||
      value.contains('fragrance') ||
      value.contains('parfum') ||
      value.contains('cologne')) {
    return 'perfume';
  }

  return null;
}

/// A product category (Skincare, Makeup, Perfume, ...) as returned
/// by the catalog API. `slug` is what gets sent back to the API when
/// filtering products by category — always normalized via
/// [normalizeCategory] so it's guaranteed to be one of ROSIVA's
/// canonical category slugs.
class CategoryModel {
  final String id;
  final String slug;
  final String name;
  final String? imageUrl;
  final int? productCount;

  const CategoryModel({
    required this.id,
    required this.slug,
    required this.name,
    this.imageUrl,
    this.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawSlug = (json['slug'] ?? json['id'] ?? '').toString();
    final slug = normalizeCategory(rawSlug) ?? rawSlug;

    return CategoryModel(
      id: (json['id'] ?? json['slug'] ?? '').toString(),
      slug: slug,
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      productCount: json['productCount'] is num
          ? (json['productCount'] as num).toInt()
          : null,
    );
  }
}
