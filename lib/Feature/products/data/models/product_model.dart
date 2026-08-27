import 'category_model.dart' show normalizeCategory;

/// A single beauty product as returned by the ROSIVA catalog API.
///
/// Every field is nullable/defaulted on purpose: the backend is the
/// single source of truth, and the UI must render sensible
/// loading/empty states rather than assume any field is always
/// present.
class ProductModel {
  final String id;
  final String name;
  final String? brand;
  final String? description;
  final double? price;
  final String currency;
  final String? imageUrl;
  final List<String> images;
  final double? rating;
  final int? reviewCount;
  final String? category;
  final List<String> tags;
  final List<String> ingredients;
  final String? benefits;
  final String? howToUse;
  final String? whyRecommended;
  final bool isEditorsChoice;
  final String? storeUrl;
  final bool inStock;

  const ProductModel({
    required this.id,
    required this.name,
    this.brand,
    this.description,
    this.price,
    this.currency = 'USD',
    this.imageUrl,
    this.images = const [],
    this.rating,
    this.reviewCount,
    this.category,
    this.tags = const [],
    this.ingredients = const [],
    this.benefits,
    this.howToUse,
    this.whyRecommended,
    this.isEditorsChoice = false,
    this.storeUrl,
    this.inStock = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? json['productId'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      price: _toDouble(json['price']),
      currency: json['currency'] as String? ?? 'USD',
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      images: _toStringList(json['images']),
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['reviewCount'] ?? json['reviewsCount']),
      // Normalized through the single canonical `normalizeCategory`
      // (never overwritten with `merchantCategory` — that's Awin's
      // own, unnormalized taxonomy and is a completely separate
      // signal, not read here at all).
      category: normalizeCategory(json['category'] as String?),
      tags: _toStringList(json['tags']),
      ingredients: _toStringList(json['ingredients']),
      benefits: json['benefits'] as String?,
      howToUse: json['howToUse'] as String?,
      whyRecommended:
          json['whyRecommended'] as String? ?? json['aiReason'] as String?,
      isEditorsChoice: json['isEditorsChoice'] as bool? ?? false,
      storeUrl: json['storeUrl'] as String? ?? json['url'] as String?,
      inStock: json['inStock'] as bool? ?? true,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}
