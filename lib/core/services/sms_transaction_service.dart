import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';

/// Service for SMS transaction parsing (disabled to satisfy Play Store permissions policy)
class SmsTransactionService {
  static bool get isSupported => false;

  Future<bool> requestPermissions() async => false;
  Future<bool> hasPermissions() async => false;

  Future<List<dynamic>> getAllSms({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];

  Future<List<Transaction>> parseTransactions({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];
}
