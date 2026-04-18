import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/currency_model.dart';

/// Service for managing currency exchange rates and conversions
class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'currency_exchange_rates';
  static const String _cacheTimeKey = 'currency_cache_time';
  static const Duration _cacheValidity = Duration(hours: 1);

  final SharedPreferences _prefs;

  CurrencyService(this._prefs);

  /// Get current exchange rates
  Future<ExchangeRateResponse> getExchangeRates([String baseCurrency = 'USD']) async {
    // Check cache first
    final cached = await _getCachedRates();
    if (cached != null && cached.baseCurrency == baseCurrency) {
      return cached;
    }

    // Fetch from API
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$baseCurrency'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final exchangeResponse = ExchangeRateResponse.fromJson(data);
        await _cacheRates(exchangeResponse);
        return exchangeResponse;
      } else {
        throw Exception('Failed to fetch exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      // Return cached rates if available, otherwise throw
      if (cached != null) {
        return cached;
      }
      throw Exception('Failed to fetch exchange rates: $e');
    }
  }

  /// Convert amount between currencies
  Future<double> convert(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return amount;

    final rates = await getExchangeRates(fromCurrency);
    final rate = rates.rates[toCurrency];

    if (rate == null) {
      throw Exception('Exchange rate not found for $toCurrency');
    }

    return amount * rate;
  }

  /// Get exchange rate between two currencies
  Future<double> getRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;

    final rates = await getExchangeRates(fromCurrency);
    final rate = rates.rates[toCurrency];

    if (rate == null) {
      throw Exception('Exchange rate not found for $toCurrency');
    }

    return rate;
  }

  /// Get all supported currencies with current rates
  Future<List<Currency>> getCurrenciesWithRates() async {
    final rates = await getExchangeRates('USD');

    return SupportedCurrencies.all.map((currency) {
      final rate = rates.rates[currency.code];
      if (rate != null) {
        return currency.copyWith(exchangeRate: rate);
      }
      return currency;
    }).toList();
  }

  /// Format amount with currency symbol
  String formatAmount(double amount, String currencyCode) {
    final currency = SupportedCurrencies.getByCode(currencyCode);
    if (currency != null) {
      return currency.format(amount);
    }
    return '$currencyCode ${amount.toStringAsFixed(2)}';
  }

  /// Convert and format amount
  Future<String> convertAndFormat(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    final converted = await convert(amount, fromCurrency, toCurrency);
    return formatAmount(converted, toCurrency);
  }

  /// Get currency by code
  Currency? getCurrency(String code) {
    return SupportedCurrencies.getByCode(code);
  }

  /// Get default currency
  Currency getDefaultCurrency() {
    final prefs = _getPreferences();
    return SupportedCurrencies.getByCode(prefs.defaultCurrencyCode) ??
        SupportedCurrencies.defaultCurrency;
  }

  /// Save currency preferences
  Future<void> savePreferences(CurrencyPreferences preferences) async {
    await _prefs.setString('currency_preferences', jsonEncode(preferences.toJson()));
  }

  /// Get currency preferences
  CurrencyPreferences getPreferences() {
    return _getPreferences();
  }

  CurrencyPreferences _getPreferences() {
    final json = _prefs.getString('currency_preferences');
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        return CurrencyPreferences.fromJson(decoded);
      } catch (e) {
        return const CurrencyPreferences();
      }
    }
    return const CurrencyPreferences();
  }

  /// Cache exchange rates
  Future<void> _cacheRates(ExchangeRateResponse rates) async {
    await _prefs.setString(_cacheKey, jsonEncode(rates.toJson()));
    await _prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached exchange rates if valid
  Future<ExchangeRateResponse?> _getCachedRates() async {
    final cachedJson = _prefs.getString(_cacheKey);
    final cachedTime = _prefs.getInt(_cacheTimeKey);

    if (cachedJson == null || cachedTime == null) return null;

    final cacheAge = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(cachedTime),
    );

    if (cacheAge > _cacheValidity) return null;

    try {
      final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
      return ExchangeRateResponse.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _prefs.remove(_cacheKey);
    await _prefs.remove(_cacheTimeKey);
  }

  /// Check if cache is valid
  bool isCacheValid() {
    final cachedTime = _prefs.getInt(_cacheTimeKey);
    if (cachedTime == null) return false;

    final cacheAge = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(cachedTime),
    );

    return cacheAge <= _cacheValidity;
  }

  /// Get last update time
  DateTime? getLastUpdateTime() {
    final cachedTime = _prefs.getInt(_cacheTimeKey);
    if (cachedTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(cachedTime);
  }
}

/// Extension for currency formatting
extension CurrencyFormatting on double {
  String toCurrency(String currencyCode) {
    final currency = SupportedCurrencies.getByCode(currencyCode);
    if (currency != null) {
      return currency.format(this);
    }
    return '$currencyCode ${toStringAsFixed(2)}';
  }
}
