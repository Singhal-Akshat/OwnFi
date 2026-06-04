import 'dart:convert';
import 'dart:io';
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

final googleSyncServiceProvider = Provider<GoogleSyncService>(
  (ref) => GoogleSyncService(),
);

class LinkedGoogleAccount {
  final String email;
  final bool isPrimary;

  LinkedGoogleAccount({required this.email, required this.isPrimary});

  Map<String, dynamic> toJson() => {
    'email': email,
    'isPrimary': isPrimary,
  };

  factory LinkedGoogleAccount.fromJson(Map<String, dynamic> json) => LinkedGoogleAccount(
    email: json['email'] as String,
    isPrimary: json['isPrimary'] as bool? ?? false,
  );
}

class GoogleSyncService {
  final _storage = const FlutterSecureStorage();
  
  // Scopes required for primary: Gmail Read + Drive AppData config
  static const _primaryScopes = [
    drive.DriveApi.driveAppdataScope,
    gmail.GmailApi.gmailReadonlyScope,
  ];

  // Scopes required for secondary: Gmail Read only
  static const _secondaryScopes = [
    gmail.GmailApi.gmailReadonlyScope,
  ];

  // Helper to initialize Google Sign In instance with specific scope
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

  // Add/Authenticate an account
  Future<LinkedGoogleAccount?> authenticateAccount(bool isPrimary) async {
    try {
      final googleSignIn = _getSignInInstance(isPrimary);
      // Ensure we sign out first to force account selector
      try {
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('Google signOut error: $e');
      }
      
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) return null;

      final accounts = await getLinkedAccounts();
      // If setting a primary, remove primary status from existing ones
      if (isPrimary) {
        for (var i = 0; i < accounts.length; i++) {
          if (accounts[i].isPrimary) {
            accounts[i] = LinkedGoogleAccount(email: accounts[i].email, isPrimary: false);
          }
        }
      }

      // Check if already linked
      accounts.removeWhere((element) => element.email == account.email);
      
      final newAccount = LinkedGoogleAccount(email: account.email, isPrimary: isPrimary);
      accounts.add(newAccount);
      await _saveLinkedAccounts(accounts);
      return newAccount;
    } catch (e) {
      debugPrint('Google authentication error: $e');
      rethrow;
    }
  }

  // Remove linked account
  Future<void> removeAccount(String email) async {
    final accounts = await getLinkedAccounts();
    accounts.removeWhere((element) => element.email == email);
    await _saveLinkedAccounts(accounts);
  }

  // Backup Isar DB to Google Drive AppData folder (Primary account only)
  Future<bool> backupToCloud(DatabaseService dbService) async {
    try {
      final accounts = await getLinkedAccounts();
      final primary = accounts.firstWhere((element) => element.isPrimary, orElse: () => throw StateError('No primary backup account configured.'));
      
      final googleSignIn = _getSignInInstance(true);
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();
      if (account == null) return false;

      final client = await googleSignIn.authenticatedClient();
      if (client == null) return false;

      final driveApi = drive.DriveApi(client);

      // Get DB directory & copy DB bytes
      final isarDbFile = File(Platform.isWindows 
          ? '${(await getApplicationSupportDirectory()).path}\\default.isar'
          : '${(await getApplicationSupportDirectory()).path}/default.isar');
          
      if (!await isarDbFile.exists()) return false;
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
      return true;
    } catch (e) {
      debugPrint('Error backing up database to Google Drive: $e');
      return false;
    }
  }

  // Restore/Sync Isar DB from Google Drive AppData folder (Primary account only)
  Future<bool> restoreFromCloud(DatabaseService dbService) async {
    try {
      final accounts = await getLinkedAccounts();
      final primary = accounts.firstWhere((element) => element.isPrimary, orElse: () => throw StateError('No primary backup account configured.'));

      final googleSignIn = _getSignInInstance(true);
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();
      if (account == null) return false;

      final client = await googleSignIn.authenticatedClient();
      if (client == null) return false;

      final driveApi = drive.DriveApi(client);

      // Query for backup
      final list = await driveApi.files.list(
        q: "name = 'money_tracker_backup.isar' and parents in 'appDataFolder'",
        spaces: 'appDataFolder',
      );

      if (list.files == null || list.files!.isEmpty) return false;
      final fileId = list.files!.first.id!;

      // Download bytes
      final drive.Media response = await driveApi.files.get(
        fileId, 
        downloadOptions: drive.DownloadOptions.metadata,
      ) as drive.Media;

      final List<int> dataBytes = [];
      await response.stream.forEach((element) => dataBytes.addAll(element));

      // Close database, write files, re-initialize
      await dbService.close();
      final isarDbFile = File(Platform.isWindows 
          ? '${(await getApplicationSupportDirectory()).path}\\default.isar'
          : '${(await getApplicationSupportDirectory()).path}/default.isar');

      await isarDbFile.writeAsBytes(dataBytes);
      await dbService.init();

      return true;
    } catch (e) {
      debugPrint('Error restoring database from Google Drive: $e');
      return false;
    }
  }

  // Fetch emails from all linked Gmail accounts and parse transactions
  Future<List<Transaction>> syncTransactionsFromGmail(DatabaseService dbService) async {
    final List<Transaction> parsedTxs = [];
    final accounts = await getLinkedAccounts();

    for (var acc in accounts) {
      try {
        final googleSignIn = _getSignInInstance(acc.isPrimary);
        final GoogleSignInAccount? account = await googleSignIn.signInSilently();
        if (account == null) continue;

        final client = await googleSignIn.authenticatedClient();
        if (client == null) continue;

        final gmailApi = gmail.GmailApi(client);

        // Fetch last sync timestamp for this specific email account
        final lastSyncKey = 'last_gmail_sync_time_${acc.email}';
        final lastSyncStr = await _storage.read(key: lastSyncKey);
        final lastSyncTime = lastSyncStr != null ? DateTime.parse(lastSyncStr) : DateTime.now().subtract(const Duration(days: 7));

        // Format query parameter (after:YYYY/MM/DD)
        final dateFilter = '${lastSyncTime.year}/${lastSyncTime.month.toString().padLeft(2, '0')}/${lastSyncTime.day.toString().padLeft(2, '0')}';
        final query = 'subject:(Alert OR Transaction OR statement OR e-statement) after:$dateFilter';

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
    // Standard extraction fallback
    return '';
  }

  Transaction? _parseTransactionFromText(String body, String? internalDateMs) {
    try {
      final cleanBody = body.toLowerCase();
      // Basic regex parsing for demonstration
      final amtRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{2})?)');
      final match = amtRegex.firstMatch(cleanBody);
      if (match == null) return null;

      final amount = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
      if (amount <= 0) return null;

      final isIncome = cleanBody.contains('credited') || cleanBody.contains('received') || cleanBody.contains('deposit');
      final isExpense = cleanBody.contains('spent') || cleanBody.contains('debited') || cleanBody.contains('charged');
      if (!isIncome && !isExpense) return null;

      // Extract Description
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
