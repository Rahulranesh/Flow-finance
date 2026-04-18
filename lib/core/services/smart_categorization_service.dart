import '../../data/models/transaction_model.dart';

/// Smart categorization service using pattern matching and learning
class SmartCategorizationService {
  // Predefined merchant patterns for common categories
  final Map<String, List<String>> _merchantPatterns = {
    'Food': [
      'restaurant', 'cafe', 'coffee', 'pizza', 'burger', 'sushi', 'taco',
      'mcdonalds', 'starbucks', 'subway', 'dominos', 'kfc', 'chipotle',
      'doordash', 'ubereats', 'grubhub', 'postmates', 'food delivery',
      'grocery', 'supermarket', 'walmart', 'target', 'costco', 'whole foods',
      'trader joes', 'kroger', 'safeway', 'publix', 'wegmans',
    ],
    'Transport': [
      'uber', 'lyft', 'taxi', 'cab', 'gas station', 'shell', 'chevron',
      'exxon', 'bp', 'marathon', 'parking', 'toll', 'transit', 'bus',
      'train', 'subway', 'metro', 'airline', 'flight', 'airport',
      'car rental', 'hertz', 'enterprise', 'avis', 'budget',
    ],
    'Shopping': [
      'amazon', 'ebay', 'etsy', 'shopify', 'walmart', 'target', 'costco',
      'best buy', 'apple store', 'nike', 'adidas', 'zara', 'h&m',
      'macy', 'nordstrom', 'gap', 'old navy', 'home depot', 'lowes',
      'ikea', 'wayfair', 'etsy', ' asos', 'shein',
    ],
    'Entertainment': [
      'netflix', 'spotify', 'hulu', 'disney+', 'hbo', 'youtube',
      'apple music', 'amazon prime', 'twitch', 'steam', 'xbox', 'playstation',
      'nintendo', 'cinema', 'movie', 'theater', 'concert', 'ticket',
      'eventbrite', 'stubhub', 'ticketmaster', 'game', 'bowling',
    ],
    'Health': [
      'pharmacy', 'cvs', 'walgreens', 'rite aid', 'doctor', 'hospital',
      'clinic', 'dental', 'dentist', 'vision', 'optometry', 'gym',
      'fitness', 'planet fitness', 'la fitness', '24 hour fitness',
      'yoga', 'pilates', 'medical', 'health', 'wellness', 'therapy',
    ],
    'Bills': [
      'electric', 'water', 'gas utility', 'internet', 'phone', 'mobile',
      'verizon', 'at&t', 't-mobile', 'sprint', 'comcast', 'spectrum',
      'insurance', 'rent', 'mortgage', 'hoa', 'subscription',
      'cable', 'streaming', 'utility', 'bill',
    ],
    'Education': [
      'tuition', 'school', 'university', 'college', 'course', 'class',
      'udemy', 'coursera', 'edx', 'skillshare', 'linkedin learning',
      'book', 'textbook', 'library', 'education', 'learning',
      'pluralsight', 'codecademy', 'khan academy', 'tutor',
    ],
    'Salary': [
      'payroll', 'salary', 'direct deposit', 'wage', 'paycheck',
      'employer', 'company', 'corp', 'inc', 'llc', 'payment received',
    ],
    'Freelance': [
      'upwork', 'fiverr', 'freelancer', 'gig', 'consulting', 'contract',
      '1099', 'invoice', 'client', 'project', 'service',
    ],
  };

  // Keywords that indicate income vs expense
  final List<String> _incomeKeywords = [
    'deposit', 'salary', 'payroll', 'payment received', 'refund',
    'cashback', 'dividend', 'interest', 'return', 'reimbursement',
  ];

  final List<String> _expenseKeywords = [
    'purchase', 'payment', 'charge', 'debit', 'withdrawal',
    'bill', 'subscription', 'order', 'checkout',
  ];

  /// Learn from user corrections to improve future categorizations
  final Map<String, String> _learnedPatterns = {};

  /// Categorize a transaction based on title/description
  CategorizationResult categorize(String title, {double? amount, String? existingCategory}) {
    final normalizedTitle = title.toLowerCase().trim();
    
    // Check learned patterns first
    for (final entry in _learnedPatterns.entries) {
      if (normalizedTitle.contains(entry.key.toLowerCase())) {
        return CategorizationResult(
          category: entry.value,
          confidence: 0.95,
          source: CategorizationSource.learned,
        );
      }
    }

    // Check for exact merchant matches
    for (final entry in _merchantPatterns.entries) {
      for (final pattern in entry.value) {
        if (normalizedTitle.contains(pattern.toLowerCase())) {
          return CategorizationResult(
            category: entry.key,
            confidence: 0.9,
            source: CategorizationSource.pattern,
          );
        }
      }
    }

    // Try amount-based heuristics
    if (amount != null) {
      final amountBased = _categorizeByAmount(amount, normalizedTitle);
      if (amountBased != null) {
        return amountBased;
      }
    }

    // Check for income indicators
    for (final keyword in _incomeKeywords) {
      if (normalizedTitle.contains(keyword)) {
        return CategorizationResult(
          category: 'Income',
          confidence: 0.7,
          source: CategorizationSource.heuristic,
        );
      }
    }

    // Return existing category if available with lower confidence
    if (existingCategory != null && existingCategory.isNotEmpty) {
      return CategorizationResult(
        category: existingCategory,
        confidence: 0.5,
        source: CategorizationSource.fallback,
      );
    }

    // Default to Other
    return CategorizationResult(
      category: 'Other',
      confidence: 0.3,
      source: CategorizationSource.fallback,
    );
  }

  /// Determine if a transaction is income or expense
  TransactionType determineType(String title, {double? amount, String? category}) {
    final normalizedTitle = title.toLowerCase().trim();

    // Check income keywords
    for (final keyword in _incomeKeywords) {
      if (normalizedTitle.contains(keyword)) {
        return TransactionType.income;
      }
    }

    // Check category-based hints
    if (category != null) {
      final lowerCategory = category.toLowerCase();
      if (lowerCategory.contains('salary') || 
          lowerCategory.contains('income') ||
          lowerCategory.contains('freelance')) {
        return TransactionType.income;
      }
    }

    // Amount-based heuristic (positive amounts often indicate income in some systems)
    // But this is unreliable, so use with caution
    
    return TransactionType.expense;
  }

  /// Learn from a user correction
  void learn(String title, String correctCategory) {
    final normalizedTitle = title.toLowerCase().trim();
    
    // Extract key terms (words longer than 3 characters)
    final keyTerms = normalizedTitle
        .split(' ')
        .where((word) => word.length > 3)
        .toList();

    // Store the most specific term
    if (keyTerms.isNotEmpty) {
      // Use the longest term as it's likely most specific
      final mostSpecific = keyTerms.reduce((a, b) => a.length > b.length ? a : b);
      _learnedPatterns[mostSpecific] = correctCategory;
    }
  }

  /// Batch categorize multiple transactions
  List<CategorizationResult> categorizeBatch(List<String> titles) {
    return titles.map((title) => categorize(title)).toList();
  }

  /// Get suggestions for a partial input
  List<CategorySuggestion> getSuggestions(String partial) {
    final normalized = partial.toLowerCase().trim();
    final suggestions = <CategorySuggestion>[];

    // Check merchant patterns
    _merchantPatterns.forEach((category, patterns) {
      for (final pattern in patterns) {
        if (pattern.contains(normalized) || normalized.contains(pattern)) {
          suggestions.add(CategorySuggestion(
            category: category,
            confidence: 0.8,
            matchedPattern: pattern,
          ));
        }
      }
    });

    // Sort by confidence and return top 3
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.take(3).toList();
  }

  /// Auto-categorize a list of transactions
  List<Transaction> autoCategorizeTransactions(List<Transaction> transactions) {
    return transactions.map((transaction) {
      if (transaction.category.isNotEmpty && transaction.category != 'Other') {
        return transaction; // Already categorized
      }

      final result = categorize(
        transaction.title,
        amount: transaction.amount,
        existingCategory: transaction.category,
      );

      final type = determineType(
        transaction.title,
        amount: transaction.amount,
        category: result.category,
      );

      return transaction.copyWith(
        category: result.category,
        type: type,
      );
    }).toList();
  }

  CategorizationResult? _categorizeByAmount(double amount, String title) {
    // Large amounts might indicate specific categories
    if (amount > 1000) {
      if (title.contains('rent') || title.contains('lease')) {
        return CategorizationResult(
          category: 'Bills',
          confidence: 0.75,
          source: CategorizationSource.heuristic,
        );
      }
    }

    // Small recurring amounts often subscriptions
    if (amount < 20 && (title.contains('sub') || title.contains('monthly'))) {
      return CategorizationResult(
        category: 'Bills',
        confidence: 0.6,
        source: CategorizationSource.heuristic,
      );
    }

    return null;
  }

  /// Get statistics about learned patterns
  Map<String, dynamic> getLearningStats() {
    return {
      'learnedPatterns': _learnedPatterns.length,
      'patterns': _learnedPatterns,
    };
  }

  /// Export learned patterns for backup
  Map<String, String> exportPatterns() {
    return Map.from(_learnedPatterns);
  }

  /// Import learned patterns from backup
  void importPatterns(Map<String, String> patterns) {
    _learnedPatterns.addAll(patterns);
  }

  /// Clear all learned patterns
  void clearLearnedPatterns() {
    _learnedPatterns.clear();
  }
}

/// Result of a categorization attempt
class CategorizationResult {
  final String category;
  final double confidence;
  final CategorizationSource source;

  CategorizationResult({
    required this.category,
    required this.confidence,
    required this.source,
  });

  bool get isConfident => confidence >= 0.8;
  bool get needsReview => confidence < 0.6;
}

enum CategorizationSource {
  learned,      // From user corrections
  pattern,      // From merchant patterns
  heuristic,    // From amount/rules
  fallback,     // Default/last resort
}

/// Category suggestion for autocomplete
class CategorySuggestion {
  final String category;
  final double confidence;
  final String matchedPattern;

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.matchedPattern,
  });
}

/// Extension to help with transaction copying
extension TransactionCopyWith on Transaction {
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
    String? walletId,
    String? currency,
    double? exchangeRate,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      walletId: walletId ?? this.walletId,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }
}
