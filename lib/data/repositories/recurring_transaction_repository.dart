import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';

/// Repository for managing recurring transactions
class RecurringTransactionRepository {
  static const String _recurringKey = 'recurring_transactions';
  static const String _lastCheckKey = 'recurring_last_check';

  final SharedPreferences _prefs;

  RecurringTransactionRepository(this._prefs);

  /// Get all recurring transactions
  Future<List<RecurringTransaction>> getAll() async {
    final jsonString = _prefs.getString(_recurringKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => RecurringTransaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get active recurring transactions
  Future<List<RecurringTransaction>> getActive() async {
    final all = await getAll();
    return all.where((t) => !t.hasEnded).toList();
  }

  /// Get recurring transactions by type
  Future<List<RecurringTransaction>> getByType(TransactionType type) async {
    final all = await getAll();
    return all.where((t) => t.type == type && !t.hasEnded).toList();
  }

  /// Get a specific recurring transaction by ID
  Future<RecurringTransaction?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new recurring transaction
  Future<RecurringTransaction> create({
    required String id,
    required String title,
    required double amount,
    required TransactionType type,
    required String category,
    String? walletId,
    String? note,
    required RecurringFrequency frequency,
    required DateTime startDate,
    EndConditionType endCondition = EndConditionType.never,
    int? occurrenceCount,
    DateTime? endDate,
  }) async {
    final transaction = RecurringTransaction(
      id: id,
      title: title,
      amount: amount,
      type: type,
      category: category,
      walletId: walletId,
      note: note,
      frequency: frequency,
      startDate: startDate,
      endCondition: endCondition,
      occurrenceCount: occurrenceCount,
      endDate: endDate,
      createdAt: DateTime.now(),
      nextDueDate: startDate,
    );

    final all = await getAll();
    all.add(transaction);
    await _saveAll(all);

    return transaction;
  }

  /// Update a recurring transaction
  Future<RecurringTransaction> update(RecurringTransaction transaction) async {
    final all = await getAll();
    final index = all.indexWhere((t) => t.id == transaction.id);

    if (index >= 0) {
      all[index] = transaction;
      await _saveAll(all);
      return transaction;
    } else {
      throw Exception('Recurring transaction not found');
    }
  }

  /// Delete a recurring transaction
  Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((t) => t.id == id);
    await _saveAll(all);
  }

  /// Toggle active status
  Future<RecurringTransaction> toggleActive(String id) async {
    final transaction = await getById(id);
    if (transaction == null) throw Exception('Transaction not found');

    final updated = transaction.copyWith(isActive: !transaction.isActive);
    return update(updated);
  }

  /// Process a recurring transaction (create actual transaction and update tracking)
  Future<Transaction> processTransaction(String id, {DateTime? date}) async {
    final transaction = await getById(id);
    if (transaction == null) throw Exception('Transaction not found');
    if (transaction.hasEnded) throw Exception('Transaction has ended');

    // Create actual transaction
    final actualTransaction = transaction.toTransaction(date: date);

    // Update recurring transaction
    final newProcessedCount = transaction.processedCount + 1;
    final nextDue = transaction.frequency.getNextDate(date ?? DateTime.now());

    final updated = transaction.copyWith(
      processedCount: newProcessedCount,
      lastProcessed: date ?? DateTime.now(),
      nextDueDate: nextDue,
    );

    await update(updated);

    return actualTransaction;
  }

  /// Get transactions that are due today
  Future<List<RecurringTransaction>> getDueToday() async {
    final all = await getActive();
    return all.where((t) => t.isDueToday).toList();
  }

  /// Get overdue transactions
  Future<List<RecurringTransaction>> getOverdue() async {
    final all = await getActive();
    return all.where((t) => t.isOverdue).toList();
  }

  /// Get upcoming transactions (next 7 days)
  Future<List<RecurringTransaction>> getUpcoming({int days = 7}) async {
    final all = await getActive();
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    return all.where((t) {
      final nextDue = t.nextDueDate ?? t.calculatedNextDueDate;
      return nextDue.isAfter(now) && nextDue.isBefore(future);
    }).toList();
  }

  /// Get summary statistics
  Future<RecurringTransactionSummary> getSummary() async {
    final all = await getAll();
    return RecurringTransactionSummary.fromList(all);
  }

  /// Auto-process all due transactions
  /// Returns list of created transactions
  Future<List<Transaction>> autoProcessDueTransactions() async {
    final due = await getDueToday();
    final created = <Transaction>[];

    for (final recurring in due) {
      try {
        final transaction = await processTransaction(recurring.id);
        created.add(transaction);
      } catch (e) {
        // Log error but continue processing others
        print('Failed to process recurring transaction ${recurring.id}: $e');
      }
    }

    // Update last check time
    await _prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());

    return created;
  }

  /// Check if auto-processing should run
  bool shouldAutoProcess() {
    final lastCheck = _prefs.getString(_lastCheckKey);
    if (lastCheck == null) return true;

    final lastDate = DateTime.parse(lastCheck);
    final now = DateTime.now();

    // Only run once per day
    return lastDate.year != now.year ||
           lastDate.month != now.month ||
           lastDate.day != now.day;
  }

  /// Get estimated balance impact for a date range
  Future<Map<String, double>> getEstimatedImpact(DateTime start, DateTime end) async {
    final all = await getActive();
    double income = 0;
    double expense = 0;

    for (final t in all) {
      // Calculate how many times this transaction occurs in the range
      int occurrences = 0;
      DateTime current = t.nextDueDate ?? t.calculatedNextDueDate;

      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        if (current.isAfter(start) || current.isAtSameMomentAs(start)) {
          occurrences++;
        }
        current = t.frequency.getNextDate(current);

        // Safety check for infinite loops
        if (occurrences > 1000) break;
      }

      final total = t.amount * occurrences;
      if (t.type == TransactionType.income) {
        income += total;
      } else {
        expense += total;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'net': income - expense,
    };
  }

  /// Get recurring transactions by category
  Future<Map<String, List<RecurringTransaction>>> getByCategory() async {
    final all = await getActive();
    final map = <String, List<RecurringTransaction>>{};

    for (final t in all) {
      map.putIfAbsent(t.category, () => []);
      map[t.category]!.add(t);
    }

    return map;
  }

  // Private helper methods

  Future<void> _saveAll(List<RecurringTransaction> transactions) async {
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await _prefs.setString(_recurringKey, jsonEncode(jsonList));
  }
}
