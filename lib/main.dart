import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'core/database_service.dart';
import 'core/providers.dart';
import 'core/sync/google_auth_manager.dart';
import 'core/sync/drive_backup_service.dart';
import 'core/sync/gmail_sync_service.dart';
import 'core/sync/backup_orchestrator.dart';
import 'core/sync_service.dart';
import 'app.dart';
import 'core/utils/category_utils.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final dbService = DatabaseService();
      await dbService.init();
      final auth = GoogleAuthManager();
      final driveBackup = DriveBackupService(auth);
      final gmailSync = GmailSyncService(auth);
      final webdavSync = SyncService(dbService);
      final orchestrator = BackupOrchestrator();

      await orchestrator.backupToConfiguredBackends(dbService, driveBackup, webdavSync);
      await gmailSync.syncTransactionsFromGmail(dbService);
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
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      "nightly-backup-task",
      "nightlyBackupSync",
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresDeviceIdle: true,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Workmanager initialization failed: $e\n$stackTrace');
  }

  final dbService = DatabaseService();
  await dbService.init();

  // Hook up automatic backups on database changes
  final auth = GoogleAuthManager();
  final driveBackup = DriveBackupService(auth);
  final webdavSync = SyncService(dbService);
  final orchestrator = BackupOrchestrator();
  dbService.onChanged = () {
    orchestrator.triggerAutoBackup(dbService, driveBackup, webdavSync);
  };

  runApp(
    ProviderScope(
      overrides: [databaseServiceProvider.overrideWithValue(dbService)],
      child: const MyApp(),
    ),
  );
}
