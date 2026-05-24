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
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      flag: '🇮🇳',
      decimalDigits: 2,
      exchangeRate: 83.0,
    ),
    Currency(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      flag: '🇺🇸',
      decimalDigits: 2,
      exchangeRate: 1.0,
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

  /// Get default currency (INR)
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
    this.defaultCurrencyCode = 'INR',
    this.enabledCurrencies = const ['INR', 'USD'],
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
      defaultCurrencyCode: json['defaultCurrencyCode'] as String? ?? 'INR',
      enabledCurrencies:
          (json['enabledCurrencies'] as List<dynamic>?)?.cast<String>() ??
              const ['INR', 'USD'],
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
