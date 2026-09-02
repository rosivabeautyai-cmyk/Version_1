import 'package:flutter/material.dart';

import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/affiliate_store_model.dart';
import '../../data/repositories/affiliate_store_repository.dart';

/// Add / Edit an affiliate store.
///
/// The Integration section is DYNAMIC: choosing a type shows only the
/// fields that type needs. Private credentials (feed passwords, API
/// keys, tokens) are never fields here — a note points to the backend
/// environment instead.
class AdminAffiliateStoreFormScreen extends StatefulWidget {
  final AffiliateStoreRepository repository;
  final AffiliateStore? existing;
  final List<String> currencies;
  final List<String> countries;

  const AdminAffiliateStoreFormScreen({
    super.key,
    required this.repository,
    this.existing,
    this.currencies = const [],
    this.countries = const [],
  });

  @override
  State<AdminAffiliateStoreFormScreen> createState() =>
      _AdminAffiliateStoreFormScreenState();
}

class _AdminAffiliateStoreFormScreenState
    extends State<AdminAffiliateStoreFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _websiteUrl =
      TextEditingController(text: widget.existing?.websiteUrl ?? '');
  late final _logoUrl =
      TextEditingController(text: widget.existing?.logoUrl ?? '');
  late final _programId =
      TextEditingController(text: widget.existing?.programId ?? '');
  late final _affiliateId =
      TextEditingController(text: widget.existing?.affiliateId ?? '');
  late final _network =
      TextEditingController(text: widget.existing?.affiliateNetwork ?? '');
  late final _commissionRate = TextEditingController(
    text: (widget.existing?.defaultCommissionRate ?? '').toString(),
  );

  // Feed
  late final _feedUrl =
      TextEditingController(text: widget.existing?.feedUrl ?? '');
  late final _feedUsername =
      TextEditingController(text: widget.existing?.feedUsername ?? '');
  late final _feedLanguage =
      TextEditingController(text: widget.existing?.feedLanguage ?? '');
  late final _feedItemPath =
      TextEditingController(text: widget.existing?.feedItemPath ?? '');

  // REST
  late final _apiBaseUrl =
      TextEditingController(text: widget.existing?.apiBaseUrl ?? '');
  late final _apiProductsPath = TextEditingController(
    text: widget.existing?.apiProductsPath ?? '/products',
  );
  late final _apiHeaderName = TextEditingController(
    text: widget.existing?.apiAuthHeaderName ?? 'X-Api-Key',
  );
  late final _apiQueryParam = TextEditingController(
    text: widget.existing?.apiAuthQueryParam ?? 'api_key',
  );
  late final _publicApiId =
      TextEditingController(text: widget.existing?.publicApiId ?? '');
  late final _apiItemsPath = TextEditingController(
    text: widget.existing?.apiItemsPath ?? 'data',
  );

  late String _currency =
      widget.existing?.currency ?? (widget.currencies.isNotEmpty ? widget.currencies.first : 'USD');
  String? _country;
  late AffiliateIntegrationType _integrationType =
      widget.existing?.integrationType ?? AffiliateIntegrationType.manual;
  late AffiliateFeedFormat _feedFormat =
      widget.existing?.feedFormat ?? AffiliateFeedFormat.csv;
  late String _feedAuthType = widget.existing?.feedAuthType ?? 'none';
  late String _apiAuthType = widget.existing?.apiAuthType ?? 'none';
  late AffiliateCommissionType _commissionType =
      widget.existing?.commissionType ?? AffiliateCommissionType.percentage;
  late bool _syncEnabled = widget.existing?.syncEnabled ?? true;
  late AffiliateSyncFrequency _syncFrequency =
      widget.existing?.syncFrequency ?? AffiliateSyncFrequency.daily;

  bool _saving = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final existingCountry = widget.existing?.country;
    if (existingCountry != null && widget.countries.contains(existingCountry)) {
      _country = existingCountry;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name, _description, _websiteUrl, _logoUrl, _programId, _affiliateId,
      _network, _commissionRate, _feedUrl, _feedUsername, _feedLanguage,
      _feedItemPath, _apiBaseUrl, _apiProductsPath, _apiHeaderName,
      _apiQueryParam, _publicApiId, _apiItemsPath,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  AffiliateStore _buildStore() {
    final id = widget.existing?.id ??
        AffiliateStoreRepository.slugify(_name.text.trim());
    return AffiliateStore(
      id: id,
      name: _name.text.trim(),
      slug: widget.existing?.slug ?? id,
      logoUrl: _nullIfEmpty(_logoUrl.text),
      description: _nullIfEmpty(_description.text),
      websiteUrl: _nullIfEmpty(_websiteUrl.text),
      country: _country,
      currency: _currency,
      affiliateNetwork: _nullIfEmpty(_network.text)?.toLowerCase(),
      programId: _nullIfEmpty(_programId.text),
      affiliateId: _nullIfEmpty(_affiliateId.text),
      integrationType: _integrationType,
      feedUrl: _nullIfEmpty(_feedUrl.text),
      feedFormat: _feedFormat,
      feedAuthType: _feedAuthType,
      feedUsername: _nullIfEmpty(_feedUsername.text),
      feedLanguage: _nullIfEmpty(_feedLanguage.text),
      feedItemPath: _nullIfEmpty(_feedItemPath.text),
      apiBaseUrl: _nullIfEmpty(_apiBaseUrl.text),
      apiProductsPath: _nullIfEmpty(_apiProductsPath.text),
      apiAuthType: _apiAuthType,
      apiAuthHeaderName: _nullIfEmpty(_apiHeaderName.text),
      apiAuthQueryParam: _nullIfEmpty(_apiQueryParam.text),
      publicApiId: _nullIfEmpty(_publicApiId.text),
      apiItemsPath: _nullIfEmpty(_apiItemsPath.text),
      fieldMap: widget.existing?.fieldMap ?? const {},
      defaultCommissionRate:
          num.tryParse(_commissionRate.text.trim()) ?? 0,
      commissionType: _commissionType,
      syncEnabled: _syncEnabled,
      syncFrequency: _syncFrequency,
      status: widget.existing?.status ?? 'active',
    );
  }

  static String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final lang = AppLocalizations.of(context)!;
    try {
      final store = _buildStore();
      if (widget.existing == null) {
        await widget.repository.createStore(store);
      } else {
        await widget.repository.updateStore(widget.existing!.id, store);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        SnackbarService.error(
          context,
          e is StateError ? e.message : lang.affiliateFormSaveError,
        );
      }
    }
  }

  Future<void> _testConnection() async {
    final lang = AppLocalizations.of(context)!;
    if (_integrationType == AffiliateIntegrationType.manual) {
      _showResultDialog(
        title: lang.affiliateDataSourceRequired,
        body: lang.affiliateDataSourceRequiredBody,
        ok: false,
      );
      return;
    }
    if (!widget.repository.backendConfigured) {
      SnackbarService.warning(context, lang.affiliateBackendMissing);
      return;
    }
    setState(() => _testing = true);
    final store = _buildStore();
    final res = await widget.repository.testConnection(
      store.id,
      storeOverride: store.toWriteMap(),
    );
    if (!mounted) return;
    setState(() => _testing = false);

    if (res.ok) {
      _showResultDialog(
        title: lang.affiliateTestOkTitle,
        body: lang.affiliateTestOkBody(
          res.productsDetected?.toString() ?? '—',
          res.sampleCount,
        ),
        ok: true,
        sample: res.sample,
      );
    } else {
      _showResultDialog(
        title: res.errorCode == 'data_source_required'
            ? lang.affiliateDataSourceRequired
            : lang.affiliateTestFailTitle,
        body: res.errorMessage ?? lang.somethingWentWrongDesc,
        ok: false,
      );
    }
  }

  void _showResultDialog({
    required String title,
    required String body,
    required bool ok,
    List<Map<String, dynamic>> sample = const [],
  }) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          ok ? Icons.check_circle_rounded : Icons.error_rounded,
          color: ok ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            if (sample.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final p in sample.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '• ${p['name']}'
                    '${p['price'] != null ? ' — ${p['price']} ${p['currency'] ?? ''}' : ''}'
                    '${p['category'] != null ? ' (${p['category']})' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? lang.affiliateAddStore
              : lang.affiliateEditStore,
        ),
        actions: [
          // Always rendered so it is discoverable. Disabled (with a
          // tooltip) for Manual, which has no data source to test.
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Tooltip(
              message: _integrationType == AffiliateIntegrationType.manual
                  ? lang.affiliateTestManualTooltip
                  : lang.affiliateTestConnection,
              child: TextButton.icon(
                onPressed: (_testing ||
                        _integrationType == AffiliateIntegrationType.manual)
                    ? null
                    : _testConnection,
                icon: _testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering_rounded, size: 18),
                label: Text(_testing
                    ? lang.affiliateTesting
                    : lang.affiliateTestConnection),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle(lang.affiliateSectionBasic),
                    _field(_name, lang.affiliateFieldStoreName, required: true),
                    _field(_logoUrl, lang.affiliateFieldLogoUrl),
                    _field(_description, lang.affiliateFieldDescription,
                        maxLines: 2),
                    _field(_websiteUrl, lang.affiliateFieldWebsiteUrl,
                        keyboardType: TextInputType.url),
                    Row(
                      children: [
                        Expanded(child: _countryDropdown(lang)),
                        const SizedBox(width: 12),
                        Expanded(child: _currencyDropdown(lang)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _SectionTitle(lang.affiliateSectionAffiliate),
                    _field(_network, lang.affiliateFieldNetwork,
                        hint: 'awin'),
                    _field(_programId, lang.affiliateFieldProgramId),
                    _field(_affiliateId, lang.affiliateFieldAffiliateId),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _commissionRate,
                            lang.affiliateFieldDefaultCommission,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _commissionTypeDropdown(lang)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _SectionTitle(lang.affiliateSectionIntegration),
                    _integrationTypeDropdown(lang),
                    const SizedBox(height: 8),
                    ..._dynamicIntegrationFields(lang, theme),
                    const SizedBox(height: 20),

                    _SectionTitle(lang.affiliateSectionSync),
                    if (_integrationType == AffiliateIntegrationType.manual)
                      _NoteBox(lang.affiliateManualNoSync)
                    else ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(lang.affiliateFieldSyncEnabled),
                        value: _syncEnabled,
                        onChanged: (v) => setState(() => _syncEnabled = v),
                      ),
                      _syncFrequencyDropdown(lang),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.existing == null
                              ? lang.affiliateAddStore
                              : lang.affiliateEditStore),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _dynamicIntegrationFields(AppLocalizations lang, ThemeData theme) {
    switch (_integrationType) {
      case AffiliateIntegrationType.manual:
        return [_NoteBox(lang.affiliateManualNoSync)];

      case AffiliateIntegrationType.mock:
        return [_NoteBox(lang.affiliateMockNote)];

      case AffiliateIntegrationType.productFeed:
      case AffiliateIntegrationType.affiliateNetwork:
        return [
          if (_integrationType == AffiliateIntegrationType.affiliateNetwork)
            _NoteBox(
              _network.text.trim().toLowerCase() == 'awin'
                  ? 'Awin delivers products as a downloadable feed. The private feed URL is a backend secret (AWIN_FEED_URL / AFFILIATE_<SLUG>_FEED_URL).'
                  : 'Only Awin has a built-in connector today. Other networks need a connector added on the backend.',
            ),
          _field(_feedUrl, lang.affiliateFieldFeedUrl,
              hint: lang.affiliateFieldFeedUrlHint,
              keyboardType: TextInputType.url),
          _feedFormatDropdown(lang),
          _feedAuthDropdown(lang),
          if (_feedAuthType == 'basic')
            _field(_feedUsername, lang.affiliateFieldFeedUsername),
          _field(_feedLanguage, lang.affiliateFieldFeedLanguage, hint: 'en'),
          if (_feedFormat != AffiliateFeedFormat.csv)
            _field(_feedItemPath, 'Feed item path', hint: 'products.product'),
          _NoteBox(lang.affiliateSecretNote),
        ];

      case AffiliateIntegrationType.restApi:
        return [
          _field(_apiBaseUrl, lang.affiliateFieldApiBaseUrl,
              hint: 'https://api.example.com/v2',
              keyboardType: TextInputType.url),
          _field(_apiProductsPath, lang.affiliateFieldApiProductsPath,
              hint: '/products'),
          _apiAuthDropdown(lang),
          if (_apiAuthType == 'header')
            _field(_apiHeaderName, lang.affiliateFieldApiHeaderName),
          if (_apiAuthType == 'query')
            _field(_apiQueryParam, lang.affiliateFieldApiQueryParam),
          _field(_publicApiId, lang.affiliateFieldPublicApiId),
          _field(_apiItemsPath, lang.affiliateFieldApiItemsPath, hint: 'data'),
          _NoteBox(lang.affiliateSecretNote),
        ];
    }
  }

  // ---- small field helpers ----

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final lang = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? lang.affiliateRequired : null
            : null,
      ),
    );
  }

  Widget _countryDropdown(AppLocalizations lang) {
    return DropdownButtonFormField<String?>(
      initialValue: _country,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: lang.affiliateFieldCountry,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('—')),
        for (final c in widget.countries)
          DropdownMenuItem(value: c, child: Text(c)),
      ],
      onChanged: (v) => setState(() => _country = v),
    );
  }

  Widget _currencyDropdown(AppLocalizations lang) {
    final options = {
      _currency,
      ...widget.currencies,
      'USD',
      'GBP',
      'EUR',
    }.toList();
    return DropdownButtonFormField<String>(
      initialValue: _currency,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: lang.affiliateFieldCurrency,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final c in options) DropdownMenuItem(value: c, child: Text(c)),
      ],
      onChanged: (v) => setState(() => _currency = v ?? _currency),
    );
  }

  Widget _commissionTypeDropdown(AppLocalizations lang) {
    return DropdownButtonFormField<AffiliateCommissionType>(
      initialValue: _commissionType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: lang.affiliateFieldCommissionType,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: AffiliateCommissionType.percentage,
          child: Text(lang.affiliateCommissionPercentage),
        ),
        DropdownMenuItem(
          value: AffiliateCommissionType.fixed,
          child: Text(lang.affiliateCommissionFixed),
        ),
      ],
      onChanged: (v) =>
          setState(() => _commissionType = v ?? _commissionType),
    );
  }

  Widget _integrationTypeDropdown(AppLocalizations lang) {
    String label(AffiliateIntegrationType t) {
      switch (t) {
        case AffiliateIntegrationType.productFeed:
          return lang.affiliateIntegrationProductFeed;
        case AffiliateIntegrationType.restApi:
          return lang.affiliateIntegrationRestApi;
        case AffiliateIntegrationType.affiliateNetwork:
          return lang.affiliateIntegrationNetwork;
        case AffiliateIntegrationType.manual:
          return lang.affiliateIntegrationManual;
        case AffiliateIntegrationType.mock:
          return lang.affiliateIntegrationMock;
      }
    }

    return DropdownButtonFormField<AffiliateIntegrationType>(
      initialValue: _integrationType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: lang.affiliateFieldIntegrationType,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final t in AffiliateIntegrationType.values)
          DropdownMenuItem(value: t, child: Text(label(t))),
      ],
      onChanged: (v) =>
          setState(() => _integrationType = v ?? _integrationType),
    );
  }

  Widget _feedFormatDropdown(AppLocalizations lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<AffiliateFeedFormat>(
        initialValue: _feedFormat,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: lang.affiliateFieldFeedFormat,
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: AffiliateFeedFormat.csv, child: Text('CSV')),
          DropdownMenuItem(value: AffiliateFeedFormat.xml, child: Text('XML')),
          DropdownMenuItem(value: AffiliateFeedFormat.json, child: Text('JSON')),
        ],
        onChanged: (v) => setState(() => _feedFormat = v ?? _feedFormat),
      ),
    );
  }

  Widget _feedAuthDropdown(AppLocalizations lang) => _authDropdown(
        lang.affiliateFieldFeedAuth,
        _feedAuthType,
        const ['none', 'basic', 'bearer'],
        (v) => setState(() => _feedAuthType = v),
        lang,
      );

  Widget _apiAuthDropdown(AppLocalizations lang) => _authDropdown(
        lang.affiliateFieldApiAuth,
        _apiAuthType,
        const ['none', 'bearer', 'header', 'query'],
        (v) => setState(() => _apiAuthType = v),
        lang,
      );

  Widget _authDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
    AppLocalizations lang,
  ) {
    String text(String o) {
      switch (o) {
        case 'basic':
          return lang.affiliateAuthBasic;
        case 'bearer':
          return lang.affiliateAuthBearer;
        case 'header':
          return lang.affiliateAuthHeader;
        case 'query':
          return lang.affiliateAuthQuery;
        default:
          return lang.affiliateAuthNone;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final o in options)
            DropdownMenuItem(value: o, child: Text(text(o))),
        ],
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }

  Widget _syncFrequencyDropdown(AppLocalizations lang) {
    String text(AffiliateSyncFrequency f) {
      switch (f) {
        case AffiliateSyncFrequency.every6Hours:
          return lang.affiliateFreq6h;
        case AffiliateSyncFrequency.every12Hours:
          return lang.affiliateFreq12h;
        case AffiliateSyncFrequency.daily:
          return lang.affiliateFreqDaily;
        case AffiliateSyncFrequency.weekly:
          return lang.affiliateFreqWeekly;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<AffiliateSyncFrequency>(
        initialValue: _syncFrequency,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: lang.affiliateFieldSyncFrequency,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final f in AffiliateSyncFrequency.values)
            DropdownMenuItem(value: f, child: Text(text(f))),
        ],
        onChanged: (v) => setState(() => _syncFrequency = v ?? _syncFrequency),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String text;
  const _NoteBox(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
