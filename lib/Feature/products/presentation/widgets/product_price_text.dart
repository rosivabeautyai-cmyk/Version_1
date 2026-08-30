import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';

import '../../data/models/product_model.dart';

/// The one shopper-facing price widget. Priority (item 2):
///   1. a real country offer for the selected country → shown verbatim,
///      NEVER converted
///   2. otherwise the (possibly admin-overridden) base price/currency
///   3. optionally an "≈ N XXX" estimate — only when no real country
///      offer applies, a different currency is selected, and a rate
///      exists. The estimate is clearly labelled and never presented
///      as the store price.
class ProductPriceText extends StatelessWidget {
  final ProductModel product;
  final bool showApprox;
  final TextStyle? style;
  final TextStyle? approxStyle;

  const ProductPriceText({
    super.key,
    required this.product,
    this.showApprox = true,
    this.style,
    this.approxStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regional = context.watch<RegionalPrefsProvider?>();
    final country = regional?.countryCode;
    final selectedCurrency = regional?.currencyCode;
    final cs = regional?.currencyService;

    final offer = product.offerFor(country);
    final price = offer.price;
    if (price == null) return const SizedBox.shrink();

    final currency = offer.currency;
    final hasRealCountryOffer = country != null &&
        product.countryOffers.containsKey(country.toUpperCase());

    final primary = cs != null
        ? cs.format(price, currency)
        : '$currency ${price.toStringAsFixed(2)}';

    String? approx;
    if (showApprox &&
        !hasRealCountryOffer &&
        cs != null &&
        selectedCurrency != null &&
        selectedCurrency.toUpperCase() != currency.toUpperCase()) {
      approx = cs.approx(price, currency, selectedCurrency);
    }

    final primaryStyle = style ??
        theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary);

    if (approx == null) {
      return Text(primary, style: primaryStyle);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(primary, style: primaryStyle),
        SizedBox(height: 2.h),
        Text(
          approx,
          style: approxStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
