import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/transaction_model.dart';

/// Result of import operation
class ImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });

  bool get isSuccess => errorCount == 0;
}

/// Service for importing data from various formats
class ImportService {
  ImportService._();

  static const _uuid = Uuid();

  /// Import transactions from CSV file
  static Future<ImportResult> importFromCsv(String csvContent) async {
    final errors = <String>[];
    final transactions = <Transaction>[];

    try {
      final rows = const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) {
        return ImportResult(
          successCount: 0,
          errorCount: 1,
          errors: ['CSV file is empty'],
        );
      }

      // Skip header row
      final dataRows = rows.skip(1);

      for (var i = 0; i < dataRows.length; i++) {
        try {
          final row = dataRows.elementAt(i);
          final transaction = _parseCsvRow(row, i + 2); // +2 for header and 0-index
          if (transaction != null) {
            transactions.add(transaction);
          }
        } catch (e) {
          errors.add('Row ${i + 2}: ${e.toString()}');
        }
      }
    } catch (e) {
      errors.add('Failed to parse CSV: ${e.toString()}');
    }

    return ImportResult(
      successCount: transactions.length,
      errorCount: errors.length,
      errors: errors,
    );
  }

  /// Import transactions from JSON
  static Future<ImportResult> importFromJson(String jsonContent) async {
    final errors = <String>[];
    final transactions = <Transaction>[];

    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final transactionsData = data['transactions'] as List<dynamic>?;

      if (transactionsData == null) {
        return ImportResult(
          successCount: 0,
          errorCount: 1,
          errors: ['Invalid JSON format: missing transactions array'],
        );
      }

      for (var i = 0; i < transactionsData.length; i++) {
        try {
          final transactionData = transactionsData[i] as Map<String, dynamic>;
          final transaction = Transaction.fromJson(transactionData);
          transactions.add(transaction);
        } catch (e) {
          errors.add('Item ${i + 1}: ${e.toString()}');
        }
      }
    } catch (e) {
      errors.add('Failed to parse JSON: ${e.toString()}');
    }

    return ImportResult(
      successCount: transactions.length,
      errorCount: errors.length,
      errors: errors,
    );
  }

  /// Pick and import CSV file
  static Future<(ImportResult, List<Transaction>)?> pickAndImportCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      return null;
    }

    final csvContent = utf8.decode(file.bytes!);
    final importResult = await importFromCsv(csvContent);

    // Parse transactions again for return
    final rows = const CsvToListConverter().convert(csvContent);
    final transactions = <Transaction>[];
    for (var i = 1; i < rows.length; i++) {
      final transaction = _parseCsvRow(rows[i], i + 1);
      if (transaction != null) {
        transactions.add(transaction);
      }
    }

    return (importResult, transactions);
  }

  /// Pick and import JSON file
  static Future<(ImportResult, List<Transaction>)?> pickAndImportJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      return null;
    }

    final jsonContent = utf8.decode(file.bytes!);
    final importResult = await importFromJson(jsonContent);

    // Parse transactions again for return
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    final transactionsData = data['transactions'] as List<dynamic>;
    final transactions = transactionsData
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList();

    return (importResult, transactions);
  }

  /// Parse a CSV row into a Transaction
  static Transaction? _parseCsvRow(List<dynamic> row, int rowNumber) {
    if (row.length < 6) {
      throw Exception('Insufficient columns');
    }

    try {
      final typeStr = row[3].toString().toLowerCase();
      final type = TransactionType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => TransactionType.expense,
      );

      return Transaction(
        id: row[0].toString().isNotEmpty ? row[0].toString() : _uuid.v4(),
        title: row[1].toString(),
        amount: double.tryParse(row[2].toString()) ?? 0.0,
        type: type,
        category: row[4].toString(),
        date: DateTime.tryParse(row[5].toString()) ?? DateTime.now(),
        note: row.length > 6 ? row[6].toString() : null,
        paymentMethod: row.length > 7 ? row[7].toString() : null,
        isRecurring: row.length > 8
            ? row[8].toString().toLowerCase() == 'yes'
            : false,
      );
    } catch (e) {
      throw Exception('Parse error: ${e.toString()}');
    }
  }

  /// Validate import file format
  static bool isValidCsvFormat(String content) {
    try {
      final rows = const CsvToListConverter().convert(content);
      if (rows.isEmpty) return false;

      // Check header
      final header = rows.first.map((e) => e.toString().toLowerCase()).toList();
      return header.contains('title') &&
          header.contains('amount') &&
          header.contains('type');
    } catch (e) {
      return false;
    }
  }

  /// Validate JSON format
  static bool isValidJsonFormat(String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data.containsKey('transactions') &&
          data['transactions'] is List;
    } catch (e) {
      return false;
    }
  }
}
