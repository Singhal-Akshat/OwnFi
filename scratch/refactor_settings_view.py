import re

with open('e:/Projects/Money_Tracker/lib/ui/settings/settings_view.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace variables declaration
vars_target = """    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    String selectedType = 'expense';
    String selectedCategory = 'Other';
    String selectedAccount = 'Cash';

    // State for payback and repayments
    bool isPayback = false;
    final paybackContactController = TextEditingController();
    DateTime paybackDate = DateTime.now().add(const Duration(days: 30));
    int? selectedDebtId;
    String selectedToAccount = 'Cash';

    // Investment state variables
    bool isCreatingNewInvestment = false;
    String selectedInvestmentName = '';
    final newInvestmentNameController = TextEditingController();
    String newInvestmentAssetType = 'stock';"""

content = content.replace(vars_target, "    final controller = TransactionFormController();")

# 2. Replace the holdingsProvider watch / investment setup at start of build
holdings_watch_target = """            final holdingsState = ref.watch(holdingsProvider);
            final existingInvestments = holdingsState.valueOrNull ?? [];

            if (selectedCategory == 'Investment') {
              if (selectedInvestmentName.isEmpty && existingInvestments.isNotEmpty && !isCreatingNewInvestment) {
                selectedInvestmentName = existingInvestments.first.name;
                if (merchantController.text.isEmpty) {
                  merchantController.text = selectedInvestmentName;
                }
              } else if (existingInvestments.isEmpty) {
                isCreatingNewInvestment = true;
              }
            }"""

content = content.replace(holdings_watch_target, "")

# 3. Replace ensureParsed geminiResult.then(...) variables update
gemini_then_target = """                      if (lastInitializedIndex != currentIndex) {
                        isPayback = false;
                        paybackContactController.clear();
                        paybackDate = DateTime.now().add(const Duration(days: 30));
                        selectedDebtId = null;
                        selectedToAccount = 'Cash';
                      }
                      
                      if (currentIndex == index) {
                        amountController.text = geminiResult.amount.toStringAsFixed(0);
                        merchantController.text = geminiResult.merchant;
                        selectedType = geminiResult.transactionType;
                        selectedCategory = geminiResult.category;
                        if (selectedCategory == 'Utilities') selectedCategory = 'Bills';
                        const allowedCategories = ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Salary', 'Investment', 'Health', 'Education', 'Other'];
                        if (!allowedCategories.contains(selectedCategory)) {
                          selectedCategory = 'Other';
                        }

                        selectedAccount = 'Cash';
                        if (geminiResult.matchedAccountId != null) {
                          selectedAccount = geminiResult.matchedAccountId!;
                        } else {
                          final bodyLower = bodyText.toLowerCase();
                          if (bodyLower.contains('hdfc')) {
                            cardsState.whenData((cards) {}); // just force reload
                            bankAccountsState.whenData((banks) {
                              final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                              if (match.id != Isar.autoIncrement) {
                                selectedAccount = 'bank:${match.id}';
                              }
                            });
                          } else if (bodyLower.contains('sbi')) {
                            bankAccountsState.whenData((banks) {
                              final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                              if (match.id != Isar.autoIncrement) {
                                selectedAccount = 'bank:${match.id}';
                              }
                            });
                          }
                          
                          if (selectedAccount == 'Cash') {
                            if (geminiResult.cardLast4 != null) {
                              cardsState.whenData((cards) {
                                final match = cards.firstWhere((c) => c.last4 == geminiResult.cardLast4, orElse: () => CreditCard());
                                if (match.id != Isar.autoIncrement) {
                                  selectedAccount = 'card:${match.id}';
                                }
                              });
                            } else if (geminiResult.accountLast4 != null) {
                              bankAccountsState.whenData((banks) {
                                final match = banks.firstWhere((b) => b.last4 == geminiResult.accountLast4, orElse: () => BankAccount());
                                if (match.id != Isar.autoIncrement) {
                                  selectedAccount = 'bank:${match.id}';
                                }
                              });
                            }
                          }
                        }"""

gemini_then_replacement = """                      if (lastInitializedIndex != currentIndex) {
                        controller.reset();
                      }
                      
                      if (currentIndex == index) {
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
                            cardsState.whenData((cards) {}); // just force reload
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
                        }"""

content = content.replace(gemini_then_target, gemini_then_replacement)

# 4. Replace lastInitializedIndex != currentIndex check
index_reset_target = """            if (lastInitializedIndex != currentIndex || lastGemini != geminiResult || lastRegex != regexResult) {
              if (lastInitializedIndex != currentIndex) {
                isPayback = false;
                paybackContactController.clear();
                paybackDate = DateTime.now().add(const Duration(days: 30));
                selectedDebtId = null;
                selectedToAccount = 'Cash';
                isCreatingNewInvestment = false;
                selectedInvestmentName = '';
                newInvestmentNameController.clear();
                newInvestmentAssetType = 'stock';
              }
              lastInitializedIndex = currentIndex;
              lastGemini = geminiResult;
              lastRegex = regexResult;

              final initialSource = geminiResult ?? regexResult;
              amountController.text = (initialSource?.amount ?? 0.0).toStringAsFixed(0);
              merchantController.text = initialSource?.merchant ?? 'Unknown Merchant';
              selectedType = initialSource?.transactionType ?? 'expense';
              selectedCategory = initialSource?.category ?? 'Other';
              if (selectedCategory == 'Utilities') selectedCategory = 'Bills';
              const allowedCategories = ['Food', 'Shopping', 'Bills', 'Entertainment', 'Travel', 'Salary', 'Investment', 'Health', 'Education', 'Other'];
              if (!allowedCategories.contains(selectedCategory)) {
                selectedCategory = 'Other';
              }

              selectedAccount = 'Cash';
              if (initialSource?.matchedAccountId != null) {
                selectedAccount = initialSource!.matchedAccountId!;
              } else {
                final bodyLower = rawBody.toLowerCase();
                if (bodyLower.contains('hdfc')) {
                  bankAccountsState.whenData((banks) {
                    final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('hdfc'), orElse: () => BankAccount());
                    if (match.id != Isar.autoIncrement) {
                      selectedAccount = 'bank:${match.id}';
                    }
                  });
                } else if (bodyLower.contains('sbi')) {
                  bankAccountsState.whenData((banks) {
                    final match = banks.firstWhere((b) => b.bankName.toLowerCase().contains('sbi'), orElse: () => BankAccount());
                    if (match.id != Isar.autoIncrement) {
                      selectedAccount = 'bank:${match.id}';
                    }
                  });
                }

                if (selectedAccount == 'Cash') {
                  final last4 = initialSource?.cardLast4 ?? initialSource?.accountLast4;
                  if (last4 != null) {
                    if (initialSource?.cardLast4 != null) {
                      cardsState.whenData((cards) {
                        final match = cards.firstWhere((c) => c.last4 == last4, orElse: () => CreditCard());
                        if (match.id != Isar.autoIncrement) {
                          selectedAccount = 'card:${match.id}';
                        }
                      });
                    } else {
                      bankAccountsState.whenData((banks) {
                        final match = banks.firstWhere((b) => b.last4 == last4, orElse: () => BankAccount());
                        if (match.id != Isar.autoIncrement) {
                          selectedAccount = 'bank:${match.id}';
                        }
                      });
                    }
                  }
                }
              }
            }"""

index_reset_replacement = """            if (lastInitializedIndex != currentIndex || lastGemini != geminiResult || lastRegex != regexResult) {
              if (lastInitializedIndex != currentIndex) {
                controller.reset();
              }
              lastInitializedIndex = currentIndex;
              lastGemini = geminiResult;
              lastRegex = regexResult;

              final initialSource = geminiResult ?? regexResult;
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
            }"""

content = content.replace(index_reset_target, index_reset_replacement)

# 5. Replace Use Regex Guess / Use Gemini Guess buttons actions
content = content.replace("amountController.text = regexResult.amount.toStringAsFixed(0);", "controller.amountController.text = regexResult.amount.toStringAsFixed(0);")
content = content.replace("merchantController.text = regexResult.merchant;", "controller.descriptionController.text = regexResult.merchant;")
content = content.replace("selectedType = regexResult.transactionType;", "controller.selectedType = regexResult.transactionType;")
content = content.replace("selectedCategory = regexResult.category;", "controller.selectedCategory = regexResult.category;")
content = content.replace("selectedAccount = regexResult.matchedAccountId!;", "controller.selectedAccount = regexResult.matchedAccountId!;")
content = content.replace("selectedAccount = 'card:' + match.id.toString();", "controller.selectedAccount = 'card:' + match.id.toString();")
content = content.replace("selectedAccount = 'bank:' + match.id.toString();", "controller.selectedAccount = 'bank:' + match.id.toString();")
content = content.replace("selectedAccount = 'card:${match.id}';", "controller.selectedAccount = 'card:${match.id}';")
content = content.replace("selectedAccount = 'bank:${match.id}';", "controller.selectedAccount = 'bank:${match.id}';")

content = content.replace("amountController.text = geminiResult.amount.toStringAsFixed(0);", "controller.amountController.text = geminiResult.amount.toStringAsFixed(0);")
content = content.replace("merchantController.text = geminiResult.merchant;", "controller.descriptionController.text = geminiResult.merchant;")
content = content.replace("selectedType = geminiResult.transactionType;", "controller.selectedType = geminiResult.transactionType;")
content = content.replace("selectedCategory = geminiResult.category;", "controller.selectedCategory = geminiResult.category;")
content = content.replace("selectedAccount = geminiResult.matchedAccountId!;", "controller.selectedAccount = geminiResult.matchedAccountId!;")

# 6. Replace the entire Form UI block
# The form UI block starts right after the Gemini/Regex buttons wrap
form_block_start = "                        const SizedBox(height: 12),\n\n                        Row("
# Ends right before Mark Wrong / Flags wrap button
form_block_end = "                        const SizedBox(height: 16),\n\n                        Wrap(\n                          spacing: 8,\n                          runSpacing: 8,\n                          alignment: WrapAlignment.spaceBetween"

# Let's find index of start and end
start_idx = content.find(form_block_start)
end_idx = content.find(form_block_end)

if start_idx != -1 and end_idx != -1:
    new_form_code = """                        const SizedBox(height: 12),
                        TransactionFormFields(
                          controller: controller,
                          onStateChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 16),"""
    content = content[:start_idx] + new_form_code + content[end_idx:]
else:
    print("WARNING: Could not find form block indices", start_idx, end_idx)

# 7. Replace the Approve button handler logic
approve_handler_target = """                                  onPressed: () async {
                                    final double amt = double.tryParse(amountController.text) ?? 0.0;
                                    final merchant = merchantController.text.trim();
                                    if (selectedCategory == 'Investment') {
                                      final name = isCreatingNewInvestment ? newInvestmentNameController.text.trim() : selectedInvestmentName;
                                      if (name.isNotEmpty) {
                                        Holding? targetHolding;
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
                                            ..assetType = newInvestmentAssetType
                                            ..broker = 'manual'
                                            ..quantity = 0.0
                                            ..buyAvgPrice = 0.0
                                            ..currentPrice = 0.0;
                                        }

                                        if (targetHolding.assetType == 'stable') {
                                          if (selectedType == 'expense' || selectedType == 'transfer') {
                                            targetHolding.quantity += amt;
                                            targetHolding.buyAvgPrice = 1.0;
                                            targetHolding.currentPrice = 1.0;
                                          } else if (selectedType == 'income') {
                                            targetHolding.quantity = (targetHolding.quantity - amt).clamp(0.0, double.infinity);
                                          }
                                        } else {
                                          if (selectedType == 'expense' || selectedType == 'transfer') {
                                            final double oldCost = targetHolding.buyAvgPrice * targetHolding.quantity;
                                            final double newCost = oldCost + amt;
                                            targetHolding.quantity += 1.0;
                                            targetHolding.buyAvgPrice = targetHolding.quantity > 0 ? newCost / targetHolding.quantity : 0.0;
                                            if (targetHolding.currentPrice == 0.0) {
                                              targetHolding.currentPrice = targetHolding.buyAvgPrice;
                                            }
                                          } else if (selectedType == 'income') {
                                            targetHolding.quantity = (targetHolding.quantity - 1.0).clamp(0.0, double.infinity);
                                          }
                                        }
                                        targetHolding.lastUpdated = DateTime.now();
                                        await ref.read(databaseServiceProvider).saveHolding(targetHolding);
                                        await ref.read(holdingsProvider.notifier).loadHoldings();
                                      }
                                    }

                                    final tx = Transaction()
                                      ..amount = amt
                                      ..description = selectedType == 'income' ? 'Received from $merchant' : 'Spent at $merchant'
                                      ..transactionType = selectedType
                                      ..category = selectedCategory
                                      ..timestamp = date
                                      ..source = item['source'] ?? 'sms'
                                      ..parserSource = geminiResult != null ? 'gemini' : 'regex'
                                      ..rawMessage = rawBody;

                                    if (selectedType == 'transfer') {
                                      tx.accountName = selectedAccount;
                                      if (selectedToAccount.startsWith('card:')) {
                                        tx.cardId = selectedToAccount.substring(5);
                                      } else if (selectedToAccount.startsWith('bank:')) {
                                        tx.cardId = selectedToAccount;
                                      } else {
                                        tx.cardId = null;
                                      }
                                    } else {
                                      if (selectedAccount.startsWith('card:')) {
                                        tx.cardId = selectedAccount.substring(5);
                                        tx.accountName = 'Credit Card';
                                      } else {
                                        tx.cardId = null;
                                        tx.accountName = selectedAccount;
                                      }
                                    }

                                    if (selectedType == 'income' && isPayback) {
                                      final contact = paybackContactController.text.trim();
                                      if (contact.isNotEmpty) {
                                        final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                        try {
                                          final existing = allLoans.firstWhere(
                                            (l) => !l.isLent && l.remainingBalance > 0 && l.contactName.trim().toLowerCase() == contact.toLowerCase(),
                                          );
                                          existing.amount += amt;
                                          existing.remainingBalance += amt;
                                          existing.paybackDate = paybackDate;
                                          final savedId = await ref.read(loansProvider.notifier).addLoan(existing);
                                          tx.linkedLoanId = savedId;
                                        } catch (_) {
                                          final loan = Loan()
                                            ..contactName = contact
                                            ..isLent = false // borrowed debt
                                            ..amount = amt
                                            ..remainingBalance = amt
                                            ..startDate = DateTime.now()
                                            ..paybackDate = paybackDate
                                            ..interestRate = 0.0
                                            ..compoundInterval = 'none'
                                            ..emiAmount = 0.0;
                                          final savedId = await ref.read(loansProvider.notifier).addLoan(loan);
                                          tx.linkedLoanId = savedId;
                                        }
                                      }
                                    }

                                    if ((selectedType == 'expense' || selectedType == 'transfer') && selectedDebtId != null) {
                                      final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                      try {
                                        final target = allLoans.firstWhere((l) => l.id == selectedDebtId);
                                        target.remainingBalance = (target.remainingBalance - amt).clamp(0.0, double.infinity);
                                        await ref.read(loansProvider.notifier).addLoan(target);
                                      } catch (_) {}
                                      tx.linkedLoanId = selectedDebtId;
                                    }"""

approve_handler_replacement = """                                  onPressed: () async {
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
                                          if (controller.selectedType == 'expense' || controller.selectedType == 'transfer') {
                                            targetHolding.quantity += amt;
                                            targetHolding.buyAvgPrice = 1.0;
                                            targetHolding.currentPrice = 1.0;
                                          } else if (controller.selectedType == 'income') {
                                            targetHolding.quantity = (targetHolding.quantity - amt).clamp(0.0, double.infinity);
                                          }
                                        } else {
                                          if (controller.selectedType == 'expense' || controller.selectedType == 'transfer') {
                                            final double oldCost = targetHolding.buyAvgPrice * targetHolding.quantity;
                                            final double newCost = oldCost + amt;
                                            targetHolding.quantity += 1.0;
                                            targetHolding.buyAvgPrice = targetHolding.quantity > 0 ? newCost / targetHolding.quantity : 0.0;
                                            if (targetHolding.currentPrice == 0.0) {
                                              targetHolding.currentPrice = targetHolding.buyAvgPrice;
                                            }
                                          } else if (controller.selectedType == 'income') {
                                            targetHolding.quantity = (targetHolding.quantity - 1.0).clamp(0.0, double.infinity);
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
                                            (l) => !l.isLent && l.remainingBalance > 0 && l.contactName.trim().toLowerCase() == contact.toLowerCase(),
                                          );
                                          existing.amount += amt;
                                          existing.remainingBalance += amt;
                                          existing.paybackDate = controller.paybackDate;
                                          final savedId = await ref.read(loansProvider.notifier).addLoan(existing);
                                          tx.linkedLoanId = savedId;
                                        } catch (_) {
                                          final loan = Loan()
                                            ..contactName = contact
                                            ..isLent = false // borrowed debt
                                            ..amount = amt
                                            ..remainingBalance = amt
                                            ..startDate = DateTime.now()
                                            ..paybackDate = controller.paybackDate
                                            ..interestRate = 0.0
                                            ..compoundInterval = 'none'
                                            ..emiAmount = 0.0;
                                          final savedId = await ref.read(loansProvider.notifier).addLoan(loan);
                                          tx.linkedLoanId = savedId;
                                        }
                                      }
                                    }

                                    if ((controller.selectedType == 'expense' || controller.selectedType == 'transfer') && controller.selectedDebtId != null) {
                                      final allLoans = ref.read(loansProvider).valueOrNull ?? [];
                                      try {
                                        final target = allLoans.firstWhere((l) => l.id == controller.selectedDebtId);
                                        target.remainingBalance = (target.remainingBalance - amt).clamp(0.0, double.infinity);
                                        await ref.read(loansProvider.notifier).addLoan(target);
                                      } catch (_) {}
                                      tx.linkedLoanId = controller.selectedDebtId;
                                    }"""

content = content.replace(approve_handler_target, approve_handler_replacement)

# Also fix the final logDebug statement of the Approve button:
content = content.replace(
    'Parsed: Amount=$amt, Merchant="$merchant", Type="$selectedType", Category="$selectedCategory", Account="$selectedAccount"',
    'Parsed: Amount=$amt, Merchant="$merchant", Type="${controller.selectedType}", Category="${controller.selectedCategory}", Account="${controller.selectedAccount}"'
)

with open('e:/Projects/Money_Tracker/lib/ui/settings/settings_view.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Refactored settings_view successfully!")
