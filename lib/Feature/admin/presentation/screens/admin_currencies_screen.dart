import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/currency_config_model.dart';
import '../../provider/admin_config_provider.dart';

/// Manage the `currencies` collection — display symbol + USD exchange
/// rate used only for the app's approximate "≈ X EGP" hint.
class AdminCurrenciesScreen extends StatelessWidget {
  const AdminCurrenciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminConfigProvider(),
      child: const _AdminCurrenciesView(),
    );
  }
}

class _AdminCurrenciesView extends StatelessWidget {
  const _AdminCurrenciesView();

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final provider = context.watch<AdminConfigProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(lang.adminCurrenciesTitle)),
      body: SafeArea(
        child: !provider.loadedOnce
            ? const Center(child: CircularProgressIndicator())
            : provider.currencies.isEmpty
                ? Center(child: Text(lang.adminNothingToShow))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(lang.adminCurrenciesSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      for (final c in provider.currencies)
                        _CurrencyTile(
                          currency: c,
                          onTap: () => _edit(context, provider, c),
                        ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    AdminConfigProvider provider,
    CurrencyConfig currency,
  ) async {
    final lang = AppLocalizations.of(context)!;
    final symbol = TextEditingController(text: currency.symbol);
    final rate = TextEditingController(
      text: currency.rateToUsd?.toString() ?? '',
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(currency.code,
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: symbol,
              decoration: InputDecoration(labelText: lang.adminCurrencySymbol),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: rate,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: lang.adminCurrencyRate,
                helperText: lang.adminCurrencyRateHint,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: Text(lang.adminSave),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    try {
      await provider.repository.upsertCurrency(
        currency.copyWith(symbol: symbol.text.trim()),
      );
      final parsed = double.tryParse(rate.text.trim());
      await provider.repository.setCurrencyRate(
        currency.code,
        rate.text.trim().isEmpty ? null : parsed,
      );
      if (context.mounted) SnackbarService.success(context, lang.adminSaved);
    } catch (_) {
      if (context.mounted) {
        SnackbarService.error(context, lang.adminSaveFailed);
      }
    }
  }
}

class _CurrencyTile extends StatelessWidget {
  final CurrencyConfig currency;
  final VoidCallback onTap;

  const _CurrencyTile({required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text(currency.symbol)),
        title: Text('${currency.code} · ${currency.nameEn}'),
        subtitle: Text(
          currency.hasRate
              ? '1 ${currency.code} ≈ ${currency.rateToUsd} USD'
              : lang.adminCurrencyNoRate,
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
