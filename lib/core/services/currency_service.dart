import 'package:intl/intl.dart';

import 'package:rosivia/Feature/admin/data/models/currency_config_model.dart';

/// The one place currency is turned into text and (approximately)
/// converted. Never scatter `${currency} ${price}` or exchange-rate
/// math across widgets again.
///
/// Fed the Firestore-managed [CurrencyConfig] map (symbols + rates);
/// falls back to a small built-in symbol table so it still works
/// before that data loads or offline. Conversion returns `null` when a
/// rate is missing — callers must then show the listed price as-is
/// rather than guessing, because for an affiliate product the merchant
/// store is always the real source of truth for what a shopper pays.
class CurrencyService {
  final Map<String, CurrencyConfig> _byCode;

  CurrencyService({Map<String, CurrencyConfig> currencies = const {}})
      : _byCode = {
          for (final entry in currencies.entries)
            entry.key.toUpperCase(): entry.value,
        };

  static const Map<String, String> _fallbackSymbols = {
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'EGP': 'ج.م',
    'SAR': 'ر.س',
    'AED': 'د.إ',
    'QAR': 'ر.ق',
    'KWD': 'د.ك',
    'JOD': 'د.أ',
  };

  /// Currencies whose symbol goes *before* the amount with no space
  /// (`$12.00`, `£12.00`). Everything else renders `12.00 ج.م`.
  static const Set<String> _prefixSymbolCodes = {'USD', 'EUR', 'GBP'};

  CurrencyConfig? configFor(String code) => _byCode[code.toUpperCase()];

  String symbolFor(String code) {
    final upper = code.toUpperCase();
    return _byCode[upper]?.symbol ?? _fallbackSymbols[upper] ?? upper;
  }

  String _number(num amount, {int decimals = 2}) {
    final pattern = decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}';
    return NumberFormat(pattern).format(amount);
  }

  /// e.g. `"$25.00"`, `"1,300 ج.م"`. [decimals] 0 for whole-number
  /// approximate conversions.
  String format(num amount, String code, {int decimals = 2}) {
    final upper = code.toUpperCase();
    final n = _number(amount, decimals: decimals);
    final symbol = symbolFor(upper);
    if (_prefixSymbolCodes.contains(upper)) return '$symbol$n';
    return '$n $symbol';
  }

  /// Approximate conversion of [amount] [from] one currency [to]
  /// another via each currency's `rateToUsd`. Returns `null` if either
  /// currency has no rate, or the currencies are the same.
  double? convert(num amount, String from, String to) {
    final f = from.toUpperCase();
    final t = to.toUpperCase();
    if (f == t) return amount.toDouble();
    final fromRate = _byCode[f]?.rateToUsd;
    final toRate = _byCode[t]?.rateToUsd;
    if (fromRate == null || fromRate <= 0) return null;
    if (toRate == null || toRate <= 0) return null;
    return amount.toDouble() * fromRate / toRate;
  }

  /// e.g. `"≈ 1,300 EGP"`. Returns `null` when conversion is not
  /// possible or pointless (same currency). Uses the ISO code, not the
  /// symbol, so it reads clearly as an estimate.
  String? approx(num amount, String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return null;
    final converted = convert(amount, from, to);
    if (converted == null) return null;
    final decimals = converted >= 100 ? 0 : 2;
    return '≈ ${_number(converted, decimals: decimals)} ${to.toUpperCase()}';
  }
}
