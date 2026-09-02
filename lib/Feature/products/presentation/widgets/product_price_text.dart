import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/product_model.dart';

/// The one shopper-facing price widget. Priority:
///   1. a real country offer for the EXPLICITLY chosen country → shown
///      verbatim, NEVER converted
///   2. otherwise the (possibly admin-overridden) base price/currency
///   3. optionally an "≈ N XXX" estimate — only when no real country
///      offer applies, a different currency is in effect (explicit pick
///      OR device region), a fresh rate exists, and the product's
///      currency is a real value (not a sync default). The estimate is
///      clearly labelled, visually secondary, and never presented as
///      the store price.
class ProductPriceText extends StatelessWidget {
  final ProductModel product;

  /// Show the "≈ N XXX" estimate line when applicable.
  final bool showApprox;

  /// When an estimate is shown, also render the one-line caveat caption
  /// ("Approximate — the store charges in …"). Use on the product page,
  /// not on compact cards.
  final bool showCaption;

  /// Rendered on the same line as the exact price (e.g. a rating chip),
  /// so a 2-line price block stays aligned.
  final Widget? trailing;

  final TextStyle? style;
  final TextStyle? approxStyle;

  const ProductPriceText({
    super.key,
    required this.product,
    this.showApprox = true,
    this.showCaption = false,
    this.trailing,
    this.style,
    this.approxStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Null-safe: this widget is unit-tested without a localizations
    // delegate. The caption simply doesn't render if it's unavailable.
    final lang = AppLocalizations.of(context);
    final regional = context.watch<RegionalPrefsProvider?>();

    // Country offers + the "real offer" check use ONLY the explicit
    // choice — a device-region guess must not swap in a per-country
    // price or affiliate URL.
    final explicitCountry = regional?.countryCode;
    // The estimate's target currency follows the *effective* country
    // (explicit pick, else device region).
    final selectedCurrency = regional?.currencyCode;
    final cs = regional?.currencyService;

    final offer = product.offerFor(explicitCountry);
    final price = offer.price;
    if (price == null) return const SizedBox.shrink();

    final currency = offer.currency;
    final hasRealCountryOffer = explicitCountry != null &&
        product.countryOffers.containsKey(explicitCountry.toUpperCase());

    final primary = cs != null
        ? cs.format(price, currency)
        : '$currency ${price.toStringAsFixed(2)}';

    String? approx;
    if (showApprox &&
        !hasRealCountryOffer &&
        !product.currencyIsAssumed &&
        cs != null &&
        selectedCurrency != null &&
        selectedCurrency.toUpperCase() != currency.toUpperCase()) {
      approx = cs.approx(price, currency, selectedCurrency);
    }

    final primaryStyle = style ??
        theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary);
    final secondaryStyle = approxStyle ??
        theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final primaryText = Text(primary, style: primaryStyle);
    final priceLine = trailing == null
        ? primaryText
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: primaryText),
              SizedBox(width: 8.w),
              trailing!,
            ],
          );

    if (approx == null) return priceLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        priceLine,
        SizedBox(height: 2.h),
        Text(approx, style: secondaryStyle),
        if (showCaption && lang != null) ...[
          SizedBox(height: 2.h),
          Text(
            lang.priceApproxCaption(currency.toUpperCase()),
            style: secondaryStyle,
          ),
        ],
      ],
    );
  }
}
