import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/features/cards_loans/models/card_loan_models.dart';
import 'bank_account_detail_view.dart';

class BankAccountCard extends StatefulWidget {
  final BankAccount account;
  final WidgetRef ref;
  final String Function(double) formatCurrency;
  final Function(BuildContext, WidgetRef, BankAccount) onOptionsPressed;

  const BankAccountCard({
    super.key,
    required this.account,
    required this.ref,
    required this.formatCurrency,
    required this.onOptionsPressed,
  });

  @override
  State<BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<BankAccountCard> {
  bool _isFlipped = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.obsidianSurface,
      ),
    );
  }

  Future<void> _authenticateAndFlip() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric auth not available')),
          );
        }
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to view secure bank details',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (didAuthenticate && mounted) {
        setState(() => _isFlipped = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Auth error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = AppColors.glassCard;
    if (widget.account.colorHex.isNotEmpty) {
      try {
        cardColor = Color(
          int.parse(widget.account.colorHex.replaceFirst('#', '0xff')),
        ).withOpacity(0.18);
      } catch (_) {}
    }

    return Container(
      width: 165,
      height: 185,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onLongPress: () =>
            widget.onOptionsPressed(context, widget.ref, widget.account),
        onTap: () {
          if (!_isFlipped) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BankAccountDetailView(account: widget.account),
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
          child: _isFlipped
              ? _buildBackSide(cardColor)
              : _buildFrontSide(cardColor),
        ),
      ),
    );
  }

  Widget _buildFrontSide(Color cardColor) {
    return GlassBlur(
      key: const ValueKey('front'),
      borderRadius: 20,
      cardColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.bankName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '•••• ${widget.account.last4}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (widget.account.logoAsset.isNotEmpty)
                  SvgPicture.asset(
                    'assets/bank_logos/${widget.account.logoAsset}',
                    width: 20,
                    height: 20,
                  )
                else
                  const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BALANCE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.formatCurrency(widget.account.balance),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.visibility_rounded,
                        color: AppColors.neonTeal,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _authenticateAndFlip,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide(Color cardColor) {
    return GlassBlur(
      key: const ValueKey('back'),
      borderRadius: 20,
      cardColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DETAILS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonTeal,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isFlipped = false),
                  child: const Icon(
                    Icons.visibility_off_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildBackDetailRow('Holder', widget.account.accountHolderName),
            const SizedBox(height: 4),
            _buildBackDetailRow('A/C No', widget.account.fullAccountNumber),
            const SizedBox(height: 4),
            _buildBackDetailRow('IFSC', widget.account.ifscCode),
            const Spacer(),
          ],
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
                  fontSize: 11,
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
            onTap: () => _copyToClipboard(value, label),
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
}
