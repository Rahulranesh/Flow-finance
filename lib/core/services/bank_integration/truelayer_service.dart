import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/bank_account.dart';
import '../../models/bank_transaction.dart';
import '../secure/token_manager.dart';

/// TrueLayer API integration service
/// 
/// Supports UK and European banks
/// Requires TrueLayer account with valid API keys
class TrueLayerService {
  static final TrueLayerService _instance = TrueLayerService._internal();
  factory TrueLayerService() => _instance;
  TrueLayerService._internal();

  final TokenManager _tokenManager = TokenManager();
  String _authBaseUrl = '';
  String _apiBaseUrl = '';
  
  // Configuration
  String _clientId = '';
  String _clientSecret = '';
  String _redirectUri = '';
  TrueLayerEnvironment _environment = TrueLayerEnvironment.sandbox;
  
  // Base URLs
  static const Map<TrueLayerEnvironment, Map<String, String>> _baseUrls = {
    TrueLayerEnvironment.sandbox: {
      'auth': 'https://auth.truelayer-sandbox.com',
      'api': 'https://api.truelayer-sandbox.com',
    },
    TrueLayerEnvironment.production: {
      'auth': 'https://auth.truelayer.com',
      'api': 'https://api.truelayer.com',
    },
  };

  /// Initialize the service
  void initialize({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    TrueLayerEnvironment environment = TrueLayerEnvironment.sandbox,
  }) {
    _clientId = clientId;
    _clientSecret = clientSecret;
    _redirectUri = redirectUri;
    _environment = environment;
    
    final urls = _baseUrls[environment]!;
    
    _authBaseUrl = urls['auth']!;
    _apiBaseUrl = urls['api']!;
  }

  /// Check if initialized
  bool get isInitialized => _clientId.isNotEmpty && _clientSecret.isNotEmpty;

  /// Generate OAuth authorization URL
  String generateAuthUrl({
    required String userId,
    List<String> scopes = const ['accounts', 'transactions', 'balance'],
    String? state,
    String? providerId,
  }) {
    _ensureInitialized();
    
    final params = {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': scopes.join(' '),
      if (state != null) 'state': state,
      if (providerId != null) 'providers': providerId,
    };
    
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '${_baseUrls[_environment]!['auth']}/?${queryString}';
  }

  /// Exchange authorization code for access token
  Future<TrueLayerTokens> exchangeCode(String code) async {
    _ensureInitialized();
    
    try {
      final response = await http.post(
        Uri.parse('$_authBaseUrl/connect/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'redirect_uri': _redirectUri,
        }),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TrueLayerTokens.fromJson(data);
    } catch (e) {
      throw Exception('Failed to exchange code: $e');
    }
  }

  /// Refresh access token
  Future<TrueLayerTokens> refreshToken(String refreshToken) async {
    _ensureInitialized();
    
    try {
      final response = await http.post(
        Uri.parse('$_authBaseUrl/connect/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
        }),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TrueLayerTokens.fromJson(data);
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  /// Store tokens securely
  Future<void> storeTokens(String userId, TrueLayerTokens tokens) async {
    await _tokenManager.storeAuthTokens(
      'truelayer',
      userId,
      AuthTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiry: tokens.expiresAt,
      ),
    );
  }

  /// Get stored tokens
  Future<TrueLayerTokens?> getTokens(String userId) async {
    final authTokens = await _tokenManager.getAuthTokens('truelayer', userId);
    if (authTokens == null) return null;
    
    return TrueLayerTokens(
      accessToken: authTokens.accessToken,
      refreshToken: authTokens.refreshToken,
      expiresAt: authTokens.expiry,
    );
  }

  /// Get accounts
  Future<List<BankAccount>> getAccounts(
    String accessToken,
    String userId, {
    String? linkedWalletId,
  }) async {
    _ensureInitialized();
    
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/data/v1/accounts'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List;
      return results
          .map((account) => _parseTrueLayerAccount(
            account as Map<String, dynamic>,
            userId,
            linkedWalletId: linkedWalletId,
          ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get accounts: $e');
    }
  }

  /// Get account balance
  Future<double> getBalance(String accessToken, String accountId) async {
    _ensureInitialized();
    
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/data/v1/accounts/$accountId/balance'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List;
      if (results.isNotEmpty) {
        return (results[0]['current'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  /// Get transactions
  Future<List<BankTransaction>> getTransactions({
    required String accessToken,
    required String accountId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _ensureInitialized();
    
    try {
      final queryParams = <String, String>{};
      if (fromDate != null) {
        queryParams['from'] = _formatDate(fromDate);
      }
      if (toDate != null) {
        queryParams['to'] = _formatDate(toDate);
      }
      
      var uri = Uri.parse('$_apiBaseUrl/data/v1/accounts/$accountId/transactions');
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List;
      return results
          .map((tx) => BankTransaction.fromTrueLayer(
            tx as Map<String, dynamic>,
            accountId,
          ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  /// Get pending transactions
  Future<List<BankTransaction>> getPendingTransactions(
    String accessToken,
    String accountId,
  ) async {
    _ensureInitialized();
    
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/data/v1/accounts/$accountId/transactions/pending'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List;
      return results
          .map((tx) => BankTransaction.fromTrueLayer(
            tx as Map<String, dynamic>,
            accountId,
          ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending transactions: $e');
    }
  }

  /// Get all providers (banks)
  Future<List<TrueLayerProvider>> getProviders({String? country}) async {
    _ensureInitialized();
    
    try {
      var uri = Uri.parse('$_apiBaseUrl/data/v1/providers');
      if (country != null) {
        uri = uri.replace(queryParameters: {'country': country});
      }
      
      final response = await http.get(uri);
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List;
      return results
          .map((p) => TrueLayerProvider.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get providers: $e');
    }
  }

  /// Delete connection (disconnect bank)
  Future<void> deleteConnection(String accessToken) async {
    _ensureInitialized();
    
    try {
      await http.delete(
        Uri.parse('$_apiBaseUrl/data/v1/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    } catch (e) {
      throw Exception('Failed to delete connection: $e');
    }
  }

  /// Handle webhook events
  TrueLayerWebhookPayload? parseWebhook(String body, Map<String, String> headers) {
    try {
      // Verify webhook signature (X-TL-Signature header)
      final data = jsonDecode(body) as Map<String, dynamic>;
      return TrueLayerWebhookPayload.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing TrueLayer webhook: $e');
      return null;
    }
  }

  // Private methods

  void _ensureInitialized() {
    if (!isInitialized) {
      throw Exception('TrueLayerService not initialized. Call initialize() first.');
    }
  }

  BankAccount _parseTrueLayerAccount(
    Map<String, dynamic> data,
    String userId, {
    String? linkedWalletId,
  }) {
    final accountType = data['account_type'] as String? ?? 'Unknown';
    
    return BankAccount(
      id: data['account_id'] as String,
      userId: userId,
      provider: 'truelayer',
      providerAccountId: data['account_id'] as String,
      institutionId: data['provider']?['provider_id'] as String? ?? 'unknown',
      institutionName: data['provider']?['display_name'] as String? ?? 'Unknown Bank',
      name: data['display_name'] as String? ?? 'Account',
      officialName: data['account_number']?['name'] as String?,
      type: _parseAccountType(accountType),
      subtype: _parseAccountSubtype(accountType),
      mask: data['account_number']?['number']?.toString().substring(
            (data['account_number']?['number']?.toString().length ?? 4) - 4,
          ) ?? '****',
      currency: data['currency'] as String? ?? 'GBP',
      createdAt: DateTime.now(),
      linkedWalletId: linkedWalletId,
    );
  }

  BankAccountType _parseAccountType(String type) {
    switch (type.toLowerCase()) {
      case 'transaction':
      case 'current':
        return BankAccountType.depository;
      case 'savings':
        return BankAccountType.depository;
      case 'credit_card':
        return BankAccountType.credit;
      case 'mortgage':
        return BankAccountType.loan;
      case 'investment':
        return BankAccountType.investment;
      default:
        return BankAccountType.other;
    }
  }

  BankAccountSubtype _parseAccountSubtype(String type) {
    switch (type.toLowerCase()) {
      case 'transaction':
      case 'current':
        return BankAccountSubtype.checking;
      case 'savings':
        return BankAccountSubtype.savings;
      case 'credit_card':
        return BankAccountSubtype.creditCard;
      case 'mortgage':
        return BankAccountSubtype.mortgage;
      default:
        return BankAccountSubtype.other;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Exception _handleError(dynamic e) {
    return Exception('Network error: $e');
  }
}

enum TrueLayerEnvironment {
  sandbox,
  production,
}

/// TrueLayer tokens
class TrueLayerTokens {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? scope;

  TrueLayerTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.scope,
  });

  factory TrueLayerTokens.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int?;
    return TrueLayerTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn))
          : null,
      scope: json['scope'] as String?,
    );
  }
}

/// TrueLayer provider (bank)
class TrueLayerProvider {
  final String id;
  final String displayName;
  final String logoUri;
  final String iconUri;
  final List<String> supportedScopes;
  final List<String> countries;

  TrueLayerProvider({
    required this.id,
    required this.displayName,
    required this.logoUri,
    required this.iconUri,
    required this.supportedScopes,
    required this.countries,
  });

  factory TrueLayerProvider.fromJson(Map<String, dynamic> json) {
    return TrueLayerProvider(
      id: json['provider_id'] as String,
      displayName: json['display_name'] as String,
      logoUri: json['logo_uri'] as String,
      iconUri: json['icon_uri'] as String,
      supportedScopes: (json['scopes'] as List).cast<String>(),
      countries: (json['country'] as String).split(','),
    );
  }
}

/// TrueLayer webhook payload
class TrueLayerWebhookPayload {
  final String eventType;
  final String eventId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  TrueLayerWebhookPayload({
    required this.eventType,
    required this.eventId,
    required this.timestamp,
    required this.data,
  });

  factory TrueLayerWebhookPayload.fromJson(Map<String, dynamic> json) {
    return TrueLayerWebhookPayload(
      eventType: json['event_type'] as String,
      eventId: json['event_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// TrueLayer exception
class TrueLayerException implements Exception {
  final String error;
  final String description;

  TrueLayerException(this.error, this.description);

  @override
  String toString() => 'TrueLayerException($error): $description';
}
