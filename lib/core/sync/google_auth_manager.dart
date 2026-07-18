import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

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

  factory LinkedGoogleAccount.fromJson(Map<String, dynamic> json) =>
      LinkedGoogleAccount(
        email: json['email'] as String,
        isPrimary: json['isPrimary'] as bool? ?? false,
        refreshToken: json['refreshToken'] as String?,
        desktopClientId: json['desktopClientId'] as String?,
        desktopClientSecret: json['desktopClientSecret'] as String?,
      );
}

class GoogleAuthManager {
  final _storage = const FlutterSecureStorage();

  // Scopes required for primary: Gmail Read + Drive AppData config + email
  static const primaryScopes = [
    drive.DriveApi.driveAppdataScope,
    gmail.GmailApi.gmailReadonlyScope,
    'email',
  ];

  // Scopes required for secondary: Gmail Read only + email
  static const secondaryScopes = [gmail.GmailApi.gmailReadonlyScope, 'email'];

  // Helper to initialize Google Sign In instance with specific scope (mobile)
  GoogleSignIn _getSignInInstance(bool isPrimary) {
    return GoogleSignIn(scopes: isPrimary ? primaryScopes : secondaryScopes);
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
  Future<void> saveLinkedAccounts(List<LinkedGoogleAccount> accounts) async {
    final data = jsonEncode(accounts.map((e) => e.toJson()).toList());
    await _storage.write(key: 'google_linked_accounts', value: data);
  }

  // Helper to get authenticated Client on either mobile or Windows
  Future<http.Client?> getHttpClient(
    LinkedGoogleAccount account,
    List<String> scopes,
  ) async {
    if (Platform.isWindows) {
      if (account.refreshToken == null || account.desktopClientId == null) {
        return null;
      }
      final client = http.Client();
      try {
        final credentials = await auth.refreshCredentials(
          auth.ClientId(account.desktopClientId!, account.desktopClientSecret),
          auth.AccessCredentials(
            auth.AccessToken(
              'Bearer',
              '',
              DateTime.now().toUtc().subtract(const Duration(hours: 1)),
            ),
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
      final GoogleSignInAccount? signedInAccount = await googleSignIn
          .signInSilently();
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
          throw StateError(
            'OAuth configuration file (client_secret_windows.json or client_secret.json) not found in the project root folder. Please download your OAuth Desktop client credentials JSON from Google Cloud Console and save it in the root folder of this project.',
          );
        }

        final jsonContent = await clientSecretFile.readAsString();
        final config = jsonDecode(jsonContent);
        final oauthParams = config['installed'] ?? config['web'];
        if (oauthParams == null) {
          throw const FormatException(
            'Invalid OAuth configuration file format. Expected "installed" or "web" root key.',
          );
        }

        final String clientId = oauthParams['client_id'];
        final String? clientSecret = oauthParams['client_secret'];

        final client = http.Client();
        final credentials = await auth.obtainAccessCredentialsViaUserConsent(
          auth.ClientId(clientId, clientSecret),
          isPrimary ? primaryScopes : secondaryScopes,
          client,
          (url) async {
            // Open user's default browser window using PowerShell to prevent CMD escaping/ampersand issues
            await Process.run('powershell', [
              '-Command',
              "Start-Process '$url'",
            ]);
          },
        );

        // Fetch user email using details endpoint
        final oauth2Api = http.Client();
        final userInfoRes = await auth
            .authenticatedClient(oauth2Api, credentials)
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
        await saveLinkedAccounts(accounts);
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

        final newAccount = LinkedGoogleAccount(
          email: account.email,
          isPrimary: isPrimary,
        );
        accounts.add(newAccount);
        await saveLinkedAccounts(accounts);
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
    await saveLinkedAccounts(accounts);
  }

  Future<void> updateLastSyncTimeForAllAccounts() async {
    final accounts = await getLinkedAccounts();
    for (var acc in accounts) {
      await _storage.write(
        key: 'last_gmail_sync_time_${acc.email}',
        value: DateTime.now().toIso8601String(),
      );
    }
  }
}
