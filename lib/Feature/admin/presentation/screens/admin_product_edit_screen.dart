import 'package:flutter/material.dart';
import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../products/data/models/country_offer_model.dart';
import '../../data/models/country_config_model.dart';
import '../../data/models/currency_config_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/country_offers_editor.dart';

/// Edit the admin-managed side of a product.
///
/// Base fields (name / brand / description / image / price / currency /
/// store URL) are owned by the daily Awin sync — anything the admin
/// changes here is stored in `products/{id}.adminOverrides` and layered
/// back over the sync data on read, so the two never fight. `category`
/// and `gender` come from the classifier and are shown read-only.
class AdminProductEditScreen extends StatefulWidget {
  final String productId;
  final AdminRepository repository;
  final List<CurrencyConfig> currencies;
  final List<CountryConfig> countries;

  const AdminProductEditScreen({
    super.key,
    required this.productId,
    required this.repository,
    this.currencies = const [],
    this.countries = const [],
  });

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offersKey = GlobalKey<CountryOffersEditorState>();
  Map<String, CountryOffer> _initialOffers = const {};

  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _price = TextEditingController();
  final _storeUrl = TextEditingController();
  final _productType = TextEditingController();
  final _adminNote = TextEditingController();

  String _currency = 'USD';
  bool _featured = false;
  bool _active = true;

  Map<String, dynamic> _raw = const {};
  String _category = '';
  String _gender = '';

  bool _loading = true;
  bool _saving = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _brand, _description, _imageUrl, _price, _storeUrl,
      _productType, _adminNote,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _syncedString(String key, [String? altKey]) {
    final v = _raw[key] ?? (altKey != null ? _raw[altKey] : null);
    return v?.toString();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final raw = await widget.repository.fetchProductRaw(widget.productId);
      final ov = (raw['adminOverrides'] as Map?)?.cast<String, dynamic>() ??
          const {};

      String eff(String key, [String? altKey]) =>
          (ov[key] ?? raw[key] ?? (altKey != null ? raw[altKey] : null) ?? '')
              .toString();

      _raw = raw;
      _name.text = eff('name');
      _brand.text = eff('brand');
      _description.text = eff('description');
      _imageUrl.text = eff('imageUrl', 'image');
      final effPrice = ov['price'] ?? raw['price'];
      _price.text = effPrice == null ? '' : effPrice.toString();
      _currency = (ov['currency'] ?? raw['currency'] ?? 'USD')
          .toString()
          .toUpperCase();
      _storeUrl.text = eff('storeUrl', 'url');
      _productType.text = (raw['productType'] ?? '').toString();
      _adminNote.text = (raw['adminNote'] ?? '').toString();
      _featured = raw['featured'] as bool? ??
          raw['isEditorsChoice'] as bool? ??
          false;
      _active = raw['active'] as bool? ?? raw['inStock'] as bool? ?? true;
      _category = (raw['rosivaCategory'] ?? raw['category'] ?? '—').toString();
      _gender = (raw['gender'] ?? 'unknown').toString();
      _initialOffers = CountryOffer.mapFromJson(raw['countryOffers']);

      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  bool _isValidHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    return uri.scheme == 'https' || uri.scheme == 'http';
  }

  /// Builds the overrides map: only base fields the admin changed away
  /// from the sync value are recorded; matching the sync value again
  /// removes the override.
  Map<String, dynamic> _buildOverrides() {
    final out = <String, dynamic>{};

    void putStr(String key, String input, {String? altKey}) {
      final v = input.trim();
      final synced = (_syncedString(key, altKey) ?? '').trim();
      if (v.isEmpty || v == synced) return;
      out[key] = v;
    }

    putStr('name', _name.text);
    putStr('brand', _brand.text);
    putStr('description', _description.text);
    putStr('imageUrl', _imageUrl.text, altKey: 'image');
    putStr('storeUrl', _storeUrl.text, altKey: 'url');

    final priceInput = _price.text.trim();
    final parsedPrice = double.tryParse(priceInput);
    final syncedPrice = (_raw['price'] as num?)?.toDouble();
    if (priceInput.isNotEmpty && parsedPrice != null && parsedPrice != syncedPrice) {
      out['price'] = parsedPrice;
    }
    final syncedCurrency =
        (_raw['currency'] ?? 'USD').toString().toUpperCase();
    if (_currency != syncedCurrency) out['currency'] = _currency;

    return out;
  }

  Future<void> _save() async {
    final lang = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await showAdminConfirmDialog(
      context,
      title: lang.adminConfirmSaveProductTitle,
      message: lang.adminConfirmSaveProductBody,
      confirmLabel: lang.adminSave,
    );
    if (!confirmed || !mounted) return;

    final offersResult = _offersKey.currentState?.result();
    if (offersResult?.error != null) {
      SnackbarService.error(context, offersResult!.error!);
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repository.updateProductAdmin(
        widget.productId,
        productType: _productType.text.trim(),
        featured: _featured,
        active: _active,
        adminNote: _adminNote.text.trim(),
        adminOverrides: _buildOverrides(),
        countryOffers: offersResult?.offers ?? const {},
      );
      if (!mounted) return;
      SnackbarService.success(context, lang.adminSaved);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.error(context, lang.adminSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(lang.adminEditProduct)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(lang.somethingWentWrongDesc),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _Note(text: lang.adminProductOverridesNote),
                        const SizedBox(height: 16),
                        _field(_name, lang.adminFieldName, required: true),
                        _field(_brand, lang.adminFieldBrand),
                        _field(
                          _description,
                          lang.adminFieldDescription,
                          maxLines: 4,
                        ),
                        _field(
                          _imageUrl,
                          lang.adminFieldImageUrl,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty || _isValidHttpUrl(v))
                                  ? null
                                  : lang.adminInvalidUrl,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _field(
                                _price,
                                lang.adminFieldPrice,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  return double.tryParse(v.trim()) == null
                                      ? lang.adminInvalidNumber
                                      : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _currencyDropdown(lang)),
                          ],
                        ),
                        _field(
                          _storeUrl,
                          lang.adminFieldStoreUrl,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty || _isValidHttpUrl(v))
                                  ? null
                                  : lang.adminInvalidUrl,
                        ),
                        const Divider(height: 32),
                        _field(
                          _productType,
                          lang.adminFieldProductType,
                          hint: lang.adminFieldProductTypeHint,
                        ),
                        const SizedBox(height: 8),
                        _readOnlyChips(theme, lang),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(lang.adminFieldFeatured),
                          subtitle: Text(lang.adminFieldFeaturedDesc),
                          value: _featured,
                          onChanged: (v) => setState(() => _featured = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(lang.adminFieldActive),
                          subtitle: Text(lang.adminFieldActiveDesc),
                          value: _active,
                          onChanged: (v) => setState(() => _active = v),
                        ),
                        _field(
                          _adminNote,
                          lang.adminFieldAdminNote,
                          maxLines: 3,
                        ),
                        const Divider(height: 32),
                        Text(
                          lang.adminCountryOffers,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        CountryOffersEditor(
                          key: _offersKey,
                          initial: _initialOffers,
                          enabledCountries: widget.countries
                              .where((c) => c.enabled)
                              .toList(),
                          currencyCodes:
                              widget.currencies.map((c) => c.code).toList(),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(lang.adminSave),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final lang = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? lang.adminRequiredField
                    : null
                : null),
      ),
    );
  }

  Widget _currencyDropdown(AppLocalizations lang) {
    final codes = <String>{
      _currency,
      'USD', 'GBP', 'EUR', 'EGP', 'SAR', 'AED', 'QAR', 'KWD', 'JOD',
      ...widget.currencies.map((c) => c.code),
    }.toList()
      ..sort();
    return DropdownButtonFormField<String>(
      initialValue: codes.contains(_currency) ? _currency : codes.first,
      decoration: InputDecoration(labelText: lang.adminFieldCurrency),
      items: [
        for (final c in codes) DropdownMenuItem(value: c, child: Text(c)),
      ],
      onChanged: (v) => setState(() => _currency = v ?? _currency),
    );
  }

  Widget _readOnlyChips(ThemeData theme, AppLocalizations lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('${lang.adminFieldCategory}: $_category')),
              Chip(label: Text('${lang.adminFieldGender}: $_gender')),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lang.adminGenderClassifierNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
