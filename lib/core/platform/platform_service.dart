import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'platform_service.g.dart';

abstract class PlatformService {
  bool get isAndroid;
  bool get isIOS;
  bool get isWeb;
  bool get isMacOS;
  bool get isLinux;
  bool get isWindows;
  Future<bool> isNfcAvailable();
}

class DefaultPlatformService implements PlatformService {
  const DefaultPlatformService();

  @override
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  bool get isIOS => !kIsWeb && Platform.isIOS;

  @override
  bool get isWeb => kIsWeb;

  @override
  bool get isMacOS => !kIsWeb && Platform.isMacOS;

  @override
  bool get isLinux => !kIsWeb && Platform.isLinux;

  @override
  bool get isWindows => !kIsWeb && Platform.isWindows;

  @override
  Future<bool> isNfcAvailable() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
PlatformService platformService(PlatformServiceRef ref) {
  return const DefaultPlatformService();
}
