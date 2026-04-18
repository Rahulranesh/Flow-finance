import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/transaction_model.dart';

/// Service for exporting data to various formats
class ExportService {
  ExportService._();

  /// Export transactions to CSV
  static Future<String> exportToCsv(List<Transaction> transactions) async {
    final rows = <List<dynamic>>[];

    // Header
    rows.add([
      'ID',
      'Title',
      'Amount',
      'Type',
      'Category',
      'Date',
      'Note',
      'Payment Method',
      'Is Recurring',
    ]);

    // Data rows
    for (final transaction in transactions) {
      rows.add([
        transaction.id,
        transaction.title,
        transaction.amount,
        transaction.type.name,
        transaction.category,
        transaction.date.toIso8601String(),
        transaction.note ?? '',
        transaction.paymentMethod ?? '',
        transaction.isRecurring ? 'Yes' : 'No',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    return csv;
  }

  /// Export transactions to JSON
  static Future<String> exportToJson(List<Transaction> transactions) async {
    final data = transactions.map((t) => t.toJson()).toList();
    return jsonEncode({'transactions': data});
  }

  /// Save and share CSV file
  static Future<void> shareCsv(
    List<Transaction> transactions, {
    String filename = 'transactions',
  }) async {
    final csv = await exportToCsv(transactions);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Flow Finance - Transactions Export',
    );
  }

  /// Save and share JSON file
  static Future<void> shareJson(
    List<Transaction> transactions, {
    String filename = 'transactions_backup',
  }) async {
    final json = await exportToJson(transactions);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename.json');
    await file.writeAsString(json);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Flow Finance - Backup',
    );
  }

  /// Generate summary report
  static Future<String> generateSummaryReport(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = income - expense;

    // Group by category
    final categoryTotals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    // Sort categories by amount
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    buffer.writeln('FLOW FINANCE - SUMMARY REPORT');
    buffer.writeln('==============================');
    buffer.writeln();
    buffer.writeln('Period: ${startDate.toShortDate()} - ${endDate.toShortDate()}');
    buffer.writeln();
    buffer.writeln('FINANCIAL OVERVIEW');
    buffer.writeln('------------------');
    buffer.writeln('Total Income:  +\$${income.toStringAsFixed(2)}');
    buffer.writeln('Total Expense: -\$${expense.toStringAsFixed(2)}');
    buffer.writeln('Balance:       \$${balance.toStringAsFixed(2)}');
    buffer.writeln();
    buffer.writeln('TOP EXPENSE CATEGORIES');
    buffer.writeln('----------------------');
    for (final entry in sortedCategories.take(5)) {
      buffer.writeln('${entry.key}: \$${entry.value.toStringAsFixed(2)}');
    }
    buffer.writeln();
    buffer.writeln('TRANSACTION COUNT: ${transactions.length}');
    buffer.writeln();
    buffer.writeln('Generated on: ${DateTime.now().toDateTime()}');

    return buffer.toString();
  }

  /// Share summary report
  static Future<void> shareSummaryReport(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final report = await generateSummaryReport(transactions, startDate, endDate);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/financial_summary.txt');
    await file.writeAsString(report);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Flow Finance - Summary Report',
    );
  }
}

/// Extension for date formatting
extension DateFormatting on DateTime {
  String toShortDate() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}
