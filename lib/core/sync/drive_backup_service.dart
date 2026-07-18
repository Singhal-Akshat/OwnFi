import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import 'google_auth_manager.dart';

class DriveBackupService {
  final GoogleAuthManager _authManager;
  final _storage = const FlutterSecureStorage();

  DriveBackupService(this._authManager);

  // Startup cloud sync pull check
  Future<bool> syncOnStartup(DatabaseService dbService) async {
    try {
      final accounts = await _authManager.getLinkedAccounts();
      final primary = accounts.firstWhere(
        (element) => element.isPrimary,
        orElse: () => throw StateError('No primary backup account linked.'),
      );

      final client = await _authManager.getHttpClient(primary, GoogleAuthManager.primaryScopes);
      if (client == null) return false;

      final driveApi = drive.DriveApi(client);
      final list = await driveApi.files.list(
        q: "name = 'money_tracker_backup.isar' and parents in 'appDataFolder'",
        spaces: 'appDataFolder',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (list.files == null || list.files!.isEmpty) return false;
      final cloudFile = list.files!.first;
      final cloudModifiedTime = cloudFile.modifiedTime;
      if (cloudModifiedTime == null) return false;

      final localLastBackupStr = await _storage.read(
        key: 'last_local_backup_time',
      );
      final localLastBackup = localLastBackupStr != null
          ? DateTime.parse(localLastBackupStr)
          : DateTime.fromMillisecondsSinceEpoch(0);

      // If the cloud backup is newer than our last local backup/sync by more than 10 seconds
      if (cloudModifiedTime.toUtc().isAfter(
        localLastBackup.toUtc().add(const Duration(seconds: 10)),
      )) {
        debugPrint(
          'Newer backup found on Google Drive ($cloudModifiedTime). Auto-restoring...',
        );
        final error = await restoreFromCloud(dbService);
        if (error == null) {
          await _storage.write(
            key: 'last_local_backup_time',
            value: cloudModifiedTime.toUtc().toIso8601String(),
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Startup cloud sync check: $e');
      return false;
    }
  }

  // Backup Isar DB to Google Drive AppData folder
  Future<String?> backupToCloud(DatabaseService dbService) async {
    try {
      final accounts = await _authManager.getLinkedAccounts();
      final primary = accounts.firstWhere(
        (element) => element.isPrimary,
        orElse: () => throw StateError('No primary backup account configured.'),
      );

      final client = await _authManager.getHttpClient(primary, GoogleAuthManager.primaryScopes);
      if (client == null) {
        return 'Could not authenticate. Please re-link your Google account.';
      }

      final driveApi = drive.DriveApi(client);

      // Get DB directory & copy DB bytes
      final dir = await getApplicationSupportDirectory();
      final isarDbFile = File(
        Platform.isWindows
            ? '${dir.path}\\default.isar'
            : '${dir.path}/default.isar',
      );

      if (!await isarDbFile.exists()) return 'Local database file not found.';
      final bytes = await isarDbFile.readAsBytes();

      // Query for existing backup in AppData
      final list = await driveApi.files.list(
        q: "name = 'money_tracker_backup.isar' and parents in 'appDataFolder'",
        spaces: 'appDataFolder',
      );

      final media = drive.Media(Stream.value(bytes), bytes.length);
      final driveFile = drive.File()
        ..name = 'money_tracker_backup.isar'
        ..parents = ['appDataFolder'];

      if (list.files != null && list.files!.isNotEmpty) {
        // Update existing backup
        final existingId = list.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          existingId,
          uploadMedia: media,
        );
      } else {
        // Create new backup
        await driveApi.files.create(driveFile, uploadMedia: media);
      }

      // Backup API keys and UI/AI preferences securely to appDataFolder
      final geminiKey = await _storage.read(key: 'ai_gemini_key') ?? '';
      final openaiKey = await _storage.read(key: 'ai_openai_key') ?? '';
      final ollamaHost = await _storage.read(key: 'ai_ollama_host') ?? '';

      final prefs = await SharedPreferences.getInstance();
      final categoriesExpense = prefs.getStringList('categories_expense');
      final categoriesIncome = prefs.getStringList('categories_income');
      final categoriesTransfer = prefs.getStringList('categories_transfer');
      final customCategoryIcons = prefs.getStringList('custom_category_icons');
      final customCategoryColors = prefs.getStringList(
        'custom_category_colors',
      );
      final selectedModelId = prefs.getString('selectedModelId');
      final hasSeenModelOnboarding = prefs.getBool('hasSeenModelOnboarding');

      final keysMap = {
        'ai_gemini_key': geminiKey,
        'ai_openai_key': openaiKey,
        'ai_ollama_host': ollamaHost,
        if (categoriesExpense != null) 'categories_expense': categoriesExpense,
        if (categoriesIncome != null) 'categories_income': categoriesIncome,
        if (categoriesTransfer != null)
          'categories_transfer': categoriesTransfer,
        if (customCategoryIcons != null)
          'custom_category_icons': customCategoryIcons,
        if (customCategoryColors != null)
          'custom_category_colors': customCategoryColors,
        if (selectedModelId != null) 'selectedModelId': selectedModelId,
        if (hasSeenModelOnboarding != null)
          'hasSeenModelOnboarding': hasSeenModelOnboarding,
      };
      final keysBytes = utf8.encode(jsonEncode(keysMap));
      final keysMedia = drive.Media(Stream.value(keysBytes), keysBytes.length);
      final keysFile = drive.File()
        ..name = 'money_tracker_keys.json'
        ..parents = ['appDataFolder'];

      final keysList = await driveApi.files.list(
        q: "name = 'money_tracker_keys.json' and parents in 'appDataFolder'",
        spaces: 'appDataFolder',
      );
      if (keysList.files != null && keysList.files!.isNotEmpty) {
        await driveApi.files.update(
          drive.File(),
          keysList.files!.first.id!,
          uploadMedia: keysMedia,
        );
      } else {
        await driveApi.files.create(keysFile, uploadMedia: keysMedia);
      }

      // Save last local backup/sync timestamp
      await _storage.write(
        key: 'last_local_backup_time',
        value: DateTime.now().toUtc().toIso8601String(),
      );

      return null;
    } catch (e) {
      debugPrint('Error backing up database to Google Drive: $e');
      return e.toString();
    }
  }

  // Restore/Sync Isar DB from Google Drive AppData folder
  Future<String?> restoreFromCloud(DatabaseService dbService) async {
    try {
      final accounts = await _authManager.getLinkedAccounts();
      final primary = accounts.firstWhere(
        (element) => element.isPrimary,
        orElse: () => throw StateError('No primary backup account configured.'),
      );

      final client = await _authManager.getHttpClient(primary, GoogleAuthManager.primaryScopes);
      if (client == null) {
        return 'Could not authenticate. Please re-link your Google account.';
      }

      final driveApi = drive.DriveApi(client);

      // Query for backup
      final list = await driveApi.files.list(
        q: "name = 'money_tracker_backup.isar' and parents in 'appDataFolder'",
        spaces: 'appDataFolder',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (list.files == null || list.files!.isEmpty) {
        return 'No backup file found on Google Drive AppData folder.';
      }
      final cloudFile = list.files!.first;
      final fileId = cloudFile.id!;

      // Download bytes
      final drive.Media response =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> dataBytes = [];
      await response.stream.forEach((element) => dataBytes.addAll(element));

      // Close database, write files, re-initialize
      await dbService.close();
      final dir = await getApplicationSupportDirectory();
      final isarDbFile = File(
        Platform.isWindows
            ? '${dir.path}\\default.isar'
            : '${dir.path}/default.isar',
      );

      await isarDbFile.writeAsBytes(dataBytes);
      await dbService.init();

      // Restore API keys if available
      final keysList = await driveApi.files.list(
        q: "name = 'money_tracker_keys.json' and parents in 'appDataFolder'",
        spaces: 'appDataFolder',
        $fields: 'files(id, name)',
      );
      if (keysList.files != null && keysList.files!.isNotEmpty) {
        final keysResponse =
            await driveApi.files.get(
                  keysList.files!.first.id!,
                  downloadOptions: drive.DownloadOptions.fullMedia,
                )
                as drive.Media;
        final List<int> keysData = [];
        await keysResponse.stream.forEach(
          (element) => keysData.addAll(element),
        );
        if (keysData.isNotEmpty) {
          try {
            final keysMap = jsonDecode(utf8.decode(keysData));
            if (keysMap['ai_gemini_key'] != null) {
              await _storage.write(
                key: 'ai_gemini_key',
                value: keysMap['ai_gemini_key'],
              );
            }
            if (keysMap['ai_openai_key'] != null) {
              await _storage.write(
                key: 'ai_openai_key',
                value: keysMap['ai_openai_key'],
              );
            }
            if (keysMap['ai_ollama_host'] != null) {
              await _storage.write(
                key: 'ai_ollama_host',
                value: keysMap['ai_ollama_host'],
              );
            }

            final prefs = await SharedPreferences.getInstance();
            if (keysMap['categories_expense'] != null) {
              await prefs.setStringList(
                'categories_expense',
                List<String>.from(keysMap['categories_expense'] as List),
              );
            }
            if (keysMap['categories_income'] != null) {
              await prefs.setStringList(
                'categories_income',
                List<String>.from(keysMap['categories_income'] as List),
              );
            }
            if (keysMap['categories_transfer'] != null) {
              await prefs.setStringList(
                'categories_transfer',
                List<String>.from(keysMap['categories_transfer'] as List),
              );
            }
            if (keysMap['custom_category_icons'] != null) {
              await prefs.setStringList(
                'custom_category_icons',
                List<String>.from(keysMap['custom_category_icons'] as List),
              );
            }
            if (keysMap['custom_category_colors'] != null) {
              await prefs.setStringList(
                'custom_category_colors',
                List<String>.from(keysMap['custom_category_colors'] as List),
              );
            }
            if (keysMap['selectedModelId'] != null) {
              await prefs.setString(
                'selectedModelId',
                keysMap['selectedModelId'] as String,
              );
            }
            if (keysMap['hasSeenModelOnboarding'] != null) {
              await prefs.setBool(
                'hasSeenModelOnboarding',
                keysMap['hasSeenModelOnboarding'] as bool,
              );
            }
          } catch (e) {
            debugPrint('Failed to decode restored keys: $e');
          }
        }
      }

      // Align local sync timestamp with cloud modified time
      final cloudModifiedTime = cloudFile.modifiedTime;
      if (cloudModifiedTime != null) {
        await _storage.write(
          key: 'last_local_backup_time',
          value: cloudModifiedTime.toUtc().toIso8601String(),
        );
      } else {
        await _storage.write(
          key: 'last_local_backup_time',
          value: DateTime.now().toUtc().toIso8601String(),
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error restoring database from Google Drive: $e');
      return e.toString();
    }
  }
}
