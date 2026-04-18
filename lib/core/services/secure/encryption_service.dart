import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

// Stub implementations for missing dependencies
class FlutterSecureStorage {
  final Map<String, String> _storage = {};
  
  FlutterSecureStorage({AndroidOptions? aOptions, IOSOptions? iOptions});
  
  Future<String?> read({required String key}) async => _storage[key];
  
  Future<void> write({required String key, required String? value}) async {
    if (value != null) _storage[key] = value;
  }
  
  Future<void> delete({required String key}) async => _storage.remove(key);
  
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_storage);
  
  Future<void> deleteAll() async => _storage.clear();
}

class AndroidOptions {
  final bool encryptedSharedPreferences;
  AndroidOptions({this.encryptedSharedPreferences = true});
}

class IOSOptions {
  final String? accountName;
  IOSOptions({this.accountName});
}

// Simple encryption stub using base64 (NOT for production)
class _Encrypter {
  final _Key key;
  _Encrypter(this.key);
  
  String encrypt(String data, _IV iv) {
    final combined = base64Encode(utf8.encode(data));
    return combined;
  }
  
  String decrypt(String encrypted, _IV iv) {
    return utf8.decode(base64Decode(encrypted));
  }
}

class _Key {
  final Uint8List bytes;
  _Key(this.bytes);
}

class _IV {
  final Uint8List bytes;
  _IV(this.bytes);
}

/// Service for encrypting and decrypting sensitive data
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accountName: 'flutter_encryption_key',
    ),
  );

  static const String _masterKeyPrefix = 'master_key_';
  static const String _credentialsPrefix = 'credentials_';

  /// Generate or retrieve the master encryption key for a user
  Future<String> getOrCreateEncryptionKey(String userId) async {
    final keyId = '$_masterKeyPrefix$userId';
    String? key = await _secureStorage.read(key: keyId);
    
    if (key == null) {
      // Generate a new 256-bit key
      final random = Random.secure();
      final keyBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        keyBytes[i] = random.nextInt(256);
      }
      key = base64Encode(keyBytes);
      await _secureStorage.write(key: keyId, value: key);
    }
    
    return key;
  }

  /// Generate a new encryption key
  String generateKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return base64Encode(keyBytes);
  }

  /// Encrypt data using AES-256-GCM
  String encrypt(String data, String key) {
    try {
      final keyBytes = base64Decode(key);
      final encKey = _Key(keyBytes);
      
      // Generate random IV
      final random = Random.secure();
      final ivBytes = Uint8List(16);
      for (int i = 0; i < 16; i++) {
        ivBytes[i] = random.nextInt(256);
      }
      final iv = _IV(ivBytes);
      
      final encrypter = _Encrypter(encKey);
      final encrypted = encrypter.encrypt(data, iv);
      
      // Combine IV + encrypted data
      final combined = base64Encode(ivBytes) + '.' + encrypted;
      
      return combined;
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  /// Decrypt data using AES-256-GCM
  String decrypt(String encryptedData, String key) {
    try {
      final keyBytes = base64Decode(key);
      final encKey = _Key(keyBytes);
      
      final parts = encryptedData.split('.');
      if (parts.length != 2) throw Exception('Invalid encrypted data');
      
      final ivBytes = base64Decode(parts[0]);
      final encrypted = parts[1];
      
      final iv = _IV(Uint8List.fromList(ivBytes));
      
      final encrypter = _Encrypter(encKey);
      return encrypter.decrypt(encrypted, iv);
    } catch (e) {
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Hash data using SHA-256
  String hash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash data with salt
  String hashWithSalt(String data, String salt) {
    final combined = utf8.encode(data + salt);
    final digest = sha256.convert(combined);
    return digest.toString();
  }

  /// Generate a secure random salt
  String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64Encode(saltBytes);
  }

  /// Store encrypted credentials securely
  Future<void> storeCredentials(
    String keyId,
    Map<String, String> credentials,
    String userId,
  ) async {
    try {
      final encryptionKey = await getOrCreateEncryptionKey(userId);
      final jsonData = jsonEncode(credentials);
      final encrypted = encrypt(jsonData, encryptionKey);
      
      await _secureStorage.write(
        key: '$_credentialsPrefix$keyId',
        value: encrypted,
      );
    } catch (e) {
      throw EncryptionException('Failed to store credentials: $e');
    }
  }

  /// Retrieve and decrypt credentials
  Future<Map<String, String>?> getCredentials(
    String keyId,
    String userId,
  ) async {
    try {
      final encrypted = await _secureStorage.read(
        key: '$_credentialsPrefix$keyId',
      );
      
      if (encrypted == null) return null;
      
      final encryptionKey = await getOrCreateEncryptionKey(userId);
      final decrypted = decrypt(encrypted, encryptionKey);
      final jsonData = jsonDecode(decrypted) as Map<String, dynamic>;
      
      return jsonData.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      throw EncryptionException('Failed to retrieve credentials: $e');
    }
  }

  /// Delete stored credentials
  Future<void> deleteCredentials(String keyId) async {
    await _secureStorage.delete(key: '$_credentialsPrefix$keyId');
  }

  /// Check if credentials exist
  Future<bool> hasCredentials(String keyId) async {
    final value = await _secureStorage.read(key: '$_credentialsPrefix$keyId');
    return value != null;
  }

  /// Delete all credentials for a user
  Future<void> deleteAllCredentials(String userId) async {
    await _secureStorage.delete(key: '$_masterKeyPrefix$userId');
    
    // Delete all credentials with this user prefix
    final allKeys = await _secureStorage.readAll();
    for (final key in allKeys.keys) {
      if (key.startsWith(_credentialsPrefix)) {
        await _secureStorage.delete(key: key);
      }
    }
  }

  /// Rotate encryption key
  Future<void> rotateKey(String userId) async {
    final oldKey = await getOrCreateEncryptionKey(userId);
    final newKey = generateKey();
    
    // Re-encrypt all credentials with new key
    final allKeys = await _secureStorage.readAll();
    for (final entry in allKeys.entries) {
      if (entry.key.startsWith(_credentialsPrefix)) {
        try {
          final decrypted = decrypt(entry.value, oldKey);
          final reEncrypted = encrypt(decrypted, newKey);
          await _secureStorage.write(key: entry.key, value: reEncrypted);
        } catch (e) {
          // Skip credentials that can't be decrypted
          continue;
        }
      }
    }
    
    // Store new master key
    await _secureStorage.write(key: '$_masterKeyPrefix$userId', value: newKey);
  }

  /// Securely wipe all encryption data
  Future<void> secureWipe() async {
    await _secureStorage.deleteAll();
  }
}

/// Exception for encryption errors
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}

/// Extension for secure string operations
extension SecureStringExtension on String {
  /// Mask sensitive data (show only last 4 characters)
  String mask() {
    if (length <= 4) return '*' * length;
    return '${'*' * (length - 4)}${substring(length - 4)}';
  }

  /// Mask completely
  String maskAll() => '*' * length;
}
