import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/transaction_model.dart';

/// PDF export service for generating transaction reports
class PdfExportService {
  /// Export transactions to PDF
  static Future<void> exportTransactionsToPdf({
    required List<Transaction> transactions,
    required String title,
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpense;

    // Add page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
                pw.SizedBox(height: 16),
                pw.Divider(),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Income', totalIncome, PdfColors.green),
                _buildSummaryItem('Total Expense', totalExpense, PdfColors.red),
                _buildSummaryItem('Balance', balance, 
                    balance >= 0 ? PdfColors.blue : PdfColors.red),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Transactions table
          pw.Text(
            'Transactions',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                children: [
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Description', isHeader: true),
                  _buildTableCell('Category', isHeader: true),
                  _buildTableCell('Amount', isHeader: true),
                ],
              ),
              // Data rows
              ...transactions.map((transaction) {
                final isExpense = transaction.type == TransactionType.expense;
                return pw.TableRow(
                  children: [
                    _buildTableCell(_formatDate(transaction.date)),
                    _buildTableCell(transaction.title),
                    _buildTableCell(transaction.category),
                    _buildTableCell(
                      '${isExpense ? '-' : '+'}₹${transaction.amount.toStringAsFixed(2)}',
                      color: isExpense ? PdfColors.red : PdfColors.green,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.SizedBox(height: 24),

          // Footer
          pw.Text(
            'Generated on ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );

    // Save and share
    await _savePdf(pdf, title);
  }

  static pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '₹${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static Future<void> _savePdf(pw.Document pdf, String fileName) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');

      // Save PDF
      await file.writeAsBytes(await pdf.save());

      // Share PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: fileName,
      );
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  /// Print PDF directly
  static Future<void> printTransactions({
    required List<Transaction> transactions,
    required String title,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdf = pw.Document();
        // Add similar content as exportTransactionsToPdf
        return pdf.save();
      },
    );
  }
}
