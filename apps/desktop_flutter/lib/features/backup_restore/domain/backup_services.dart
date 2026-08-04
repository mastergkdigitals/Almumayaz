import 'backup_models.dart';

abstract interface class BackupConfigurationRepository {
  Future<BackupConfiguration> load(String deviceId);

  Future<void> save(BackupConfiguration configuration);
}

abstract interface class BackupService {
  Future<List<BackupRecord>> listHistory();

  Future<BackupRecord> createBackup({
    required BackupConfiguration configuration,
    required bool uploadToGoogleDrive,
  });

  Future<BackupVerification> verifyRestoreSource(
    BackupRestoreSource source,
  );

  Future<RestoreResult> restore(RestoreRequest request);
}

/// OAuth and Drive operations stay behind this boundary so demo and real
/// implementations can be exchanged without changing Settings widgets.
abstract interface class GoogleDriveBackupService {
  Future<CloudConnection> connection();

  Future<CloudConnection> connect();

  Future<void> disconnect();

  Future<List<CloudFolder>> listFolders({String? parentId});

  Future<CloudConnection> selectFolder(CloudFolder folder);

  Future<String> uploadEncryptedBackup(BackupRecord backup);
}
