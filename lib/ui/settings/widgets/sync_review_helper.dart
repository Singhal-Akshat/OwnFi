import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';

import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/database_service.dart';
import '../../../../features/expenses/models/transaction_model.dart';
import '../../../../features/cards_loans/models/card_loan_models.dart';
import '../../../../features/investments/models/holding_model.dart';
import '../../../../features/parser/services/sms_parser_service.dart';
import '../../../../features/expenses/ui/widgets/transaction_dialogs.dart';

// Expose GlassBlur if defined locally or copy its style
// In settings_view, GlassBlur was imported/used. Since we don't know where it is, let's look at settings_view imports.
// Ah! In settings_view, there is no separate import for GlassBlur, meaning it is defined in theme.dart or settings_view.dart itself.
// Let's check theme.dart or search the project for "class GlassBlur".
// Actually, let's write a standard GlassBlur or fallback in this helper to be safe, or import it.
// Let's search the project for "class GlassBlur".
void showFlagKeywordsDialog(BuildContext context, String rawBody) {
  final flagController = TextEditingController();
  final parser = SmsParserService();
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: GlassBlur(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parser Tuning & Logs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonTeal,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Add keywords to train the Regex parser. Red flags exclude similar messages (e.g. OTPs). Green flags force match them.',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: flagController,
                  decoration: const InputDecoration(
                    labelText: 'Keyword / Phrase',
                    hintText: 'e.g. "otp", "pre-approved"',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final word = flagController.text.trim().toLowerCase();
                        if (word.isEmpty) return;

                        final prefs = await SharedPreferences.getInstance();
                        final list = prefs.getStringList('custom_red_flags') ?? [];
                        if (!list.contains(word)) {
                          list.add(word);
                          await prefs.setStringList('custom_red_flags', list);
                        }
                        await parser.logDebug('Added Red Flag keyword: "$word" for message: "$rawBody"');
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added Red Flag: "$word"'),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text('Add Red Flag', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final word = flagController.text.trim().toLowerCase();
                        if (word.isEmpty) return;

                        final prefs = await SharedPreferences.getInstance();
                        final list = prefs.getStringList('custom_green_flags') ?? [];
                        if (!list.contains(word)) {
                          list.add(word);
                          await prefs.setStringList('custom_green_flags', list);
                        }
                        await parser.logDebug('Added Green Flag keyword: "$word" for message: "$rawBody"');
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added Green Flag: "$word"'),
                            backgroundColor: AppColors.neonEmerald,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonEmerald),
                      child: const Text('Add Green Flag', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showSyncReviewDialog(
  BuildContext context,
  WidgetRef ref,
  List<Map<String, dynamic>> items, {
  required bool showOnlyValidSmsEmail,
}) {
  final validItems = items.where((item) => item['approvedByRegex'] == true).toList();
  final rejectedItems = items.where((item) => item['approvedByRegex'] == false).toList();

  List<Map<String, dynamic>> currentReviewItems = showOnlyValidSmsEmail ? validItems : items;
  bool reviewingRejected = false;

  int currentIndex = 0;
  int importedCount = 0;
  int skippedCount = 0;

  int? editingRejectedIndex;
  final Set<int> processedIndices = {};

  final parser = SmsParserService();
  final Map<int, ParsedSmsTransaction?> regexCache = {};
  final Map<int, ParsedSmsTransaction?> geminiCache = {};
  final Map<int, bool> geminiLoading = {};
  final Map<int, bool> forceGemini = {};
  final Map<int, bool> disagreed = {};

  int? lastInitializedIndex;
  ParsedSmsTransaction? lastGemini;
  ParsedSmsTransaction? lastRegex;

  final controller = TransactionFormController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (stateContext, setState) {
          if (reviewingRejected && editingRejectedIndex == null) {
            final unprocessedRejectedIndices = List.generate(rejectedItems.length, (i) => i)
                .where((i) => !processedIndices.contains(i))
                .toList();

            if (unprocessedRejectedIndices.isEmpty) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: GlassBlur(
                  borderRadius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.neonEmerald,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'All Rejected Messages Reviewed!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Imported: $importedCount\nSkipped: $skippedCount',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            const storage = FlutterSecureStorage();
                            await storage.write(key: 'last_sms_sync_time', value: DateTime.now().toIso8601String());
                            ref.read(transactionsProvider.notifier).loadTransactions();
                            ref.read(creditCardsProvider.notifier).loadCreditCards();
                            ref.read(loansProvider.notifier).loadLoans();
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonTeal,
                          ),
                          child: const Text('Finish Sync', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rejected Messages (${unprocessedRejectedIndices.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonTeal,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              const storage = FlutterSecureStorage();
                              await storage.write(key: 'last_sms_sync_time', value: DateTime.now().toIso8601String());
                              ref.read(transactionsProvider.notifier).loadTransactions();
                              ref.read(creditCardsProvider.notifier).loadCreditCards();
                              ref.read(loansProvider.notifier).loadLoans();
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'These messages were filtered out by rules. Tap any message to manually approve it as a transaction.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: unprocessedRejectedIndices.length,
                          itemBuilder: (context, index) {
                            final rejectedIndex = unprocessedRejectedIndices[index];
                            final rejectedItem = rejectedItems[rejectedIndex];
                            final String body = rejectedItem['body'] ?? '';
                            final DateTime date = rejectedItem['date'] ?? DateTime.now();
                            final String source = rejectedItem['source'] ?? 'sms';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    editingRejectedIndex = rejectedIndex;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                source == 'sms' ? Icons.sms_rounded : Icons.email_rounded,
                                                size: 14,
                                                color: Colors.blueAccent,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                source.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a').format(date),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white38,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        body,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: Colors.white70,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Process Message',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.neonTeal,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 10,
                                            color: AppColors.neonTeal,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final skippedList = prefs.getStringList('skipped_sms_messages') ?? [];
                              int newlySkipped = 0;
                              for (final idx in unprocessedRejectedIndices) {
                                final rItem = rejectedItems[idx];
                                final rBody = rItem['body'] ?? '';
                                if (!skippedList.contains(rBody)) {
                                  skippedList.add(rBody);
                                  newlySkipped++;
                                }
                                processedIndices.add(idx);
                              }
                              if (newlySkipped > 0) {
                                await prefs.setStringList('skipped_sms_messages', skippedList);
                              }
                              setState(() {
                                skippedCount += newlySkipped;
                              });
                            },
                            child: const Text(
                              'Skip All Remaining',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonTeal,
                            ),
                            onPressed: () async {
                              const storage = FlutterSecureStorage();
                              await storage.write(key: 'last_sms_sync_time', value: DateTime.now().toIso8601String());
                              ref.read(transactionsProvider.notifier).loadTransactions();
                              ref.read(creditCardsProvider.notifier).loadCreditCards();
                              ref.read(loansProvider.notifier).loadLoans();
                              Navigator.pop(dialogContext);
                            },
                            child: const Text(
                              'Finish Sync',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (currentIndex >= currentReviewItems.length) {
            if (showOnlyValidSmsEmail && !reviewingRejected && rejectedItems.isNotEmpty) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: GlassBlur(
                  borderRadius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.neonEmerald,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Valid Messages Reviewed!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Imported: $importedCount\nSkipped: $skippedCount',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            'There are ${rejectedItems.length} messages that were rejected/filtered out by the regex parser.',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () async {
                                const storage = FlutterSecureStorage();
                                await storage.write(key: 'last_sms_sync_time', value: DateTime.now().toIso8601String());
                                ref.read(transactionsProvider.notifier).loadTransactions();
                                ref.read(creditCardsProvider.notifier).loadCreditCards();
                                ref.read(loansProvider.notifier).loadLoans();
                                Navigator.pop(dialogContext);
                              },
                              child: const Text('Finish Sync', style: TextStyle(color: Colors.white70)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentReviewItems = rejectedItems;
                                  currentIndex = 0;
                                  reviewingRejected = true;
                                  regexCache.clear();
                                  geminiCache.clear();
                                  geminiLoading.clear();
                                  forceGemini.clear();
                                  disagreed.clear();
                                  lastInitializedIndex = null;
                                  lastGemini = null;
                                  lastRegex = null;
                                  controller.reset();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonTeal,
                              ),
                              child: Text(
                                'Review Rejected (${rejectedItems.length})',
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.neonEmerald,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        reviewingRejected ? 'Rejected Review Finished!' : 'Sync Review Finished!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Imported: $importedCount\nSkipped: $skippedCount',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          const storage = FlutterSecureStorage();
                          await storage.write(key: 'last_sms_sync_time', value: DateTime.now().toIso8601String());
                          ref.read(transactionsProvider.notifier).loadTransactions();
                          ref.read(creditCardsProvider.notifier).loadCreditCards();
                          ref.read(loansProvider.notifier).loadLoans();
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonTeal,
                        ),
                        child: const Text('Close', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final activeIndex = reviewingRejected && editingRejectedIndex != null ? editingRejectedIndex! : currentIndex;
          final item = currentReviewItems[activeIndex];
          final String rawBody = item['body'] ?? '';
          final DateTime date = item['date'] ?? DateTime.now();

          final cardsState = ref.watch(creditCardsProvider);
          final bankAccountsState = ref.watch(bankAccountsProvider);

          void ensureParsed(int index) {
            if (index < 0 || index >= currentReviewItems.length) return;
            final bodyText = currentReviewItems[index]['body'] as String;
            final isApproved = currentReviewItems[index]['approvedByRegex'] ?? false;

            if (!regexCache.containsKey(index)) {
              regexCache[index] = parser.parseRegexOnly(bodyText);
            }

            final shouldCallGemini = isApproved || (forceGemini[index] ?? false);

            if (index == activeIndex && shouldCallGemini && !geminiCache.containsKey(index) && !(geminiLoading[index] ?? false)) {
              geminiLoading[index] = true;
              final activeCards = cardsState.valueOrNull;
              final activeBanks = bankAccountsState.valueOrNull;
              parser.parseGeminiOnly(bodyText, cards: activeCards, bankAccounts: activeBanks).then((geminiResult) {
                if (geminiResult != null) {
                  setState(() {
                    geminiCache[index] = geminiResult;
                    geminiLoading[index] = false;
                    if (lastInitializedIndex != activeIndex) {
                      controller.reset();
                    }
                    
                    if (activeIndex == index) {
                      controller.amountController.text = geminiResult.amount.toStringAsFixed(0);
                      controller.descriptionController.text = geminiResult.merchant;
                      controller.selectedType = geminiResult.transactionType;
                      controller.selectedCategory = geminiResult.category;
                      if (controller.selectedCategory == 'Utilities') controller.selectedCategory = 'Bills';

                      controller.selectedAccount = 'Cash';
                      if (geminiResult.matchedAccountId != null) {
                        controller.selectedAccount = geminiResult.matchedAccountId!;
                      } else {
                        final bodyLower = bodyText.toLowerCase();
                        if (bodyLower.contains('hdfc')) {
                          bankAccountsState.whenData((banks) {
                            final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                            if (match.id != Isar.autoIncrement) {
                              controller.selectedAccount = 'bank:${match.id}';
                            }
                          });
                        } else if (bodyLower.contains('sbi')) {
                          bankAccountsState.whenData((banks) {
                            final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                            if (match.id != Isar.autoIncrement) {
                              controller.selectedAccount = 'bank:${match.id}';
                            }
                          });
                        }
                        
                        if (controller.selectedAccount == 'Cash') {
                          if (geminiResult.cardLast4 != null) {
                            cardsState.whenData((cards) {
                              final match = cards.firstWhere((c) => c.last4 == geminiResult.cardLast4, orElse: () => CreditCard());
                              if (match.id != Isar.autoIncrement) {
                                controller.selectedAccount = 'card:${match.id}';
                              }
                            });
                          } else if (geminiResult.accountLast4 != null) {
                            bankAccountsState.whenData((banks) {
                              final match = banks.firstWhere((b) => b.last4 == geminiResult.accountLast4, orElse: () => BankAccount());
                              if (match.id != Isar.autoIncrement) {
                                controller.selectedAccount = 'bank:${match.id}';
                              }
                            });
                          }
                        }
                      }
                    }
                  });
                } else {
                  setState(() {
                    geminiLoading[index] = false;
                  });
                }
              }).catchError((e) {
                setState(() {
                  geminiLoading[index] = false;
                });
                parser.logDebug('Gemini parse error: $e');
              });
            }
          }

          ensureParsed(activeIndex);
          if (!reviewingRejected) {
            ensureParsed(activeIndex + 1);
            ensureParsed(activeIndex + 2);
          }

          final regexResult = regexCache[activeIndex];
          final geminiResult = geminiCache[activeIndex];

          if (lastInitializedIndex != activeIndex || lastGemini != geminiResult || lastRegex != regexResult) {
            if (lastInitializedIndex != activeIndex) {
              controller.reset();
            }
            lastInitializedIndex = activeIndex;
            lastGemini = geminiResult;
            lastRegex = regexResult;

            final initialSource = (geminiResult != null && geminiResult.isTransaction) ? geminiResult : (regexResult ?? geminiResult);
            controller.amountController.text = (initialSource?.amount ?? 0.0).toStringAsFixed(0);
            controller.descriptionController.text = initialSource?.merchant ?? 'Unknown Merchant';
            controller.selectedType = initialSource?.transactionType ?? 'expense';
            controller.selectedCategory = initialSource?.category ?? 'Other';
            if (controller.selectedCategory == 'Utilities') controller.selectedCategory = 'Bills';

            controller.selectedAccount = 'Cash';
            if (initialSource?.matchedAccountId != null) {
              controller.selectedAccount = initialSource!.matchedAccountId!;
            } else {
              final bodyLower = rawBody.toLowerCase();
              if (bodyLower.contains('hdfc')) {
                bankAccountsState.whenData((banks) {
                  final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                  if (match.id != Isar.autoIncrement) {
                    controller.selectedAccount = 'bank:${match.id}';
                  }
                });
              } else if (bodyLower.contains('sbi')) {
                bankAccountsState.whenData((banks) {
                  final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                  if (match.id != Isar.autoIncrement) {
                    controller.selectedAccount = 'bank:${match.id}';
                  }
                });
              }

              if (controller.selectedAccount == 'Cash') {
                final last4 = initialSource?.cardLast4 ?? initialSource?.accountLast4;
                if (last4 != null) {
                  if (initialSource?.cardLast4 != null) {
                    cardsState.whenData((cards) {
                      final match = cards.firstWhere((c) => c.last4 == last4, orElse: () => CreditCard());
                      if (match.id != Isar.autoIncrement) {
                        controller.selectedAccount = 'card:${match.id}';
                      }
                    });
                  } else {
                    bankAccountsState.whenData((banks) {
                      final match = banks.firstWhere((b) => b.last4 == last4, orElse: () => BankAccount());
                      if (match.id != Isar.autoIncrement) {
                        controller.selectedAccount = 'bank:${match.id}';
                      }
                    });
                  }
                }
              }
            }
          }

          return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, prefsSnapshot) {
              if (!prefsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.neonTeal));
              }
              final prefs = prefsSnapshot.data!;
              final expenseCats = List<String>.from(prefs.getStringList('categories_expense') ?? ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Health', 'Education', 'Investment', 'Other']);
              final incomeCats = List<String>.from(prefs.getStringList('categories_income') ?? ['Salary', 'Investment', 'Family Money transfer', 'Friend money transfer', 'Due Amount', 'Other']);
              final transferCats = List<String>.from(prefs.getStringList('categories_transfer') ?? ['Internal transfer', 'Credit card payment', 'Investment', 'Other']);

              final currentCats = List<String>.from(controller.selectedType == 'expense'
                  ? expenseCats
                  : (controller.selectedType == 'income' ? incomeCats : transferCats));

              if (!currentCats.contains('Investment')) {
                currentCats.add('Investment');
              }

              if (!currentCats.contains(controller.selectedCategory)) {
                if (currentCats.contains('Other')) {
                  controller.selectedCategory = 'Other';
                } else if (currentCats.isNotEmpty) {
                  controller.selectedCategory = currentCats.first;
                } else {
                  controller.selectedCategory = '';
                }
              }

              List<DropdownMenuItem<String>> buildDropdownItems(String valueToVerify) {
                final List<DropdownMenuItem<String>> menu = [
                  const DropdownMenuItem(
                    value: 'Cash',
                    child: Text('Cash', overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                ];
                bankAccountsState.maybeWhen(
                  data: (banks) {
                    menu.addAll(banks.map((b) => DropdownMenuItem(
                      value: 'bank:${b.id}',
                      child: Text(b.bankName, overflow: TextOverflow.ellipsis, maxLines: 1),
                    )));
                  },
                  orElse: () {},
                );
                cardsState.maybeWhen(
                  data: (cards) {
                    menu.addAll(cards.map((c) => DropdownMenuItem(
                      value: 'card:${c.id}',
                      child: Text(c.cardName, overflow: TextOverflow.ellipsis, maxLines: 1),
                    )));
                  },
                  orElse: () {},
                );
                final hasSel = menu.any((item) => item.value == valueToVerify);
                if (!hasSel) {
                  menu.add(
                    DropdownMenuItem(
                      value: valueToVerify,
                      child: Text(
                        valueToVerify.startsWith('bank:')
                            ? 'Deleted Bank Account'
                            : valueToVerify.startsWith('card:')
                                ? 'Deleted Card'
                                : valueToVerify,
                      ),
                    ),
                  );
                }
                return menu;
              }

              return Dialog(
                backgroundColor: Colors.transparent,
                child: GlassBlur(
                  borderRadius: 24,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (reviewingRejected && editingRejectedIndex != null) ...[
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      editingRejectedIndex = null;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  reviewingRejected
                                      ? 'Review Rejected'
                                      : 'Review Sync (${currentIndex + 1}/${currentReviewItems.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neonTeal,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['source'] == 'sms' ? '📱 SMS' : '📧 Email',
                                  style: const TextStyle(fontSize: 10, color: Colors.blueAccent),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(date),
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (item['approvedByRegex'] ?? false) ? AppColors.neonEmerald.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (item['approvedByRegex'] ?? false) ? AppColors.neonEmerald : Colors.redAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  (item['approvedByRegex'] ?? false) ? 'Regex: Approved' : 'Regex: Rejected',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: (item['approvedByRegex'] ?? false) ? AppColors.neonEmerald : Colors.redAccent,
                                  ),
                                ),
                              ),
                              if (!(item['approvedByRegex'] ?? false) && !(forceGemini[activeIndex] ?? false) && geminiCache[activeIndex] == null) ...[
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      forceGemini[activeIndex] = true;
                                    });
                                    parser.logDebug('Manual Gemini request triggered for index $activeIndex: "$rawBody"');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonTeal.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.neonTeal, width: 1),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_awesome, size: 10, color: AppColors.neonTeal),
                                        SizedBox(width: 4),
                                        Text(
                                          'Run Gemini anyway',
                                          style: TextStyle(fontSize: 10, color: AppColors.neonTeal, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Raw Message Context:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(maxHeight: 100),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                rawBody,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if ((!(item['approvedByRegex'] ?? false) || (geminiResult != null && !geminiResult.isTransaction)) && !(disagreed[activeIndex] ?? false)) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (geminiResult != null && !geminiResult.isTransaction)
                                          ? 'Gemini AI classified this message as Non-Transactional/Spam. Do you agree?'
                                          : 'This message was classified as Non-Transactional (like an OTP, alert, or spam). Do you agree?',
                                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    parser.logDebug('Agreed with rejection (Spam/Non-Tx) for index $activeIndex: "$rawBody"');
                                    final prefs = await SharedPreferences.getInstance();
                                    final skippedList = prefs.getStringList('skipped_sms_messages') ?? [];
                                    if (!skippedList.contains(rawBody)) {
                                      skippedList.add(rawBody);
                                      await prefs.setStringList('skipped_sms_messages', skippedList);
                                    }
                                    setState(() {
                                      skippedCount++;
                                      if (reviewingRejected) {
                                        processedIndices.add(activeIndex);
                                        editingRejectedIndex = null;
                                      } else {
                                        currentIndex++;
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.check_circle_outline, color: AppColors.neonEmerald, size: 14),
                                  label: const Text('Agree (Reject)', style: TextStyle(color: AppColors.neonEmerald, fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.neonEmerald),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    parser.logDebug('Disagreed with rejection (Message is transaction) for index $activeIndex: "$rawBody"');
                                    setState(() {
                                      disagreed[activeIndex] = true;
                                      forceGemini[activeIndex] = true;
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded, color: Colors.black, size: 14),
                                  label: const Text('Disagree (Approve)', style: TextStyle(color: Colors.black, fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                          if (geminiLoading[activeIndex] ?? false)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonTeal),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Gemini AI parsing in background...',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.neonTeal,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),

                          if (regexResult != null || geminiResult != null)
                            Row(
                              children: [
                                if (regexResult != null)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        controller.amountController.text = regexResult.amount.toStringAsFixed(0);
                                        controller.descriptionController.text = regexResult.merchant;
                                        setState(() {
                                          controller.selectedType = regexResult.transactionType;
                                          controller.selectedCategory = regexResult.category;
                                          if (controller.selectedCategory == 'Utilities') controller.selectedCategory = 'Bills';
                                          const allowedCategories = ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Health', 'Education', 'Other'];
                                          if (!allowedCategories.contains(controller.selectedCategory)) {
                                            controller.selectedCategory = 'Other';
                                          }

                                          controller.selectedAccount = 'Cash';
                                          if (regexResult.matchedAccountId != null) {
                                            controller.selectedAccount = regexResult.matchedAccountId!;
                                          } else {
                                            final bodyLower = rawBody.toLowerCase();
                                            if (bodyLower.contains('hdfc')) {
                                              bankAccountsState.whenData((banks) {
                                                final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                                                if (match.id != Isar.autoIncrement) {
                                                  controller.selectedAccount = 'bank:${match.id}';
                                                }
                                              });
                                            } else if (bodyLower.contains('sbi')) {
                                              bankAccountsState.whenData((banks) {
                                                final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                                                if (match.id != Isar.autoIncrement) {
                                                  controller.selectedAccount = 'bank:${match.id}';
                                                }
                                              });
                                            }

                                            if (controller.selectedAccount == 'Cash') {
                                              final last4 = regexResult.cardLast4 ?? regexResult.accountLast4;
                                              if (last4 != null) {
                                                if (regexResult.cardLast4 != null) {
                                                  cardsState.whenData((cards) {
                                                    final match = cards.firstWhere((c) => c.last4 == last4, orElse: () => CreditCard());
                                                    if (match.id != Isar.autoIncrement) {
                                                      controller.selectedAccount = 'card:${match.id}';
                                                    }
                                                  });
                                                } else {
                                                  bankAccountsState.whenData((banks) {
                                                    final match = banks.firstWhere((b) => b.last4 == last4, orElse: () => BankAccount());
                                                    if (match.id != Isar.autoIncrement) {
                                                      controller.selectedAccount = 'bank:${match.id}';
                                                    }
                                                  });
                                                }
                                              }
                                            }
                                          }
                                        });
                                      },
                                      child: const Text('Use Regex Guess', style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                if (geminiResult != null)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        controller.amountController.text = geminiResult.amount.toStringAsFixed(0);
                                        controller.descriptionController.text = geminiResult.merchant;
                                        setState(() {
                                          controller.selectedType = geminiResult.transactionType;
                                          controller.selectedCategory = geminiResult.category;
                                          if (controller.selectedCategory == 'Utilities') controller.selectedCategory = 'Bills';
                                          const allowedCategories = ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Health', 'Education', 'Other'];
                                          if (!allowedCategories.contains(controller.selectedCategory)) {
                                            controller.selectedCategory = 'Other';
                                          }

                                          controller.selectedAccount = 'Cash';
                                          if (geminiResult.matchedAccountId != null) {
                                            controller.selectedAccount = geminiResult.matchedAccountId!;
                                          } else {
                                            final bodyLower = rawBody.toLowerCase();
                                            if (bodyLower.contains('hdfc')) {
                                              bankAccountsState.whenData((banks) {
                                                final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                                                if (match.id != Isar.autoIncrement) {
                                                  controller.selectedAccount = 'bank:${match.id}';
                                                }
                                              });
                                            } else if (bodyLower.contains('sbi')) {
                                              bankAccountsState.whenData((banks) {
                                                final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                                                if (match.id != Isar.autoIncrement) {
                                                  controller.selectedAccount = 'bank:${match.id}';
                                                }
                                              });
                                            }

                                            if (controller.selectedAccount == 'Cash') {
                                              if (geminiResult.cardLast4 != null) {
                                                cardsState.whenData((cards) {
                                                  final match = cards.firstWhere((c) => c.last4 == geminiResult.cardLast4, orElse: () => CreditCard());
                                                  if (match.id != Isar.autoIncrement) {
                                                    controller.selectedAccount = 'card:${match.id}';
                                                  }
                                                });
                                              } else if (geminiResult.accountLast4 != null) {
                                                bankAccountsState.whenData((banks) {
                                                  final match = banks.firstWhere((b) => b.last4 == geminiResult.accountLast4, orElse: () => BankAccount());
                                                  if (match.id != Isar.autoIncrement) {
                                                    controller.selectedAccount = 'bank:${match.id}';
                                                  }
                                                });
                                              }
                                            }
                                          }
                                        });
                                      },
                                      child: const Text('Use Gemini Guess', style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          TransactionFormFields(
                            controller: controller,
                            onStateChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 16),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  showFlagKeywordsDialog(context, rawBody);
                                },
                                icon: const Icon(Icons.flag_rounded, color: Colors.orangeAccent, size: 16),
                                label: const Text(
                                  'Mark Wrong / Flags',
                                  style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      parser.logDebug('Skip clicked for index $activeIndex. Raw body: "$rawBody"');
                                      final prefs = await SharedPreferences.getInstance();
                                      final skippedList = prefs.getStringList('skipped_sms_messages') ?? [];
                                      if (!skippedList.contains(rawBody)) {
                                        skippedList.add(rawBody);
                                        await prefs.setStringList('skipped_sms_messages', skippedList);
                                      }
                                      setState(() {
                                        skippedCount++;
                                        if (reviewingRejected) {
                                          processedIndices.add(activeIndex);
                                          editingRejectedIndex = null;
                                        } else {
                                          currentIndex++;
                                        }
                                      });
                                    },
                                    child: const Text('Skip', style: TextStyle(color: Colors.white70)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final double amt = double.tryParse(controller.amountController.text) ?? 0.0;
                                      final merchant = controller.descriptionController.text.trim();
                                      if (controller.selectedCategory == 'Investment') {
                                        final name = controller.isCreatingNewInvestment ? controller.newInvestmentNameController.text.trim() : controller.selectedInvestmentName;
                                        if (name.isNotEmpty) {
                                          Holding? targetHolding;
                                          final existingInvestments = ref.read(holdingsProvider).valueOrNull ?? [];
                                          for (final h in existingInvestments) {
                                            if (h.name.toLowerCase() == name.toLowerCase()) {
                                              targetHolding = h;
                                              break;
                                            }
                                          }
                                          if (targetHolding == null) {
                                            targetHolding = Holding()
                                              ..name = name
                                              ..symbol = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase()
                                              ..assetType = controller.newInvestmentAssetType
                                              ..broker = 'manual'
                                              ..quantity = 0.0
                                              ..buyAvgPrice = 0.0
                                              ..currentPrice = 0.0;
                                          }

                                          if (targetHolding.assetType == 'stable') {
                                            targetHolding.quantity += amt;
                                            targetHolding.buyAvgPrice = 1.0;
                                            targetHolding.currentPrice = 1.0;
                                          } else {
                                            final double oldCost = targetHolding.buyAvgPrice * targetHolding.quantity;
                                            final double newCost = oldCost + amt;
                                            targetHolding.quantity += 1.0;
                                            targetHolding.buyAvgPrice = targetHolding.quantity > 0 ? newCost / targetHolding.quantity : 0.0;
                                            if (targetHolding.currentPrice == 0.0) {
                                              targetHolding.currentPrice = targetHolding.buyAvgPrice;
                                            }
                                          }
                                          targetHolding.lastUpdated = DateTime.now();
                                          await ref.read(databaseServiceProvider).saveHolding(targetHolding);
                                          await ref.read(holdingsProvider.notifier).loadHoldings();
                                        }
                                      }

                                      final tx = Transaction()
                                        ..amount = amt
                                        ..description = controller.selectedType == 'income' ? 'Received from $merchant' : 'Spent at $merchant'
                                        ..transactionType = controller.selectedType
                                        ..category = controller.selectedCategory
                                        ..timestamp = date
                                        ..source = item['source'] ?? 'sms'
                                        ..parserSource = geminiResult != null ? 'gemini' : 'regex'
                                        ..rawMessage = rawBody;

                                      if (controller.selectedType == 'transfer') {
                                        tx.accountName = controller.selectedAccount;
                                        if (controller.selectedToAccount.startsWith('card:')) {
                                          tx.cardId = controller.selectedToAccount.substring(5);
                                        } else if (controller.selectedToAccount.startsWith('bank:')) {
                                          tx.cardId = controller.selectedToAccount;
                                        } else {
                                          tx.cardId = null;
                                        }
                                      } else {
                                        if (controller.selectedAccount.startsWith('card:')) {
                                          tx.cardId = controller.selectedAccount.substring(5);
                                          tx.accountName = 'Credit Card';
                                        } else {
                                          tx.cardId = null;
                                          tx.accountName = controller.selectedAccount;
                                        }
                                      }

                                      if (controller.selectedType == 'income' && controller.isPayback) {
                                        final contact = controller.paybackContactController.text.trim();
                                        if (contact.isNotEmpty) {
                                          final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                          try {
                                            final existing = allLoans.firstWhere(
                                              (l) => !l.isCompleted && l.contactName.trim().toLowerCase() == contact.toLowerCase(),
                                            );
                                            if (existing.isLent) {
                                              if (amt >= existing.remainingBalance) {
                                                final excess = amt - existing.remainingBalance;
                                                if (excess > 0) {
                                                  existing.isLent = false;
                                                  existing.remainingBalance = excess;
                                                  existing.amount = excess;
                                                  existing.isCompleted = false;
                                                } else {
                                                  existing.remainingBalance = 0.0;
                                                  existing.isCompleted = true;
                                                }
                                              } else {
                                                existing.remainingBalance -= amt;
                                              }
                                            } else {
                                              existing.amount += amt;
                                              existing.remainingBalance += amt;
                                              existing.isCompleted = false;
                                            }
                                            existing.paybackDate = controller.paybackDate;
                                            final savedId = await ref.read(loansProvider.notifier).addLoan(existing);
                                            tx.linkedLoanId = savedId;
                                          } catch (_) {
                                            final loan = Loan()
                                              ..contactName = contact
                                              ..isLent = false
                                              ..amount = amt
                                              ..remainingBalance = amt
                                              ..startDate = DateTime.now()
                                              ..paybackDate = controller.paybackDate
                                              ..interestRate = 0.0
                                              ..compoundInterval = 'none'
                                              ..emiAmount = 0.0
                                              ..isCompleted = false;
                                            final savedId = await ref.read(loansProvider.notifier).addLoan(loan);
                                            tx.linkedLoanId = savedId;
                                          }
                                        }
                                      }

                                      if ((controller.selectedType == 'expense' || controller.selectedType == 'transfer') && controller.selectedDebtId != null) {
                                        final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                        try {
                                          final target = allLoans.firstWhere((l) => l.id == controller.selectedDebtId);
                                          if (amt >= target.remainingBalance) {
                                            final overpaid = amt - target.remainingBalance;
                                            if (overpaid > 0) {
                                              target.isLent = true;
                                              target.remainingBalance = overpaid;
                                              target.amount = overpaid;
                                              target.isCompleted = false;
                                            } else {
                                              target.remainingBalance = 0.0;
                                              target.isCompleted = true;
                                            }
                                          } else {
                                            target.remainingBalance -= amt;
                                          }
                                          await ref.read(loansProvider.notifier).addLoan(target);
                                        } catch (_) {}
                                        tx.linkedLoanId = controller.selectedDebtId;
                                      }

                                      await ref.read(transactionsProvider.notifier).addTransaction(tx);

                                      parser.logDebug('Approve clicked for index $activeIndex. Parsed: Amount=$amt, Merchant="$merchant", Type="${controller.selectedType}", Category="${controller.selectedCategory}", Account="${controller.selectedAccount}", Source="${geminiResult != null ? "gemini" : "regex"}". Raw body: "$rawBody"');
                                      setState(() {
                                        importedCount++;
                                        if (reviewingRejected) {
                                          processedIndices.add(activeIndex);
                                          editingRejectedIndex = null;
                                        } else {
                                          currentIndex++;
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonEmerald),
                                    child: const Text('Approve', style: TextStyle(color: Colors.black)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
