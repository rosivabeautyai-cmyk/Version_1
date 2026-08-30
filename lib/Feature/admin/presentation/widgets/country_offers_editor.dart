import 'package:flutter/material.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../products/data/models/country_offer_model.dart';
import '../../data/models/country_config_model.dart';

/// Reusable "Country Offers" editor used by both the admin product
/// edit and create screens. One row per enabled country: toggle an
/// offer on, then set price / currency / affiliate URL / in-stock.
///
/// Uncontrolled — the parent keeps a [GlobalKey] and calls
/// [CountryOffersEditorState.result] on save to get the validated
/// `countryOffers` map (or an error string to block the save).
class CountryOffersEditor extends StatefulWidget {
  final Map<String, CountryOffer> initial;
  final List<CountryConfig> enabledCountries;
  final List<String> currencyCodes;

  const CountryOffersEditor({
    super.key,
    this.initial = const {},
    this.enabledCountries = const [],
    this.currencyCodes = const [],
  });

  @override
  State<CountryOffersEditor> createState() => CountryOffersEditorState();
}

class _OfferRow {
  bool enabled;
  final TextEditingController price;
  final TextEditingController url;
  String currency;
  bool inStock;
  _OfferRow({
    required this.enabled,
    required this.price,
    required this.url,
    required this.currency,
    required this.inStock,
  });
}

class CountryOffersEditorState extends State<CountryOffersEditor> {
  final Map<String, _OfferRow> _rows = {};

  @override
  void initState() {
    super.initState();
    for (final c in widget.enabledCountries) {
      final existing = widget.initial[c.code.toUpperCase()];
      _rows[c.code.toUpperCase()] = _OfferRow(
        enabled: existing != null,
        price: TextEditingController(
          text: existing?.price?.toString() ?? '',
        ),
        url: TextEditingController(text: existing?.affiliateUrl ?? ''),
        currency: (existing?.currency ??
                (c.currencyCode.isNotEmpty ? c.currencyCode : 'USD'))
            .toUpperCase(),
        inStock: existing?.inStock ?? true,
      );
    }
  }

  @override
  void dispose() {
    for (final r in _rows.values) {
      r.price.dispose();
      r.url.dispose();
    }
    super.dispose();
  }

  bool _validUrl(String v) {
    final s = v.trim();
    if (s.isEmpty) return true;
    final uri = Uri.tryParse(s);
    return uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  /// Validated result. `error` non-null blocks the save.
  ({Map<String, dynamic> offers, String? error}) result() {
    final lang = AppLocalizations.of(context)!;
    final out = <String, dynamic>{};
    final validCurrencies = widget.currencyCodes.map((c) => c.toUpperCase()).toSet();

    for (final entry in _rows.entries) {
      final row = entry.value;
      if (!row.enabled) continue;
      final priceText = row.price.text.trim();
      final urlText = row.url.text.trim();
      if (priceText.isEmpty && urlText.isEmpty) continue; // nothing entered

      double? price;
      if (priceText.isNotEmpty) {
        price = double.tryParse(priceText);
        if (price == null) return (offers: {}, error: lang.adminInvalidNumber);
        if (price < 0) return (offers: {}, error: lang.adminOfferNegativePrice);
      }
      if (!_validUrl(urlText)) {
        return (offers: {}, error: lang.adminInvalidUrl);
      }
      if (validCurrencies.isNotEmpty &&
          !validCurrencies.contains(row.currency.toUpperCase())) {
        return (offers: {}, error: lang.adminOfferInvalidCurrency);
      }

      out[entry.key] = {
        'price': ?price,
        'currency': row.currency.toUpperCase(),
        if (urlText.isNotEmpty) 'affiliateUrl': urlText,
        'inStock': row.inStock,
      };
    }
    return (offers: out, error: null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    if (widget.enabledCountries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          lang.adminNoEnabledCountries,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final currencies = <String>{
      ...widget.currencyCodes.map((c) => c.toUpperCase()),
      'USD', 'GBP', 'EUR', 'EGP', 'SAR', 'AED', 'QAR', 'KWD', 'JOD',
    }.toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.adminCountryOffersDesc, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final c in widget.enabledCountries)
          _row(context, c, currencies, lang),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    CountryConfig c,
    List<String> currencies,
    AppLocalizations lang,
  ) {
    final row = _rows[c.code.toUpperCase()]!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${c.code} · ${c.nameEn}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                Switch(
                  value: row.enabled,
                  onChanged: (v) => setState(() => row.enabled = v),
                ),
              ],
            ),
            if (row.enabled) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: row.price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          InputDecoration(labelText: lang.adminFieldPrice),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: currencies.contains(row.currency)
                          ? row.currency
                          : currencies.first,
                      decoration:
                          InputDecoration(labelText: lang.adminFieldCurrency),
                      items: [
                        for (final code in currencies)
                          DropdownMenuItem(value: code, child: Text(code)),
                      ],
                      onChanged: (v) =>
                          setState(() => row.currency = v ?? row.currency),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: row.url,
                decoration:
                    InputDecoration(labelText: lang.adminFieldStoreUrl),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(lang.adminOfferInStock),
                value: row.inStock,
                onChanged: (v) => setState(() => row.inStock = v),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  row.enabled = false;
                  row.price.clear();
                  row.url.clear();
                }),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(lang.adminClearOffer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
