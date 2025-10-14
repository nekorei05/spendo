import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/db_helper.dart';
import 'notification_service.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;
  SmsService();

  // Ask SMS permission
  Future<bool> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // Listen for new SMS
  Future<void> initSmsListener(Function onNewTransaction) async {
    if (!await _requestSmsPermission()) return;

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _processSms(message, onNewTransaction);
      },
      onBackgroundMessage: _backgroundSmsHandler,
    );
  }

  // Import all past SMS
  Future<void> importExistingSms(Function onImported) async {
    if (!await _requestSmsPermission()) return;

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );

    for (final msg in messages) {
      await _processSms(msg, null); // no UI callback
    }

    onImported();
  }

  // Process SMS → save to DB
  Future<void> _processSms(SmsMessage msg, Function? onNewTransaction) async {
    final body = msg.body ?? '';
    final sender = msg.address ?? '';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);

    final amount = _extractAmount(body);
    if (amount != null) {
      final merchant = _extractMerchant(body, sender);
      final type = _detectType(body);
      final mode = _detectMode(body);
      final category = _detectCategory(body, mode);

      final transaction = {
        'amount': amount,
        'date': timestamp.toIso8601String(),
        'paidTo': merchant,
        'mode': mode,
        'category': category,
        'note': body,
        'type': type,
      };

      final isDuplicate = await DBHelper.checkDuplicate(transaction);
      if (!isDuplicate) {
        await DBHelper.insertExpense(transaction);

        if (onNewTransaction != null) {
          onNewTransaction();

          // Add notification here if you prefer:
          NotificationService.showNotification(
            type == 'income' ? 'Income Received' : 'Expense Recorded',
            '₹$amount at ${merchant ?? 'Unknown'}',
          );
        }
      }
    }
  }

  // Background SMS handler
  static Future<void> _backgroundSmsHandler(SmsMessage message) async {
    final body = message.body ?? '';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

    final amount = _extractAmountStatic(body);
    if (amount != null) {
      final merchant = _extractMerchantStatic(
        message.body ?? '',
        message.address ?? '',
      );
      final type = _detectTypeStatic(body);
      final mode = _detectModeStatic(body);
      final category = _detectCategoryStatic(body, mode);

      final transaction = {
        'amount': amount,
        'date': timestamp.toIso8601String(),
        'paidTo': merchant,
        'mode': mode,
        'category': category,
        'note': body,
        'type': type,
      };

      final isDuplicate = await DBHelper.checkDuplicate(transaction);
      if (!isDuplicate) await DBHelper.insertExpense(transaction);
    }
  }

  // Amount extraction with regex
  // Amount extraction with regex
  double? _extractAmount(String body) {
    final regex = RegExp(r'(₹|Rs\.?|INR)\s?([0-9,]+(\.[0-9]{1,2})?)');
    final match = regex.firstMatch(body);
    if (match != null) {
      final numStr = match.group(2)!.replaceAll(',', '');
      final value = double.tryParse(numStr);
      if (value != null) {
        return double.parse(value.toStringAsFixed(2)); // always 2 decimals
      }
    }
    return null;
  }

  static double? _extractAmountStatic(String body) {
    final regex = RegExp(r'(₹|Rs\.?|INR)\s?([0-9,]+(\.[0-9]{1,2})?)');
    final match = regex.firstMatch(body);
    if (match != null) {
      final numStr = match.group(2)!.replaceAll(',', '');
      final value = double.tryParse(numStr);
      if (value != null) {
        return double.parse(value.toStringAsFixed(2));
      }
    }
    return null;
  }

  // Merchant extraction
  String? _extractMerchant(String body, String sender) {
    final keywords = ['at', 'to', 'via', 'on', 'with', 'by'];
    for (var kw in keywords) {
      final pattern = RegExp(r'\b' + kw + r'\s+([A-Za-z&\-\s]{2,20})');
      final match = pattern.firstMatch(body.toLowerCase());
      if (match != null) {
        var merchant = match.group(1)?.trim();
        if (merchant != null) {
          merchant = merchant
              .split(' ')
              .take(2)
              .join(' '); // only first 2 words
          // Capitalize first letter
          return merchant[0].toUpperCase() + merchant.substring(1);
        }
      }
    }

    // If UPI handle present → use before '@'
    final upiRegex = RegExp(r'[\w\.\-]+@[\w]+');
    final upiMatch = upiRegex.firstMatch(body);
    if (upiMatch != null) {
      return upiMatch.group(0)!.split('@')[0];
    }

    // Fallback to sender if nothing found
    return sender;
  }

  static String? _extractMerchantStatic(String body, String sender) {
    final keywords = ['at', 'to', 'via', 'on', 'with', 'by'];
    for (var kw in keywords) {
      final pattern = RegExp(r'\b' + kw + r'\s+([A-Za-z&\-\s]{2,20})');
      final match = pattern.firstMatch(body.toLowerCase());
      if (match != null) {
        var merchant = match.group(1)?.trim();
        if (merchant != null) {
          merchant = merchant.split(' ').take(2).join(' ');
          return merchant[0].toUpperCase() + merchant.substring(1);
        }
      }
    }

    final upiRegex = RegExp(r'[\w\.\-]+@[\w]+');
    final upiMatch = upiRegex.firstMatch(body);
    if (upiMatch != null) {
      return upiMatch.group(0)!.split('@')[0];
    }

    return sender;
  }

  // Detect mode
  String _detectMode(String body) {
    final lower = body.toLowerCase();
    if (lower.contains("upi")) return "UPI";
    if (lower.contains("card")) return "Card";
    if (lower.contains("atm")) return "ATM";
    if (lower.contains("cash")) return "Cash";
    return "Other";
  }

  static String _detectModeStatic(String body) {
    final lower = body.toLowerCase();
    if (lower.contains("upi")) return "UPI";
    if (lower.contains("card")) return "Card";
    if (lower.contains("atm")) return "ATM";
    if (lower.contains("cash")) return "Cash";
    return "Other";
  }

  // Detect type (income or expense)
  String _detectType(String body) {
    final lower = body.toLowerCase();
    if (lower.contains("credited") ||
        lower.contains("received") ||
        lower.contains("deposit")) {
      return "income";
    }
    return "expense";
  }

  static String _detectTypeStatic(String body) {
    final lower = body.toLowerCase();
    if (lower.contains("credited") ||
        lower.contains("received") ||
        lower.contains("deposit")) {
      return "income";
    }
    return "expense";
  }

  // Detect category
  String _detectCategory(String body, String mode) {
    final lower = body.toLowerCase();
    if (mode == "UPI") return "UPI";
    if (mode == "Card") return "Card Payment";
    if (lower.contains("atm")) return "ATM Withdrawal";
    if (lower.contains("salary") || lower.contains("credited")) return "Salary";
    if (lower.contains("bill")) return "Bills";
    if (lower.contains("travel") ||
        lower.contains("bus") ||
        lower.contains("train"))
      return "Travel";
    return "Other";
  }

  static String _detectCategoryStatic(String body, String mode) {
    final lower = body.toLowerCase();
    if (mode == "UPI") return "UPI";
    if (mode == "Card") return "Card Payment";
    if (lower.contains("atm")) return "ATM Withdrawal";
    if (lower.contains("salary") || lower.contains("credited")) return "Salary";
    if (lower.contains("bill")) return "Bills";
    if (lower.contains("travel") ||
        lower.contains("bus") ||
        lower.contains("train"))
      return "Travel";
    return "Other";
  }
}
