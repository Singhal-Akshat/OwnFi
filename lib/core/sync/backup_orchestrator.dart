import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database_service.dart';
import '../sync_service.dart';
import 'drive_backup_service.dart';

class BackupOrchestrator {
  Timer? _backupDebounceTimer;

  // Debounced auto-backup matching database changes
  void triggerAutoBackup(
    DatabaseService dbService,
    DriveBackupService driveBackup,
    SyncService webdavSync,
  ) {
    _backupDebounceTimer?.cancel();
    _backupDebounceTimer = Timer(const Duration(seconds: 5), () async {
      debugPrint('BackupOrchestrator: Triggering auto-backup...');
      await backupToConfiguredBackends(dbService, driveBackup, webdavSync);
    });
  }

  // Backup to all configured/available endpoints (Google Drive and WebDAV)
  Future<void> backupToConfiguredBackends(
    DatabaseService dbService,
    DriveBackupService driveBackup,
    SyncService webdavSync,
  ) async {
    // 1. Google Drive appData backup
    try {
      final googleAccounts = await driveBackup.syncOnStartup(dbService).catchError((_) => false);
      // Wait, syncOnStartup is a check, but we can call backupToCloud directly:
      debugPrint('BackupOrchestrator: Initiating Google Drive backup...');
      final driveError = await driveBackup.backupToCloud(dbService);
      if (driveError != null) {
        debugPrint('BackupOrchestrator: Google Drive backup warning: $driveError');
      } else {
        debugPrint('BackupOrchestrator: Google Drive backup successful.');
      }
    } catch (e) {
      debugPrint('BackupOrchestrator: Google Drive backup failed: $e');
    }

    // 2. WebDAV Backup (if credentials configured)
    try {
      if (await webdavSync.isConfigured()) {
        debugPrint('BackupOrchestrator: Initiating WebDAV backup...');
        await webdavSync.uploadBackup();
        debugPrint('BackupOrchestrator: WebDAV backup successful.');
      } else {
        debugPrint('BackupOrchestrator: WebDAV backup skipped (not configured).');
      }
    } catch (e) {
      debugPrint('BackupOrchestrator: WebDAV backup failed: $e');
    }
  }

  // Restore from primary cloud backend (prefers Google Drive if configured, otherwise falls back to WebDAV)
  Future<String?> restoreFromPrimary(
    DatabaseService dbService,
    DriveBackupService driveBackup,
    SyncService webdavSync,
  ) async {
    // Attempt Google Drive restore first
    try {
      debugPrint('BackupOrchestrator: Attempting Google Drive restore...');
      final driveError = await driveBackup.restoreFromCloud(dbService);
      if (driveError == null) {
        debugPrint('BackupOrchestrator: Google Drive restore successful.');
        return null;
      }
      debugPrint('BackupOrchestrator: Google Drive restore failed, falling back: $driveError');
    } catch (e) {
      debugPrint('BackupOrchestrator: Google Drive restore exception: $e');
    }

    // Fallback to WebDAV
    try {
      if (await webdavSync.isConfigured()) {
        debugPrint('BackupOrchestrator: Attempting WebDAV restore fallback...');
        await webdavSync.restoreBackup();
        debugPrint('BackupOrchestrator: WebDAV restore successful.');
        return null;
      }
    } catch (e) {
      debugPrint('BackupOrchestrator: WebDAV restore failed: $e');
      return e.toString();
    }

    return 'No sync backend configured or restore failed.';
  }
}
