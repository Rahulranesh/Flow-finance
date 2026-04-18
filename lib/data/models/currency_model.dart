import 'package:flutter/material.dart';

/// Currency model representing a currency with exchange rate
@immutable
class Currency {
  final String code;
  final String name;
  final String symbol;
  final String? flag;
  final int decimalDigits;
  final double exchangeRate; // Rate relative to base currency (USD)

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    this.flag,
    this.decimalDigits = 2,
    this.exchangeRate = 1.0,
  });

  /// Convert amount from this currency to target currency
  double convertTo(double amount, Currency targetCurrency) {
    final inBase = amount / exchangeRate;
    return inBase * targetCurrency.exchangeRate;
  }

  /// Convert amount from base currency to this currency
  double convertFromBase(double baseAmount) {
    return baseAmount * exchangeRate;
  }

  /// Format amount with currency symbol
  String format(double amount) {
    return '$symbol${amount.toStringAsFixed(decimalDigits)}';
  }

  /// Create copy with new exchange rate
  Currency copyWith({
    String? code,
    String? name,
    String? symbol,
    String? flag,
    int? decimalDigits,
    double? exchangeRate,
  }) {
    return Currency(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      flag: flag ?? this.flag,
      decimalDigits: decimalDigits ?? this.decimalDigits,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Currency($code - $name)';
}

/// Predefined list of supported currencies
class SupportedCurrencies {
  static const List<Currency> all = [
    Currency(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      flag: '🇺🇸',
      decimalDigits: 2,
      exchangeRate: 1.0,
    ),
    Currency(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      flag: '🇪🇺',
      decimalDigits: 2,
      exchangeRate: 0.92,
    ),
    Currency(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      flag: '🇬🇧',
      decimalDigits: 2,
      exchangeRate: 0.79,
    ),
    Currency(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      flag: '🇯🇵',
      decimalDigits: 0,
      exchangeRate: 150.0,
    ),
    Currency(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      flag: '🇨🇦',
      decimalDigits: 2,
      exchangeRate: 1.35,
    ),
    Currency(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      flag: '🇦🇺',
      decimalDigits: 2,
      exchangeRate: 1.52,
    ),
    Currency(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'Fr',
      flag: '🇨🇭',
      decimalDigits: 2,
      exchangeRate: 0.88,
    ),
    Currency(
      code: 'CNY',
      name: 'Chinese Yuan',
      symbol: '¥',
      flag: '🇨🇳',
      decimalDigits: 2,
      exchangeRate: 7.19,
    ),
    Currency(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      flag: '🇮🇳',
      decimalDigits: 2,
      exchangeRate: 83.0,
    ),
    Currency(
      code: 'SGD',
      name: 'Singapore Dollar',
      symbol: 'S\$',
      flag: '🇸🇬',
      decimalDigits: 2,
      exchangeRate: 1.34,
    ),
    Currency(
      code: 'AED',
      name: 'UAE Dirham',
      symbol: 'د.إ',
      flag: '🇦🇪',
      decimalDigits: 2,
      exchangeRate: 3.67,
    ),
    Currency(
      code: 'SAR',
      name: 'Saudi Riyal',
      symbol: '﷼',
      flag: '🇸🇦',
      decimalDigits: 2,
      exchangeRate: 3.75,
    ),
  ];

  /// Get currency by code
  static Currency? getByCode(String code) {
    try {
      return all.firstWhere((c) => c.code == code.toUpperCase());
    } catch (e) {
      return null;
    }
  }

  /// Get default currency (USD)
  static Currency get defaultCurrency => all.first;

  /// Get currency codes list
  static List<String> get codes => all.map((c) => c.code).toList();
}

/// Currency exchange rate response
class ExchangeRateResponse {
  final String baseCurrency;
  final DateTime date;
  final Map<String, double> rates;

  const ExchangeRateResponse({
    required this.baseCurrency,
    required this.date,
    required this.rates,
  });

  factory ExchangeRateResponse.fromJson(Map<String, dynamic> json) {
    return ExchangeRateResponse(
      baseCurrency: json['base'] as String,
      date: DateTime.parse(json['date'] as String),
      rates: (json['rates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base': baseCurrency,
      'date': date.toIso8601String(),
      'rates': rates,
    };
  }
}

/// User currency preferences
class CurrencyPreferences {
  final String defaultCurrencyCode;
  final List<String> enabledCurrencies;
  final bool showConvertedAmounts;

  const CurrencyPreferences({
    this.defaultCurrencyCode = 'USD',
    this.enabledCurrencies = const ['USD'],
    this.showConvertedAmounts = true,
  });

  CurrencyPreferences copyWith({
    String? defaultCurrencyCode,
    List<String>? enabledCurrencies,
    bool? showConvertedAmounts,
  }) {
    return CurrencyPreferences(
      defaultCurrencyCode: defaultCurrencyCode ?? this.defaultCurrencyCode,
      enabledCurrencies: enabledCurrencies ?? this.enabledCurrencies,
      showConvertedAmounts: showConvertedAmounts ?? this.showConvertedAmounts,
    );
  }

  factory CurrencyPreferences.fromJson(Map<String, dynamic> json) {
    return CurrencyPreferences(
      defaultCurrencyCode: json['defaultCurrencyCode'] as String? ?? 'USD',
      enabledCurrencies: (json['enabledCurrencies'] as List<dynamic>?)
              ?.cast<String>() ??
          const ['USD'],
      showConvertedAmounts: json['showConvertedAmounts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultCurrencyCode': defaultCurrencyCode,
      'enabledCurrencies': enabledCurrencies,
      'showConvertedAmounts': showConvertedAmounts,
    };
  }
}
