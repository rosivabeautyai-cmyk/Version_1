import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/country_config_model.dart';
import '../../provider/admin_config_provider.dart';

/// Manage the `countries` collection — the source of truth the shopper
/// country picker reads instead of a hardcoded list.
class AdminCountriesScreen extends StatelessWidget {
  const AdminCountriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminConfigProvider(),
      child: const _AdminCountriesView(),
    );
  }
}

class _AdminCountriesView extends StatelessWidget {
  const _AdminCountriesView();

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final provider = context.watch<AdminConfigProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(lang.adminCountriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCountry(context, provider, null),
        icon: const Icon(Icons.add_rounded),
        label: Text(lang.adminAddCountry),
      ),
      body: SafeArea(
        child: !provider.loadedOnce
            ? const Center(child: CircularProgressIndicator())
            : provider.countries.isEmpty
                ? Center(child: Text(lang.adminNothingToShow))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(lang.adminCountriesSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      for (final c in provider.countries)
                        _CountryTile(
                          country: c,
                          onToggle: (v) => provider.repository
                              .setCountryEnabled(c.code, v)
                              .catchError((_) => _fail(context)),
                          onTap: () => _editCountry(context, provider, c),
                        ),
                    ],
                  ),
      ),
    );
  }

  static void _fail(BuildContext context) {
    SnackbarService.error(
        context, AppLocalizations.of(context)!.adminSaveFailed);
  }

  Future<void> _editCountry(
    BuildContext context,
    AdminConfigProvider provider,
    CountryConfig? existing,
  ) async {
    final lang = AppLocalizations.of(context)!;
    final code = TextEditingController(text: existing?.code ?? '');
    final nameEn = TextEditingController(text: existing?.nameEn ?? '');
    final nameAr = TextEditingController(text: existing?.nameAr ?? '');
    final currency =
        TextEditingController(text: existing?.currencyCode ?? 'USD');
    final sort =
        TextEditingController(text: (existing?.sortOrder ?? 999).toString());
    var enabled = existing?.enabled ?? true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: code,
                  enabled: existing == null,
                  textCapitalization: TextCapitalization.characters,
                  decoration:
                      InputDecoration(labelText: lang.adminCountryCode),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameEn,
                  decoration:
                      InputDecoration(labelText: lang.adminCountryNameEn),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameAr,
                  textDirection: TextDirection.rtl,
                  decoration:
                      InputDecoration(labelText: lang.adminCountryNameAr),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: currency,
                  textCapitalization: TextCapitalization.characters,
                  decoration:
                      InputDecoration(labelText: lang.adminFieldCurrency),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sort,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: lang.adminCountrySortOrder),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(lang.adminCountryEnabledDesc),
                  value: enabled,
                  onChanged: (v) => setSheet(() => enabled = v),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: Text(lang.adminSave),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved != true) return;
    final cc = code.text.trim().toUpperCase();
    if (cc.isEmpty) return;
    try {
      await provider.repository.upsertCountry(
        CountryConfig(
          code: cc,
          nameEn: nameEn.text.trim(),
          nameAr: nameAr.text.trim(),
          currencyCode: currency.text.trim().toUpperCase(),
          enabled: enabled,
          sortOrder: int.tryParse(sort.text.trim()) ?? 999,
        ),
      );
      if (context.mounted) {
        SnackbarService.success(context, lang.adminSaved);
      }
    } catch (_) {
      if (context.mounted) _fail(context);
    }
  }
}

class _CountryTile extends StatelessWidget {
  final CountryConfig country;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const _CountryTile({
    required this.country,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text('${country.code} · ${country.nameEn}'),
        subtitle: Text(country.currencyCode,
            style: theme.textTheme.bodySmall),
        trailing: Switch(value: country.enabled, onChanged: onToggle),
      ),
    );
  }
}
