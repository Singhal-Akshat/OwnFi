import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:my_personal_tracker/core/theme.dart';

class ApiKeysDialog extends StatefulWidget {
  const ApiKeysDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const ApiKeysDialog(),
    );
  }

  @override
  State<ApiKeysDialog> createState() => _ApiKeysDialogState();
}

class _ApiKeysDialogState extends State<ApiKeysDialog> {
  final _storage = const FlutterSecureStorage();
  final _geminiController = TextEditingController();
  final _openaiController = TextEditingController();
  final _ollamaController = TextEditingController(text: 'http://localhost:11434');

  bool _obscureGemini = true;
  bool _obscureOpenAI = true;

  @override
  void initState() {
    super.initState();
    // Pre-populate if exists
    _storage.read(key: 'ai_gemini_key').then((val) {
      if (mounted) setState(() => _geminiController.text = val ?? '');
    });
    _storage.read(key: 'ai_openai_key').then((val) {
      if (mounted) setState(() => _openaiController.text = val ?? '');
    });
    _storage.read(key: 'ai_ollama_host').then((val) {
      if (mounted) {
        setState(() => _ollamaController.text = val ?? 'http://localhost:11434');
      }
    });
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _openaiController.dispose();
    _ollamaController.dispose();
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
                  'AI Advisor API Keys',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Provide keys for local Ollama host or cloud API fallbacks. Stored securely on-device.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ollamaController,
                  decoration: const InputDecoration(
                    labelText: 'Local Ollama Host',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _geminiController,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureGemini ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () async {
                        if (_obscureGemini) {
                          final LocalAuthentication auth = LocalAuthentication();
                          final bool didAuthenticate = await auth.authenticate(
                            localizedReason: 'Please authenticate to view API Key',
                            options: const AuthenticationOptions(biometricOnly: false),
                          );
                          if (didAuthenticate && mounted) {
                            setState(() {
                              _obscureGemini = false;
                            });
                          }
                        } else {
                          setState(() {
                            _obscureGemini = true;
                          });
                        }
                      },
                    ),
                  ),
                  obscureText: _obscureGemini,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _openaiController,
                  decoration: InputDecoration(
                    labelText: 'OpenAI API Key (Optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureOpenAI ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () async {
                        if (_obscureOpenAI) {
                          final LocalAuthentication auth = LocalAuthentication();
                          final bool didAuthenticate = await auth.authenticate(
                            localizedReason: 'Please authenticate to view API Key',
                            options: const AuthenticationOptions(biometricOnly: false),
                          );
                          if (didAuthenticate && mounted) {
                            setState(() {
                              _obscureOpenAI = false;
                            });
                          }
                        } else {
                          setState(() {
                            _obscureOpenAI = true;
                          });
                        }
                      },
                    ),
                  ),
                  obscureText: _obscureOpenAI,
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
                        backgroundColor: AppColors.neonPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final gemini = _geminiController.text.trim();
                        final openai = _openaiController.text.trim();
                        final ollama = _ollamaController.text.trim();

                        if (gemini.isNotEmpty) {
                          // Show progress loader
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.neonPurple,
                              ),
                            ),
                          );

                          try {
                            final model = GenerativeModel(
                              model: 'gemini-3.1-flash-lite',
                              apiKey: gemini,
                            );
                            final content = [Content.text("Ping")];
                            final response = await model
                                .generateContent(content)
                                .timeout(const Duration(seconds: 15));
                            if (response.text == null ||
                                response.text!.isEmpty) {
                              throw Exception("Verification failed");
                            }
                            if (context.mounted) Navigator.pop(context); // Close loader
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context); // Close loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Invalid Gemini API Key: ${e.toString().replaceAll('Exception: ', '')}',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }
                        }

                        await _storage.write(
                          key: 'ai_gemini_key',
                          value: gemini,
                        );
                        await _storage.write(
                          key: 'ai_openai_key',
                          value: openai,
                        );
                        await _storage.write(
                          key: 'ai_ollama_host',
                          value: ollama,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'AI Advisor configuration saved locally',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Save Keys'),
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
