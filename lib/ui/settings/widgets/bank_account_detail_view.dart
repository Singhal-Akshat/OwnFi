import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/core/animated_gradient_background.dart';
import 'package:my_personal_tracker/core/providers.dart';
import 'package:my_personal_tracker/core/utils/category_utils.dart';
import 'package:my_personal_tracker/features/cards_loans/models/card_loan_models.dart';
import 'package:my_personal_tracker/features/expenses/ui/widgets/transaction_dialogs.dart';

class BankAccountDetailView extends ConsumerStatefulWidget {
  final BankAccount account;

  const BankAccountDetailView({super.key, required this.account});

  @override
  ConsumerState<BankAccountDetailView> createState() =>
      _BankAccountDetailViewState();
}

class _BankAccountDetailViewState extends ConsumerState<BankAccountDetailView> {
  late TextEditingController _balanceController;
  bool _isEditingBalance = false;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
      text: widget.account.balance.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  void _saveBalance() async {
    final newBal = double.tryParse(_balanceController.text) ?? 0.0;
    final updatedAcc = widget.account..balance = newBal;

    await ref.read(bankAccountsProvider.notifier).updateBankAccount(updatedAcc);

    setState(() => _isEditingBalance = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balance updated successfully'),
          backgroundColor: AppColors.obsidianSurface,
        ),
      );
    }
  }

  void _showBankAccountDetailsBottomSheet(
    BuildContext context,
    BankAccount account,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassBlur(
          borderRadius: 24,
          blurX: 30,
          blurY: 30,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      account.bankName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.neonTeal,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Account Holder', account.accountHolderName),
                const SizedBox(height: 12),
                _buildDetailRow('Account Number', account.fullAccountNumber),
                const SizedBox(height: 12),
                _buildDetailRow('IFSC Code', account.ifscCode),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Balance',
                  '₹${account.balance.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonTeal,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFrontCard(Color cardColor) {
    return GlassBlur(
      key: const ValueKey('front'),
      borderRadius: 20,
      cardColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SizedBox(
          height: 148,
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
                        widget.account.bankName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'A/C: •••• ${widget.account.last4}',
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
                                      'Authenticate to view secure bank details',
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
                  if (widget.account.logoAsset.isNotEmpty)
                    SvgPicture.asset(
                      'assets/bank_logos/${widget.account.logoAsset}',
                      width: 32,
                      height: 32,
                    )
                  else
                    const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white70,
                      size: 32,
                    ),
                ],
              ),
              const Spacer(),

              const Text(
                'CURRENT BALANCE',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (!_isEditingBalance) ...[
                    Text(
                      '₹${widget.account.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.neonTeal,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isEditingBalance = true),
                    ),
                  ] else ...[
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _balanceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '₹',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.neonTeal),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.neonTeal,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.neonEmerald,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _saveBalance,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _balanceController.text = widget.account.balance
                              .toStringAsFixed(0);
                          _isEditingBalance = false;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(Color cardColor) {
    return GlassBlur(
      key: const ValueKey('back'),
      borderRadius: 20,
      cardColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SizedBox(
          height: 148,
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
              _buildBackDetailRow(
                'Holder Name',
                widget.account.accountHolderName,
              ),
              const SizedBox(height: 12),
              _buildBackDetailRow(
                'Account Number',
                widget.account.fullAccountNumber,
              ),
              const SizedBox(height: 12),
              _buildBackDetailRow('IFSC Code', widget.account.ifscCode),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackDetailRow(String label, String value) {
    final displayValue = value.isEmpty ? 'N/A' : value;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        if (value.isNotEmpty)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppColors.obsidianSurface,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final txsState = ref.watch(transactionsProvider);

    Color cardColor = AppColors.glassCard;
    if (widget.account.colorHex.isNotEmpty) {
      try {
        cardColor = Color(
          int.parse(widget.account.colorHex.replaceFirst('#', '0xff')),
        ).withOpacity(0.18);
      } catch (_) {}
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                        'Account Detail',
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

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          final flipAnimation =
                              Tween<double>(begin: 0.0, end: 1.0).animate(
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
                        ? _buildBackCard(cardColor)
                        : _buildFrontCard(cardColor),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                        final accountTxs = txs
                            .where(
                              (t) =>
                                  t.accountName == 'bank:${widget.account.id}',
                            )
                            .toList();
                        accountTxs.sort(
                          (a, b) => b.timestamp.compareTo(a.timestamp),
                        ); // recent to previous

                        if (accountTxs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No transactions associated with this bank.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: accountTxs.length,
                          itemBuilder: (context, index) {
                            final tx = accountTxs[index];
                            final isIncome = tx.transactionType == 'income';
                            final formattedAmt =
                                '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}';

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
                                        isIncome ? AppColors.neonEmerald : AppColors.neonTeal,
                                      ).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CategoryUtils.getCategoryIcon(tx.category),
                                      color: CategoryUtils.getCategoryColor(
                                        tx.category,
                                        isIncome ? AppColors.neonEmerald : AppColors.neonTeal,
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
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isIncome
                                          ? AppColors.neonEmerald
                                          : Colors.white,
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
