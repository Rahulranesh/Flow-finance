import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../data/models/transaction_model.dart';

enum ExportFormat { csv, pdf }

class DataExportService {
  const DataExportService();

  Future<XFile> exportTransactions({
    required List<Transaction> transactions,
    required DateTimeRange dateRange,
    required ExportFormat format,
    required String currencySymbol,
  }) async {
    switch (format) {
      case ExportFormat.csv:
        return _exportCsv(
          transactions: transactions,
          dateRange: dateRange,
          currencySymbol: currencySymbol,
        );
      case ExportFormat.pdf:
        return _exportPdf(
          transactions: transactions,
          dateRange: dateRange,
          currencySymbol: currencySymbol,
        );
    }
  }

  Future<void> shareExport({
    required List<Transaction> transactions,
    required DateTimeRange dateRange,
    required ExportFormat format,
    required String currencySymbol,
  }) async {
    final file = await exportTransactions(
      transactions: transactions,
      dateRange: dateRange,
      format: format,
      currencySymbol: currencySymbol,
    );
    await Share.shareXFiles([file], subject: 'Flow Finance export');
  }

  Future<XFile> _exportCsv({
    required List<Transaction> transactions,
    required DateTimeRange dateRange,
    required String currencySymbol,
  }) async {
    final rows = <List<dynamic>>[
      ['Date', 'Title', 'Category', 'Type', 'Amount', 'Currency', 'Note'],
      ...transactions.map(
        (transaction) => [
          _formatDate(transaction.date),
          transaction.title,
          transaction.category,
          transaction.type.name,
          transaction.amount.toStringAsFixed(2),
          transaction.currency,
          transaction.note ?? '',
        ],
      ),
    ];

    final content = const ListToCsvConverter().convert(rows);
    final file = await _createFile('csv');
    await File(file.path).writeAsString(content);
    return file;
  }

  Future<XFile> _exportPdf({
    required List<Transaction> transactions,
    required DateTimeRange dateRange,
    required String currencySymbol,
  }) async {
    final pdf = pw.Document();
    final totalIncome = transactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalExpense = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Flow Finance Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}',
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                  'Total Income: $currencySymbol${totalIncome.toStringAsFixed(2)}'),
              pw.Text(
                  'Total Expense: $currencySymbol${totalExpense.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Title', 'Category', 'Type', 'Amount'],
            data: transactions
                .map(
                  (transaction) => [
                    _formatDate(transaction.date),
                    transaction.title,
                    transaction.category,
                    transaction.type.name,
                    '$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    final file = await _createFile('pdf');
    await File(file.path).writeAsBytes(await pdf.save());
    return file;
  }

  Future<XFile> _createFile(String extension) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/flow_finance_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    return XFile(file.path);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
