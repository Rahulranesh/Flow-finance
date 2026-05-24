import 'package:telephony/telephony.dart';
import '../../data/models/transaction_model.dart';
import 'sms_transaction_service.dart';

/// Service for syncing Google Pay transactions from SMS
class GooglePayService {
  final Telephony telephony = Telephony.instance;
  final SmsTransactionService _smsParser = SmsTransactionService();

  /// Get all Google Pay SMS messages
  Future<List<SmsMessage>> getGooglePaySms({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final messages = await telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        filter: SmsFilter.where(SmsColumn.ADDRESS)
            .equals('GPAY')
            .or(SmsColumn.ADDRESS)
            .like('%google%pay%'),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      // Filter by date range if provided
      var filteredMessages = messages;
      
      if (startDate != null || endDate != null) {
        filteredMessages = messages.where((msg) {
          if (msg.date == null) return false;
          final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date!);
          
          if (startDate != null && msgDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && msgDate.isAfter(endDate.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        }).toList();
      }

      if (limit != null && filteredMessages.length > limit) {
        return filteredMessages.sublist(0, limit);
      }

      return filteredMessages;
    } catch (e) {
      print('Error getting Google Pay SMS: $e');
      return [];
    }
  }

  /// Parse Google Pay transactions
  Future<List<Transaction>> parseGooglePayTransactions({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final messages = await getGooglePaySms(
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
    final transactions = <Transaction>[];

    for (final message in messages) {
      final transaction = _smsParser.parseGooglePayMessage(message);
      if (transaction != null) {
        // Additional date filtering if needed
        if (startDate != null && transaction.date.isBefore(startDate)) {
          continue;
        }
        if (endDate != null && transaction.date.isAfter(endDate.add(const Duration(days: 1)))) {
          continue;
        }
        transactions.add(transaction);
      }
    }

    return transactions;
  }
}
