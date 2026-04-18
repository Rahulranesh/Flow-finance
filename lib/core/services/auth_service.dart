import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';

/// Authentication result
class AuthResult {
  final bool success;
  final String? error;
  final AuthErrorType? errorType;

  AuthResult({
    required this.success,
    this.error,
    this.errorType,
  });

  factory AuthResult.success() => AuthResult(success: true);

  factory AuthResult.failure(String error, {AuthErrorType? type}) =>
      AuthResult(success: false, error: error, errorType: type);
}

/// Authentication error types
enum AuthErrorType {
  notAvailable,
  notEnrolled,
  passcodeNotSet,
  lockedOut,
  cancelled,
  unknown,
}

/// Service for handling biometric authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometrics
  Future<bool> isDeviceSupported() async {
    return await _localAuth.isDeviceSupported();
  }

  /// Check if biometrics are available
  Future<bool> canCheckBiometrics() async {
    return await _localAuth.canCheckBiometrics;
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  /// Check if biometrics are enrolled
  Future<bool> areBiometricsEnrolled() async {
    final available = await getAvailableBiometrics();
    return available.isNotEmpty;
  }

  /// Authenticate with biometrics
  Future<AuthResult> authenticateWithBiometrics({
    String localizedReason = 'Please authenticate to access Flow Finance',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final isAvailable = await canCheckBiometrics();
      if (!isAvailable) {
        return AuthResult.failure(
          'Biometric authentication is not available on this device',
          type: AuthErrorType.notAvailable,
        );
      }

      final isEnrolled = await areBiometricsEnrolled();
      if (!isEnrolled) {
        return AuthResult.failure(
          'No biometric credentials are enrolled',
          type: AuthErrorType.notEnrolled,
        );
      }

      final success = await _localAuth.authenticate(
        localizedReason: localizedReason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            cancelButton: 'Cancel',
            biometricHint: 'Verify your identity',
            biometricNotRecognized: 'Not recognized, try again',
            biometricRequiredTitle: 'Biometric authentication required',
            biometricSuccess: 'Authentication successful',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription: 'Please set up device credentials',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Please set up biometric authentication in Settings',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Please set up biometric authentication in Settings',
            lockOut: 'Please reenable biometric authentication',
          ),
        ],
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false,
        ),
      );

      if (success) {
        return AuthResult.success();
      } else {
        return AuthResult.failure(
          'Authentication failed',
          type: AuthErrorType.unknown,
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred: $e',
        type: AuthErrorType.unknown,
      );
    }
  }

  /// Authenticate with biometrics only (no device credentials)
  Future<AuthResult> authenticateWithBiometricsOnly({
    String localizedReason = 'Please authenticate to access Flow Finance',
  }) async {
    try {
      final isAvailable = await canCheckBiometrics();
      if (!isAvailable) {
        return AuthResult.failure(
          'Biometric authentication is not available',
          type: AuthErrorType.notAvailable,
        );
      }

      final success = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: false,
          biometricOnly: true,
        ),
      );

      if (success) {
        return AuthResult.success();
      } else {
        return AuthResult.failure(
          'Biometric authentication failed',
          type: AuthErrorType.unknown,
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred: $e',
        type: AuthErrorType.unknown,
      );
    }
  }

  /// Stop authentication
  Future<bool> stopAuthentication() async {
    return await _localAuth.stopAuthentication();
  }

  /// Handle platform exceptions
  AuthResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return AuthResult.failure(
          'Biometric authentication is not available',
          type: AuthErrorType.notAvailable,
        );
      case 'NotEnrolled':
        return AuthResult.failure(
          'No biometric credentials are enrolled',
          type: AuthErrorType.notEnrolled,
        );
      case 'PasscodeNotSet':
        return AuthResult.failure(
          'Passcode is not set on the device',
          type: AuthErrorType.passcodeNotSet,
        );
      case 'LockedOut':
        return AuthResult.failure(
          'Too many failed attempts. Please try again later.',
          type: AuthErrorType.lockedOut,
        );
      case 'UserCancel':
      case 'SystemCancel':
        return AuthResult.failure(
          'Authentication was cancelled',
          type: AuthErrorType.cancelled,
        );
      default:
        return AuthResult.failure(
          'Authentication error: ${e.message}',
          type: AuthErrorType.unknown,
        );
    }
  }
}

/// App lock manager
class AppLockManager {
  static final AppLockManager _instance = AppLockManager._internal();
  factory AppLockManager() => _instance;
  AppLockManager._internal();

  final AuthService _authService = AuthService();

  bool _isLocked = false;
  bool _isEnabled = false;
  DateTime? _lastActiveTime;
  Duration _lockTimeout = const Duration(minutes: 5);

  bool get isLocked => _isLocked;
  bool get isEnabled => _isEnabled;
  Duration get lockTimeout => _lockTimeout;

  /// Enable app lock
  Future<void> enable() async {
    final canAuthenticate = await _authService.canCheckBiometrics();
    final isEnrolled = await _authService.areBiometricsEnrolled();

    if (!canAuthenticate || !isEnrolled) {
      throw Exception('Biometric authentication is not available or enrolled');
    }

    _isEnabled = true;
  }

  /// Disable app lock
  void disable() {
    _isEnabled = false;
    _isLocked = false;
  }

  /// Set lock timeout
  void setLockTimeout(Duration timeout) {
    _lockTimeout = timeout;
  }

  /// Lock the app
  void lock() {
    if (_isEnabled) {
      _isLocked = true;
    }
  }

  /// Unlock the app
  void unlock() {
    _isLocked = false;
    _lastActiveTime = DateTime.now();
  }

  /// Try to unlock with biometrics
  Future<AuthResult> tryUnlock() async {
    if (!_isEnabled) {
      return AuthResult.success();
    }

    final result = await _authService.authenticateWithBiometrics(
      localizedReason: 'Unlock Flow Finance',
    );

    if (result.success) {
      unlock();
    }

    return result;
  }

  /// Check if app should be locked
  void checkLockStatus() {
    if (!_isEnabled || _isLocked) return;

    if (_lastActiveTime != null) {
      final inactiveDuration = DateTime.now().difference(_lastActiveTime!);
      if (inactiveDuration > _lockTimeout) {
        lock();
      }
    }
  }

  /// Update last active time
  void updateLastActiveTime() {
    _lastActiveTime = DateTime.now();
  }

  /// Handle app lifecycle change
  void handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        checkLockStatus();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        updateLastActiveTime();
        break;
      case AppLifecycleState.detached:
        lock();
        break;
    }
  }
}
