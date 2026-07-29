import 'package:flutter/foundation.dart';
import '../../core/services/premium_service.dart';

class PremiumController extends ChangeNotifier {
  final PremiumService _service;

  PremiumController(this._service) {
    _service.addListener(_onServiceChanged);
    _service.initialize();
  }

  PremiumService get service => _service;
  bool get isPremium => _service.isPremium;
  String? get currentPlan => _service.currentPlan;
  String? get monthlyPrice => _service.monthlyProduct?.price;
  String? get yearlyPrice => _service.yearlyProduct?.price;
  bool get initialized => _service.initialized;

  void _onServiceChanged() {
    notifyListeners();
  }

  Future<void> purchaseMonthly() async {
    await _service.purchaseMonthly();
  }

  Future<void> purchaseYearly() async {
    await _service.purchaseYearly();
  }

  Future<void> restorePurchases() async {
    await _service.restorePurchases();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }
}
