import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import '../logging/structured_logger.dart';

class DbMigrationManager {
  final FlutterSecureStorage _storage;
  static const String _dbVersionKey = 'isar_db_schema_version';
  static const int currentSchemaVersion = 1;

  DbMigrationManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> runMigrations(Isar isar) async {
    final storedVersionStr = await _storage.read(key: _dbVersionKey);
    final storedVersion = storedVersionStr != null ? int.tryParse(storedVersionStr) ?? 0 : 0;

    LoggerService.info('DbMigrationManager: Stored DB version: $storedVersion, Target version: $currentSchemaVersion');

    if (storedVersion < currentSchemaVersion) {
      for (var v = storedVersion + 1; v <= currentSchemaVersion; v++) {
        LoggerService.info('DbMigrationManager: Running migration step to version $v...');
        await _executeMigrationStep(isar, v);
      }
      await _storage.write(key: _dbVersionKey, value: currentSchemaVersion.toString());
      LoggerService.info('DbMigrationManager: Migration completed to version $currentSchemaVersion');
    } else {
      LoggerService.info('DbMigrationManager: No migrations needed.');
    }
  }

  Future<void> _executeMigrationStep(Isar isar, int version) async {
    switch (version) {
      case 1:
        // Initial version setup. No special migrations needed for v1.
        break;
      default:
        throw UnimplementedError('Migration step for version $version is not defined.');
    }
  }
}
