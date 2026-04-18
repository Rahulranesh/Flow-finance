import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/database/database.dart';
import '../../data/models/transaction_model.dart';
import 'export_service.dart';

/// Service for backup and restore operations
class BackupService {
  final AppDatabase _database;

  BackupService(this._database);

  /// Create a full backup of all data
  Future<String> createBackup() async {
    final backup = <String, dynamic>{
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'appName': 'Flow Finance',
    };

    // Export transactions
    final transactions = await _database.getAllTransactions();
    backup['transactions'] = transactions.map((t) => {
      'id': t.id,
      'title': t.title,
      'amount': t.amount,
      'type': t.type,
      'category': t.category,
      'date': t.date.toIso8601String(),
      'note': t.note,
      'paymentMethod': t.paymentMethod,
      'isRecurring': t.isRecurring,
      'recurringId': t.recurringId,
    }).toList();

    // Export budgets
    final budgets = await _database.getAllBudgets();
    backup['budgets'] = budgets.map((b) => {
      'id': b.id,
      'categoryId': b.categoryId,
      'limit': b.limit,
      'period': b.period,
      'startDate': b.startDate.toIso8601String(),
      'endDate': b.endDate?.toIso8601String(),
      'isActive': b.isActive,
    }).toList();

    // Export categories
    final categories = await _database.getAllCategories();
    backup['categories'] = categories.map((c) => {
      'id': c.id,
      'name': c.name,
      'iconName': c.iconName,
      'colorValue': c.colorValue,
      'budgetLimit': c.budgetLimit,
      'isDefault': c.isDefault,
    }).toList();

    // Export settings
    // Note: Settings are stored as key-value pairs
    backup['settings'] = {};

    return jsonEncode(backup);
  }

  /// Save backup to file and share
  Future<void> shareBackup() async {
    final backupJson = await createBackup();
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/flow_finance_backup_$timestamp.json');
    await file.writeAsString(backupJson);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Flow Finance - Full Backup',
    );
  }

  /// Create compressed backup
  Future<void> shareCompressedBackup() async {
    final backupJson = await createBackup();
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Create archive
    final archive = Archive();
    final backupBytes = utf8.encode(backupJson);
    archive.addFile(ArchiveFile(
      'backup.json',
      backupBytes.length,
      backupBytes,
    ));

    // Compress
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    if (zipData != null) {
      final zipFile = File('${directory.path}/flow_finance_backup_$timestamp.zip');
      await zipFile.writeAsBytes(zipData);

      await Share.shareXFiles(
        [XFile(zipFile.path)],
        subject: 'Flow Finance - Compressed Backup',
      );
    }
  }

  /// Restore from backup JSON
  Future<RestoreResult> restoreFromJson(String jsonContent) async {
    try {
      final backup = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Validate backup format
      if (!backup.containsKey('version')) {
        return RestoreResult(
          success: false,
          message: 'Invalid backup format: missing version',
        );
      }

      // Restore transactions
      final transactionsData = backup['transactions'] as List<dynamic>?;
      if (transactionsData != null) {
        for (final data in transactionsData) {
          final companion = TransactionsCompanion(
            id: Value(data['id'] as String),
            title: Value(data['title'] as String),
            amount: Value((data['amount'] as num).toDouble()),
            type: Value(data['type'] as String),
            category: Value(data['category'] as String),
            date: Value(DateTime.parse(data['date'] as String)),
            note: Value(data['note'] as String?),
            paymentMethod: Value(data['paymentMethod'] as String?),
            isRecurring: Value(data['isRecurring'] as bool? ?? false),
            recurringId: Value(data['recurringId'] as String?),
          );
          await _database.insertTransaction(companion);
        }
      }

      // Restore budgets
      final budgetsData = backup['budgets'] as List<dynamic>?;
      if (budgetsData != null) {
        for (final data in budgetsData) {
          final companion = BudgetsCompanion(
            id: Value(data['id'] as String),
            categoryId: Value(data['categoryId'] as String),
            limit: Value((data['limit'] as num).toDouble()),
            period: Value(data['period'] as String),
            startDate: Value(DateTime.parse(data['startDate'] as String)),
            endDate: Value(data['endDate'] != null
                ? DateTime.parse(data['endDate'] as String)
                : null),
            isActive: Value(data['isActive'] as bool? ?? true),
          );
          await _database.insertBudget(companion);
        }
      }

      // Restore categories
      final categoriesData = backup['categories'] as List<dynamic>?;
      if (categoriesData != null) {
        for (final data in categoriesData) {
          final companion = CategoriesCompanion(
            id: Value(data['id'] as String),
            name: Value(data['name'] as String),
            iconName: Value(data['iconName'] as String),
            colorValue: Value(data['colorValue'] as int),
            budgetLimit: Value(data['budgetLimit'] != null
                ? (data['budgetLimit'] as num).toDouble()
                : null),
            isDefault: Value(data['isDefault'] as bool? ?? false),
          );
          await _database.insertCategory(companion);
        }
      }

      return RestoreResult(
        success: true,
        message: 'Backup restored successfully',
        transactionsCount: transactionsData?.length ?? 0,
        budgetsCount: budgetsData?.length ?? 0,
        categoriesCount: categoriesData?.length ?? 0,
      );
    } catch (e) {
      return RestoreResult(
        success: false,
        message: 'Restore failed: ${e.toString()}',
      );
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    final transactions = await _database.getAllTransactions();
    for (final t in transactions) {
      await _database.deleteTransaction(t.id);
    }

    final budgets = await _database.getAllBudgets();
    for (final b in budgets) {
      await _database.deleteBudget(b.id);
    }

    final categories = await _database.getAllCategories();
    for (final c in categories) {
      if (!c.isDefault) {
        await _database.deleteCategory(c.id);
      }
    }
  }

  /// Get backup info without restoring
  Future<BackupInfo?> getBackupInfo(String jsonContent) async {
    try {
      final backup = jsonDecode(jsonContent) as Map<String, dynamic>;

      return BackupInfo(
        version: backup['version'] as int? ?? 1,
        createdAt: DateTime.parse(backup['createdAt'] as String),
        appName: backup['appName'] as String? ?? 'Unknown',
        transactionsCount: (backup['transactions'] as List<dynamic>?)?.length ?? 0,
        budgetsCount: (backup['budgets'] as List<dynamic>?)?.length ?? 0,
        categoriesCount: (backup['categories'] as List<dynamic>?)?.length ?? 0,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Result of restore operation
class RestoreResult {
  final bool success;
  final String message;
  final int? transactionsCount;
  final int? budgetsCount;
  final int? categoriesCount;

  RestoreResult({
    required this.success,
    required this.message,
    this.transactionsCount,
    this.budgetsCount,
    this.categoriesCount,
  });
}

/// Info about a backup file
class BackupInfo {
  final int version;
  final DateTime createdAt;
  final String appName;
  final int transactionsCount;
  final int budgetsCount;
  final int categoriesCount;

  BackupInfo({
    required this.version,
    required this.createdAt,
    required this.appName,
    required this.transactionsCount,
    required this.budgetsCount,
    required this.categoriesCount,
  });
}
