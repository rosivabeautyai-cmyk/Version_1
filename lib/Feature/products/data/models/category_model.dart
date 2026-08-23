/// A product category (Skincare, Makeup, Perfume, ...) as returned
/// by the catalog API. `slug` is what gets sent back to the API when
/// filtering products by category.
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
    return CategoryModel(
      id: (json['id'] ?? json['slug'] ?? '').toString(),
      slug: (json['slug'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      productCount: json['productCount'] is num
          ? (json['productCount'] as num).toInt()
          : null,
    );
  }
}
