import 'package:flutter/material.dart';
import '../../core/services/currency_formatter.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/settings_repository.dart';

/// App-wide settings controller backed by the settings repository.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  UserSettings _settings = const UserSettings();
  bool _isLoading = false;

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _settings.themeMode;
  String get currencyCode => _settings.currency;
  String get languageCode => _settings.language;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    final storedCurrency = await _repository.getCurrency();
    final storedLanguage = await _repository.getLanguage();

    _settings = UserSettings(
      currency: storedCurrency == 'USD' ? 'USD' : 'INR',
      language: storedLanguage == 'ta' ? 'ta' : 'en',
      themeMode: await _repository.getThemeMode(),
      notificationsEnabled: await _repository.getNotificationsEnabled(),
      biometricEnabled: await _repository.getBiometricEnabled(),
      userName: await _repository.getUserName(),
      userEmail: await _repository.getUserEmail(),
    );

    CurrencyFormatter.updateCurrency(_settings.currency);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
  }

  Future<void> updateCurrency(String currencyCode) async {
    final normalized = currencyCode == 'USD' ? 'USD' : 'INR';
    await _repository.setCurrency(normalized);
    CurrencyFormatter.updateCurrency(normalized);
    _settings = _settings.copyWith(currency: normalized);
    notifyListeners();
  }

  Future<void> updateLanguage(String languageCode) async {
    final normalized = languageCode == 'ta' ? 'ta' : 'en';
    await _repository.setLanguage(normalized);
    _settings = _settings.copyWith(language: normalized);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _repository.setNotificationsEnabled(enabled);
    if (enabled) {
      try {
        final notifications = NotificationService();
        await notifications.initialize();
        await notifications.requestPermissions();
        await notifications.scheduleDailyBudgetCheck();
        await notifications.scheduleWeeklySummary();
      } catch (_) {
        // Notification initialization may fail on some devices
      }
    } else {
      try {
        await NotificationService().cancelAllNotifications();
      } catch (_) {}
    }
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _repository.setBiometricEnabled(enabled);
    _settings = _settings.copyWith(biometricEnabled: enabled);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    await _repository.setUserName(name);
    await _repository.setUserEmail(email);
    _settings = _settings.copyWith(
      userName: name,
      userEmail: email,
    );
    notifyListeners();
  }
}
