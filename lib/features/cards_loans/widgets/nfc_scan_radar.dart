import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../services/nfc_card_reader_service.dart';

class NfcScanDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController last4Controller;

  const NfcScanDialog({
    super.key,
    required this.nameController,
    required this.last4Controller,
  });

  @override
  State<NfcScanDialog> createState() => _NfcScanDialogState();
}

class _NfcScanDialogState extends State<NfcScanDialog> with SingleTickerProviderStateMixin {
  final _nfcService = NfcCardReaderService();
  late AnimationController _animationController;
  String _statusMessage = 'Hold your contactless card near the back of your phone';
  String _scanState = 'idle'; // idle, scanning, completed, error
  String _errorMessage = '';
  ScannedCard? _scannedCard;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startNfcScan();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nfcService.stopScan();
    super.dispose();
  }

  void _startNfcScan() async {
    setState(() {
      _scanState = 'scanning';
      _statusMessage = 'Hold your contactless card near the back of your phone';
    });

    await _nfcService.startScan(
      onCardScanned: (card) {
        if (!mounted) return;
        setState(() {
          _scanState = 'completed';
          _scannedCard = card;
          _statusMessage = 'Scanned ${card.cardBrand} Card successfully!';
        });

        // Pre-fill controllers
        widget.nameController.text = card.cardName;
        widget.last4Controller.text = card.last4;

        // Automatically close after a delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _scanState = 'error';
          _errorMessage = err;
          _statusMessage = 'Scan failed';
        });
      },
    );
  }

  void _triggerSimulation() async {
    setState(() {
      _scanState = 'scanning';
      _statusMessage = 'Detecting card via NFC...';
    });

    try {
      final card = await _nfcService.simulateScan();
      if (!mounted) return;

      setState(() {
        _scanState = 'completed';
        _scannedCard = card;
        _statusMessage = 'Simulated ${card.cardBrand} Scan successfully!';
      });

      // Pre-fill controllers
      widget.nameController.text = card.cardName;
      widget.last4Controller.text = card.last4;

      // Automatically close after a delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanState = 'error';
        _errorMessage = e.toString();
        _statusMessage = 'Simulation failed';
      });
    }
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NFC Card Scanner',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Animated Radar & Status Indicator
              SizedBox(
                height: 180,
                width: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_scanState == 'scanning')
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final value = _animationController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: List.generate(3, (index) {
                              final delay = index * 0.33;
                              var progress = value - delay;
                              if (progress < 0) progress += 1.0;
                              return Container(
                                width: 40 + (progress * 130),
                                height: 40 + (progress * 130),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.neonTeal.withOpacity(1.0 - progress),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neonTeal.withOpacity((1.0 - progress) * 0.15),
                                      blurRadius: 8,
                                      spreadRadius: progress * 8,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    
                    // Central Card Graphic / Silhouette
                    _buildCenterGraphic(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Status text
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
              ),
              
              if (_scanState == 'error') ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonTeal.withOpacity(0.2),
                    foregroundColor: AppColors.neonTeal,
                    side: const BorderSide(color: AppColors.neonTeal, width: 1),
                  ),
                  onPressed: _startNfcScan,
                  child: const Text('Retry Scan'),
                ),
              ],
              
              const SizedBox(height: 24),
              const Divider(color: AppColors.glassBorder, height: 1),
              const SizedBox(height: 16),
              
              // Simulation Trigger Button (Wow / Testing factor)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple.withOpacity(0.15),
                  foregroundColor: AppColors.neonTeal,
                  side: const BorderSide(color: AppColors.neonPurple, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _scanState == 'scanning' ? null : _triggerSimulation,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('Simulate Scan (Desktop/Dev)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterGraphic() {
    switch (_scanState) {
      case 'completed':
        return Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonEmerald,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.black, size: 40),
        );
      case 'error':
        return Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
        );
      default:
        return Container(
          width: 100,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.neonTeal.withOpacity(0.8), width: 2),
            color: AppColors.midnightBg.withOpacity(0.6),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonTeal.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ]
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.nfc_rounded, color: AppColors.neonTeal, size: 32),
        );
    }
  }
}
