import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/db_helper.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;
  Future<void> initSmsListener() async {
    bool granted = await _requestSmsPermission();
    if (!granted) return;

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _processSms(message);
      },
      onBackgroundMessage: _backgroundSmsHandler,
    );
  }

  Future<void> importExistingSms() async {
    final granted = await _requestSmsPermission();
    if (!granted) return;

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );

    for (final msg in messages) {
      _processSms(msg);
    }
  }

  Future<bool> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  void _processSms(SmsMessage msg) {
    final body = msg.body ?? '';
    final sender = msg.address ?? '';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);

    // Very simple example to extract amount using regex
    final amountMatch = RegExp(r"₹\s?([\d,]+\.\d{2})").firstMatch(body);
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(amountStr);

      if (amount != null) {
        final transaction = {
          'amount': amount,
          'date': timestamp.toIso8601String(),
          'paidTo': sender,
          'mode': 'SMS',
          'category': 'Auto',
          'note': body,
          'type': 'expense',
        };
        DBHelper.insertExpense(transaction);
      }
    }
  }
}

// Required for background SMS
void _backgroundSmsHandler(SmsMessage message) {
  // You can log or queue for processing later
}
