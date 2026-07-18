import '../../features/parser/services/sms_parser_service.dart';

class TransactionMerger {
  /// Merges duplicate transactions across SMS and Email channels.
  static List<Map<String, dynamic>> mergeDuplicateTransactions(List<Map<String, dynamic>> items) {
    final parser = SmsParserService();
    final List<Map<String, dynamic>> merged = [];
    final Set<int> mergedIndices = {};

    Map<String, dynamic>? parseGeneric(String body) {
      if (SmsParserService.isOtpOrPromo(body)) return null;
      final res = parser.parseRegexOnly(body);
      if (res != null && res.amount > 0) {
        return {
          'amount': res.amount,
          'transactionType': res.transactionType,
        };
      }
      try {
        final cleanBody = body.toLowerCase();
        final amtRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{2})?)');
        final match = amtRegex.firstMatch(cleanBody);
        if (match == null) return null;
        final amount = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
        if (amount <= 0) return null;

        final isIncome = cleanBody.contains('credited') || cleanBody.contains('received') || cleanBody.contains('deposit');
        final isExpense = cleanBody.contains('spent') ||
            cleanBody.contains('debited') ||
            cleanBody.contains('charged') ||
            cleanBody.contains('sent') ||
            cleanBody.contains('transaction') ||
            cleanBody.contains('txn') ||
            cleanBody.contains('purchase') ||
            cleanBody.contains('payment') ||
            cleanBody.contains('upi');
        if (!isIncome && !isExpense) return null;

        return {
          'amount': amount,
          'transactionType': isIncome ? 'income' : 'expense',
        };
      } catch (_) {
        return null;
      }
    }

    for (int i = 0; i < items.length; i++) {
      if (mergedIndices.contains(i)) continue;

      final itemA = items[i];
      final bodyA = itemA['body'] as String;
      final dateA = itemA['date'] as DateTime;
      final sourceA = itemA['source'] as String;

      final parsedA = parseGeneric(bodyA);
      if (parsedA == null || (parsedA['amount'] as double) <= 0) {
        merged.add(itemA);
        continue;
      }

      final List<int> matches = [];
      for (int j = i + 1; j < items.length; j++) {
        if (mergedIndices.contains(j)) continue;

        final itemB = items[j];
        final bodyB = itemB['body'] as String;
        final dateB = itemB['date'] as DateTime;

        if (bodyA == bodyB) {
          matches.add(j);
          continue;
        }

        final timeDiff = dateA.difference(dateB).abs().inMinutes;
        if (timeDiff > 15) continue;

        final parsedB = parseGeneric(bodyB);
        if (parsedB == null || (parsedB['amount'] as double) <= 0) continue;

        final amtA = parsedA['amount'] as double;
        final amtB = parsedB['amount'] as double;
        final amtDiff = (amtA - amtB).abs();

        final bodyALower = bodyA.toLowerCase();
        final bodyBLower = bodyB.toLowerCase();
        final isCardPayment = bodyALower.contains('cred') ||
            bodyALower.contains('towards') ||
            bodyALower.contains('card payment') ||
            bodyALower.contains('credit card') ||
            bodyBLower.contains('cred') ||
            bodyBLower.contains('towards') ||
            bodyBLower.contains('card payment') ||
            bodyBLower.contains('credit card');

        bool isMatch = false;

        if (isCardPayment) {
          if (amtDiff <= 150.0 && (amtDiff / amtA) < 0.02) {
            isMatch = true;
          }
        } else {
          if (amtDiff <= 0.05) {
            final typeA = parsedA['transactionType'] == 'transfer' ? 'expense' : parsedA['transactionType'];
            final typeB = parsedB['transactionType'] == 'transfer' ? 'expense' : parsedB['transactionType'];
            if (typeA == typeB) {
              isMatch = true;
            }
          }
        }

        if (isMatch) {
          matches.add(j);
        }
      }

      if (matches.isNotEmpty) {
        String smsBody = sourceA == 'sms' ? bodyA : '';
        String emailBody = sourceA == 'email' ? bodyA : '';
        String? mergedSubject = itemA['subject'] as String?;
        bool approvedByRegex = itemA['approvedByRegex'] == true;
        bool isAlreadyRecorded = itemA['isAlreadyRecorded'] == true;
        bool isSkipped = itemA['isSkipped'] == true;

        for (final matchIdx in matches) {
          mergedIndices.add(matchIdx);
          final matchItem = items[matchIdx];
          final matchSrc = matchItem['source'] as String;
          final matchBody = matchItem['body'] as String;
          final matchSubject = matchItem['subject'] as String?;
          if (matchSrc == 'sms') {
            if (smsBody.isEmpty) {
              smsBody = matchBody;
            } else if (!smsBody.contains(matchBody)) {
              smsBody = '$smsBody\n\n$matchBody';
            }
          }
          if (matchSrc == 'email') {
            if (emailBody.isEmpty) {
              emailBody = matchBody;
            } else if (!emailBody.contains(matchBody)) {
              emailBody = '$emailBody\n\n$matchBody';
            }
          }
          if (mergedSubject == null || mergedSubject.isEmpty) {
            mergedSubject = matchSubject;
          }
          if (matchItem['approvedByRegex'] == true) approvedByRegex = true;
          if (matchItem['isAlreadyRecorded'] == true) isAlreadyRecorded = true;
          if (matchItem['isSkipped'] == true) isSkipped = true;
        }

        final finalSource = (smsBody.isNotEmpty && emailBody.isNotEmpty)
            ? 'sms_email'
            : (smsBody.isNotEmpty ? 'sms' : 'email');

        final finalBody = finalSource == 'sms_email'
            ? '📱 SMS:\n$smsBody\n\n📧 EMAIL:\n$emailBody'
            : (smsBody.isNotEmpty ? smsBody : emailBody);

        merged.add({
          'body': finalBody,
          'date': dateA,
          'source': finalSource,
          'approvedByRegex': approvedByRegex,
          'smsBody': smsBody.isNotEmpty ? smsBody : null,
          'emailBody': emailBody.isNotEmpty ? emailBody : null,
          'subject': mergedSubject,
          'isAlreadyRecorded': isAlreadyRecorded,
          'isSkipped': isSkipped,
        });
      } else {
        merged.add(itemA);
      }
    }

    return merged;
  }
}
