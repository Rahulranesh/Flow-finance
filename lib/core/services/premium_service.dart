import 'dart:async';
import 'package:flutter/foundation.dart';

class PremiumService extends ChangeNotifier {
  static const String _monthlyId = 'com.flowfinance.premium.monthly';
  static const String _yearlyId = 'com.flowfinance.premium.yearly';

  bool _initialized = false;

  bool get isPremium => true;
  String? get currentPlan => 'pro_unlocked';
  DateTime? get expiryDate => null;
  String get monthlyId => _monthlyId;
  String get yearlyId => _yearlyId;
  dynamic get monthlyProduct => null;
  dynamic get yearlyProduct => null;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    notifyListeners();
  }

  Future<void> purchaseMonthly() async {}
  Future<void> purchaseYearly() async {}
  Future<void> restorePurchases() async {}
}
