import 'package:flutter/material.dart';
import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/country_config_model.dart';
import '../../data/models/currency_config_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/country_offers_editor.dart';

/// Create a new, manually-authored product. It is written with
/// `source: 'admin'` (the security rule requires it) and
/// `isRosivaProduct: false` — admin products are outside the
/// classifier's remit, so they never enter the AI catalog unless a
/// future explicit decision changes that.
class AdminProductCreateScreen extends StatefulWidget {
  final AdminRepository repository;
  final List<CurrencyConfig> currencies;
  final List<CountryConfig> countries;

  const AdminProductCreateScreen({
    super.key,
    required this.repository,
    this.currencies = const [],
    this.countries = const [],
  });

  @override
  State<AdminProductCreateScreen> createState() =>
      _AdminProductCreateScreenState();
}

class _AdminProductCreateScreenState extends State<AdminProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offersKey = GlobalKey<CountryOffersEditorState>();

  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _price = TextEditingController();
  final _storeUrl = TextEditingController();
  final _productType = TextEditingController();
  final _adminNote = TextEditingController();

  String _currency = 'USD';
  String _category = 'skincare';
  String _gender = 'women';
  bool _featured = false;
  bool _active = true;
  bool _saving = false;

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

  bool _isValidHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    return uri.scheme == 'https' || uri.scheme == 'http';
  }

  Future<void> _save() async {
    final lang = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final offers = _offersKey.currentState?.result();
    if (offers?.error != null) {
      SnackbarService.error(context, offers!.error!);
      return;
    }

    final confirmed = await showAdminConfirmDialog(
      context,
      title: lang.adminCreateProduct,
      message: lang.adminCreateProductDesc,
      confirmLabel: lang.adminSave,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      await widget.repository.createProduct(
        name: _name.text,
        brand: _brand.text,
        description: _description.text,
        imageUrl: _imageUrl.text,
        price: double.tryParse(_price.text.trim()),
        currency: _currency,
        storeUrl: _storeUrl.text,
        rosivaCategory: _category,
        gender: _gender,
        productType: _productType.text,
        featured: _featured,
        active: _active,
        adminNote: _adminNote.text,
        countryOffers: offers?.offers ?? const {},
      );
      if (!mounted) return;
      SnackbarService.success(context, lang.adminProductCreated);
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
    final currencyCodes = <String>{
      _currency,
      ...widget.currencies.map((c) => c.code),
      'USD', 'GBP', 'EUR', 'EGP', 'SAR', 'AED', 'QAR', 'KWD', 'JOD',
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(title: Text(lang.adminNewProduct)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(lang.adminCreateProductDesc, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              _field(_name, lang.adminFieldName, required: true),
              _field(_brand, lang.adminFieldBrand),
              _field(_description, lang.adminFieldDescription, maxLines: 4),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim());
                        if (n == null) return lang.adminInvalidNumber;
                        if (n < 0) return lang.adminOfferNegativePrice;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration:
                          InputDecoration(labelText: lang.adminFieldCurrency),
                      items: [
                        for (final c in currencyCodes)
                          DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: (v) => setState(() => _currency = v ?? _currency),
                    ),
                  ),
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration:
                          InputDecoration(labelText: lang.adminFieldCategory),
                      items: const [
                        DropdownMenuItem(
                            value: 'skincare', child: Text('skincare')),
                        DropdownMenuItem(value: 'makeup', child: Text('makeup')),
                        DropdownMenuItem(
                            value: 'perfume', child: Text('perfume')),
                      ],
                      onChanged: (v) => setState(() => _category = v ?? _category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration:
                          InputDecoration(labelText: lang.adminFieldGender),
                      items: [
                        DropdownMenuItem(
                            value: 'women', child: Text(lang.adminFieldGenderWomen)),
                        DropdownMenuItem(
                            value: 'men', child: Text(lang.adminFieldGenderMen)),
                        DropdownMenuItem(
                            value: 'unisex',
                            child: Text(lang.adminFieldGenderUnisex)),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? _gender),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field(
                _productType,
                lang.adminFieldProductType,
                hint: lang.adminFieldProductTypeHint,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(lang.adminFieldFeatured),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(lang.adminFieldActive),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              _field(_adminNote, lang.adminFieldAdminNote, maxLines: 3),
              const Divider(height: 32),
              Text(
                lang.adminCountryOffers,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              CountryOffersEditor(
                key: _offersKey,
                enabledCountries:
                    widget.countries.where((c) => c.enabled).toList(),
                currencyCodes: widget.currencies.map((c) => c.code).toList(),
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
                    : Text(lang.adminCreateProduct),
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
}
