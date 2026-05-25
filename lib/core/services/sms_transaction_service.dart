import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import '../../data/models/transaction_model.dart';

/// Service for parsing SMS messages and extracting transaction data
class SmsTransactionService {
  final Telephony telephony = Telephony.instance;

  /// Request SMS permissions
  Future<bool> requestPermissions() async {
    try {
      final bool? result = await telephony.requestPhoneAndSmsPermissions;
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting SMS permissions: $e');
      return false;
    }
  }

  /// Check if SMS permissions are granted
  Future<bool> hasPermissions() async {
    try {
      // Try to get inbox messages to check permission
      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ID],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      return messages.isNotEmpty || true; // If no error, we have permission
    } catch (e) {
      return false;
    }
  }

  /// Get all SMS messages from inbox
  Future<List<SmsMessage>> getAllSms({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final messages = await telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      // Filter by date range if provided
      var filteredMessages = messages;
      
      if (startDate != null || endDate != null) {
        filteredMessages = messages.where((msg) {
          if (msg.date == null) return false;
          final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date!);
          
          if (startDate != null && msgDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && msgDate.isAfter(endDate.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        }).toList();
      }

      if (limit != null && filteredMessages.length > limit) {
        return filteredMessages.sublist(0, limit);
      }

      return filteredMessages;
    } catch (e) {
      debugPrint('Error getting SMS messages: $e');
      return [];
    }
  }

  /// Parse SMS messages and extract transactions
  Future<List<Transaction>> parseTransactions({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final messages = await getAllSms(
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
    final transactions = <Transaction>[];

    for (final message in messages) {
      final transaction = _parseMessage(message);
      if (transaction != null) {
        // Additional date filtering if needed
        if (startDate != null && transaction.date.isBefore(startDate)) {
          continue;
        }
        if (endDate != null && transaction.date.isAfter(endDate.add(const Duration(days: 1)))) {
          continue;
        }
        transactions.add(transaction);
      }
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Parse a Google Pay message using the same India-first heuristics.
  Transaction? parseGooglePayMessage(SmsMessage message) {
    return _parseMessage(message, forceGooglePay: true);
  }

  /// Parse a single SMS message into a transaction
  Transaction? _parseMessage(
    SmsMessage message, {
    bool forceGooglePay = false,
  }) {
    final body = message.body ?? '';
    final address = message.address ?? '';
    final date = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();

    // Check if this is a transaction SMS
    if (!forceGooglePay && !_isTransactionSms(body, address)) {
      return null;
    }

    // Extract amount
    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) {
      return null;
    }

    // Determine transaction type
    final type = _determineType(body);

    final bankName = _extractBankName(address, body);
    final counterparty = _extractCounterparty(body);
    final merchant = _extractMerchant(body);
    final title = counterparty ?? merchant ?? bankName ?? 'Bank transaction';

    // Extract category
    final category = _categorizeTransaction(title, body, type);
    final upiId = _extractUpiId(body);
    final reference = _extractReference(body);
    final note = _buildNote(
      bankName: bankName,
      counterparty: counterparty,
      upiId: upiId,
      reference: reference,
      source: address,
    );

    return Transaction(
      id: 'sms_${message.id}',
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date,
      paymentMethod:
          _resolvePaymentMethod(body, forceGooglePay: forceGooglePay),
      note: note,
      currency: 'INR',
    );
  }

  /// Check if SMS is a transaction message
  bool _isTransactionSms(String body, String address) {
    final lowerBody = body.toLowerCase();
    final lowerAddress = address.toLowerCase();

    // Common bank/payment keywords
    final keywords = [
      'debited',
      'credited',
      'paid',
      'received',
      'transaction',
      'payment',
      'transfer',
      'withdrawn',
      'deposited',
      'spent',
      'upi',
      'imps',
      'neft',
      'rtgs',
      'atm',
      'pos',
    ];

    // Common bank sender IDs
    final senders = [
      'bank',
      'paytm',
      'phonepe',
      'gpay',
      'googlepay',
      'amazonpay',
      'bhim',
      'upi',
    ];

    return keywords.any((k) => lowerBody.contains(k)) ||
        senders.any((s) => lowerAddress.contains(s));
  }

  /// Extract amount from SMS body
  double? _extractAmount(String body) {
    // Common patterns: Rs. 1,234.56, INR 1234.56, ₹1,234.56
    final patterns = [
      RegExp(r'(?:rs\.?|inr|₹)\s*([0-9,]+\.?[0-9]*)', caseSensitive: false),
      RegExp(r'([0-9,]+\.?[0-9]*)\s*(?:rs\.?|inr|₹)', caseSensitive: false),
      RegExp(
        r'amount[:\s]+(?:rs\.?|inr|₹)?\s*([0-9,]+\.?[0-9]*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:debited|credited|paid|sent|received)\s+(?:with\s+)?(?:rs\.?|inr|₹)?\s*([0-9,]+\.?[0-9]*)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          return double.tryParse(amountStr);
        }
      }
    }

    return null;
  }

  /// Determine transaction type (income/expense)
  TransactionType _determineType(String body) {
    final lowerBody = body.toLowerCase();

    final creditKeywords = [
      'credited',
      'received',
      'deposited',
      'refund',
      'cashback',
      'salary',
    ];
    final debitKeywords = [
      'debited',
      'paid',
      'withdrawn',
      'spent',
      'purchase',
      'sent',
      'transferred',
    ];

    if (creditKeywords.any((k) => lowerBody.contains(k))) {
      return TransactionType.income;
    }

    if (debitKeywords.any((k) => lowerBody.contains(k))) {
      return TransactionType.expense;
    }

    // Default to expense
    return TransactionType.expense;
  }

  /// Extract merchant/description from SMS
  String? _extractMerchant(String body) {
    // Try to extract merchant name from common patterns
    final patterns = [
      RegExp(
        r'(?:at|to|from)\s+([A-Z][A-Za-z0-9\s&.\-]+?)(?:\s+on|\s+for|\s+via|\.|,)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:merchant|vendor):\s*([A-Za-z0-9\s&.\-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:paid to|sent to)\s+([A-Za-z0-9\s&.\-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:trf to|transfer to|purchase at)\s+([A-Za-z0-9\s&.\-]+)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  String? _extractCounterparty(String body) {
    final patterns = [
      RegExp(
        r'(?:upi|imps|neft|rtgs).{0,40}?(?:to|from)\s+([A-Za-z][A-Za-z0-9\s.&\-]{2,40})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:sent to|paid to|received from|transfer to|transfer from)\s+([A-Za-z][A-Za-z0-9\s.&\-]{2,40})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:from|to)\s+([A-Za-z][A-Za-z0-9\s.&\-]{2,40})\s+(?:upi|a\/c|acct|ref|utr|on)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:vpa|upi id)\s*[:\-]?\s*([A-Za-z0-9.\-_]{2,}@[A-Za-z0-9]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:collect from|received from)\s+([A-Za-z][A-Za-z0-9\s.&\-]{2,40})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return _cleanEntity(value);
      }
    }
    return null;
  }

  String? _extractBankName(String address, String body) {
    final normalizedAddress = address.toUpperCase();
    const banks = {
      'HDFC': 'HDFC Bank',
      'ICICI': 'ICICI Bank',
      'SBI': 'State Bank of India',
      'SBIINB': 'State Bank of India',
      'AXIS': 'Axis Bank',
      'KOTAK': 'Kotak Mahindra Bank',
      'IDFC': 'IDFC First Bank',
      'PNB': 'Punjab National Bank',
      'BOB': 'Bank of Baroda',
      'CANARA': 'Canara Bank',
      'UNION': 'Union Bank of India',
      'INDUS': 'IndusInd Bank',
      'YESBNK': 'Yes Bank',
      'PAYTM': 'Paytm Payments Bank',
      'GPAY': 'Google Pay',
      'PHONEPE': 'PhonePe',
      'AIRTEL': 'Airtel Payments Bank',
      'BOI': 'Bank of India',
      'IOB': 'Indian Overseas Bank',
      'UCO': 'UCO Bank',
      'RBL': 'RBL Bank',
      'FEDERAL': 'Federal Bank',
      'HSBC': 'HSBC',
      'DBS': 'DBS Bank',
    };

    for (final entry in banks.entries) {
      if (normalizedAddress.contains(entry.key) ||
          body.toUpperCase().contains(entry.key)) {
        return entry.value;
      }
    }

    final match = RegExp(
      r'(?:from|by)\s+([A-Za-z ]+bank)',
      caseSensitive: false,
    ).firstMatch(body);
    return match == null ? null : _cleanEntity(match.group(1)!);
  }

  String? _extractUpiId(String body) {
    final match =
        RegExp(r'([a-zA-Z0-9.\-_]{2,}@[a-zA-Z0-9]{2,})').firstMatch(body);
    return match?.group(1);
  }

  String? _extractReference(String body) {
    final patterns = [
      RegExp(
          r'(?:utr|ref(?:erence)?|txn|transaction id|rrn)[:\s\-]*([A-Za-z0-9\-]+)',
          caseSensitive: false),
      RegExp(r'\b([0-9]{10,18})\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      final value = match?.group(1)?.trim();
      if (value != null && value.length >= 6) {
        return value;
      }
    }
    return null;
  }

  /// Categorize transaction based on merchant and body
  String _categorizeTransaction(
    String merchant,
    String body,
    TransactionType type,
  ) {
    final lowerMerchant = merchant.toLowerCase();
    final lowerBody = body.toLowerCase();

    if (type == TransactionType.income) {
      if (_containsAny(lowerBody, ['salary', 'payroll'])) {
        return 'Salary';
      }
      if (_containsAny(lowerBody, ['rent'])) {
        return 'Rental Income';
      }
      if (_containsAny(lowerBody, ['bonus', 'incentive'])) {
        return 'Bonus';
      }
      if (_containsAny(lowerBody, ['refund', 'cashback'])) {
        return 'Refund';
      }
      if (_containsAny(lowerBody, ['interest'])) {
        return 'Interest';
      }
      return 'Income';
    }

    // Food & Dining
    if (_containsAny(lowerMerchant, [
      'restaurant',
      'cafe',
      'food',
      'zomato',
      'swiggy',
      'uber eats',
      'dominos',
      'pizza',
      'mcdonald',
      'kfc',
      'starbucks',
      'biryani',
      'hotel',
      'bakery',
      'juice',
      'tea',
      'coffee',
    ])) {
      return 'Food & Dining';
    }

    // Transport
    if (_containsAny(lowerMerchant, [
      'uber',
      'ola',
      'rapido',
      'fuel',
      'petrol',
      'diesel',
      'parking',
      'metro',
      'rail',
      'irctc',
      'bus',
      'fastag',
      'uber moto',
      'petrol bunk',
    ])) {
      return 'Transportation';
    }

    // Shopping
    if (_containsAny(lowerMerchant, [
      'amazon',
      'flipkart',
      'myntra',
      'ajio',
      'shopping',
      'mall',
      'store',
      'mart',
      'bazaar',
      'supermarket',
      'dmart',
      'reliance fresh',
      'jiomart',
      'bigbasket',
    ])) {
      return 'Shopping';
    }

    // Entertainment
    if (_containsAny(lowerMerchant, [
      'netflix',
      'prime',
      'hotstar',
      'spotify',
      'youtube',
      'movie',
      'cinema',
      'pvr',
      'inox',
      'bookmyshow',
      'gaming',
    ])) {
      return 'Entertainment';
    }

    // Bills & Utilities
    if (_containsAny(lowerBody, [
      'electricity',
      'water',
      'gas',
      'internet',
      'broadband',
      'mobile',
      'recharge',
      'bill payment',
      'postpaid',
      'dth',
      'emi',
      'loan',
      'insurance',
    ])) {
      return 'Bills & Utilities';
    }

    // Health
    if (_containsAny(lowerMerchant, [
      'hospital',
      'clinic',
      'pharmacy',
      'medical',
      'doctor',
      'apollo',
      'fortis',
      'diagnostic',
    ])) {
      return 'Health & Fitness';
    }

    if (_containsAny(lowerBody, ['school', 'college', 'tuition', 'fees'])) {
      return 'Education';
    }

    if (_containsAny(lowerMerchant, [
      'medical',
      'pharma',
      'hospital',
      'clinic',
    ])) {
      return 'Health & Fitness';
    }

    if (_containsAny(lowerBody, [
      'grocer',
      'grocery',
      'vegetable',
      'super market',
      'kirana',
      'provision',
    ])) {
      return 'Groceries';
    }

    if (_containsAny(lowerBody, [
      'mutual fund',
      'sip',
      'stocks',
      'demat',
      'zerodha',
      'groww',
      'upstox',
    ])) {
      return 'Investment';
    }

    if (_containsAny(lowerBody, ['atm', 'cash withdrawal'])) {
      return 'Cash Withdrawal';
    }

    if (_containsAny(lowerBody, ['upi', 'imps', 'neft', 'rtgs'])) {
      return 'Transfer';
    }

    // Default
    return 'Other';
  }

  String _buildNote({
    required String? bankName,
    required String? counterparty,
    required String? upiId,
    required String? reference,
    required String source,
  }) {
    final pieces = <String>[
      if (bankName != null) bankName,
      if (counterparty != null && counterparty != bankName)
        'Person: $counterparty',
      if (upiId != null) 'UPI: $upiId',
      if (reference != null) 'Ref: $reference',
      'SMS: $source',
    ];
    return pieces.join(' • ');
  }

  String _resolvePaymentMethod(
    String body, {
    required bool forceGooglePay,
  }) {
    final lowerBody = body.toLowerCase();
    if (forceGooglePay ||
        lowerBody.contains('gpay') ||
        lowerBody.contains('google pay')) {
      return 'Google Pay';
    }
    if (lowerBody.contains('phonepe')) return 'PhonePe';
    if (lowerBody.contains('paytm')) return 'Paytm';
    if (lowerBody.contains('upi')) return 'UPI';
    if (lowerBody.contains('imps')) return 'IMPS';
    if (lowerBody.contains('neft')) return 'NEFT';
    if (lowerBody.contains('rtgs')) return 'RTGS';
    if (lowerBody.contains('atm')) return 'ATM';
    if (lowerBody.contains('pos')) return 'Card';
    return 'Bank';
  }

  String _cleanEntity(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[,.]$'), '')
        .trim();
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}
