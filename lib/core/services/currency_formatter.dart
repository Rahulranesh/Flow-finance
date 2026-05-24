import 'package:intl/intl.dart';
import '../../data/models/currency_model.dart';

/// Central currency formatter that follows the current app setting.
class CurrencyFormatter {
  CurrencyFormatter._();

  static String _currencyCode = SupportedCurrencies.defaultCurrency.code;

  static String get currentCurrencyCode => _currencyCode;

  static Currency get currentCurrency =>
      SupportedCurrencies.getByCode(_currencyCode) ??
      SupportedCurrencies.defaultCurrency;

  static void updateCurrency(String currencyCode) {
    _currencyCode = currencyCode.toUpperCase();
  }

  static String format(
    num amount, {
    String? currencyCode,
    String? symbol,
    int? decimalDigits,
  }) {
    final currency = SupportedCurrencies.getByCode(
          currencyCode ?? _currencyCode,
        ) ??
        SupportedCurrencies.defaultCurrency;

    return NumberFormat.currency(
      name: currency.code,
      symbol: symbol ?? currency.symbol,
      decimalDigits: decimalDigits ?? currency.decimalDigits,
    ).format(amount);
  }
}
