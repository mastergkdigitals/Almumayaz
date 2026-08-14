import 'dart:async';

import '../../../core/domain/business_values.dart';
import '../../../core/services/app_operation_gate.dart';
import '../../audit_log/application/audit_write_support.dart';
import '../../audit_log/domain/audit_models.dart';
import '../../audit_log/domain/audit_repository.dart';
import '../domain/backup_models.dart';
import '../domain/backup_services.dart';

class AuditedBackupConfigurationRepository
    implements BackupConfigurationRepository {
  const AuditedBackupConfigurationRepository({
    required BackupConfigurationRepository delegate,
    required AuditEventWriter auditWriter,
    AuditActorProvider? actorProvider,
    AppOperationGate? operationGate,
  })  : _delegate = delegate,
        _auditWriter = auditWriter,
        _actorProvider = actorProvider,
        _operationGate = operationGate;

  final BackupConfigurationRepository _delegate;
  final AuditEventWriter _auditWriter;
  final AuditActorProvider? _actorProvider;
  final AppOperationGate? _operationGate;

  @override
  Future<BackupConfiguration> load(String deviceId) =>
      _runBackupOperation(_operationGate, () => _delegate.load(deviceId));

  @override
  Future<void> save(BackupConfiguration configuration) =>
      _runBackupOperation(_operationGate, () => _save(configuration));

  Future<void> _save(BackupConfiguration configuration) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    BackupConfiguration? previous;
    try {
      previous = await _delegate.load(configuration.deviceId);
    } on Object {
      // A missing/unavailable previous value must not prevent the actual save.
    }
    try {
      await _delegate.save(configuration);
      await _writeConfiguration(
        configuration: configuration,
        outcome: AuditOutcome.success,
        summary: 'تم تحديث إعدادات النسخ الاحتياطي',
        before: previous == null ? const {} : _configurationSnapshot(previous),
        after: _configurationSnapshot(configuration),
        actor: actor,
      );
    } on Object catch (error) {
      await _writeConfiguration(
        configuration: configuration,
        outcome: auditFailureOutcome(error),
        summary: 'تعذر تحديث إعدادات النسخ الاحتياطي',
        before: previous == null ? const {} : _configurationSnapshot(previous),
        after: _configurationSnapshot(configuration),
        details: safeAuditFailureDetails(error),
        actor: actor,
      );
      rethrow;
    }
  }

  Future<void> _writeConfiguration({
    required BackupConfiguration configuration,
    required AuditOutcome outcome,
    required String summary,
    required Map<String, Object?> before,
    required Map<String, Object?> after,
    required AuditActor? actor,
    Map<String, Object?> details = const {},
  }) {
    return writeAuditBestEffort(
      _auditWriter,
      AuditEvent(
        action: AuditAction.update,
        outcome: outcome,
        summary: summary,
        actor: actor,
        details: details,
        before: before,
        after: after,
        entityType: 'backupConfiguration',
        entityId: EntityId(
          'backup-configuration:${configuration.deviceId}',
        ),
      ),
    );
  }
}

class AuditedBackupService implements BackupService {
  const AuditedBackupService({
    required BackupService delegate,
    required AuditEventWriter auditWriter,
    AuditActorProvider? actorProvider,
    AppOperationGate? operationGate,
  })  : _delegate = delegate,
        _auditWriter = auditWriter,
        _actorProvider = actorProvider,
        _operationGate = operationGate;

  final BackupService _delegate;
  final AuditEventWriter _auditWriter;
  final AuditActorProvider? _actorProvider;
  final AppOperationGate? _operationGate;
  static final EntityId _pendingBackupId = EntityId('backup-pending');
  static final EntityId _externalBackupId = EntityId('backup-external');

  @override
  Future<List<BackupRecord>> listHistory() =>
      _runBackupOperation(_operationGate, _delegate.listHistory);

  @override
  Future<BackupRecord> createBackup({
    required BackupConfiguration configuration,
    required bool uploadToGoogleDrive,
  }) =>
      _runBackupOperation(
        _operationGate,
        () => _createBackup(
          configuration: configuration,
          uploadToGoogleDrive: uploadToGoogleDrive,
        ),
      );

  Future<BackupRecord> _createBackup({
    required BackupConfiguration configuration,
    required bool uploadToGoogleDrive,
  }) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    try {
      final record = await _delegate.createBackup(
        configuration: configuration,
        uploadToGoogleDrive: uploadToGoogleDrive,
      );
      final cloudFailed = record.status == BackupStatus.uploadFailed;
      await writeAuditBestEffort(
        _auditWriter,
        AuditEvent(
          action: AuditAction.backup,
          outcome:
              cloudFailed ? AuditOutcome.failure : AuditOutcome.success,
          summary: cloudFailed
              ? 'اكتملت النسخة المحلية وتعذر رفع النسخة السحابية'
              : 'اكتمل إنشاء النسخة الاحتياطية',
          actor: actor,
          details: {
            'destination': record.destination.name,
            'localBackupAvailable': true,
            'cloudCopyAvailable': record.remoteFileId != null,
          },
          after: _backupSnapshot(record),
          entityType: 'backup',
          entityId: record.id,
        ),
      );
      return record;
    } on Object catch (error) {
      await writeAuditBestEffort(
        _auditWriter,
        AuditEvent(
          action: AuditAction.backup,
          outcome: auditFailureOutcome(error),
          summary: 'فشل إنشاء النسخة الاحتياطية',
          actor: actor,
          details: {
            'destination': uploadToGoogleDrive
                ? BackupDestination.localAndGoogleDrive.name
                : BackupDestination.local.name,
            ...safeAuditFailureDetails(error),
          },
          entityType: 'backup',
          entityId: _pendingBackupId,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<BackupVerification> verifyRestoreSource(
    BackupRestoreSource source,
  ) =>
      _runBackupOperation(
        _operationGate,
        () => _verifyRestoreSource(source),
      );

  Future<BackupVerification> _verifyRestoreSource(
    BackupRestoreSource source,
  ) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    final storedSource = source is StoredBackupSource ? source : null;
    final entityId = storedSource?.backupId ?? _externalBackupId;
    try {
      final verification = await _delegate.verifyRestoreSource(source);
      if (!verification.canRestore) {
        await writeAuditBestEffort(
          _auditWriter,
          AuditEvent(
            action: AuditAction.restore,
            outcome: AuditOutcome.blocked,
            summary: 'رُفض مصدر استعادة النسخة الاحتياطية',
            actor: actor,
            details: {
              'operation': 'verifyRestoreSource',
              'source': storedSource == null
                  ? 'externalBackup'
                  : 'storedBackup',
              'verificationStatus': verification.status.name,
              'checksumMatches': verification.checksumMatches,
            },
            entityType: 'backup',
            entityId: entityId,
          ),
        );
      }
      return verification;
    } on Object catch (error) {
      await writeAuditBestEffort(
        _auditWriter,
        AuditEvent(
          action: AuditAction.restore,
          outcome: auditFailureOutcome(error),
          summary: 'تعذر التحقق من مصدر استعادة النسخة الاحتياطية',
          actor: actor,
          details: {
            'operation': 'verifyRestoreSource',
            'source': storedSource == null
                ? 'externalBackup'
                : 'storedBackup',
            ...safeAuditFailureDetails(error),
          },
          entityType: 'backup',
          entityId: entityId,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<RestoreResult> restore(RestoreRequest request) =>
      _runBackupOperation(_operationGate, () => _restore(request));

  Future<RestoreResult> _restore(RestoreRequest request) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    final source = request.source;
    final storedSource = source is StoredBackupSource ? source : null;
    try {
      final result = await _delegate.restore(request);
      await writeAuditBestEffort(
        _auditWriter,
        AuditEvent(
          action: AuditAction.restore,
          outcome: AuditOutcome.success,
          summary: 'اكتملت استعادة النسخة الاحتياطية التجريبية',
          actor: actor,
          details: {
            'source': storedSource == null
                ? 'externalBackup'
                : 'storedBackup',
            'restartRequired': result.restartRequired,
          },
          before: const {'restoreCompleted': false},
          after: {
            'restoreCompleted': true,
            'restartRequired': result.restartRequired,
          },
          entityType: 'backup',
          entityId: storedSource?.backupId ?? _externalBackupId,
        ),
      );
      return result;
    } on Object catch (error) {
      await writeAuditBestEffort(
        _auditWriter,
        AuditEvent(
          action: AuditAction.restore,
          outcome: auditFailureOutcome(error),
          summary: 'فشلت استعادة النسخة الاحتياطية التجريبية',
          actor: actor,
          details: {
            'source': storedSource == null
                ? 'externalBackup'
                : 'storedBackup',
            ...safeAuditFailureDetails(error),
          },
          entityType: 'backup',
          entityId: storedSource?.backupId ?? _externalBackupId,
        ),
      );
      rethrow;
    }
  }
}

class AuditedGoogleDriveBackupService implements GoogleDriveBackupService {
  AuditedGoogleDriveBackupService({
    required GoogleDriveBackupService delegate,
    required AuditEventWriter auditWriter,
    AuditActorProvider? actorProvider,
    AppOperationGate? operationGate,
  })  : _delegate = delegate,
        _auditWriter = auditWriter,
        _actorProvider = actorProvider,
        _operationGate = operationGate;

  final GoogleDriveBackupService _delegate;
  final AuditEventWriter _auditWriter;
  final AuditActorProvider? _actorProvider;
  final AppOperationGate? _operationGate;
  static final EntityId _connectionId = EntityId('google-drive-backup');

  @override
  Future<CloudConnection> connection() =>
      _runBackupOperation(_operationGate, _delegate.connection);

  @override
  Future<CloudConnection> connect() =>
      _runBackupOperation(_operationGate, _connect);

  Future<CloudConnection> _connect() async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    final before = await _connectionSnapshotBestEffort();
    try {
      final connected = await _delegate.connect();
      await _writeConnection(
        outcome: AuditOutcome.success,
        summary: 'تم ربط خدمة النسخ السحابي التجريبية',
        operation: 'connect',
        before: before,
        after: _connectionSnapshot(connected),
        actor: actor,
      );
      return connected;
    } on Object catch (error) {
      await _writeConnection(
        outcome: auditFailureOutcome(error),
        summary: 'تعذر ربط خدمة النسخ السحابي التجريبية',
        operation: 'connect',
        before: before,
        details: safeAuditFailureDetails(error),
        actor: actor,
      );
      rethrow;
    }
  }

  @override
  Future<void> disconnect() =>
      _runBackupOperation(_operationGate, _disconnect);

  Future<void> _disconnect() async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    final before = await _connectionSnapshotBestEffort();
    try {
      await _delegate.disconnect();
      await _writeConnection(
        outcome: AuditOutcome.success,
        summary: 'تم فصل خدمة النسخ السحابي التجريبية',
        operation: 'disconnect',
        before: before,
        after: const {'status': 'disconnected'},
        actor: actor,
      );
    } on Object catch (error) {
      await _writeConnection(
        outcome: auditFailureOutcome(error),
        summary: 'تعذر فصل خدمة النسخ السحابي التجريبية',
        operation: 'disconnect',
        before: before,
        details: safeAuditFailureDetails(error),
        actor: actor,
      );
      rethrow;
    }
  }

  @override
  Future<List<CloudFolder>> listFolders({String? parentId}) =>
      _runBackupOperation(
        _operationGate,
        () => _delegate.listFolders(parentId: parentId),
      );

  @override
  Future<CloudConnection> selectFolder(CloudFolder folder) =>
      _runBackupOperation(_operationGate, () => _selectFolder(folder));

  Future<CloudConnection> _selectFolder(CloudFolder folder) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    final before = await _connectionSnapshotBestEffort();
    try {
      final selected = await _delegate.selectFolder(folder);
      await _writeConnection(
        outcome: AuditOutcome.success,
        summary: 'تم تحديث مجلد النسخ السحابي',
        operation: 'selectFolder',
        before: before,
        after: _connectionSnapshot(selected),
        actor: actor,
      );
      return selected;
    } on Object catch (error) {
      await _writeConnection(
        outcome: auditFailureOutcome(error),
        summary: 'تعذر تحديث مجلد النسخ السحابي',
        operation: 'selectFolder',
        before: before,
        after: {'selectedFolderId': folder.id},
        details: safeAuditFailureDetails(error),
        actor: actor,
      );
      rethrow;
    }
  }

  @override
  Future<String> uploadEncryptedBackup(BackupRecord backup) =>
      _runBackupOperation(
        _operationGate,
        () => _delegate.uploadEncryptedBackup(backup),
      );

  Future<Map<String, Object?>> _connectionSnapshotBestEffort() async {
    try {
      return _connectionSnapshot(await _delegate.connection());
    } on Object {
      return const {};
    }
  }

  Future<void> _writeConnection({
    required AuditOutcome outcome,
    required String summary,
    required String operation,
    required Map<String, Object?> before,
    required AuditActor? actor,
    Map<String, Object?> after = const {},
    Map<String, Object?> details = const {},
  }) {
    return writeAuditBestEffort(
      _auditWriter,
      AuditEvent(
        action: AuditAction.update,
        outcome: outcome,
        summary: summary,
        actor: actor,
        details: {'operation': operation, ...details},
        before: before,
        after: after,
        entityType: 'backupCloudConnection',
        entityId: _connectionId,
      ),
    );
  }
}

Map<String, Object?> _configurationSnapshot(
  BackupConfiguration configuration,
) {
  return {
    'deviceId': configuration.deviceId,
    'localPathConfigured': configuration.localPath.isNotEmpty,
    'scheduleEnabled': configuration.schedule.isEnabled,
    'frequency': configuration.schedule.frequency.name,
    'googleDriveFolderId': configuration.googleDriveFolderId,
  };
}

Map<String, Object?> _connectionSnapshot(CloudConnection connection) {
  return {
    'status': connection.status.name,
    'selectedFolderId': connection.selectedFolder?.id,
  };
}

Map<String, Object?> _backupSnapshot(BackupRecord record) {
  return {
    'status': record.status.name,
    'destination': record.destination.name,
    'byteSize': record.byteSize,
    'encrypted': record.isEncrypted,
    'checksumAvailable': record.checksum != null,
    'localBackupAvailable': true,
    'cloudCopyAvailable': record.remoteFileId != null,
  };
}

Future<T> _runBackupOperation<T>(
  AppOperationGate? gate,
  FutureOr<T> Function() operation,
) {
  return gate == null ? Future<T>.sync(operation) : gate.run(operation);
}
