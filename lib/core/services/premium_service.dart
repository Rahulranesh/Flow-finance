import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService extends ChangeNotifier {
  static const _premiumKey = 'is_premium';
  static const _planKey = 'premium_plan';
  static const _expiryKey = 'premium_expiry';

  static const String _monthlyId = 'com.flowfinance.premium.monthly';
  static const String _yearlyId = 'com.flowfinance.premium.yearly';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? _monthlyProduct;
  ProductDetails? _yearlyProduct;
  bool _isPremium = false;
  String? _currentPlan;
  DateTime? _expiryDate;
  bool _initialized = false;

  ProductDetails? get monthlyProduct => _monthlyProduct;
  ProductDetails? get yearlyProduct => _yearlyProduct;
  bool get isPremium => _isPremium;
  String? get currentPlan => _currentPlan;
  DateTime? get expiryDate => _expiryDate;
  String get monthlyId => _monthlyId;
  String get yearlyId => _yearlyId;
  bool get initialized => _initialized;

  List<ProductDetails> get availableProducts {
    return [_monthlyProduct, _yearlyProduct]
        .whereType<ProductDetails>()
        .toList();
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    _currentPlan = prefs.getString(_planKey);
    final expiryMs = prefs.getInt(_expiryKey);
    if (expiryMs != null) {
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryMs);
      if (_expiryDate!.isBefore(DateTime.now())) {
        await _setPremiumState(false, null, null);
      }
    }

    try {
      final available = await _iap.queryProductDetails({_monthlyId, _yearlyId});
      for (final product in available.productDetails) {
        if (product.id == _monthlyId) _monthlyProduct = product;
        if (product.id == _yearlyId) _yearlyProduct = product;
      }
    } catch (e) {
      debugPrint('Failed to query products: $e');
    }

    _initialized = true;
    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdates);
    notifyListeners();
    await _restorePurchases();
  }

  Future<void> _setPremiumState(bool premium, String? plan, DateTime? expiry) async {
    _isPremium = premium;
    _currentPlan = plan;
    _expiryDate = expiry;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, premium);
    if (plan != null) await prefs.setString(_planKey, plan);
    if (expiry != null) {
      await prefs.setInt(_expiryKey, expiry.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_expiryKey);
    }
    notifyListeners();
  }

  Future<void> purchaseMonthly() => _purchase(_monthlyId);
  Future<void> purchaseYearly() => _purchase(_yearlyId);

  Future<void> _purchase(String productId) async {
    final product = productId == _monthlyId ? _monthlyProduct : _yearlyProduct;
    if (product == null) return;

    final params = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: params);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> updates) async {
    for (final purchase in updates) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        final plan = purchase.productID == _monthlyId ? 'monthly' : 'yearly';
        await _setPremiumState(true, plan, null);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
      }
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _restorePurchases() async {
    await _iap.restorePurchases();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
