import '../../data/models/transaction_model.dart';
import 'sms_transaction_service.dart';

/// Service for Google Pay transactions
class GooglePayService {
  final SmsTransactionService _smsParser = SmsTransactionService();

  Future<List<dynamic>> getGooglePaySms({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return [];
  }

  Future<List<Transaction>> parseGooglePayTransactions({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return [];
  }
}

