import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:workmanager/workmanager.dart';
import 'core/database_service.dart';
import 'core/providers.dart';
import 'core/google_sync_service.dart';
import 'app.dart';
import 'core/utils/category_utils.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final dbService = DatabaseService();
      await dbService.init();
      final syncService = GoogleSyncService();
      await syncService.backupToCloud(dbService);
      await syncService.syncTransactionsFromGmail(dbService);
    } catch (e, stackTrace) {
      debugPrint('Workmanager task execution failed: $e\n$stackTrace');
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CategoryUtils.loadCustomCategories();
  try {
    await FlutterGemma.initialize();
  } catch (e) {
    debugPrint('Failed to initialize FlutterGemma: $e');
  }

  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      "nightly-backup-task",
      "nightlyBackupSync",
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresCharging: true,
        requiresDeviceIdle: true,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Workmanager initialization failed: $e\n$stackTrace');
  }

  final dbService = DatabaseService();
  await dbService.init();

  // Hook up automatic backups on database changes
  final syncService = GoogleSyncService();
  dbService.onChanged = () {
    syncService.triggerAutoBackup(dbService);
  };

  runApp(
    ProviderScope(
      overrides: [databaseServiceProvider.overrideWithValue(dbService)],
      child: const MyApp(),
    ),
  );
}
