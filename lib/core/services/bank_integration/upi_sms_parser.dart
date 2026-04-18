import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../models/upi_transaction.dart';

/// Parser for UPI transaction SMS messages (India-specific)
class UPISmsParser {
  static final UPISmsParser _instance = UPISmsParser._internal();
  factory UPISmsParser() => _instance;
  UPISmsParser._internal();

  /// Comprehensive list of UPI SMS patterns from different banks
  final List<SmsPattern> _patterns = [
    // HDFC Bank patterns
    SmsPattern(
      bank: 'HDFC',
      regex: RegExp(
        r'Rs\.(\d+\.?\d*)\s+(?:has been\s+)?debited\s+from\s+a/c\s+(?:\*+|x)?(\d+).*?to\s+VPA\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.debit,
      amountGroup: 1,
      accountGroup: 2,
      upiIdGroup: 3,
    ),
    SmsPattern(
      bank: 'HDFC',
      regex: RegExp(
        r'Rs\.(\d+\.?\d*)\s+(?:has been\s+)?credited\s+to\s+a/c\s+(?:\*+|x)?(\d+).*?from\s+VPA\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.credit,
      amountGroup: 1,
      accountGroup: 2,
      upiIdGroup: 3,
    ),
    
    // SBI patterns
    SmsPattern(
      bank: 'SBI',
      regex: RegExp(
        r'INR\s+(\d+\.?\d*)\s+(?:has been\s+)?(?:debited|transferred|sent)\s+from\s+a/c\s+(?:\*+|x)?(\d+).*?to\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.debit,
      amountGroup: 1,
      accountGroup: 2,
      upiIdGroup: 3,
    ),
    SmsPattern(
      bank: 'SBI',
      regex: RegExp(
        r'INR\s+(\d+\.?\d*)\s+(?:has been\s+)?credited\s+to\s+a/c\s+(?:\*+|x)?(\d+).*?from\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.credit,
      amountGroup: 1,
      accountGroup: 2,
      upiIdGroup: 3,
    ),
    
    // ICICI Bank patterns
    SmsPattern(
      bank: 'ICICI',
      regex: RegExp(
        r'Rs\.?\s*(\d+\.?\d*)\s+(?:has been\s+)?(?:debited|sent|paid)\s+from\s+a/c\s+(?:\*+|x)?(\d+).*?to\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.debit,
      amountGroup: 1,
      accountGroup: 2,
      upiIdGroup: 3,
    ),
    SmsPattern(
      bank: 'ICICI',
      regex: RegExp(
        r'Rs\.?\s*(\d+\.?\d*)\s+(?:has been\s+)?(?:credited|received)\s+to\s+a/c\s+(?:\*+|x)?(\d+).*?from\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.credit,
      amountGroup: 1,
      accountGroup: 2,
      upiIdGroup: 3,
    ),
    
    // Axis Bank patterns
    SmsPattern(
      bank: 'AXIS',
      regex: RegExp(
        r'INR\s+(\d+\.?\d*)\s+(?:has been\s+)?(?:debited|transferred)\s+from\s+A/C\s+(?:\*+|x)?(\d+).*?to\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.debit,
      amountGroup: 1,
      accountGroup: 2,
      upiIdGroup: 3,
    ),
    
    // Kotak Mahindra patterns
    SmsPattern(
      bank: 'KOTAK',
      regex: RegExp(
        r'Rs\.?\s*(\d+\.?\d*)\s+(?:has been\s+)?(?:debited|sent)\s+from\s+A/C\s+(?:\*+|x)?(\d+).*?to\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.debit,
      amountGroup: 1,
      accountGroup: 2,
      upiIdGroup: 3,
    ),
    
    // Google Pay patterns
    SmsPattern(
      bank: 'GPAY',
      regex: RegExp(
        r'Rs\.?\s*(\d+\.?\d*)\s+(?:has been\s+)?(?:sent|paid)\s+to\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.debit,
      amountGroup: 1,
      upiIdGroup: 2,
    ),
    SmsPattern(
      bank: 'GPAY',
      regex: RegExp(
        r'Rs\.?\s*(\d+\.?\d*)\s+(?:has been\s+)?(?:received|credited)\s+from\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.credit,
      amountGroup: 1,
      upiIdGroup: 2,
    ),
    
    // PhonePe patterns
    SmsPattern(
      bank: 'PHONEPE',
      regex: RegExp(
        r'Rs\.?\s*(\d+\.?\d*)\s+(?:has been\s+)?(?:sent|paid)\s+to\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.debit,
      amountGroup: 1,
      upiIdGroup: 2,
    ),
    
    // PayTM patterns
    SmsPattern(
      bank: 'PAYTM',
      regex: RegExp(
        r'Rs\.?\s*(\d+\.?\d*)\s+(?:has been\s+)?(?:sent|paid|debited).*?to\s+([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.debit,
      amountGroup: 1,
      upiIdGroup: 2,
    ),
    
    // Generic patterns (fallback)
    SmsPattern(
      bank: 'GENERIC',
      regex: RegExp(
        r'(?:Rs\.?|INR)\s*(\d+\.?\d*).*?(?:debited|sent|paid|transferred).*?(?:to|from).*?([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.debit,
      amountGroup: 1,
      upiIdGroup: 2,
    ),
    SmsPattern(
      bank: 'GENERIC',
      regex: RegExp(
        r'(?:Rs\.?|INR)\s*(\d+\.?\d*).*?(?:credited|received).*?(?:from|to).*?([\w.@-]+)',
        caseSensitive: false,
      ),
      type: UPITransactionType.credit,
      amountGroup: 1,
      upiIdGroup: 2,
    ),
  ];

  /// Bank sender identifiers
  final Map<String, List<String>> _bankSenders = {
    'HDFC': ['HDFCBK', 'HDFCBANK', 'HDFC-CIB'],
    'SBI': ['SBI', 'SBIBNK', 'SBIINB', 'ATMSBI'],
    'ICICI': ['ICICI', 'ICICIB', 'ICICICC', 'ICICICC1'],
    'AXIS': ['AXISBK', 'AXISBANK', 'ATMAXIS'],
    'KOTAK': ['KOTAKB', 'KOTAKBK', 'KOTAKMB'],
    'PNB': ['PNBSMS', 'PUNBNK', 'ATMPNB'],
    'BOB': ['BOBTXN', 'BOBANK', 'BARODA'],
    'CANARA': ['CANBNK', 'CANARABANK'],
    'UNION': ['UNIONB', 'UNIONBK'],
    'BOI': ['BOIIND', 'BOIINDIA'],
    'IDBI': ['IDBIBK', 'IDBI'],
    'YES': ['YESBNK', 'YESBANK'],
    'INDUSIND': ['INDUSB', 'INDUSIND'],
    'FEDERAL': ['FEDBNK', 'FEDERAL'],
    'SOUTHINDIAN': ['SIB', 'SIBANK'],
    'GPAY': ['GPAY', 'GOOGLEPAY', 'G-PAY'],
    'PHONEPE': ['PHONEPE', 'PAYTM', 'PAYTMB', 'AMAZONPAY'],
  };

  /// Parse SMS and extract UPI transaction
  UPITransaction? parseSms(String smsBody, String sender) {
    final bank = identifyBank(sender);
    
    // Try bank-specific patterns first
    final bankPatterns = _patterns.where((p) => 
      p.bank == bank || (bank == null && p.bank == 'GENERIC')
    );
    
    for (final pattern in bankPatterns) {
      final match = pattern.regex.firstMatch(smsBody);
      if (match != null) {
        return _extractTransaction(match, pattern, smsBody, sender, bank);
      }
    }
    
    // Try all patterns if no bank-specific match
    for (final pattern in _patterns) {
      final match = pattern.regex.firstMatch(smsBody);
      if (match != null) {
        return _extractTransaction(match, pattern, smsBody, sender, bank);
      }
    }
    
    return null;
  }

  /// Extract transaction from regex match
  UPITransaction? _extractTransaction(
    RegExpMatch match,
    SmsPattern pattern,
    String smsBody,
    String sender,
    String? bank,
  ) {
    try {
      // Extract amount
      final amountStr = match.group(pattern.amountGroup);
      if (amountStr == null) return null;
      final amount = double.parse(amountStr.replaceAll(',', ''));
      
      // Extract UPI ID
      final upiId = pattern.upiIdGroup != null 
          ? match.group(pattern.upiIdGroup!) 
          : null;
      
      // Extract account number (masked)
      final accountNumber = pattern.accountGroup != null
          ? match.group(pattern.accountGroup!)
          : null;
      
      // Extract UTR/Reference number
      final utr = extractUtrNumber(smsBody);
      
      // Extract timestamp
      final timestamp = extractTimestamp(smsBody);
      
      // Extract description/note
      final description = extractDescription(smsBody);
      
      // Determine payer/payee
      String? payerUpiId;
      String? payeeUpiId;
      
      if (pattern.type == UPITransactionType.debit) {
        payeeUpiId = upiId;
      } else {
        payerUpiId = upiId;
      }
      
      return UPITransaction(
        id: const Uuid().v4(),
        utrNumber: utr ?? 'UNKNOWN',
        upiId: upiId ?? 'UNKNOWN',
        payerUpiId: payerUpiId,
        payeeUpiId: payeeUpiId,
        amount: amount,
        type: pattern.type,
        timestamp: timestamp ?? DateTime.now(),
        description: description,
        bankReference: utr,
        sourceApp: identifySourceApp(sender) ?? bank ?? 'UNKNOWN',
        accountNumber: accountNumber,
        rawSms: smsBody,
        senderId: sender,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Identify bank from sender
  String? identifyBank(String sender) {
    final upperSender = sender.toUpperCase();
    
    for (final entry in _bankSenders.entries) {
      for (final identifier in entry.value) {
        if (upperSender.contains(identifier.toUpperCase())) {
          return entry.key;
        }
      }
    }
    
    return null;
  }

  /// Identify source app (GPay, PhonePe, etc.)
  String? identifySourceApp(String sender) {
    final upperSender = sender.toUpperCase();
    
    if (upperSender.contains('GPAY') || upperSender.contains('GOOGLE')) {
      return 'Google Pay';
    }
    if (upperSender.contains('PHONEPE')) {
      return 'PhonePe';
    }
    if (upperSender.contains('PAYTM')) {
      return 'Paytm';
    }
    if (upperSender.contains('AMAZON')) {
      return 'Amazon Pay';
    }
    if (upperSender.contains('BHIM')) {
      return 'BHIM';
    }
    
    return null;
  }

  /// Extract UTR number from SMS
  String? extractUtrNumber(String smsBody) {
    // Common UTR patterns
    final patterns = [
      RegExp(r'UTR[:\s]+(\d+)', caseSensitive: false),
      RegExp(r'UPI Ref[:\s]+(\d+)', caseSensitive: false),
      RegExp(r'Ref[:\s]+(\d+)', caseSensitive: false),
      RegExp(r'Reference[:\s]+(\d+)', caseSensitive: false),
      RegExp(r'UPI[:\s]+(\d{12,})', caseSensitive: false),
      RegExp(r'Txn ID[:\s]+(\w+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        return match.group(1);
      }
    }
    
    return null;
  }

  /// Extract timestamp from SMS
  DateTime? extractTimestamp(String smsBody) {
    // Try to find date patterns
    final patterns = [
      // DD-MM-YYYY or DD/MM/YYYY
      RegExp(r'(\d{2})[-/](\d{2})[-/](\d{4})'),
      // DD-MM-YY
      RegExp(r'(\d{2})[-/](\d{2})[-/](\d{2})'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        try {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          var year = int.parse(match.group(3)!);
          
          // Handle 2-digit year
          if (year < 100) {
            year += year < 50 ? 2000 : 1900;
          }
          
          return DateTime(year, month, day);
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }

  /// Extract description/note from SMS
  String? extractDescription(String smsBody) {
    // Look for description patterns
    final patterns = [
      RegExp(r'(?:Desc|Description|Note|Remarks)[:\s]+([^\n]+)', caseSensitive: false),
      RegExp(r'(?:for|towards)\s+(.+?)(?:\.|$)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    
    return null;
  }

  /// Extract UPI ID from text
  String? extractUpiId(String text) {
    final pattern = RegExp(r'[\w.+-]+@[\w.]+');
    final match = pattern.firstMatch(text);
    return match?.group(0);
  }

  /// Extract amount from text
  double? extractAmount(String text) {
    final patterns = [
      RegExp(r'Rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'INR\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'₹\s*([\d,]+\.?\d*)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          return double.parse(match.group(1)!.replaceAll(',', ''));
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }

  /// Check if SMS is a UPI transaction message
  bool isUpiTransaction(String smsBody) {
    final upiKeywords = [
      'upi',
      'debited',
      'credited',
      'vpa',
      'utr',
      '@ok',
      '@paytm',
      '@ybl',
      '@axl',
      '@ibl',
      '@sbi',
    ];
    
    final lowerBody = smsBody.toLowerCase();
    return upiKeywords.any((keyword) => lowerBody.contains(keyword));
  }

  /// Batch parse multiple SMS messages
  List<UPITransaction> parseBatch(List<SmsMessage> messages) {
    final transactions = <UPITransaction>[];
    
    for (final message in messages) {
      final transaction = parseSms(message.body, message.sender);
      if (transaction != null) {
        transactions.add(transaction);
      }
    }
    
    return transactions;
  }

  /// Get statistics about parsed SMS
  SmsParseStats getStats(List<SmsMessage> messages) {
    int parsed = 0;
    int failed = 0;
    final bankCounts = <String, int>{};
    
    for (final message in messages) {
      final transaction = parseSms(message.body, message.sender);
      if (transaction != null) {
        parsed++;
        final bank = identifyBank(message.sender) ?? 'UNKNOWN';
        bankCounts[bank] = (bankCounts[bank] ?? 0) + 1;
      } else {
        failed++;
      }
    }
    
    return SmsParseStats(
      totalMessages: messages.length,
      parsedSuccessfully: parsed,
      failedToParse: failed,
      successRate: messages.isEmpty ? 0 : parsed / messages.length,
      bankDistribution: bankCounts,
    );
  }
}

/// SMS pattern definition
class SmsPattern {
  final String bank;
  final RegExp regex;
  final UPITransactionType type;
  final int amountGroup;
  final int? accountGroup;
  final int? upiIdGroup;

  SmsPattern({
    required this.bank,
    required this.regex,
    required this.type,
    required this.amountGroup,
    this.accountGroup,
    this.upiIdGroup,
  });
}

/// SMS message structure
class SmsMessage {
  final String id;
  final String sender;
  final String body;
  final DateTime timestamp;
  final DateTime receivedAt;

  SmsMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.timestamp,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'receivedAt': receivedAt.toIso8601String(),
    };
  }

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      receivedAt: DateTime.parse(json['receivedAt'] as String),
    );
  }
}

/// SMS parsing statistics
class SmsParseStats {
  final int totalMessages;
  final int parsedSuccessfully;
  final int failedToParse;
  final double successRate;
  final Map<String, int> bankDistribution;

  SmsParseStats({
    required this.totalMessages,
    required this.parsedSuccessfully,
    required this.failedToParse,
    required this.successRate,
    required this.bankDistribution,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalMessages': totalMessages,
      'parsedSuccessfully': parsedSuccessfully,
      'failedToParse': failedToParse,
      'successRate': successRate,
      'bankDistribution': bankDistribution,
    };
  }
}
