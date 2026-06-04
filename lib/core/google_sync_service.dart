import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';
import '../features/expenses/models/transaction_model.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

final googleSyncServiceProvider = Provider<GoogleSyncService>(
  (ref) => GoogleSyncService(),
);

class LinkedGoogleAccount {
  final String email;
  final bool isPrimary;
  final String? refreshToken;
  final String? desktopClientId;
  final String? desktopClientSecret;

  LinkedGoogleAccount({
    required this.email,
    required this.isPrimary,
    this.refreshToken,
    this.desktopClientId,
    this.desktopClientSecret,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'isPrimary': isPrimary,
    'refreshToken': refreshToken,
    'desktopClientId': desktopClientId,
    'desktopClientSecret': desktopClientSecret,
  };

  factory LinkedGoogleAccount.fromJson(Map<String, dynamic> json) => LinkedGoogleAccount(
    email: json['email'] as String,
    isPrimary: json['isPrimary'] as bool? ?? false,
    refreshToken: json['refreshToken'] as String?,
    desktopClientId: json['desktopClientId'] as String?,
    desktopClientSecret: json['desktopClientSecret'] as String?,
  );
}

class GoogleSyncService {
  final _storage = const FlutterSecureStorage();
  Timer? _backupDebounceTimer;
  
  // Scopes required for primary: Gmail Read + Drive AppData config + email
  static const _primaryScopes = [
    drive.DriveApi.driveAppdataScope,
    gmail.GmailApi.gmailReadonlyScope,
    'email',
  ];

  // Scopes required for secondary: Gmail Read only + email
  static const _secondaryScopes = [
    gmail.GmailApi.gmailReadonlyScope,
    'email',
  ];

  // Helper to initialize Google Sign In instance with specific scope (mobile)
  GoogleSignIn _getSignInInstance(bool isPrimary) {
    return GoogleSignIn(
      scopes: isPrimary ? _primaryScopes : _secondaryScopes,
    );
  }

  // Get list of linked accounts
  Future<List<LinkedGoogleAccount>> getLinkedAccounts() async {
    try {
      final data = await _storage.read(key: 'google_linked_accounts');
      if (data == null) return [];
      final List decoded = jsonDecode(data);
      return decoded.map((e) => LinkedGoogleAccount.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // Save list of linked accounts
  Future<void> _saveLinkedAccounts(List<LinkedGoogleAccount> accounts) async {
    final data = jsonEncode(accounts.map((e) => e.toJson()).toList());
    await _storage.write(key: 'google_linked_accounts', value: data);
  }

  // Helper to get authenticated Client on either mobile or Windows
  Future<http.Client?> _getHttpClient(LinkedGoogleAccount account, List<String> scopes) async {
    if (Platform.isWindows) {
      if (account.refreshToken == null || account.desktopClientId == null) return null;
      final client = http.Client();
      try {
        final credentials = await auth.refreshCredentials(
          auth.ClientId(account.desktopClientId!, account.desktopClientSecret),
          auth.AccessCredentials(
            auth.AccessToken('Bearer', '', DateTime.now().toUtc().subtract(const Duration(hours: 1))),
            account.refreshToken,
            scopes,
          ),
          client,
        );
        return auth.authenticatedClient(client, credentials);
      } catch (e) {
        debugPrint('Error refreshing credentials on Windows: $e');
        return null;
      }
    } else {
      final googleSignIn = _getSignInInstance(account.isPrimary);
      final GoogleSignInAccount? signedInAccount = await googleSignIn.signInSilently();
      if (signedInAccount == null) return null;
      return await googleSignIn.authenticatedClient();
    }
  }

  // Add/Authenticate an account
  Future<LinkedGoogleAccount?> authenticateAccount(bool isPrimary) async {
    try {
      if (Platform.isWindows) {
        var clientSecretFile = File('client_secret_windows.json');
        if (!await clientSecretFile.exists()) {
          clientSecretFile = File('client_secret.json');
        }
        if (!await clientSecretFile.exists()) {
          throw StateError('OAuth configuration file (client_secret_windows.json or client_secret.json) not found in the project root folder. Please download your OAuth Desktop client credentials JSON from Google Cloud Console and save it in the root folder of this project.');
        }

        final jsonContent = await clientSecretFile.readAsString();
        final config = jsonDecode(jsonContent);
        final oauthParams = config['installed'] ?? config['web'];
        if (oauthParams == null) {
          throw const FormatException('Invalid OAuth configuration file format. Expected "installed" or "web" root key.');
        }

        final String clientId = oauthParams['client_id'];
        final String? clientSecret = oauthParams['client_secret'];

        final client = http.Client();
        final credentials = await auth.obtainAccessCredentialsViaUserConsent(
          auth.ClientId(clientId, clientSecret),
          isPrimary ? _primaryScopes : _secondaryScopes,
          client,
          (url) async {
            // Open user's default browser window using PowerShell to prevent CMD escaping/ampersand issues
            await Process.run('powershell', ['-Command', "Start-Process '$url'"]);
          },
        );

        // Fetch user email using details endpoint
        final oauth2Api = http.Client();
        final userInfoRes = await auth.authenticatedClient(oauth2Api, credentials)
            .get(Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'));

        String email = 'unknown@gmail.com';
        if (userInfoRes.statusCode == 200) {
          final userInfo = jsonDecode(userInfoRes.body);
          if (userInfo['email'] != null) {
            email = userInfo['email'] as String;
          }
        }

        final accounts = await getLinkedAccounts();
        if (isPrimary) {
          for (var i = 0; i < accounts.length; i++) {
            if (accounts[i].isPrimary) {
              accounts[i] = LinkedGoogleAccount(
                email: accounts[i].email,
                isPrimary: false,
                refreshToken: accounts[i].refreshToken,
                desktopClientId: accounts[i].desktopClientId,
                desktopClientSecret: accounts[i].desktopClientSecret,
              );
            }
          }
        }

        accounts.removeWhere((element) => element.email == email);

        final newAccount = LinkedGoogleAccount(
          email: email,
          isPrimary: isPrimary,
          refreshToken: credentials.refreshToken,
          desktopClientId: clientId,
          desktopClientSecret: clientSecret,
        );
        accounts.add(newAccount);
        await _saveLinkedAccounts(accounts);
        return newAccount;
      } else {
        // Native Mobile Flow
        final googleSignIn = _getSignInInstance(isPrimary);
        try {
          await googleSignIn.signOut();
        } catch (e) {
          debugPrint('Google signOut error: $e');
        }

        final GoogleSignInAccount? account = await googleSignIn.signIn();
        if (account == null) return null;

        final accounts = await getLinkedAccounts();
        if (isPrimary) {
          for (var i = 0; i < accounts.length; i++) {
            if (accounts[i].isPrimary) {
              accounts[i] = LinkedGoogleAccount(
                email: accounts[i].email,
                isPrimary: false,
              );
            }
          }
        }

        accounts.removeWhere((element) => element.email == account.email);

        final newAccount = LinkedGoogleAccount(email: account.email, isPrimary: isPrimary);
        accounts.add(newAccount);
        await _saveLinkedAccounts(accounts);
        return newAccount;
      }
    } catch (e) {
      debugPrint('Google authentication error: $e');
      rethrow;
    }
  }

  // Remove linked account
  Future<void> removeAccount(String email) async {
    final accounts = await getLinkedAccounts();
    accounts.removeWhere((element) => email == element.email);
    await _saveLinkedAccounts(accounts);
  }

  // Debounced auto-backup
  void triggerAutoBackup(DatabaseService dbService) {
    _backupDebounceTimer?.cancel();
    _backupDebounceTimer = Timer(const Duration(seconds: 5), () async {
      debugPrint('Triggering auto-backup due to database changes...');
      final error = await backupToCloud(dbService);
      debugPrint('Auto-backup completed. Error: $error');
    });
  }

  // Startup cloud sync pull check
  Future<bool> syncOnStartup(DatabaseService dbService) async {
    try {
      final accounts = await getLinkedAccounts();
      final primary = accounts.firstWhere(
        (element) => element.isPrimary,
        orElse: () => throw StateError('No primary backup account linked.'),
      );

      final client = await _getHttpClient(primary, _primaryScopes);
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

      final localLastBackupStr = await _storage.read(key: 'last_local_backup_time');
      final localLastBackup = localLastBackupStr != null 
          ? DateTime.parse(localLastBackupStr) 
          : DateTime.fromMillisecondsSinceEpoch(0);

      // If the cloud backup is newer than our last local backup/sync by more than 10 seconds
      if (cloudModifiedTime.toUtc().isAfter(localLastBackup.toUtc().add(const Duration(seconds: 10)))) {
        debugPrint('Newer backup found on Google Drive ($cloudModifiedTime). Auto-restoring...');
        final error = await restoreFromCloud(dbService);
        if (error == null) {
          await _storage.write(key: 'last_local_backup_time', value: cloudModifiedTime.toUtc().toIso8601String());
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
      final accounts = await getLinkedAccounts();
      final primary = accounts.firstWhere((element) => element.isPrimary, orElse: () => throw StateError('No primary backup account configured.'));
      
      final client = await _getHttpClient(primary, _primaryScopes);
      if (client == null) return 'Could not authenticate. Please re-link your Google account.';

      final driveApi = drive.DriveApi(client);

      // Get DB directory & copy DB bytes
      final dir = await getApplicationSupportDirectory();
      final isarDbFile = File(Platform.isWindows 
          ? '${dir.path}\\default.isar'
          : '${dir.path}/default.isar');
          
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
        await driveApi.files.update(drive.File(), existingId, uploadMedia: media);
      } else {
        // Create new backup
        await driveApi.files.create(driveFile, uploadMedia: media);
      }
      
      // Save last local backup/sync timestamp
      await _storage.write(key: 'last_local_backup_time', value: DateTime.now().toUtc().toIso8601String());
      
      return null;
    } catch (e) {
      debugPrint('Error backing up database to Google Drive: $e');
      return e.toString();
    }
  }

  // Restore/Sync Isar DB from Google Drive AppData folder
  Future<String?> restoreFromCloud(DatabaseService dbService) async {
    try {
      final accounts = await getLinkedAccounts();
      final primary = accounts.firstWhere((element) => element.isPrimary, orElse: () => throw StateError('No primary backup account configured.'));

      final client = await _getHttpClient(primary, _primaryScopes);
      if (client == null) return 'Could not authenticate. Please re-link your Google account.';

      final driveApi = drive.DriveApi(client);

      // Query for backup
      final list = await driveApi.files.list(
        q: "name = 'money_tracker_backup.isar' and parents in 'appDataFolder'",
        spaces: 'appDataFolder',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (list.files == null || list.files!.isEmpty) return 'No backup file found on Google Drive AppData folder.';
      final cloudFile = list.files!.first;
      final fileId = cloudFile.id!;

      // Download bytes
      final drive.Media response = await driveApi.files.get(
        fileId, 
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataBytes = [];
      await response.stream.forEach((element) => dataBytes.addAll(element));

      // Close database, write files, re-initialize
      await dbService.close();
      final dir = await getApplicationSupportDirectory();
      final isarDbFile = File(Platform.isWindows 
          ? '${dir.path}\\default.isar'
          : '${dir.path}/default.isar');

      await isarDbFile.writeAsBytes(dataBytes);
      await dbService.init();

      // Align local sync timestamp with cloud modified time
      final cloudModifiedTime = cloudFile.modifiedTime;
      if (cloudModifiedTime != null) {
        await _storage.write(key: 'last_local_backup_time', value: cloudModifiedTime.toUtc().toIso8601String());
      } else {
        await _storage.write(key: 'last_local_backup_time', value: DateTime.now().toUtc().toIso8601String());
      }

      return null;
    } catch (e) {
      debugPrint('Error restoring database from Google Drive: $e');
      return e.toString();
    }
  }

  // Fetch emails from all linked Gmail accounts and parse transactions
  Future<List<Transaction>> syncTransactionsFromGmail(DatabaseService dbService) async {
    final List<Transaction> parsedTxs = [];
    final accounts = await getLinkedAccounts();

    for (var acc in accounts) {
      try {
        final client = await _getHttpClient(acc, acc.isPrimary ? _primaryScopes : _secondaryScopes);
        if (client == null) continue;

        final gmailApi = gmail.GmailApi(client);

        final lastSyncKey = 'last_gmail_sync_time_${acc.email}';

        // Fetch last sync timestamp for this specific email account or custom range
        final customStartStr = await _storage.read(key: 'settings_sync_start_date');
        final customEndStr = await _storage.read(key: 'settings_sync_end_date');

        String query;
        if (customStartStr != null && customEndStr != null) {
          final start = DateTime.parse(customStartStr);
          final end = DateTime.parse(customEndStr);
          final startFilter = '${start.year}/${start.month.toString().padLeft(2, '0')}/${start.day.toString().padLeft(2, '0')}';
          final endInclusive = end.add(const Duration(days: 1));
          final endFilter = '${endInclusive.year}/${endInclusive.month.toString().padLeft(2, '0')}/${endInclusive.day.toString().padLeft(2, '0')}';
          query = 'subject:(Alert OR Transaction OR statement OR e-statement) after:$startFilter before:$endFilter';
        } else {
          final lastSyncStr = await _storage.read(key: lastSyncKey);
          final lastSyncTime = lastSyncStr != null ? DateTime.parse(lastSyncStr) : DateTime.now().subtract(const Duration(days: 7));
          final dateFilter = '${lastSyncTime.year}/${lastSyncTime.month.toString().padLeft(2, '0')}/${lastSyncTime.day.toString().padLeft(2, '0')}';
          query = 'subject:(Alert OR Transaction OR statement OR e-statement) after:$dateFilter';
        }

        final listRes = await gmailApi.users.messages.list('me', q: query);
        if (listRes.messages == null || listRes.messages!.isEmpty) continue;

        for (var msgRef in listRes.messages!) {
          final msg = await gmailApi.users.messages.get('me', msgRef.id!, format: 'full');
          if (msg.payload == null) continue;

          // Parse Snippet or Body for transaction info
          final bodyText = _parseGmailMessageBody(msg);
          if (bodyText.isNotEmpty) {
            final tx = _parseTransactionFromText(bodyText, msg.internalDate);
            if (tx != null) {
              await dbService.saveTransaction(tx);
              parsedTxs.add(tx);
            }
          }
        }

        // Save last sync time
        await _storage.write(key: lastSyncKey, value: DateTime.now().toIso8601String());
      } catch (e) {
        debugPrint('Gmail Sync error for ${acc.email}: $e');
      }
    }

    return parsedTxs;
  }

  String _parseGmailMessageBody(gmail.Message msg) {
    if (msg.snippet != null) return msg.snippet!;
    return '';
  }

  Transaction? _parseTransactionFromText(String body, String? internalDateMs) {
    try {
      final cleanBody = body.toLowerCase();
      final amtRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{2})?)');
      final match = amtRegex.firstMatch(cleanBody);
      if (match == null) return null;

      final amount = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
      if (amount <= 0) return null;

      final isIncome = cleanBody.contains('credited') || cleanBody.contains('received') || cleanBody.contains('deposit');
      final isExpense = cleanBody.contains('spent') || cleanBody.contains('debited') || cleanBody.contains('charged');
      if (!isIncome && !isExpense) return null;

      String desc = 'Gmail Transaction Alert';
      final merchants = ['netflix', 'amazon', 'uber', 'zomato', 'swiggy', 'zerodha', 'starbucks', 'spotify'];
      for (var m in merchants) {
        if (cleanBody.contains(m)) {
          desc = '${m.toUpperCase()} Transaction';
          break;
        }
      }

      final date = internalDateMs != null 
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(internalDateMs)) 
          : DateTime.now();

      return Transaction()
        ..amount = amount
        ..description = desc
        ..transactionType = isIncome ? 'income' : 'expense'
        ..category = isIncome ? 'Salary' : 'Shopping'
        ..source = 'gmail'
        ..timestamp = date;
    } catch (_) {
      return null;
    }
  }
}
