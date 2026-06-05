import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/animated_gradient_background.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../cards_loans/models/card_loan_models.dart';
import 'package:my_personal_tracker/features/expenses/ui/widgets/transaction_dialogs.dart';

class CreditCardDetailView extends ConsumerStatefulWidget {
  final CreditCard card;

  const CreditCardDetailView({super.key, required this.card});

  @override
  ConsumerState<CreditCardDetailView> createState() =>
      _CreditCardDetailViewState();
}

class _CreditCardDetailViewState extends ConsumerState<CreditCardDetailView> {
  late TextEditingController _spendController;
  late TextEditingController _statementController;
  bool _isEditing = false;
  bool _isFlipped = false;
  String _selectedFilter = 'spent'; // 'spent' or 'statement'


  @override
  void initState() {
    super.initState();
    _spendController = TextEditingController(
      text: widget.card.currentSpendings.toStringAsFixed(0),
    );
    _statementController = TextEditingController(
      text: widget.card.statementAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _spendController.dispose();
    _statementController.dispose();
    super.dispose();
  }

  /// Compute statement-cycle bounds and return (spent, statement) totals from [allTxs].
  (double, double) _computeTotals(List<dynamic> allTxs) {
    final cardTxs = allTxs
        .where((t) => t.cardId == widget.card.id.toString())
        .toList();

    final now = DateTime.now();
    DateTime mostRecentStatementDate;
    DateTime previousStatementDate;

    if (now.day >= widget.card.statementDay) {
      mostRecentStatementDate =
          DateTime(now.year, now.month, widget.card.statementDay);
      previousStatementDate = DateTime(
        now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1,
        widget.card.statementDay,
      );
    } else {
      mostRecentStatementDate = DateTime(
        now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1,
        widget.card.statementDay,
      );
      final prevMonth = mostRecentStatementDate.month;
      final prevYear = mostRecentStatementDate.year;
      previousStatementDate = DateTime(
        prevMonth == 1 ? prevYear - 1 : prevYear,
        prevMonth == 1 ? 12 : prevMonth - 1,
        widget.card.statementDay,
      );
    }

    final spent = cardTxs
        .where((t) =>
            t.timestamp.isAfter(mostRecentStatementDate) &&
            t.transactionType == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final stmt = cardTxs
        .where((t) =>
            t.timestamp.isAfter(previousStatementDate) &&
            t.timestamp.isBefore(
                mostRecentStatementDate.add(const Duration(seconds: 1))) &&
            t.transactionType == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    return (spent, stmt);
  }


  void _saveDetails() async {
    final newSpend = double.tryParse(_spendController.text) ?? 0.0;
    final newStatement = double.tryParse(_statementController.text) ?? 0.0;
    final updatedCard = widget.card
      ..currentSpendings = newSpend
      ..statementAmount = newStatement;

    await ref.read(creditCardsProvider.notifier).updateCreditCard(updatedCard);

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card details updated successfully'),
          backgroundColor: AppColors.obsidianSurface,
        ),
      );
    }
  }

  Widget _buildSecureFieldCompact(String label, String value, bool copyable) {
    final displayValue = value.isEmpty ? 'Not set' : value;
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
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

  Widget _buildFrontCardContent(double computedSpent, double computedStatement) {
    return GlassBlur(
      key: const ValueKey('front'),
      borderRadius: 20,
      cardColor: Colors.black.withOpacity(0.25),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.card.cardName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'A/C: •••• ${widget.card.last4}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_rounded,
                              color: AppColors.neonTeal,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final LocalAuthentication auth =
                                  LocalAuthentication();
                              try {
                                final bool canAuthenticateWithBiometrics =
                                    await auth.canCheckBiometrics;
                                final bool canAuthenticate =
                                    canAuthenticateWithBiometrics ||
                                    await auth.isDeviceSupported();
                                if (!canAuthenticate) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Biometric auth not available',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final bool
                                didAuthenticate = await auth.authenticate(
                                  localizedReason:
                                      'Authenticate to view secure card details',
                                  options: const AuthenticationOptions(
                                    biometricOnly: true,
                                  ),
                                );
                                if (didAuthenticate && mounted) {
                                  setState(() => _isFlipped = true);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Auth error: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.card.imageUrl.isEmpty)
                    const Icon(
                      Icons.credit_card_rounded,
                      color: Colors.white70,
                      size: 32,
                    ),
                ],
              ),
              const Spacer(),
              if (!_isEditing) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedFilter = 'spent'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedFilter == 'spent'
                              ? AppColors.neonTeal.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedFilter == 'spent'
                                ? AppColors.neonTeal
                                : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENT SPENT',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '₹${computedSpent.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFilter = 'statement'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedFilter == 'statement'
                              ? AppColors.neonTeal.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedFilter == 'statement'
                                ? AppColors.neonTeal
                                : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STATEMENT',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '₹${computedStatement.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.neonTeal,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _isEditing = true),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _spendController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Spent',
                          prefixText: '₹',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _statementController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Statement',
                          prefixText: '₹',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.neonEmerald,
                        size: 28,
                      ),
                      onPressed: _saveDetails,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _spendController.text = widget.card.currentSpendings
                              .toStringAsFixed(0);
                          _statementController.text = widget
                              .card
                              .statementAmount
                              .toStringAsFixed(0);
                          _isEditing = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCardContent() {
    return GlassBlur(
      key: const ValueKey('back'),
      borderRadius: 20,
      cardColor: Colors.black.withOpacity(0.55),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SECURE DETAILS',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonTeal,
                      letterSpacing: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isFlipped = false),
                    child: const Icon(
                      Icons.visibility_off_rounded,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildSecureFieldCompact(
                'Card Number',
                widget.card.fullCardNumber,
                true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSecureFieldCompact(
                      'Expiry Date',
                      widget.card.expiryDate,
                      false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecureFieldCompact(
                      'CVV',
                      widget.card.cvv,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final txsState = ref.watch(transactionsProvider);
    // Compute spent/statement eagerly from already-loaded data so the
    // card header shows correct numbers immediately (no setState deferral).
    final allTxs = txsState.valueOrNull ?? [];
    final (computedSpent, computedStatement) = _computeTotals(allTxs);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Card Detail',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.0,
                        ),
                        gradient: widget.card.imageUrl.isEmpty
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
                        children: [
                          if (widget.card.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child:
                                  widget.card.imageUrl.toLowerCase().endsWith(
                                    '.svg',
                                  )
                                  ? SvgPicture.asset(
                                      'assets/credit_card_images/${widget.card.imageUrl}',
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.fill,
                                    )
                                  : Image.asset(
                                      'assets/credit_card_images/${widget.card.imageUrl}',
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  final flipAnimation =
                                      Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                        ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeInOut,
                                        ),
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
                            child: _isFlipped
                                ? _buildBackCardContent()
                                : _buildFrontCardContent(computedSpent, computedStatement),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFilter == 'spent'
                            ? 'Spent Transactions'
                            : 'Statement Contributions',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Stmt Day: ${widget.card.statementDay}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: txsState.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.neonTeal,
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (txs) {
                        var cardTxs = txs
                            .where((t) => t.cardId == widget.card.id.toString())
                            .toList();

                        // Calculate statement date cycle bounds
                        final now = DateTime.now();
                        DateTime mostRecentStatementDate;
                        DateTime previousStatementDate;

                        if (now.day >= widget.card.statementDay) {
                          mostRecentStatementDate = DateTime(
                            now.year,
                            now.month,
                            widget.card.statementDay,
                          );
                          previousStatementDate = DateTime(
                            now.month == 1 ? now.year - 1 : now.year,
                            now.month == 1 ? 12 : now.month - 1,
                            widget.card.statementDay,
                          );
                        } else {
                          mostRecentStatementDate = DateTime(
                            now.month == 1 ? now.year - 1 : now.year,
                            now.month == 1 ? 12 : now.month - 1,
                            widget.card.statementDay,
                          );
                          final prevMonth = mostRecentStatementDate.month;
                          final prevYear = mostRecentStatementDate.year;
                          previousStatementDate = DateTime(
                            prevMonth == 1 ? prevYear - 1 : prevYear,
                            prevMonth == 1 ? 12 : prevMonth - 1,
                            widget.card.statementDay,
                          );
                        }

                        if (_selectedFilter == 'spent') {
                          // transactions after the statement was generated
                          cardTxs = cardTxs
                              .where(
                                (t) => t.timestamp.isAfter(
                                  mostRecentStatementDate,
                                ),
                              )
                              .toList();
                        } else {
                          // transactions linked with the statement contribution (between previousStatementDate and mostRecentStatementDate)
                          cardTxs = cardTxs
                              .where(
                                (t) =>
                                    t.timestamp.isAfter(
                                      previousStatementDate,
                                    ) &&
                                    t.timestamp.isBefore(
                                      mostRecentStatementDate.add(
                                        const Duration(seconds: 1),
                                      ),
                                    ),
                              )
                              .toList();
                        }

                        cardTxs.sort(
                          (a, b) => b.timestamp.compareTo(a.timestamp),
                        ); // recent to previous

                        if (cardTxs.isEmpty) {
                          return Center(
                            child: Text(
                              _selectedFilter == 'spent'
                                  ? 'No transactions since the last statement.'
                                  : 'No transactions in this statement period.',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: cardTxs.length,
                          itemBuilder: (context, index) {
                            final tx = cardTxs[index];
                            final formattedAmt =
                                '-₹${tx.amount.toStringAsFixed(0)}';

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
                            final dateStr =
                                '${tx.timestamp.day} ${months[tx.timestamp.month - 1]}';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassBlur(
                                borderRadius: 16,
                                child: ListTile(
                                  onTap: () => showTransactionDetailDialog(context, tx),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: CategoryUtils.getCategoryColor(
                                        tx.category,
                                        AppColors.neonTeal,
                                      ).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CategoryUtils.getCategoryIcon(tx.category),
                                      color: CategoryUtils.getCategoryColor(
                                        tx.category,
                                        AppColors.neonTeal,
                                      ),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    tx.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${tx.category} • $dateStr',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: Text(
                                    formattedAmt,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
