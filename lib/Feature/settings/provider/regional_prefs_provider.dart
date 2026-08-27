import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Persists the user's country and currency *preference* on-device.
///
/// This only stores what the user picked — it does not convert
/// product prices between currencies (that would require live
/// exchange-rate data this app doesn't have). Each product is shown
/// in the currency it was listed in.
class RegionalPrefsProvider extends ChangeNotifier {
  static const _countryKey = 'regional_country';
  static const _currencyKey = 'regional_currency';

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

  /// ISO 4217 currency codes offered in the picker.
  static const List<String> currencyCodes = [
    'USD',
    'EUR',
    'GBP',
    'EGP',
    'SAR',
    'AED',
    'QAR',
    'KWD',
    'JOD',
  ];

  String? _countryCode;
  String? _currencyCode;

  /// Null means "auto based on location" (the existing default).
  String? get countryCode => _countryCode;
  String? get currencyCode => _currencyCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _countryCode = prefs.getString(_countryKey);
    _currencyCode = prefs.getString(_currencyKey);
    notifyListeners();
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

  Future<void> setCurrency(String? code) async {
    _currencyCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_currencyKey);
    } else {
      await prefs.setString(_currencyKey, code);
    }
  }
}
