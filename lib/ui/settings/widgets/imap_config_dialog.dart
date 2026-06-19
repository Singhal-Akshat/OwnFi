import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/features/parser/services/email_sync_service.dart';
import 'package:my_personal_tracker/core/providers.dart';

class ImapConfigDialog extends ConsumerStatefulWidget {
  const ImapConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const ImapConfigDialog(),
    );
  }

  @override
  ConsumerState<ImapConfigDialog> createState() => _ImapConfigDialogState();
}

class _ImapConfigDialogState extends ConsumerState<ImapConfigDialog> {
  final _storage = const FlutterSecureStorage();
  final _emailController = TextEditingController();
  final _pwdController = TextEditingController();
  final _hostController = TextEditingController(text: 'imap.gmail.com');
  final _portController = TextEditingController(text: '993');

  @override
  void initState() {
    super.initState();
    _storage.read(key: 'imap_email').then((val) {
      if (mounted) setState(() => _emailController.text = val ?? '');
    });
    _storage.read(key: 'imap_host').then((val) {
      if (mounted) setState(() => _hostController.text = val ?? 'imap.gmail.com');
    });
    _storage.read(key: 'imap_port').then((val) {
      if (mounted) setState(() => _portController.text = val ?? '993');
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwdController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Configure Gmail IMAP',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text(
                  'For Gmail, use a 16-digit Google App Password rather than your standard login password.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pwdController,
                  decoration: const InputDecoration(
                    labelText: 'Google App Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'IMAP Host',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
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
                        final email = _emailController.text.trim();
                        final pwd = _pwdController.text.trim();
                        final host = _hostController.text.trim();
                        final port = int.tryParse(_portController.text.trim()) ?? 993;

                        if (email.isEmpty || pwd.isEmpty || host.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill email and password'),
                            ),
                          );
                          return;
                        }

                        await ref
                            .read(emailSyncServiceProvider)
                            .saveCredentials(email, pwd, host, port);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('IMAP credentials saved locally'),
                            ),
                          );
                        }
                      },
                      child: const Text('Save Config'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
