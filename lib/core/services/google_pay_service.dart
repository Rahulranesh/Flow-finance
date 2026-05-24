import 'package:telephony/telephony.dart';
import '../../data/models/transaction_model.dart';
import 'sms_transaction_service.dart';

/// Service for syncing Google Pay transactions from SMS
class GooglePayService {
  final Telephony telephony = Telephony.instance;
  final SmsTransactionService _smsParser = SmsTransactionService();

  /// Get all Google Pay SMS messages
  Future<List<SmsMessage>> getGooglePaySms({int? limit}) async {
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

      if (limit != null && messages.length > limit) {
        return messages.sublist(0, limit);
      }

      return messages;
    } catch (e) {
      print('Error getting Google Pay SMS: $e');
      return [];
    }
  }

  /// Parse Google Pay transactions
  Future<List<Transaction>> parseGooglePayTransactions({int? limit}) async {
    final messages = await getGooglePaySms(limit: limit);
    final transactions = <Transaction>[];

    for (final message in messages) {
      final transaction = _smsParser.parseGooglePayMessage(message);
      if (transaction != null) {
        transactions.add(transaction);
      }
    }

    return transactions;
  }
}
