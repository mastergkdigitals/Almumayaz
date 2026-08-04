import '../../../core/domain/business_values.dart';

enum BackupFrequency { manual, daily, weekly, monthly }

enum BackupDestination { local, googleDrive, localAndGoogleDrive }

enum BackupStatus {
  queued,
  creating,
  verifying,
  completed,
  uploadFailed,
  verificationFailed,
  restoreFailed,
  cancelled,
}

enum BackupVerificationStatus { pending, valid, invalid, unreadable }

class BackupSchedule {
  const BackupSchedule({
    required this.isEnabled,
    required this.frequency,
  });

  final bool isEnabled;
  final BackupFrequency frequency;
}

class BackupConfiguration {
  BackupConfiguration({
    required String deviceId,
    required String localPath,
    required this.schedule,
    this.googleDriveFolderId,
  })  : deviceId = deviceId.trim(),
        localPath = localPath.trim() {
    if (this.deviceId.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Must not be empty');
    }
    if (this.localPath.isEmpty) {
      throw ArgumentError.value(localPath, 'localPath', 'Must not be empty');
    }
  }

  final String deviceId;
  final String localPath;
  final BackupSchedule schedule;
  final String? googleDriveFolderId;
}

class BackupRecord {
  const BackupRecord({
    required this.id,
    required this.createdAt,
    required this.destination,
    required this.status,
    required this.localPath,
    required this.byteSize,
    required this.isEncrypted,
    this.checksum,
    this.remoteFileId,
    this.failureMessage,
  });

  final EntityId id;
  final AuditTimestamp createdAt;
  final BackupDestination destination;
  final BackupStatus status;
  final String localPath;
  final int byteSize;
  final bool isEncrypted;
  final String? checksum;
  final String? remoteFileId;
  final String? failureMessage;
}

class BackupVerification {
  const BackupVerification({
    required this.status,
    required this.checksumMatches,
    required this.canRestore,
    this.message,
  });

  final BackupVerificationStatus status;
  final bool checksumMatches;
  final bool canRestore;
  final String? message;
}

sealed class BackupRestoreSource {
  const BackupRestoreSource();
}

final class StoredBackupSource extends BackupRestoreSource {
  const StoredBackupSource(this.backupId);

  final EntityId backupId;
}

final class ExternalBackupSource extends BackupRestoreSource {
  ExternalBackupSource({
    required String localPath,
    this.expectedChecksum,
  }) : localPath = localPath.trim() {
    if (this.localPath.isEmpty) {
      throw ArgumentError.value(localPath, 'localPath', 'Must not be empty');
    }
  }

  final String localPath;
  final String? expectedChecksum;
}

class RestoreRequest {
  const RestoreRequest({
    required this.source,
    required this.confirmedByUser,
  });

  final BackupRestoreSource source;
  final bool confirmedByUser;
}

class RestoreResult {
  const RestoreResult({
    required this.source,
    required this.completedAt,
    required this.restartRequired,
  });

  final BackupRestoreSource source;
  final AuditTimestamp completedAt;
  final bool restartRequired;
}

class CloudFolder {
  const CloudFolder({
    required this.id,
    required this.name,
    required this.parentId,
  });

  final String id;
  final String name;
  final String? parentId;
}

enum CloudConnectionStatus { disconnected, connecting, connected, error }

class CloudConnection {
  const CloudConnection({
    required this.status,
    this.accountLabel,
    this.selectedFolder,
    this.message,
  });

  final CloudConnectionStatus status;
  final String? accountLabel;
  final CloudFolder? selectedFolder;
  final String? message;
}
