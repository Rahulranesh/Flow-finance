import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/bank_account.dart';
import '../../models/bank_transaction.dart';
import '../secure/token_manager.dart';

/// Plaid API integration service
/// 
/// Supports US, Canada, UK, and European banks
/// Requires Plaid account with valid API keys
class PlaidService {
  static final PlaidService _instance = PlaidService._internal();
  factory PlaidService() => _instance;
  PlaidService._internal();

  final TokenManager _tokenManager = TokenManager();
  String _baseUrl = '';
  
  // Configuration - Replace with your actual Plaid credentials
  String _clientId = '';
  String _secret = '';

  // Base URLs for different environments
  static const Map<PlaidEnvironment, String> _baseUrls = {
    PlaidEnvironment.sandbox: 'https://sandbox.plaid.com',
    PlaidEnvironment.development: 'https://development.plaid.com',
    PlaidEnvironment.production: 'https://production.plaid.com',
  };

  /// Initialize the service with credentials
  void initialize({
    required String clientId,
    required String secret,
    PlaidEnvironment environment = PlaidEnvironment.sandbox,
  }) {
    _clientId = clientId;
    _secret = secret;
   
    
    _baseUrl = _baseUrls[environment]!;
  }

  /// Check if service is initialized
  bool get isInitialized => _clientId.isNotEmpty && _secret.isNotEmpty;

  /// Create a Link token for connecting a bank account
  Future<String> createLinkToken({
    required String userId,
    required String clientName,
    List<String> products = const ['auth', 'transactions'],
    List<String> countryCodes = const ['US'],
    String language = 'en',
    String? webhook,
    String? linkCustomizationName,
    String? redirectUri,
    bool androidPackageName = false,
  }) async {
    _ensureInitialized();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/link/token/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'client_id': _clientId,
        'secret': _secret,
        'client_name': clientName,
        'products': products,
        'country_codes': countryCodes,
        'language': language,
        'user': {
          'client_user_id': userId,
        },
        if (webhook != null) 'webhook': webhook,
        if (linkCustomizationName != null) 
          'link_customization_name': linkCustomizationName,
        if (redirectUri != null) 'redirect_uri': redirectUri,
        if (androidPackageName) 'android_package_name': 'com.cashew.budget',
      }),
      );
      
      if (response.statusCode != 200) {
        throw PlaidException('HTTP ${response.statusCode}', response.body);
      }
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['link_token'] as String;
    } catch (e) {
      throw Exception('Failed to create link token: $e');
    }
  }

  /// Exchange public token for access token
  Future<String> exchangePublicToken(String publicToken) async {
    _ensureInitialized();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/item/public_token/exchange'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'client_id': _clientId,
        'secret': _secret,
        'public_token': publicToken,
      }),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['access_token'] as String;
    } catch (e) {
      throw Exception('Failed to exchange token: $e');
    }
  }

  /// Store access token securely
  Future<void> storeAccessToken(String userId, String accessToken) async {
    await _tokenManager.storeAccessToken(
      'plaid',
      userId,
      accessToken,
    );
  }

  /// Get stored access token
  Future<String?> getAccessToken(String userId) async {
    return await _tokenManager.getAccessToken('plaid', userId);
  }

  /// Get accounts for an access token
  Future<List<BankAccount>> getAccounts(
    String accessToken,
    String userId, {
    String? linkedWalletId,
  }) async {
    _ensureInitialized();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/accounts/get'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'client_id': _clientId,
        'secret': _secret,
        'access_token': accessToken,
      }),);
      
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final accounts = (responseData['accounts'] as List)
          .map((account) => _parsePlaidAccount(
            account as Map<String, dynamic>,
            userId,
            accessToken,
            linkedWalletId: linkedWalletId,
          ))
          .toList();
      
      return accounts;
    } catch (e) {
      throw Exception('Failed to get accounts: $e');
    }
  }

  /// Get account balances
  Future<Map<String, double>> getBalances(String accessToken) async {
    _ensureInitialized();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/accounts/balance/get'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'client_id': _clientId,
        'secret': _secret,
        'access_token': accessToken,
      }),
      );
      
      final balances = <String, double>{};
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      for (final account in responseData['accounts'] as List) {
        final id = account['account_id'] as String;
        final available = account['balances']['available'] as num?;
        balances[id] = available?.toDouble() ?? 0.0;
      }
      
      return balances;
    } catch (e) {
      throw Exception('Failed to get balances: $e');
    }
  }

  /// Get transactions for a date range
  Future<List<BankTransaction>> getTransactions({
    required String accessToken,
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
    int count = 100,
    int offset = 0,
  }) async {
    _ensureInitialized();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transactions/get'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'client_id': _clientId,
        'secret': _secret,
        'access_token': accessToken,
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
        'options': {
          'account_ids': [accountId],
          'count': count,
          'offset': offset,
        },
      }),
      );
      
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final transactions = (responseData['transactions'] as List)
          .map((tx) => BankTransaction.fromPlaid(
            tx as Map<String, dynamic>,
            accountId,
            'plaid',
          ))
          .toList();
      
      return transactions;
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  /// Get all transactions (handles pagination)
  Future<List<BankTransaction>> getAllTransactions({
    required String accessToken,
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final allTransactions = <BankTransaction>[];
    int offset = 0;
    const batchSize = 500;
    
    while (true) {
      final transactions = await getTransactions(
        accessToken: accessToken,
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
        count: batchSize,
        offset: offset,
      );
      
      if (transactions.isEmpty) break;
      
      allTransactions.addAll(transactions);
      
      if (transactions.length < batchSize) break;
      
      offset += batchSize;
    }
    
    return allTransactions;
  }

  /// Get institutions (banks) supported by Plaid
  Future<List<BankInstitution>> getInstitutions({
    String? countryCode,
    int count = 500,
    int offset = 0,
  }) async {
    _ensureInitialized();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/institutions/get'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'client_id': _clientId,
        'secret': _secret,
        'country_codes': countryCode != null ? [countryCode] : ['US', 'CA', 'GB', 'IE', 'FR', 'ES', 'NL'],
        'count': count,
        'offset': offset,
        'options': {
          'include_optional_metadata': true,
        },
      }),
      );
      
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return (responseData['institutions'] as List)
          .map((inst) => BankInstitution(
            id: inst['institution_id'] as String,
            name: inst['name'] as String,
            logo: inst['logo'] as String?,
            primaryColor: inst['primary_color'] as String?,
            url: inst['url'] as String?,
            countryCodes: (inst['country_codes'] as List).cast<String>(),
            supportedFeatures: (inst['products'] as List).cast<String>(),
          ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get institutions: $e');
    }
  }

  /// Search institutions by name
  Future<List<BankInstitution>> searchInstitutions(
    String query, {
    List<String> countryCodes = const ['US'],
  }) async {
    _ensureInitialized();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/institutions/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'client_id': _clientId,
        'secret': _secret,
        'query': query,
        'country_codes': countryCodes,
        'options': {
          'include_optional_metadata': true,
        },
      }),
      );
      
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return (responseData['institutions'] as List)
          .map((inst) => BankInstitution(
            id: inst['institution_id'] as String,
            name: inst['name'] as String,
            logo: inst['logo'] as String?,
            primaryColor: inst['primary_color'] as String?,
            url: inst['url'] as String?,
            countryCodes: (inst['country_codes'] as List).cast<String>(),
            supportedFeatures: (inst['products'] as List).cast<String>(),
          ))
          .toList();
    } catch (e) {
      throw Exception('Failed to search institutions: $e');
    }
  }

  /// Refresh transactions (for webhook updates)
  Future<void> refreshTransactions(String accessToken) async {
    _ensureInitialized();
    
    try {
      await http.post(
        Uri.parse('$_baseUrl/transactions/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'client_id': _clientId,
        'secret': _secret,
        'access_token': accessToken,
      }),
      );
    } catch (e) {
      throw Exception('Failed to refresh transactions: $e');
    }
  }

  /// Remove an item (disconnect bank)
  Future<void> removeItem(String accessToken) async {
    _ensureInitialized();
    
    try {
      await http.post(
        Uri.parse('$_baseUrl/item/remove'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
        'client_id': _clientId,
        'secret': _secret,
        'access_token': accessToken,
      }),
      );
    } catch (e) {
      throw Exception('Failed to remove item: $e');
    }
  }

  /// Handle webhook events
  PlaidWebhookPayload? parseWebhook(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return PlaidWebhookPayload.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing Plaid webhook: $e');
      return null;
    }
  }

  /// Process webhook payload
  Future<void> handleWebhook(PlaidWebhookPayload payload) async {
    switch (payload.webhookType) {
      case 'TRANSACTIONS':
        await _handleTransactionWebhook(payload);
        break;
      case 'ITEM':
        await _handleItemWebhook(payload);
        break;
      case 'INCOME':
        // Handle income verification webhooks
        break;
      default:
        debugPrint('Unhandled Plaid webhook type: ${payload.webhookType}');
    }
  }

  // Private methods

  void _ensureInitialized() {
    if (!isInitialized) {
      throw Exception('PlaidService not initialized. Call initialize() first.');
    }
  }

  BankAccount _parsePlaidAccount(
    Map<String, dynamic> data,
    String userId,
    String accessToken, {
    String? linkedWalletId,
  }) {
    return BankAccount(
      id: data['account_id'] as String,
      userId: userId,
      provider: 'plaid',
      providerAccountId: data['account_id'] as String,
      institutionId: data['institution_id'] as String? ?? 'unknown',
      institutionName: data['institution_name'] as String? ?? 'Unknown Bank',
      name: data['name'] as String,
      officialName: data['official_name'] as String?,
      type: _parseAccountType(data['type'] as String?),
      subtype: _parseAccountSubtype(data['subtype'] as String?),
      mask: data['mask'] as String? ?? '****',
      currentBalance: (data['balances']['current'] as num?)?.toDouble(),
      availableBalance: (data['balances']['available'] as num?)?.toDouble(),
      currency: data['balances']['iso_currency_code'] as String? ?? 'USD',
      limit: data['balances']['limit']?.toString(),
      createdAt: DateTime.now(),
      linkedWalletId: linkedWalletId,
      metadata: {'access_token': accessToken},
    );
  }

  BankAccountType _parseAccountType(String? type) {
    switch (type?.toLowerCase()) {
      case 'depository':
        return BankAccountType.depository;
      case 'credit':
        return BankAccountType.credit;
      case 'loan':
        return BankAccountType.loan;
      case 'investment':
        return BankAccountType.investment;
      default:
        return BankAccountType.other;
    }
  }

  BankAccountSubtype _parseAccountSubtype(String? subtype) {
    switch (subtype?.toLowerCase()) {
      case 'checking':
        return BankAccountSubtype.checking;
      case 'savings':
        return BankAccountSubtype.savings;
      case 'money market':
        return BankAccountSubtype.moneyMarket;
      case 'cd':
        return BankAccountSubtype.certificateOfDeposit;
      case 'credit card':
        return BankAccountSubtype.creditCard;
      case 'line of credit':
        return BankAccountSubtype.lineOfCredit;
      case 'mortgage':
        return BankAccountSubtype.mortgage;
      case 'auto':
        return BankAccountSubtype.auto;
      case 'student':
        return BankAccountSubtype.student;
      case 'personal':
        return BankAccountSubtype.personal;
      default:
        return BankAccountSubtype.other;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleTransactionWebhook(PlaidWebhookPayload payload) async {
    debugPrint('Processing transaction webhook: ${payload.webhookCode}');
    // Implementation would trigger sync for the affected item
  }

  Future<void> _handleItemWebhook(PlaidWebhookPayload payload) async {
    debugPrint('Processing item webhook: ${payload.webhookCode}');
    // Handle item errors, pending expiration, etc.
  }

}

enum PlaidEnvironment {
  sandbox,
  development,
  production,
}

/// Plaid webhook payload
class PlaidWebhookPayload {
  final String webhookType;
  final String webhookCode;
  final String itemId;
  final String? error;
  final int? newTransactions;
  final int? removedTransactions;
  final String? accountId;

  PlaidWebhookPayload({
    required this.webhookType,
    required this.webhookCode,
    required this.itemId,
    this.error,
    this.newTransactions,
    this.removedTransactions,
    this.accountId,
  });

  factory PlaidWebhookPayload.fromJson(Map<String, dynamic> json) {
    return PlaidWebhookPayload(
      webhookType: json['webhook_type'] as String,
      webhookCode: json['webhook_code'] as String,
      itemId: json['item_id'] as String,
      error: json['error']?.toString(),
      newTransactions: json['new_transactions'] as int?,
      removedTransactions: json['removed_transactions'] as int?,
      accountId: json['account_id'] as String?,
    );
  }
}

/// Plaid API exception
class PlaidException implements Exception {
  final String code;
  final String message;

  PlaidException(this.code, this.message);

  @override
  String toString() => 'PlaidException($code): $message';
}
