import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../cards_loans/models/card_loan_models.dart';
import '../../cards_loans/widgets/nfc_scan_radar.dart';
import 'widgets/loan_detail_page.dart';
import 'widgets/credit_card_detail_view.dart';

class CardsLoansView extends ConsumerWidget {
  const CardsLoansView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsState = ref.watch(creditCardsProvider);
    final loansState = ref.watch(loansProvider);
    final txsState = ref.watch(transactionsProvider);
    final allTxs = txsState.valueOrNull ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cards & Debts',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Cards horizontal scroll list
            SizedBox(
              height: 340,
              child: cardsState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.neonTeal),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (cards) {
                  final sortedCards = List<CreditCard>.from(cards);
                  final now = DateTime.now();
                  final cardInfoMap = <int, ({bool isPaidOff, DateTime dueDate, DateTime nextStatementDate})>{};

                  for (final card in sortedCards) {
                    final DateTime mostRecentStatementDate;
                    final DateTime previousStatementDate;
                    if (now.day >= card.statementDay) {
                      mostRecentStatementDate = DateTime(now.year, now.month, card.statementDay);
                      previousStatementDate = DateTime(
                        now.month == 1 ? now.year - 1 : now.year,
                        now.month == 1 ? 12 : now.month - 1,
                        card.statementDay,
                      );
                    } else {
                      mostRecentStatementDate = DateTime(
                        now.month == 1 ? now.year - 1 : now.year,
                        now.month == 1 ? 12 : now.month - 1,
                        card.statementDay,
                      );
                      final prevMonth = mostRecentStatementDate.month;
                      final prevYear = mostRecentStatementDate.year;
                      previousStatementDate = DateTime(
                        prevMonth == 1 ? prevYear - 1 : prevYear,
                        prevMonth == 1 ? 12 : prevMonth - 1,
                        card.statementDay,
                      );
                    }

                    final DateTime dueDate;
                    if (card.dueDay > card.statementDay) {
                      dueDate = DateTime(mostRecentStatementDate.year, mostRecentStatementDate.month, card.dueDay);
                    } else {
                      dueDate = DateTime(
                        mostRecentStatementDate.month == 12 ? mostRecentStatementDate.year + 1 : mostRecentStatementDate.year,
                        mostRecentStatementDate.month == 12 ? 1 : mostRecentStatementDate.month + 1,
                        card.dueDay,
                      );
                    }

                    final DateTime nextStatementDate;
                    if (now.day < card.statementDay) {
                      nextStatementDate = DateTime(now.year, now.month, card.statementDay);
                    } else {
                      nextStatementDate = DateTime(
                        now.month == 12 ? now.year + 1 : now.year,
                        now.month == 12 ? 1 : now.month + 1,
                        card.statementDay,
                      );
                    }

                    final cardId = card.id.toString();
                    final computedStatement = allTxs
                        .where((t) =>
                            t.cardId == cardId &&
                            t.transactionType == 'expense' &&
                            (t.timestamp.isAtSameMomentAs(previousStatementDate) || t.timestamp.isAfter(previousStatementDate)) &&
                            t.timestamp.isBefore(mostRecentStatementDate))
                        .fold<double>(0.0, (sum, t) => sum + t.amount);

                    final payments = allTxs
                        .where((t) =>
                            t.cardId == cardId &&
                            t.transactionType == 'transfer' &&
                            (t.timestamp.isAtSameMomentAs(mostRecentStatementDate) || t.timestamp.isAfter(mostRecentStatementDate)))
                        .fold<double>(0.0, (sum, t) => sum + t.amount);

                    final targetStatementAmount = card.statementAmount > 0.0 ? card.statementAmount : computedStatement;
                    final isPaidOff = targetStatementAmount <= 0.0 || payments >= targetStatementAmount;

                    cardInfoMap[card.id] = (
                      isPaidOff: isPaidOff,
                      dueDate: dueDate,
                      nextStatementDate: nextStatementDate,
                    );
                  }

                  sortedCards.sort((a, b) {
                    final infoA = cardInfoMap[a.id]!;
                    final infoB = cardInfoMap[b.id]!;

                    if (!infoA.isPaidOff && infoB.isPaidOff) return -1;
                    if (infoA.isPaidOff && !infoB.isPaidOff) return 1;

                    if (!infoA.isPaidOff) {
                      return infoA.dueDate.compareTo(infoB.dueDate);
                    } else {
                      return infoB.nextStatementDate.compareTo(infoA.nextStatementDate);
                    }
                  });

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ...sortedCards.map((card) {
                        return _buildCreditCardItem(context, ref, card, allTxs);
                      }),
                      _buildAddCardButton(context, ref),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Loans section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Loans & Ledgers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.neonTeal,
                  ),
                  label: const Text(
                    'Add Loan',
                    style: TextStyle(color: AppColors.neonTeal, fontSize: 13),
                  ),
                  onPressed: () => _showAddLoanDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Loans items list
            loansState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.neonTeal),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (allLoans) {
                final loans = allLoans.where((l) => l.remainingBalance > 0 && !l.isCompleted).toList();
                final completedLoans = allLoans.where((l) => l.isCompleted || l.remainingBalance == 0).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (loans.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No active loans. Click Add Loan to track!',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: loans.length,
                        itemBuilder: (context, index) {
                          final loan = loans[index];
                          final String typeStr = loan.isLent
                              ? 'Lent (Receivable)'
                              : 'Borrowed (Debt)';
                          final Color typeColor = loan.isLent
                              ? AppColors.neonEmerald
                              : Colors.redAccent;
                          final String emiInfo = loan.emiAmount > 0
                              ? 'EMI: ₹${loan.emiAmount.toStringAsFixed(0)} (${loan.interestRate}%)'
                              : 'Friendly Loan (${loan.interestRate}%)';

                          return Dismissible(
                            key: ValueKey(loan.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_sweep_rounded,
                                color: Colors.redAccent,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) {
                              ref.read(loansProvider.notifier).removeLoan(loan.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${loan.contactName}\'s loan deleted',
                                  ),
                                  backgroundColor: AppColors.obsidianSurface,
                                ),
                              );
                            },
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoanDetailPage(
                                    loan: loan,
                                    onEdit: () => _showAddLoanDialog(context, ref, existingLoan: loan),
                                  ),
                                ),
                              ),
                              child: _buildLoanItem(
                                loan.contactName,
                                typeStr,
                                '₹${loan.remainingBalance.toStringAsFixed(0)}',
                                emiInfo,
                                typeColor,
                              ),
                            ),
                          );
                        },
                      ),

                    if (completedLoans.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Archived & Completed Loans',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: completedLoans.length,
                        itemBuilder: (context, index) {
                          final loan = completedLoans[index];
                          final String typeStr = loan.isLent
                              ? 'Lent (Completed)'
                              : 'Borrowed (Paid Off)';
                          final Color typeColor = AppColors.neonTeal;
                          final String emiInfo = 'Completed • Original: ₹${loan.amount.toStringAsFixed(0)}';

                          return Dismissible(
                            key: ValueKey(loan.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_sweep_rounded,
                                color: Colors.redAccent,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) {
                              ref.read(loansProvider.notifier).removeLoan(loan.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${loan.contactName}\'s archived loan deleted',
                                  ),
                                  backgroundColor: AppColors.obsidianSurface,
                                ),
                              );
                            },
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoanDetailPage(
                                    loan: loan,
                                    onEdit: () => _showAddLoanDialog(context, ref, existingLoan: loan),
                                  ),
                                ),
                              ),
                              child: _buildLoanItem(
                                loan.contactName,
                                typeStr,
                                'Completed',
                                emiInfo,
                                typeColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _getOrdinalSuffix(int value) {
    if (value >= 11 && value <= 13) {
      return 'th';
    }
    switch (value % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _getMonthName(int day) {
    final now = DateTime.now();
    DateTime targetDate = DateTime(now.year, now.month, day);

    if (now.day > day) {
      targetDate = DateTime(now.year, now.month + 1, day);
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[targetDate.month - 1];
  }

  Widget _buildSecureFieldCompact(
    BuildContext context,
    String label,
    String value,
    bool copyable,
  ) {
    final displayValue = value.isEmpty ? 'N/A' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                displayValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (copyable && value.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      backgroundColor: AppColors.obsidianSurface,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.neonTeal,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreditCardItem(
    BuildContext context,
    WidgetRef ref,
    CreditCard card,
    List<dynamic> allTxs,
  ) {
    // Compute dynamic spent (current cycle) and statement (last cycle) from transactions
    final now = DateTime.now();
    final DateTime mostRecentStatementDate;
    final DateTime previousStatementDate;
    if (now.day >= card.statementDay) {
      mostRecentStatementDate = DateTime(now.year, now.month, card.statementDay);
      previousStatementDate = DateTime(
        now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1,
        card.statementDay,
      );
    } else {
      mostRecentStatementDate = DateTime(
        now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1,
        card.statementDay,
      );
      final prevMonth = mostRecentStatementDate.month;
      final prevYear = mostRecentStatementDate.year;
      previousStatementDate = DateTime(
        prevMonth == 1 ? prevYear - 1 : prevYear,
        prevMonth == 1 ? 12 : prevMonth - 1,
        card.statementDay,
      );
    }
    final cardId = card.id.toString();
    final computedSpent = allTxs
        .where((t) =>
            t.cardId == cardId &&
            t.transactionType == 'expense' &&
            (t.timestamp.isAtSameMomentAs(mostRecentStatementDate) || t.timestamp.isAfter(mostRecentStatementDate)))
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final computedStatement = allTxs
        .where((t) =>
            t.cardId == cardId &&
            t.transactionType == 'expense' &&
            (t.timestamp.isAtSameMomentAs(previousStatementDate) || t.timestamp.isAfter(previousStatementDate)) &&
            t.timestamp.isBefore(mostRecentStatementDate))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final payments = allTxs
        .where((t) =>
            t.cardId == cardId &&
            t.transactionType == 'transfer' &&
            (t.timestamp.isAtSameMomentAs(mostRecentStatementDate) || t.timestamp.isAfter(mostRecentStatementDate)))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final targetStatementAmount = card.statementAmount > 0.0 ? card.statementAmount : computedStatement;
    final isPaidOff = targetStatementAmount <= 0.0 || payments >= targetStatementAmount;
    bool showSpent = isPaidOff; // State for toggle, defaults to statement (false) if unpaid
    bool isLongPressed = false; // State for edit/delete
    bool isFlipped = false; // State for flip

    return StatefulBuilder(
      builder: (context, setState) {
        Future<void> authenticateAndFlipCard() async {
          final LocalAuthentication auth = LocalAuthentication();
          try {
            final bool canAuthenticateWithBiometrics =
                await auth.canCheckBiometrics;
            final bool canAuthenticate =
                canAuthenticateWithBiometrics || await auth.isDeviceSupported();

            if (!canAuthenticate) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Biometric auth not available')),
              );
              return;
            }

            final bool didAuthenticate = await auth.authenticate(
              localizedReason: 'Authenticate to view secure card details',
              options: const AuthenticationOptions(biometricOnly: true),
            );

            if (didAuthenticate) {
              setState(() => isFlipped = true);
            }
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Auth error: $e')));
          }
        }

        final frontSide = Container(
          key: const ValueKey('front'),
          width: 220,
          margin: const EdgeInsets.only(right: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
            gradient: card.imageUrl.isEmpty
                ? LinearGradient(
                    colors: [
                      AppColors.tealBlueGradient[0],
                      AppColors.tealBlueGradient[1],
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image layer (supports SVG and raster images)
              if (card.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: card.imageUrl.toLowerCase().endsWith('.svg')
                      ? SvgPicture.asset(
                          'assets/credit_card_images/${card.imageUrl}',
                          fit: BoxFit.fill,
                          placeholderBuilder: (context) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.1)],
                              ),
                            ),
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.1)],
                                ),
                              ),
                            ),
                            Image.asset(
                              'assets/credit_card_images/${card.imageUrl}',
                              fit: BoxFit.cover,
                              frameBuilder: (context, child, frame, wasSync) {
                                if (wasSync) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                            ),
                          ],
                        ),
                ),

              // Foreground content
              if (isLongPressed)
                GlassBlur(
                  borderRadius: 20,
                  blurX: 25.0,
                  blurY: 25.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() => isLongPressed = false);
                              _showAddCardDialog(
                                context,
                                ref,
                                existingCard: card,
                              );
                            },
                          ),
                          const SizedBox(width: 32),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() => isLongPressed = false);
                              ref
                                  .read(creditCardsProvider.notifier)
                                  .removeCreditCard(card.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Card deleted'),
                                  backgroundColor: AppColors.obsidianSurface,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(
                      0.15,
                    ), // Gentle global dimming
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: authenticateAndFlipCard,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.last4.isNotEmpty ? card.last4 : "****",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.visibility_rounded,
                              color: Colors.white70,
                              size: 24,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),

                      // Bottom area: Spent/Statement Toggle
                      GestureDetector(
                        onTap: () => setState(() => showSpent = !showSpent),
                        child: GlassBlur(
                          borderRadius: 16.0,
                          blurX: 12.0,
                          blurY: 12.0,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz_rounded,
                                      color: AppColors.neonTeal,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      showSpent ? 'SPENT' : 'STATEMENT',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: AppColors.neonTeal,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  showSpent
                                      ? '₹${computedSpent.toStringAsFixed(0)}'
                                      : '₹${computedStatement.toStringAsFixed(0)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  showSpent
                                      ? '${card.statementDay} ${_getMonthName(card.statementDay)}'
                                      : '${card.dueDay} ${_getMonthName(card.dueDay)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
            ],
          ),
        );

        final backSide = Container(
          key: const ValueKey('back'),
          width: 220,
          margin: const EdgeInsets.only(right: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
            gradient: card.imageUrl.isEmpty
                ? LinearGradient(
                    colors: [
                      AppColors.tealBlueGradient[0],
                      AppColors.tealBlueGradient[1],
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image layer (supports SVG and raster images)
              if (card.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: card.imageUrl.toLowerCase().endsWith('.svg')
                      ? SvgPicture.asset(
                          'assets/credit_card_images/${card.imageUrl}',
                          fit: BoxFit.fill,
                          placeholderBuilder: (context) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.1)],
                              ),
                            ),
                          ),
                        )
                      : Image.asset(
                          'assets/credit_card_images/${card.imageUrl}',
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, wasSync) {
                            if (wasSync) return child;
                            return AnimatedCrossFade(
                              firstChild: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.1)],
                                  ),
                                ),
                              ),
                              secondChild: child,
                              crossFadeState: frame == null
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              duration: const Duration(milliseconds: 200),
                            );
                          },
                        ),
                ),
              GlassBlur(
                borderRadius: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.65,
                    ), // slightly darker for visibility on back
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SECURE DETAILS',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonTeal,
                              letterSpacing: 1.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => isFlipped = false),
                            child: const Icon(
                              Icons.visibility_off_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildSecureFieldCompact(
                        context,
                        'Card Number',
                        card.fullCardNumber,
                        true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecureFieldCompact(
                              context,
                              'Expiry Date',
                              card.expiryDate,
                              false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSecureFieldCompact(
                              context,
                              'CVV',
                              card.cvv,
                              false,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        return GestureDetector(
          onLongPress: () => setState(() => isLongPressed = true),
          onTap: () {
            if (isLongPressed) {
              setState(() => isLongPressed = false);
            } else if (!isFlipped) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreditCardDetailView(card: card),
                ),
              );
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              );
              return AnimatedBuilder(
                animation: flipAnimation,
                child: child,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..scale(flipAnimation.value, 1.0),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
              );
            },
            child: isFlipped ? backSide : frontSide,
          ),
        );
      },
    );
  }

  Widget _buildAddCardButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _showAddCardDialog(context, ref),
        child: GlassBlur(
          borderRadius: 20,
          borderColor: AppColors.glassBorder.withOpacity(0.05),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_card_rounded,
                  color: AppColors.neonTeal,
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'Add Card',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanItem(
    String title,
    String type,
    String principal,
    String emiInfo,
    Color typeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBlur(
        borderRadius: 16,
        useBlur: false,
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            emiInfo,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                principal,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCardDialog(
    BuildContext context,
    WidgetRef ref, {
    CreditCard? existingCard,
  }) {
    final nameController = TextEditingController(
      text: existingCard?.cardName ?? '',
    );
    final last4Controller = TextEditingController(
      text: existingCard?.last4 ?? '',
    );
    final stmtDayController = TextEditingController(
      text: existingCard?.statementDay.toString() ?? '15',
    );
    final dueDayController = TextEditingController(
      text: existingCard?.dueDay.toString() ?? '5',
    );

    // Secure Fields
    final fullCardNumberController = TextEditingController(
      text: existingCard?.fullCardNumber ?? '',
    );
    final expiryDateController = TextEditingController(
      text: existingCard?.expiryDate ?? '',
    );
    final cvvController = TextEditingController(text: existingCard?.cvv ?? '');

    // Financial metrics for card
    final currentSpendingsController = TextEditingController(
      text: existingCard?.currentSpendings.toStringAsFixed(0) ?? '0',
    );
    final statementAmountController = TextEditingController(
      text: existingCard?.statementAmount.toStringAsFixed(0) ?? '0',
    );

    String selectedBrand = existingCard?.brand.isNotEmpty == true
        ? existingCard!.brand
        : 'Visa';
    String selectedImage = existingCard?.imageUrl ?? '';

    final imageOptions = [
      '',
      'HDFC_MoneyBack_Vertical_HQ.webp',
      'IDFC_Millennia_HQ.webp',
      'LIC_Axis_Cropped_Vector.svg',
      'RBL_Bank_Fitted.webp',
      'SBI_SimplySave_Mobile.webp',
      'Scapia_Rupay.webp',
      'Scapia_Visa.webp',
      'Tata_NeuCard_FullFrame.webp',
      'UNI_YesBank_Vertical.webp',
      'hsbc_vertical_card_final.webp',
    ];

    if (selectedImage.isNotEmpty && !imageOptions.contains(selectedImage)) {
      imageOptions.add(selectedImage);
    }


    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Register Credit Card',
                                style: Theme.of(context).textTheme.titleLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.neonTeal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => NfcScanDialog(
                                    nameController: nameController,
                                    last4Controller: last4Controller,
                                    fullCardNumberController:
                                        fullCardNumberController,
                                    expiryDateController: expiryDateController,
                                    onBrandDetected: (brand) {
                                      setState(() => selectedBrand = brand);
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.nfc_rounded, size: 18),
                              label: const Text(
                                'Scan',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Card Name (e.g. HDFC Regalia)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: fullCardNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Card Number',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  if (val.length >= 4) {
                                    last4Controller.text = val.substring(
                                      val.length - 4,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: last4Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Last 4',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: expiryDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Expiry (MM/YY)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: cvvController,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedBrand,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Visa', 'Mastercard', 'RuPay', 'Amex']
                              .map(
                                (b) =>
                                    DropdownMenuItem(value: b, child: Text(b)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedBrand = val!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedImage,
                          decoration: const InputDecoration(
                            labelText: 'Card Background Image',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: imageOptions
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    i.isEmpty ? 'None' : i,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedImage = val!),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: currentSpendingsController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Spendings',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: statementAmountController,
                                decoration: const InputDecoration(
                                  labelText: 'Statement Amount',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: stmtDayController,
                                decoration: const InputDecoration(
                                  labelText: 'Statement Day (1-28)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: dueDayController,
                                decoration: const InputDecoration(
                                  labelText: 'Due Day (1-28)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonTeal,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                final name = nameController.text.trim();
                                final last4 = last4Controller.text.trim();
                                final stmt =
                                    int.tryParse(stmtDayController.text) ?? 15;
                                final due =
                                    int.tryParse(dueDayController.text) ?? 5;
                                final curSp =
                                    double.tryParse(
                                      currentSpendingsController.text,
                                    ) ??
                                    0.0;
                                final stmAm =
                                    double.tryParse(
                                      statementAmountController.text,
                                    ) ??
                                    0.0;

                                if (name.isEmpty || last4.length != 4) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor:
                                          AppColors.obsidianSurface,
                                      title: const Text(
                                        'Invalid Input',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        'Please fill Name and Last 4 digits accurately.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            'OK',
                                            style: TextStyle(
                                              color: AppColors.neonTeal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                // Duplicate Check
                                final existingCards =
                                    ref.read(creditCardsProvider).value ?? [];
                                if (existingCard == null) {
                                  final cardNumber = fullCardNumberController
                                      .text
                                      .trim();
                                  if (cardNumber.isNotEmpty) {
                                    final isDuplicate = existingCards.any(
                                      (c) => c.fullCardNumber == cardNumber,
                                    );
                                    if (isDuplicate) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor:
                                              AppColors.obsidianSurface,
                                          title: const Text(
                                            'Duplicate Card',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          content: const Text(
                                            'A card with this number already exists!',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                'OK',
                                                style: TextStyle(
                                                  color: AppColors.neonTeal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                }

                                final card = existingCard ?? CreditCard();
                                card
                                  ..cardName = name
                                  ..last4 = last4
                                  ..statementDay = stmt
                                  ..dueDay = due
                                  ..fullCardNumber = fullCardNumberController
                                      .text
                                      .trim()
                                  ..expiryDate = expiryDateController.text
                                      .trim()
                                  ..cvv = cvvController.text.trim()
                                  ..brand = selectedBrand
                                  ..imageUrl = selectedImage
                                  ..currentSpendings = curSp
                                  ..statementAmount = stmAm;

                                if (existingCard == null) {
                                  ref
                                      .read(creditCardsProvider.notifier)
                                      .addCreditCard(card);
                                } else {
                                  ref
                                      .read(creditCardsProvider.notifier)
                                      .updateCreditCard(card);
                                }
                                Navigator.pop(context);
                              },
                              child: Text(
                                existingCard == null
                                    ? 'Add Card'
                                    : 'Save Changes',
                              ),
                            ),
                          ],
                        ),
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
  }

  void _showAddLoanDialog(
    BuildContext context,
    WidgetRef ref, {
    Loan? existingLoan,
  }) {
    final contactController = TextEditingController(
      text: existingLoan?.contactName ?? '',
    );
    final amountController = TextEditingController(
      text: existingLoan != null ? existingLoan.amount.toStringAsFixed(0) : '',
    );
    final rateController = TextEditingController(
      text: existingLoan != null ? existingLoan.interestRate.toString() : '0',
    );
    final emiController = TextEditingController(
      text: existingLoan != null
          ? existingLoan.emiAmount.toStringAsFixed(0)
          : '0',
    );
    bool isLent = existingLoan?.isLent ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassBlur(
                borderRadius: 24,
                blurX: 30,
                blurY: 30,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingLoan != null
                              ? 'Edit Loan / Debt'
                              : 'Track Loan / Debt',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<bool>(
                          value: isLent,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: AppColors.obsidianSurface,
                          items: const [
                            DropdownMenuItem(
                              value: false,
                              child: Text('Borrowed (Debt)'),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Lent (Receivable)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => isLent = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: contactController,
                          decoration: const InputDecoration(
                            labelText: 'Contact / Lender Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount (INR)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: rateController,
                                decoration: const InputDecoration(
                                  labelText: 'Interest Rate (%)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: emiController,
                                decoration: const InputDecoration(
                                  labelText: 'Monthly EMI (0 if none)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonTeal,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                final contact = contactController.text.trim();
                                final amount =
                                    double.tryParse(amountController.text) ??
                                    0.0;
                                final rate =
                                    double.tryParse(rateController.text) ?? 0.0;
                                final emi =
                                    double.tryParse(emiController.text) ?? 0.0;

                                if (contact.isEmpty || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter name and valid amount',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final loan = existingLoan ?? Loan();
                                loan.contactName = contact;
                                loan.isLent = isLent;
                                loan.amount = amount;
                                if (existingLoan == null) {
                                  loan.remainingBalance = amount;
                                  loan.startDate = DateTime.now();
                                } else {
                                  if (existingLoan.amount ==
                                      existingLoan.remainingBalance) {
                                    loan.remainingBalance = amount;
                                  }
                                }
                                loan.interestRate = rate;
                                loan.emiAmount = emi;

                                ref.read(loansProvider.notifier).addLoan(loan);
                                Navigator.pop(context);
                              },
                              child: Text(
                                existingLoan != null
                                    ? 'Save Changes'
                                    : 'Add Loan',
                              ),
                            ),
                          ],
                        ),
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
  }
}
