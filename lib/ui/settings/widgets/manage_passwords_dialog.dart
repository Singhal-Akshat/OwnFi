import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/core/providers.dart';

class ManagePasswordsDialog extends ConsumerStatefulWidget {
  const ManagePasswordsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const ManagePasswordsDialog(),
    );
  }

  @override
  ConsumerState<ManagePasswordsDialog> createState() => _ManagePasswordsDialogState();
}

class _ManagePasswordsDialogState extends ConsumerState<ManagePasswordsDialog> {
  final _storage = const FlutterSecureStorage();
  int? _selectedCardId;
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardsState = ref.watch(creditCardsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassBlur(
        borderRadius: 24,
        blurX: 30,
        blurY: 30,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credit Card PDF Passwords',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Stored locally to decrypt downloaded bank statement PDFs at month-end.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCardId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Credit Card',
                  border: OutlineInputBorder(),
                ),
                dropdownColor: AppColors.obsidianSurface,
                items: cardsState.maybeWhen(
                  data: (cards) => cards
                      .map(
                        (card) => DropdownMenuItem<int>(
                          value: card.id,
                          child: Text(
                            '${card.cardName} (..${card.last4})',
                          ),
                        ),
                      )
                      .toList(),
                  orElse: () => [],
                ),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCardId = val);
                    // Read existing if any
                    _storage.read(key: 'card_password_$val').then((pw) {
                      if (mounted && pw != null) {
                        _passwordController.text = pw;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Statement PDF Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonTeal,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      final pwd = _passwordController.text.trim();
                      if (_selectedCardId == null || pwd.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select card and enter password'),
                          ),
                        );
                        return;
                      }

                      await _storage.write(
                        key: 'card_password_$_selectedCardId',
                        value: pwd,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PDF statement password saved securely'),
                          ),
                        );
                      }
                    },
                    child: const Text('Save Password'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
