import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme.dart';
import 'animated_gradient_background.dart';
class LockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LockScreen({super.key, required this.onAuthenticated});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _enteredPin = '';
  bool _biometricsAvailable = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      final bioEnabled = await _storage.read(key: 'settings_biometrics') ?? 'true';
      
      setState(() {
        _biometricsAvailable = isAvailable && bioEnabled == 'true';
      });

      if (_biometricsAvailable) {
        _authenticateBiometrics();
      }
    } catch (e) {
      print('Error checking biometrics: $e');
    }
  }

  Future<void> _authenticateBiometrics() async {
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Authenticate to unlock OwnFi',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuth) {
        widget.onAuthenticated();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication failed. Please enter PIN.';
      });
    }
  }

  void _onKeyPress(String val) async {
    setState(() {
      _errorMessage = '';
    });

    if (val == 'back') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        });
      }
    } else if (val == 'bio') {
      _authenticateBiometrics();
    } else {
      if (_enteredPin.length < 4) {
        setState(() {
          _enteredPin += val;
        });
      }

      if (_enteredPin.length == 4) {
        final storedPin = await _storage.read(key: 'settings_backup_pin') ?? '1234';
        if (_enteredPin == storedPin) {
          widget.onAuthenticated();
        } else {
          setState(() {
            _enteredPin = '';
            _errorMessage = 'Invalid PIN. Please try again.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonPurple.withOpacity(0.08),
                          border: Border.all(color: AppColors.neonPurple.withOpacity(0.25)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.asset(
                            'assets/App_icon.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'OwnFi',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '100% On-Device Encrypted Lock',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Passcode dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < _enteredPin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? AppColors.neonTeal : Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: filled ? AppColors.neonTeal : Colors.white.withOpacity(0.2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        )
                      else
                        const SizedBox(height: 18),
                      const SizedBox(height: 24),
                      
                      // Numerical Grid Keypad
                      Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            String buttonText = '';
                            Widget? icon;
                            String value = '';

                            if (index < 9) {
                              buttonText = '${index + 1}';
                              value = '${index + 1}';
                            } else if (index == 9) {
                              icon = Icon(
                                _biometricsAvailable ? Icons.fingerprint_rounded : Icons.lock_open_rounded,
                                color: _biometricsAvailable ? AppColors.neonTeal : AppColors.textMuted,
                              );
                              value = 'bio';
                            } else if (index == 10) {
                              buttonText = '0';
                              value = '0';
                            } else if (index == 11) {
                              icon = const Icon(Icons.backspace_outlined, color: Colors.white);
                              value = 'back';
                            }

                            final isEnabled = value != 'bio' || _biometricsAvailable;

                            return isEnabled
                                ? InkWell(
                                    onTap: () => _onKeyPress(value),
                                    borderRadius: BorderRadius.circular(30),
                                    child: GlassBlur(
                                      borderRadius: 30,
                                      useBlur: false,
                                      child: Center(
                                        child: icon ??
                                            Text(
                                              buttonText,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                      ),
                                    ),
                                  )
                                : const SizedBox();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
