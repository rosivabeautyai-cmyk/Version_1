/// Catalog-health numbers for the Admin dashboard. Every field is
/// nullable so a metric that failed to load (e.g. an index still
/// building) shows as "—" instead of a wrong `0`.
class AdminDashboardMetrics {
  final int? totalProducts;
  final int? skincareCount;
  final int? makeupCount;
  final int? perfumeCount;
  final int? featuredCount;
  final int? ineligibleCount;
  final int? missingAffiliateCount;
  final int? missingPriceCount;
  final int? inactiveCount;

  const AdminDashboardMetrics({
    this.totalProducts,
    this.skincareCount,
    this.makeupCount,
    this.perfumeCount,
    this.featuredCount,
    this.ineligibleCount,
    this.missingAffiliateCount,
    this.missingPriceCount,
    this.inactiveCount,
  });
}
