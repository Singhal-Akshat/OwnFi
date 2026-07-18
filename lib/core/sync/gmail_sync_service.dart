import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import '../database_service.dart';
import '../../features/expenses/models/transaction_model.dart';
import 'google_auth_manager.dart';

class GmailSyncService {
  final GoogleAuthManager _authManager;
  final _storage = const FlutterSecureStorage();

  GmailSyncService(this._authManager);

  // Fetch emails from all linked Gmail accounts and parse transactions
  Future<List<Transaction>> syncTransactionsFromGmail(
    DatabaseService dbService,
  ) async {
    final List<Transaction> parsedTxs = [];
    final accounts = await _authManager.getLinkedAccounts();

    for (var acc in accounts) {
      try {
        final client = await _authManager.getHttpClient(
          acc,
          acc.isPrimary ? GoogleAuthManager.primaryScopes : GoogleAuthManager.secondaryScopes,
        );
        if (client == null) continue;

        final gmailApi = gmail.GmailApi(client);
        final lastSyncKey = 'last_gmail_sync_time_${acc.email}';

        // Fetch last sync timestamp for this specific email account or custom range
        final customStartStr = await _storage.read(
          key: 'settings_sync_start_date',
        );
        final customEndStr = await _storage.read(key: 'settings_sync_end_date');

        String query;
        if (customStartStr != null && customEndStr != null) {
          final start = DateTime.parse(customStartStr);
          final end = DateTime.parse(customEndStr);
          final localStart = DateTime(
            start.year,
            start.month,
            start.day,
            0,
            0,
            0,
          );
          final localEnd = DateTime(
            end.year,
            end.month,
            end.day,
            23,
            59,
            59,
            999,
          );
          final startSeconds = localStart.millisecondsSinceEpoch ~/ 1000;
          final endSeconds = localEnd.millisecondsSinceEpoch ~/ 1000;
          query =
              'subject:(Alert OR Transaction OR statement OR e-statement OR UPI OR txn OR debited OR credited) after:${startSeconds - 1} before:${endSeconds + 1}';
        } else {
          final lastEmailTx = await dbService.isar.transactions
              .filter()
              .isDeletedEqualTo(false)
              .group((q) => q.sourceEqualTo('gmail').or().sourceEqualTo('sms_email'))
              .sortByTimestampDesc()
              .findFirst();
          final lastSyncTime = lastEmailTx?.timestamp ?? DateTime.now().subtract(const Duration(days: 7));
          final seconds = lastSyncTime.millisecondsSinceEpoch ~/ 1000;
          query =
              'subject:(Alert OR Transaction OR statement OR e-statement OR UPI OR txn OR debited OR credited) after:$seconds';
        }

        final listRes = await gmailApi.users.messages.list('me', q: query);
        if (listRes.messages == null || listRes.messages!.isEmpty) continue;

        for (var msgRef in listRes.messages!) {
          final msg = await gmailApi.users.messages.get(
            'me',
            msgRef.id!,
            format: 'full',
          );
          if (msg.payload == null) continue;

          final date = msg.internalDate != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  int.parse(msg.internalDate!),
                )
              : DateTime.now();

          if (customStartStr != null && customEndStr != null) {
            final start = DateTime.parse(customStartStr);
            final end = DateTime.parse(customEndStr);
            final localStart = DateTime(
              start.year,
              start.month,
              start.day,
              0,
              0,
              0,
            );
            final localEnd = DateTime(
              end.year,
              end.month,
              end.day,
              23,
              59,
              59,
              999,
            );
            if (date.isBefore(localStart) || date.isAfter(localEnd)) {
              continue;
            }
          }

          // Parse Snippet or Body for transaction info
          final bodyText = _parseGmailMessageBody(msg);
          if (bodyText.isNotEmpty) {
            final tx = _parseTransactionFromText(bodyText, msg.internalDate);
            if (tx != null) {
              await dbService.saveTransaction(tx);
              parsedTxs.add(tx);
            }
          }
        }

        // Save last sync time
        await _storage.write(
          key: lastSyncKey,
          value: DateTime.now().toIso8601String(),
        );
      } catch (e) {
        debugPrint('Gmail Sync error for ${acc.email}: $e');
      }
    }

    return parsedTxs;
  }

  String _parseGmailMessageBody(gmail.Message msg) {
    if (msg.payload == null) {
      return msg.snippet ?? '';
    }

    String extractPart(gmail.MessagePart part) {
      if (part.mimeType == 'text/plain' && part.body?.data != null) {
        try {
          return utf8.decode(base64Url.decode(part.body!.data!));
        } catch (_) {}
      }
      if (part.mimeType == 'text/html' && part.body?.data != null) {
        try {
          var html = utf8.decode(base64Url.decode(part.body!.data!));
          html = html.replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
            '',
          );
          html = html.replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
            '',
          );
          html = html.replaceAll(
            RegExp(r'<head[^>]*>[\s\S]*?</head>', caseSensitive: false),
            '',
          );
          return html
              .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        } catch (_) {}
      }
      if (part.parts != null) {
        var content = '';
        for (var subPart in part.parts!) {
          final subContent = extractPart(subPart);
          if (subContent.isNotEmpty) {
            content += '$subContent\n';
          }
        }
        if (content.isNotEmpty) return content;
      }
      return '';
    }

    final fullBody = extractPart(msg.payload!);
    return fullBody.isNotEmpty ? fullBody : (msg.snippet ?? '');
  }

  Transaction? _parseTransactionFromText(String body, String? internalDateMs) {
    try {
      final cleanBody = body.toLowerCase();
      final amtRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{2})?)');
      final match = amtRegex.firstMatch(cleanBody);
      if (match == null) return null;

      final amount =
          double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
      if (amount <= 0) return null;

      final isIncome =
          cleanBody.contains('credited') ||
          cleanBody.contains('received') ||
          cleanBody.contains('deposit');
      final isExpense =
          cleanBody.contains('spent') ||
          cleanBody.contains('debited') ||
          cleanBody.contains('charged') ||
          cleanBody.contains('sent') ||
          cleanBody.contains('transaction') ||
          cleanBody.contains('txn') ||
          cleanBody.contains('purchase') ||
          cleanBody.contains('payment') ||
          cleanBody.contains('upi');
      if (!isIncome && !isExpense) return null;

      String desc = 'Gmail Transaction Alert';
      final merchants = [
        'netflix',
        'amazon',
        'uber',
        'zomato',
        'swiggy',
        'zerodha',
        'starbucks',
        'spotify',
      ];
      for (var m in merchants) {
        if (cleanBody.contains(m)) {
          desc = '${m.toUpperCase()} Transaction';
          break;
        }
      }

      final date = internalDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(internalDateMs))
          : DateTime.now();

      return Transaction()
        ..amount = amount
        ..description = desc
        ..transactionType = isIncome ? 'income' : 'expense'
        ..category = isIncome ? 'Salary' : 'Shopping'
        ..source = 'gmail'
        ..rawMessage = body
        ..timestamp = date;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNewEmailsForReview(
    DatabaseService dbService, {
    DateTime? since,
  }) async {
    final List<Map<String, dynamic>> results = [];
    final accounts = await _authManager.getLinkedAccounts();
    debugPrint(
      'fetchNewEmailsForReview: Found ${accounts.length} linked accounts.',
    );
    final prefs = await SharedPreferences.getInstance();
    final skippedList = prefs.getStringList('skipped_sms_messages') ?? [];
    final allowDuplicatesStr =
        await _storage.read(key: 'settings_sms_sync_allow_duplicates') ??
        'false';
    final bool allowDuplicates = allowDuplicatesStr == 'true';

    for (var acc in accounts) {
      try {
        debugPrint(
          'fetchNewEmailsForReview: Authenticating account ${acc.email} (isPrimary: ${acc.isPrimary})...',
        );
        final client = await _authManager.getHttpClient(
          acc,
          acc.isPrimary ? GoogleAuthManager.primaryScopes : GoogleAuthManager.secondaryScopes,
        );
        if (client == null) {
          debugPrint(
            'fetchNewEmailsForReview: Failed to get authenticated client for ${acc.email} (client was null).',
          );
          continue;
        }

        final gmailApi = gmail.GmailApi(client);
        final lastSyncKey = 'last_gmail_sync_time_${acc.email}';

        final customStartStr = await _storage.read(
          key: 'settings_sync_start_date',
        );
        final customEndStr = await _storage.read(key: 'settings_sync_end_date');

        String query;
        final bool useCustomRange =
            since == null && customStartStr != null && customEndStr != null;
        if (useCustomRange) {
          final start = DateTime.parse(customStartStr);
          final end = DateTime.parse(customEndStr);
          final localStart = DateTime(
            start.year,
            start.month,
            start.day,
            0,
            0,
            0,
          );
          final localEnd = DateTime(
            end.year,
            end.month,
            end.day,
            23,
            59,
            59,
            999,
          );
          final startSeconds = localStart.millisecondsSinceEpoch ~/ 1000;
          final endSeconds = localEnd.millisecondsSinceEpoch ~/ 1000;
          query =
              'subject:(Alert OR Transaction OR transaction OR statement OR e-statement OR UPI OR txn OR debited OR credited) after:${startSeconds - 1} before:${endSeconds + 1}';
        } else {
          final lastEmailTx = await dbService.isar.transactions
              .filter()
              .isDeletedEqualTo(false)
              .group((q) => q.sourceEqualTo('gmail').or().sourceEqualTo('sms_email'))
              .sortByTimestampDesc()
              .findFirst();
          DateTime lastSyncTime = lastEmailTx?.timestamp ?? DateTime.now().subtract(const Duration(days: 7));
          if (since != null && since.isBefore(lastSyncTime)) {
            lastSyncTime = since;
          }
          final seconds = lastSyncTime.millisecondsSinceEpoch ~/ 1000;
          query =
              'subject:(Alert OR Transaction OR transaction OR statement OR e-statement OR UPI OR txn OR debited OR credited) after:$seconds';
        }

        debugPrint('Gmail Sync Query: "$query" for account: ${acc.email}');
        final listRes = await gmailApi.users.messages.list('me', q: query);
        debugPrint(
          'Gmail API returned ${listRes.messages?.length ?? 0} messages for ${acc.email}',
        );
        if (listRes.messages == null || listRes.messages!.isEmpty) continue;

        for (var msgRef in listRes.messages!) {
          // Fetch metadata first to inspect Subject, Date and Sender without downloading the body
          final metaMsg = await gmailApi.users.messages.get(
            'me',
            msgRef.id!,
            format: 'metadata',
            metadataHeaders: ['subject', 'from'],
          );

          final subject = _getHeader(metaMsg, 'subject');
          final date = metaMsg.internalDate != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  int.parse(metaMsg.internalDate!),
                )
              : DateTime.now();

          debugPrint(
            'Processing Email ID: ${msgRef.id}, Subject: "$subject", Date (Local): $date',
          );

          if (customStartStr == null && since != null && date.isBefore(since)) {
            debugPrint(
              'Email ID ${msgRef.id} skipped: Received before since ($date is before $since)',
            );
            continue;
          }

          if (since == null && customStartStr != null && customEndStr != null) {
            final start = DateTime.parse(customStartStr);
            final end = DateTime.parse(customEndStr);
            final localStart = DateTime(
              start.year,
              start.month,
              start.day,
              0,
              0,
              0,
            );
            final localEnd = DateTime(
              end.year,
              end.month,
              end.day,
              23,
              59,
              59,
              999,
            );
            if (date.isBefore(localStart) || date.isAfter(localEnd)) {
              debugPrint(
                'Email ID ${msgRef.id} skipped: Out of date bounds ($date not between $localStart and $localEnd)',
              );
              continue;
            }
          }

          // Fetch full message body only if it passes the date checks
          final msg = await gmailApi.users.messages.get(
            'me',
            msgRef.id!,
            format: 'full',
          );
          if (msg.payload == null) {
            debugPrint('Email ID ${msgRef.id} skipped: No payload');
            continue;
          }

          final bodyText = _parseGmailMessageBody(msg);
          if (bodyText.isEmpty) {
            debugPrint('Email ID ${msgRef.id} skipped: Body is empty');
            continue;
          }

          final isar = dbService.isar;
          var isAlreadyRecorded =
              await isar.transactions
                  .filter()
                  .rawMessageEqualTo(bodyText)
                  .isDeletedEqualTo(false)
                  .findFirst() !=
              null;

          if (!isAlreadyRecorded) {
            final bodyLower = bodyText.toLowerCase();
            final isCardPayment = bodyLower.contains('cred') ||
                bodyLower.contains('towards') ||
                bodyLower.contains('card payment') ||
                bodyLower.contains('credit card');
            if (isCardPayment) {
              final amountReg = RegExp(r'(?:rs\.?|inr|₹)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false);
              final amtMatch = amountReg.firstMatch(bodyText);
              if (amtMatch != null) {
                final amt = double.tryParse(amtMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
                if (amt > 0) {
                  final startTime = date.subtract(const Duration(minutes: 15));
                  final endTime = date.add(const Duration(minutes: 15));
                  final similarTxs = await isar.transactions
                      .filter()
                      .timestampBetween(startTime, endTime)
                      .isDeletedEqualTo(false)
                      .findAll();
                  for (final tx in similarTxs) {
                    final diff = (tx.amount - amt).abs();
                    if (diff <= 150.0 && (diff / tx.amount) < 0.02) {
                      if (tx.transactionType == 'transfer' || tx.category == 'Credit card payment' || tx.category == 'Bills') {
                        isAlreadyRecorded = true;
                        break;
                      }
                    }
                  }
                }
              }
            }
          }

          final isSkipped = skippedList.contains(bodyText);

          if (!allowDuplicates && (isAlreadyRecorded || isSkipped)) {
            debugPrint(
              'Email ID ${msgRef.id} skipped: Already recorded or skipped previously (allowDuplicates=false)',
            );
            continue;
          }

          final isTx = _isTransactionalEmail(bodyText);
          debugPrint(
            'Email ID ${msgRef.id}: isTx=$isTx, isAlreadyRecorded=$isAlreadyRecorded, isSkipped=$isSkipped',
          );

          if (!isTx) {
            final regexSkippedList =
                prefs.getStringList('regex_skipped_messages') ?? [];
            final fromHeader = _getHeader(msg, 'from');
            final msgJson = jsonEncode({
              'body': bodyText,
              'date': date.toIso8601String(),
              'sender': fromHeader.isNotEmpty ? fromHeader : acc.email,
              'source': 'email',
            });
            if (!regexSkippedList.any(
              (item) => jsonDecode(item)['body'] == bodyText,
            )) {
              regexSkippedList.insert(0, msgJson);
              if (regexSkippedList.length > 200) {
                regexSkippedList.removeLast();
              }
              await prefs.setStringList(
                'regex_skipped_messages',
                regexSkippedList,
              );
            }
          }

          results.add({
            'body': bodyText,
            'subject': subject,
            'date': date,
            'source': 'email',
            'approvedByRegex': isTx,
            'isAlreadyRecorded': isAlreadyRecorded,
            'isSkipped': isSkipped,
          });
        }
      } catch (e) {
        debugPrint('Gmail Fetch Review error for ${acc.email}: $e');
      }
    }

    return results;
  }

  String _getHeader(gmail.Message msg, String name) {
    if (msg.payload?.headers == null) return '';
    for (var header in msg.payload!.headers!) {
      if (header.name?.toLowerCase() == name.toLowerCase()) {
        return header.value ?? '';
      }
    }
    return '';
  }

  bool _isTransactionalEmail(String body) {
    try {
      final cleanBody = body.toLowerCase();
      final amtRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{2})?)');
      final match = amtRegex.firstMatch(cleanBody);
      if (match == null) return false;

      final amount =
          double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
      if (amount <= 0) return false;

      final isIncome =
          cleanBody.contains('credited') ||
          cleanBody.contains('received') ||
          cleanBody.contains('deposit');
      final isExpense =
          cleanBody.contains('spent') ||
          cleanBody.contains('debited') ||
          cleanBody.contains('charged') ||
          cleanBody.contains('sent') ||
          cleanBody.contains('transaction') ||
          cleanBody.contains('txn') ||
          cleanBody.contains('purchase') ||
          cleanBody.contains('payment') ||
          cleanBody.contains('upi');
      return isIncome || isExpense;
    } catch (_) {
      return false;
    }
  }
}
