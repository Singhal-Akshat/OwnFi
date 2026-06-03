import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'database_service.dart';

class SyncService {
  final DatabaseService _dbService;
  final _storage = const FlutterSecureStorage();

  SyncService(this._dbService);

  // Derive a 32-byte AES key from password using SHA-256
  Uint8List _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  // Encrypt database file using AES-256 CBC with random IV
  Uint8List encryptDatabase(Uint8List rawBytes, String password) {
    final keyBytes = _deriveKey(password);
    final iv = enc.IV.fromLength(16); // random 16-byte IV

    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc),
    );
    final encrypted = encrypter.encryptBytes(rawBytes, iv: iv);

    // Result: [16 bytes IV] + [Ciphertext]
    final result = Uint8List(iv.bytes.length + encrypted.bytes.length);
    result.setRange(0, iv.bytes.length, iv.bytes);
    result.setRange(iv.bytes.length, result.length, encrypted.bytes);
    return result;
  }

  // Decrypt database file
  Uint8List decryptDatabase(Uint8List encryptedBytes, String password) {
    final keyBytes = _deriveKey(password);

    // Extract 16-byte IV
    final iv = enc.IV(encryptedBytes.sublist(0, 16));
    final ciphertext = encryptedBytes.sublist(16);

    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc),
    );
    final decrypted = encrypter.decryptBytes(enc.Encrypted(ciphertext), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  // Get local database file
  Future<File> _getDatabaseFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/default.isar');
  }

  // Save sync credentials to secure storage
  Future<void> saveSyncConfig({
    required String masterPassword,
    required String webdavUrl,
    required String webdavUser,
    required String webdavPassword,
  }) async {
    await _storage.write(key: 'sync_master_password', value: masterPassword);
    await _storage.write(key: 'sync_webdav_url', value: webdavUrl);
    await _storage.write(key: 'sync_webdav_user', value: webdavUser);
    await _storage.write(key: 'sync_webdav_password', value: webdavPassword);
  }

  // Retrieve sync configuration
  Future<Map<String, String>> getSyncConfig() async {
    return {
      'masterPassword': await _storage.read(key: 'sync_master_password') ?? '',
      'webdavUrl': await _storage.read(key: 'sync_webdav_url') ?? '',
      'webdavUser': await _storage.read(key: 'sync_webdav_user') ?? '',
      'webdavPassword': await _storage.read(key: 'sync_webdav_password') ?? '',
    };
  }

  // Check if WebDAV is configured
  Future<bool> isConfigured() async {
    final config = await getSyncConfig();
    return config['masterPassword']!.isNotEmpty &&
        config['webdavUrl']!.isNotEmpty &&
        config['webdavUser']!.isNotEmpty;
  }

  // Upload encrypted backup to WebDAV
  Future<void> uploadBackup() async {
    final config = await getSyncConfig();
    if (config['masterPassword']!.isEmpty ||
        config['webdavUrl']!.isEmpty ||
        config['webdavUser']!.isEmpty) {
      throw Exception('Sync is not configured. Please save credentials first.');
    }

    final dbFile = await _getDatabaseFile();
    if (!await dbFile.exists()) {
      throw Exception('Local database file not found.');
    }

    // Read local db bytes
    final rawBytes = await dbFile.readAsBytes();

    // Encrypt
    final encryptedBytes = encryptDatabase(rawBytes, config['masterPassword']!);

    // Build URL & Auth header
    var urlStr = config['webdavUrl']!;
    if (!urlStr.endsWith('/')) urlStr += '/';
    final url = Uri.parse('${urlStr}default.isar.enc');

    final authBytes = utf8.encode(
      '${config['webdavUser']}:${config['webdavPassword']}',
    );
    final authHeader = 'Basic ${base64.encode(authBytes)}';

    // Upload via PUT
    final response = await http
        .put(
          url,
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/octet-stream',
          },
          body: encryptedBytes,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'WebDAV upload failed with status code ${response.statusCode}',
      );
    }
  }

  // Download and restore encrypted backup from WebDAV
  Future<void> restoreBackup() async {
    final config = await getSyncConfig();
    if (config['masterPassword']!.isEmpty ||
        config['webdavUrl']!.isEmpty ||
        config['webdavUser']!.isEmpty) {
      throw Exception('Sync is not configured. Please save credentials first.');
    }

    // Build URL & Auth header
    var urlStr = config['webdavUrl']!;
    if (!urlStr.endsWith('/')) urlStr += '/';
    final url = Uri.parse('${urlStr}default.isar.enc');

    final authBytes = utf8.encode(
      '${config['webdavUser']}:${config['webdavPassword']}',
    );
    final authHeader = 'Basic ${base64.encode(authBytes)}';

    // Download via GET
    final response = await http
        .get(url, headers: {'Authorization': authHeader})
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download backup: WebDAV status ${response.statusCode}',
      );
    }

    final encryptedBytes = response.bodyBytes;
    if (encryptedBytes.length < 16) {
      throw Exception('Downloaded backup is corrupted or too small.');
    }

    // Decrypt
    final decryptedBytes = decryptDatabase(
      encryptedBytes,
      config['masterPassword']!,
    );

    // Write to local database file safely by closing Isar first
    final dbFile = await _getDatabaseFile();

    // Close current Isar session safely
    await _dbService.close();

    // Replace the database file on disk
    await dbFile.writeAsBytes(decryptedBytes, flush: true);

    // Re-initialize Isar database session
    await _dbService.init();
  }
}
