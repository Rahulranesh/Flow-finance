import 'dart:convert';
import 'encryption_service.dart';

// Stub for JwtDecoder
class JwtDecoder {
  static bool isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp;
    } catch (e) {
      return true;
    }
  }
  
  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid token');
    
    return jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map<String, dynamic>;
  }
}

/// Manager for secure storage and handling of API tokens
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accountName: 'flutter_tokens',
    ),
  );

  final EncryptionService _encryptionService = EncryptionService();

  static const String _tokenPrefix = 'token_';
  static const String _refreshTokenPrefix = 'refresh_token_';
  static const String _tokenExpiryPrefix = 'token_expiry_';

  /// Store access token securely
  Future<void> storeAccessToken(
    String provider,
    String userId,
    String token, {
    DateTime? expiry,
  }) async {
    final key = '$_tokenPrefix${provider}_$userId';
    
    // Encrypt token before storing
    final encryptionKey = await _encryptionService.getOrCreateEncryptionKey(userId);
    final encrypted = _encryptionService.encrypt(token, encryptionKey);
    
    await _secureStorage.write(key: key, value: encrypted);
    
    // Store expiry if provided
    if (expiry != null) {
      final expiryKey = '$_tokenExpiryPrefix${provider}_$userId';
      await _secureStorage.write(
        key: expiryKey,
        value: expiry.toIso8601String(),
      );
    }
  }

  /// Store refresh token securely
  Future<void> storeRefreshToken(
    String provider,
    String userId,
    String refreshToken,
  ) async {
    final key = '$_refreshTokenPrefix${provider}_$userId';
    
    final encryptionKey = await _encryptionService.getOrCreateEncryptionKey(userId);
    final encrypted = _encryptionService.encrypt(refreshToken, encryptionKey);
    
    await _secureStorage.write(key: key, value: encrypted);
  }

  /// Get access token
  Future<String?> getAccessToken(String provider, String userId) async {
    final key = '$_tokenPrefix${provider}_$userId';
    final encrypted = await _secureStorage.read(key: key);
    
    if (encrypted == null) return null;
    
    try {
      final encryptionKey = await _encryptionService.getOrCreateEncryptionKey(userId);
      return _encryptionService.decrypt(encrypted, encryptionKey);
    } catch (e) {
      // Token corrupted or key rotated
      await deleteToken(provider, userId);
      return null;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken(String provider, String userId) async {
    final key = '$_refreshTokenPrefix${provider}_$userId';
    final encrypted = await _secureStorage.read(key: key);
    
    if (encrypted == null) return null;
    
    try {
      final encryptionKey = await _encryptionService.getOrCreateEncryptionKey(userId);
      return _encryptionService.decrypt(encrypted, encryptionKey);
    } catch (e) {
      await deleteRefreshToken(provider, userId);
      return null;
    }
  }

  /// Check if token exists
  Future<bool> hasToken(String provider, String userId) async {
    final key = '$_tokenPrefix${provider}_$userId';
    final value = await _secureStorage.read(key: key);
    return value != null;
  }

  /// Check if token is expired
  Future<bool> isTokenExpired(String provider, String userId) async {
    final token = await getAccessToken(provider, userId);
    if (token == null) return true;

    // Check stored expiry first
    final expiryKey = '$_tokenExpiryPrefix${provider}_$userId';
    final expiryStr = await _secureStorage.read(key: expiryKey);
    
    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiry);
    }

    // Try to decode JWT if it's a JWT token
    try {
      if (JwtDecoder.isExpired(token)) {
        return true;
      }
      return false;
    } catch (e) {
      // Not a JWT, assume expired if no expiry stored
      return true;
    }
  }

  /// Get token expiry date
  Future<DateTime?> getTokenExpiry(String provider, String userId) async {
    final token = await getAccessToken(provider, userId);
    if (token == null) return null;

    // Check stored expiry
    final expiryKey = '$_tokenExpiryPrefix${provider}_$userId';
    final expiryStr = await _secureStorage.read(key: expiryKey);
    
    if (expiryStr != null) {
      return DateTime.parse(expiryStr);
    }

    // Try to decode JWT
    try {
      final decoded = JwtDecoder.decode(token);
      final exp = decoded['exp'];
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      }
    } catch (e) {
      // Not a JWT
    }

    return null;
  }

  /// Get time until token expiry
  Future<Duration?> getTimeUntilExpiry(String provider, String userId) async {
    final expiry = await getTokenExpiry(provider, userId);
    if (expiry == null) return null;
    
    final now = DateTime.now();
    if (expiry.isBefore(now)) return Duration.zero;
    
    return expiry.difference(now);
  }

  /// Delete access token
  Future<void> deleteToken(String provider, String userId) async {
    final key = '$_tokenPrefix${provider}_$userId';
    final expiryKey = '$_tokenExpiryPrefix${provider}_$userId';
    
    await _secureStorage.delete(key: key);
    await _secureStorage.delete(key: expiryKey);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken(String provider, String userId) async {
    final key = '$_refreshTokenPrefix${provider}_$userId';
    await _secureStorage.delete(key: key);
  }

  /// Delete all tokens for a provider
  Future<void> deleteAllTokensForProvider(String provider) async {
    final allKeys = await _secureStorage.readAll();
    
    for (final key in allKeys.keys) {
      if (key.contains('${provider}_')) {
        await _secureStorage.delete(key: key);
      }
    }
  }

  /// Delete all tokens for a user
  Future<void> deleteAllTokensForUser(String userId) async {
    final allKeys = await _secureStorage.readAll();
    
    for (final key in allKeys.keys) {
      if (key.endsWith('_$userId')) {
        await _secureStorage.delete(key: key);
      }
    }
  }

  /// Get all stored providers for a user
  Future<List<String>> getStoredProviders(String userId) async {
    final allKeys = await _secureStorage.readAll();
    final providers = <String>{};
    
    for (final key in allKeys.keys) {
      if (key.startsWith(_tokenPrefix) && key.endsWith('_$userId')) {
        final providerPart = key.substring(
          _tokenPrefix.length,
          key.lastIndexOf('_$userId'),
        );
        providers.add(providerPart);
      }
    }
    
    return providers.toList();
  }

  /// Store auth tokens bundle
  Future<void> storeAuthTokens(
    String provider,
    String userId,
    AuthTokens tokens,
  ) async {
    await storeAccessToken(
      provider,
      userId,
      tokens.accessToken,
      expiry: tokens.expiry,
    );
    
    if (tokens.refreshToken != null) {
      await storeRefreshToken(provider, userId, tokens.refreshToken!);
    }
  }

  /// Get auth tokens bundle
  Future<AuthTokens?> getAuthTokens(String provider, String userId) async {
    final accessToken = await getAccessToken(provider, userId);
    if (accessToken == null) return null;
    
    final refreshToken = await getRefreshToken(provider, userId);
    final expiry = await getTokenExpiry(provider, userId);
    
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiry: expiry,
    );
  }

  /// Clear all tokens (use with caution)
  Future<void> clearAllTokens() async {
    await _secureStorage.deleteAll();
  }
}

/// Auth tokens data class
class AuthTokens {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiry;

  AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiry,
  });

  /// Check if tokens are valid
  bool get isValid => accessToken.isNotEmpty;

  /// Check if token needs refresh
  bool get needsRefresh {
    if (expiry == null) return false;
    // Refresh if expires in less than 5 minutes
    return expiry!.difference(DateTime.now()).inMinutes < 5;
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiry': expiry?.toIso8601String(),
    };
  }

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiry: json['expiry'] != null
          ? DateTime.parse(json['expiry'] as String)
          : null,
    );
  }
}

/// Token refresh result
class TokenRefreshResult {
  final bool success;
  final String? newAccessToken;
  final String? error;
  final bool requiresReauth;

  TokenRefreshResult({
    required this.success,
    this.newAccessToken,
    this.error,
    this.requiresReauth = false,
  });
}
