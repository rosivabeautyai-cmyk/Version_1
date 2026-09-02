import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rosivia/Feature/admin/data/models/country_config_model.dart';
import 'package:rosivia/Feature/admin/data/models/currency_config_model.dart';
import 'package:rosivia/core/services/currency_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

/// Localized display name for a country code from [RegionalPrefsProvider.countryCodes].
String regionalCountryName(AppLocalizations lang, String code) {
  switch (code) {
    case 'EG':
      return lang.countryEgypt;
    case 'SA':
      return lang.countrySaudiArabia;
    case 'AE':
      return lang.countryUae;
    case 'US':
      return lang.countryUsa;
    case 'GB':
      return lang.countryUnitedKingdom;
    case 'QA':
      return lang.countryQatar;
    case 'KW':
      return lang.countryKuwait;
    case 'JO':
      return lang.countryJordan;
    default:
      return code;
  }
}

/// Single source of truth for country -> currency. The user picks a
/// country; the currency is *derived* from it, never picked
/// independently — a country always determines its own currency, so
/// offering a separate currency picker would just let the two
/// disagree with each other for no reason.
const Map<String, String> kCountryToCurrency = {
  'EG': 'EGP',
  'SA': 'SAR',
  'AE': 'AED',
  'US': 'USD',
  'GB': 'GBP',
  'QA': 'QAR',
  'KW': 'KWD',
  'JO': 'JOD',
};

/// App-wide provider for the shopper's regional preference.
///
/// Persists the chosen country on-device and derives the currency from
/// it. Also loads the Firestore-managed `countries` / `currencies`
/// config (best-effort, hardcoded fallback) so product prices can be
/// shown with the right symbol and an optional approximate conversion.
///
/// It does NOT convert affiliate prices for real — a per-country offer
/// (`ProductModel.offerFor`) is always used verbatim when present; the
/// approximate conversion is only ever a labelled estimate.
class RegionalPrefsProvider extends ChangeNotifier {
  static const _countryKey = 'regional_country';

  /// ISO country codes, ordered to match the picker list.
  static const List<String> countryCodes = [
    'EG',
    'SA',
    'AE',
    'US',
    'GB',
    'QA',
    'KW',
    'JO',
  ];

  String? _countryCode;
  String? _deviceCountry;
  List<CountryConfig> _remoteCountries = const [];
  Map<String, CurrencyConfig> _currencies = const {};

  /// The user's EXPLICIT choice. Null means "auto" — country offers and
  /// the affiliate checkout URL only ever use this (never the inferred
  /// value), so a device-region guess can never change what a shopper
  /// is charged.
  String? get countryCode => _countryCode;

  /// The country used for CURRENCY DISPLAY only: the explicit choice,
  /// else the device's OS region when it maps to a supported country,
  /// else null (prices then show in their original currency).
  String? get effectiveCountryCode => _countryCode ?? _deviceCountry;

  /// True when the effective country came from the device region rather
  /// than an explicit pick — for the Settings "Auto" row.
  bool get countryIsInferred => _countryCode == null && _deviceCountry != null;

  /// The device OS region, if it maps to one of the supported
  /// countries. Read once at [load]; safe (no permission, offline).
  static String? _inferDeviceCountry() {
    try {
      for (final loc in WidgetsBinding.instance.platformDispatcher.locales) {
        final cc = loc.countryCode?.toUpperCase();
        if (cc != null && kCountryToCurrency.containsKey(cc)) return cc;
      }
    } catch (_) {
      // headless / test context — no binding
    }
    return null;
  }

  List<String> get resolvedCountryCodes => _remoteCountries.isNotEmpty
      ? _remoteCountries.map((c) => c.code).toList()
      : countryCodes;

  /// Enabled countries as full config objects (for admin-agnostic UI).
  List<CountryConfig> get countries => _remoteCountries;

  String? get currencyCode {
    final code = effectiveCountryCode;
    if (code == null) return null;
    for (final c in _remoteCountries) {
      if (c.code == code && c.currencyCode.isNotEmpty) {
        return c.currencyCode;
      }
    }
    return kCountryToCurrency[code];
  }

  /// Ready-to-use formatter/converter backed by the loaded `currencies`
  /// config (falls back to built-in symbols when the config is absent).
  CurrencyService get currencyService =>
      CurrencyService(currencies: _currencies);

  String countryName(AppLocalizations lang, String code) {
    for (final c in _remoteCountries) {
      if (c.code == code) {
        return c.name(lang.localeName.startsWith('ar') ? 'ar' : 'en');
      }
    }
    return regionalCountryName(lang, code);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _countryCode = prefs.getString(_countryKey);
    _deviceCountry = _inferDeviceCountry();
    notifyListeners();
    await _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('countries')
            .where('enabled', isEqualTo: true)
            .get(),
        FirebaseFirestore.instance.collection('currencies').get(),
      ]);
      final countrySnap = results[0];
      final currencySnap = results[1];

      final list = countrySnap.docs.map(CountryConfig.fromDoc).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (list.isNotEmpty) _remoteCountries = list;

      final currencies = <String, CurrencyConfig>{
        for (final d in currencySnap.docs)
          CurrencyConfig.fromDoc(d).code: CurrencyConfig.fromDoc(d),
      };
      if (currencies.isNotEmpty) _currencies = currencies;

      if (list.isNotEmpty || currencies.isNotEmpty) notifyListeners();
    } catch (_) {
      // keep hardcoded fallbacks
    }
  }

  /// Reads the persisted country/currency preference without a live
  /// provider — used by the AI chat flow for backend regional context.
  static Future<({String? country, String? currency})> readPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_countryKey);
    return (
      country: code,
      currency: code == null ? null : kCountryToCurrency[code],
    );
  }

  Future<void> setCountry(String? code) async {
    _countryCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_countryKey);
    } else {
      await prefs.setString(_countryKey, code);
    }
  }
}
