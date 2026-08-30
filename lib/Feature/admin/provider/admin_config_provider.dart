import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:rosivia/core/services/currency_service.dart';

import '../data/models/ai_config_model.dart';
import '../data/models/country_config_model.dart';
import '../data/models/currency_config_model.dart';
import '../data/repositories/admin_repository.dart';

/// Live view of the ROSIVA global config (`countries`, `currencies`,
/// `app_config/ai`) for the Admin panel, plus a ready-to-use
/// [CurrencyService] built from the current currency docs.
///
/// Scoped to the [AdminShell] subtree — the shopper app reads country
/// config through [RegionalPrefsProvider] instead.
class AdminConfigProvider extends ChangeNotifier {
  final AdminRepository _repo;

  AdminConfigProvider({AdminRepository? repository})
      : _repo = repository ?? AdminRepository() {
    _bind();
  }

  StreamSubscription<List<CountryConfig>>? _countriesSub;
  StreamSubscription<List<CurrencyConfig>>? _currenciesSub;
  StreamSubscription<AiConfig>? _aiSub;

  List<CountryConfig> _countries = const [];
  List<CurrencyConfig> _currencies = const [];
  AiConfig _aiConfig = AiConfig.fallback;
  bool _loadedOnce = false;
  Object? _error;

  List<CountryConfig> get countries => List.unmodifiable(_countries);
  List<CurrencyConfig> get currencies => List.unmodifiable(_currencies);
  AiConfig get aiConfig => _aiConfig;
  bool get loadedOnce => _loadedOnce;
  Object? get error => _error;

  AdminRepository get repository => _repo;

  CurrencyService get currencyService => CurrencyService(
        currencies: {for (final c in _currencies) c.code: c},
      );

  void _bind() {
    _countriesSub = _repo.watchCountries().listen(
      (list) {
        _countries = list;
        _loadedOnce = true;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e;
        notifyListeners();
      },
    );
    _currenciesSub = _repo.watchCurrencies().listen(
      (list) {
        _currencies = list;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e;
        notifyListeners();
      },
    );
    _aiSub = _repo.watchAiConfig().listen(
      (cfg) {
        _aiConfig = cfg;
        notifyListeners();
      },
      onError: (_) {
        // Fail-open: keep the last good (or fallback) AI config.
      },
    );
  }

  @override
  void dispose() {
    _countriesSub?.cancel();
    _currenciesSub?.cancel();
    _aiSub?.cancel();
    super.dispose();
  }
}
