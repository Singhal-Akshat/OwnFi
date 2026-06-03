import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

class ScannedCard {
  final String cardName;
  final String last4;
  final String expiry; // MM/YY
  final String cardBrand; // Visa, Mastercard, Amex, RuPay, Unknown

  ScannedCard({
    required this.cardName,
    required this.last4,
    required this.expiry,
    required this.cardBrand,
  });
}

class NfcCardReaderService {
  static const _channel = MethodChannel('com.mypersonaltracker.tracker/nfc');

  /// Open Android settings for NFC
  Future<void> openNfcSettings() async {
    try {
      await _channel.invokeMethod('openNfcSettings');
    } catch (e) {
      print('Failed to open NFC settings: $e');
    }
  }

  // Common AIDs for EMV credit cards
  static const List<Map<String, dynamic>> _aids = [
    {
      'name': 'Visa',
      'bytes': [0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10]
    },
    {
      'name': 'Mastercard',
      'bytes': [0xA0, 0x00, 0x00, 0x00, 0x04, 0x10, 0x10]
    },
    {
      'name': 'Amex',
      'bytes': [0xA0, 0x00, 0x00, 0x00, 0x25, 0x01, 0x07]
    },
    {
      'name': 'RuPay',
      'bytes': [0xA0, 0x00, 0x05, 0x24, 0x10, 0x10]
    },
  ];

  // PPSE selection command (2PAY.SYS.DDF01)
  static final List<int> _ppseCommand = [
    0x00, 0xA4, 0x04, 0x00, 0x0E, 
    0x32, 0x50, 0x41, 0x59, 0x2E, 0x53, 0x59, 0x53, 0x2E, 0x44, 0x44, 0x46, 0x30, 0x31,
    0x00
  ];

  /// Check if NFC is available on this device
  Future<bool> isNfcAvailable() async {
    try {
      if (Platform.isWindows) return false;
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Start scanning for physical EMV cards
  Future<void> startScan({
    required Function(ScannedCard card) onCardScanned,
    required Function(String error) onError,
  }) async {
    final available = await isNfcAvailable();
    if (!available) {
      onError('NFC is not supported or disabled on this device.');
      return;
    }

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final isoDep = IsoDep.from(tag);
          if (isoDep == null) {
            onError('Not an EMV chip card. Please scan a contactless credit card.');
            return;
          }

          try {
            ScannedCard? scannedCard;

            // 1. Try PPSE selection to discover AIDs
            try {
              final response = await isoDep.transceive(data: Uint8List.fromList(_ppseCommand));
              final detectedAids = _parsePpseResponse(response);
              
              for (final aid in detectedAids) {
                scannedCard = await _tryReadCardWithAid(isoDep, aid);
                if (scannedCard != null) break;
              }
            } catch (_) {
              // Ignore PPSE failures and fall back to sequential AID selection
            }

            // 2. Fallback: try sequential selection of known AIDs if PPSE failed or returned no match
            if (scannedCard == null) {
              for (final aidMap in _aids) {
                final aidBytes = aidMap['bytes'] as List<int>;
                scannedCard = await _tryReadCardWithAid(isoDep, aidBytes);
                if (scannedCard != null) break;
              }
            }

            if (scannedCard != null) {
              await HapticFeedback.mediumImpact();
              onCardScanned(scannedCard);
            } else {
              onError('Could not extract card details. Ensure it is a contactless credit card.');
            }
          } catch (e) {
            onError('Error communicating with card: $e');
          } finally {
            await NfcManager.instance.stopSession();
          }
        },
        onError: (error) async {
          onError(error.message ?? 'NFC Scan failed.');
        },
      );
    } catch (e) {
      onError('Failed to start NFC session: $e');
    }
  }

  /// Stop active NFC scan session
  Future<void> stopScan() async {
    try {
      if (!Platform.isWindows) {
        await NfcManager.instance.stopSession();
      }
    } catch (_) {}
  }

  /// Selects an AID and reads standard records to find PAN and Expiry
  Future<ScannedCard?> _tryReadCardWithAid(IsoDep isoDep, List<int> aid) async {
    // Select AID APDU: 00 A4 04 00 [len] [AID] 00
    final selectCommand = [
      0x00, 0xA4, 0x04, 0x00, aid.length,
      ...aid,
      0x00
    ];

    try {
      final selectResponse = await isoDep.transceive(data: Uint8List.fromList(selectCommand));
      
      // Parse select response for PAN and Expiry
      var card = _extractCardFromBytes(selectResponse);
      if (card != null) return card;

      // Scan common records (SFI 1 to 4, records 1 to 5)
      // Read Record APDU: 00 B2 [Record] [SFI << 3 | 0x04] 00
      for (int sfi = 1; sfi <= 4; sfi++) {
        final p2 = (sfi << 3) | 0x04;
        for (int record = 1; record <= 5; record++) {
          final readCommand = [0x00, 0xB2, record, p2, 0x00];
          try {
            final recordResponse = await isoDep.transceive(data: Uint8List.fromList(readCommand));
            card = _extractCardFromBytes(recordResponse);
            if (card != null) return card;
          } catch (_) {
            // Record doesn't exist, continue scan
          }
        }
      }
    } catch (_) {
      // AID select failed
    }
    return null;
  }

  /// Parses PPSE response to find list of supported AIDs (Tag 4F)
  List<List<int>> _parsePpseResponse(Uint8List response) {
    final List<List<int>> detectedAids = [];
    int i = 0;
    while (i < response.length - 2) {
      if (response[i] == 0x4F) {
        final len = response[i + 1];
        if (len > 0 && len <= 16 && i + 2 + len <= response.length) {
          detectedAids.add(response.sublist(i + 2, i + 2 + len));
        }
        i += len + 1;
      } else {
        i++;
      }
    }
    return detectedAids;
  }

  /// Scans byte buffer for EMV Tags (0x5A for PAN, 0x5F24 for Expiry)
  ScannedCard? _extractCardFromBytes(Uint8List bytes) {
    String? pan;
    String? expiry;

    // Search for PAN (Tag 0x5A)
    int i = 0;
    while (i < bytes.length - 2) {
      if (bytes[i] == 0x5A) {
        final len = bytes[i + 1];
        if (len > 0 && len <= 10 && i + 2 + len <= bytes.length) {
          final bcdString = _bytesToBcdString(bytes.sublist(i + 2, i + 2 + len));
          // Strip padding 'F'
          final parsedPan = bcdString.endsWith('f') || bcdString.endsWith('F')
              ? bcdString.substring(0, bcdString.length - 1)
              : bcdString;

          if (RegExp(r'^\d{12,19}$').hasMatch(parsedPan)) {
            pan = parsedPan;
            break;
          }
        }
      }
      i++;
    }

    // Search for Expiry (Tag 0x5F 0x24)
    i = 0;
    while (i < bytes.length - 4) {
      if (bytes[i] == 0x5F && bytes[i + 1] == 0x24) {
        final len = bytes[i + 2];
        if (len == 3 && i + 3 + len <= bytes.length) {
          final bcdString = _bytesToBcdString(bytes.sublist(i + 3, i + 3 + len)); // YYMMDD
          if (bcdString.length >= 4) {
            final yy = bcdString.substring(0, 2);
            final mm = bcdString.substring(2, 4);
            expiry = '$mm/$yy';
            break;
          }
        }
      }
      i++;
    }

    if (pan != null) {
      final brand = _detectBrand(pan);
      final last4Digits = pan.substring(pan.length - 4);
      final displayName = '$brand Card (Scanned)';
      
      return ScannedCard(
        cardName: displayName,
        last4: last4Digits,
        expiry: expiry ?? '12/30', // Default backup expiry
        cardBrand: brand,
      );
    }

    return null;
  }

  /// Converts bytes to a BCD representation string
  String _bytesToBcdString(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(((b >> 4) & 0x0F).toRadixString(16));
      buffer.write((b & 0x0F).toRadixString(16));
    }
    return buffer.toString();
  }

  /// Detects credit card brand based on PAN prefix
  String _detectBrand(String pan) {
    if (pan.startsWith(RegExp(r'^4'))) return 'Visa';
    if (pan.startsWith(RegExp(r'^5[1-5]|^2[2-7]'))) return 'Mastercard';
    if (pan.startsWith(RegExp(r'^3[47]'))) return 'Amex';
    if (pan.startsWith(RegExp(r'^6[08]|6521|6522'))) return 'RuPay';
    return 'Unknown';
  }

  /// Premium Simulation fallback for testing on emulators and desktop
  Future<ScannedCard> simulateScan() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    await HapticFeedback.mediumImpact();

    // List of premium cards to cycle in simulation
    final mockCards = [
      ScannedCard(cardName: 'HDFC Regalia Gold', last4: '4392', expiry: '09/29', cardBrand: 'Visa'),
      ScannedCard(cardName: 'ICICI Rubyx MC', last4: '8720', expiry: '11/30', cardBrand: 'Mastercard'),
      ScannedCard(cardName: 'SBI Card Prime', last4: '1903', expiry: '04/28', cardBrand: 'Visa'),
      ScannedCard(cardName: 'Amex Platinum Travel', last4: '2005', expiry: '07/31', cardBrand: 'Amex'),
      ScannedCard(cardName: 'BOI RuPay Select', last4: '5541', expiry: '12/29', cardBrand: 'RuPay'),
    ];

    // Pick a card randomly
    final randomIndex = DateTime.now().millisecond % mockCards.length;
    return mockCards[randomIndex];
  }
}
