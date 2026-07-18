import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_personal_tracker/core/database/db_migration.dart';

class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }
}

void main() {
  group('DbMigrationManager Tests', () {
    test('Should read and write migration version in storage', () async {
      final mockStorage = MockSecureStorage();

      // Verify initial version in storage is null/0
      var version = await mockStorage.read(key: 'isar_db_schema_version');
      expect(version, isNull);

      await mockStorage.write(key: 'isar_db_schema_version', value: '0');
      expect(await mockStorage.read(key: 'isar_db_schema_version'), '0');

      await mockStorage.write(key: 'isar_db_schema_version', value: DbMigrationManager.currentSchemaVersion.toString());
      expect(await mockStorage.read(key: 'isar_db_schema_version'), '1');
    });
  });
}
