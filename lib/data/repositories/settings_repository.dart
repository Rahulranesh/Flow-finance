import 'dart:convert';
import 'package:flutter/material.dart';
import '../database/database.dart' as db;

/// Repository for settings data operations
class SettingsRepository {
  final db.AppDatabase _database;

  SettingsRepository(this._database);

  /// Get string setting
  Future<String?> getString(String key) => _database.getSetting(key);

  /// Set string setting
  Future<void> setString(String key, String value) =>
      _database.setSetting(key, value);

  /// Get boolean setting
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await _database.getSetting(key);
    return value != null ? value.toLowerCase() == 'true' : defaultValue;
  }

  /// Set boolean setting
  Future<void> setBool(String key, bool value) =>
      _database.setSetting(key, value.toString());

  /// Get integer setting
  Future<int?> getInt(String key) async {
    final value = await _database.getSetting(key);
    return value != null ? int.tryParse(value) : null;
  }

  /// Set integer setting
  Future<void> setInt(String key, int value) =>
      _database.setSetting(key, value.toString());

  /// Get double setting
  Future<double?> getDouble(String key) async {
    final value = await _database.getSetting(key);
    return value != null ? double.tryParse(value) : null;
  }

  /// Set double setting
  Future<void> setDouble(String key, double value) =>
      _database.setSetting(key, value.toString());

  /// Delete setting
  Future<void> deleteSetting(String key) => _database.deleteSetting(key);

  // User Settings Helpers

  /// Get user name
  Future<String?> getUserName() => getString('user_name');

  /// Set user name
  Future<void> setUserName(String name) => setString('user_name', name);

  /// Get user email
  Future<String?> getUserEmail() => getString('user_email');

  /// Set user email
  Future<void> setUserEmail(String email) => setString('user_email', email);

  /// Get currency
  Future<String> getCurrency({String defaultCurrency = 'INR'}) async {
    return await getString('currency') ?? defaultCurrency;
  }

  /// Set currency
  Future<void> setCurrency(String currency) => setString('currency', currency);

  /// Get language
  Future<String> getLanguage({String defaultLanguage = 'en'}) async {
    return await getString('language') ?? defaultLanguage;
  }

  /// Set language
  Future<void> setLanguage(String language) => setString('language', language);

  /// Get theme mode
  Future<ThemeMode> getThemeMode(
      {ThemeMode defaultMode = ThemeMode.system}) async {
    final value = await getString('theme_mode');
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => defaultMode,
    );
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) =>
      setString('theme_mode', mode.name);

  /// Get notifications enabled
  Future<bool> getNotificationsEnabled({bool defaultValue = true}) async {
    return getBool('notifications_enabled', defaultValue: defaultValue);
  }

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) =>
      setBool('notifications_enabled', enabled);

  /// Get biometric enabled
  Future<bool> getBiometricEnabled({bool defaultValue = false}) async {
    return getBool('biometric_enabled', defaultValue: defaultValue);
  }

  /// Set biometric enabled
  Future<void> setBiometricEnabled(bool enabled) =>
      setBool('biometric_enabled', enabled);

  /// Export all settings as JSON
  Future<String> exportSettings() async {
    final settings = <String, dynamic>{
      'user_name': await getUserName(),
      'user_email': await getUserEmail(),
      'currency': await getCurrency(),
      'language': await getLanguage(),
      'theme_mode': (await getThemeMode()).name,
      'notifications_enabled': await getNotificationsEnabled(),
      'biometric_enabled': await getBiometricEnabled(),
    };
    return jsonEncode(settings);
  }

  /// Import settings from JSON
  Future<void> importSettings(String json) async {
    final settings = jsonDecode(json) as Map<String, dynamic>;

    if (settings['user_name'] != null) {
      await setUserName(settings['user_name'] as String);
    }
    if (settings['user_email'] != null) {
      await setUserEmail(settings['user_email'] as String);
    }
    if (settings['currency'] != null) {
      await setCurrency(settings['currency'] as String);
    }
    if (settings['language'] != null) {
      await setLanguage(settings['language'] as String);
    }
    if (settings['theme_mode'] != null) {
      await setThemeMode(ThemeMode.values.firstWhere(
        (e) => e.name == settings['theme_mode'],
        orElse: () => ThemeMode.system,
      ));
    }
    if (settings['notifications_enabled'] != null) {
      await setNotificationsEnabled(settings['notifications_enabled'] as bool);
    }
    if (settings['biometric_enabled'] != null) {
      await setBiometricEnabled(settings['biometric_enabled'] as bool);
    }
  }
}
