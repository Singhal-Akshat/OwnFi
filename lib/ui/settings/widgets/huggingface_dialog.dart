import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_personal_tracker/core/theme.dart';

class HuggingFaceDialog extends StatefulWidget {
  const HuggingFaceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const HuggingFaceDialog(),
    );
  }

  @override
  State<HuggingFaceDialog> createState() => _HuggingFaceDialogState();
}

class _HuggingFaceDialogState extends State<HuggingFaceDialog> {
  final _storage = const FlutterSecureStorage();
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _storage.read(key: 'huggingface_token').then((val) {
      if (mounted) setState(() => _tokenController.text = val ?? '');
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HuggingFace Token',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your HuggingFace API key to download gated models.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'HuggingFace Token',
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
                      await _storage.write(
                        key: 'huggingface_token',
                        value: _tokenController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('HuggingFace Token saved.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Save Token'),
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
