import '../../../core/domain/business_values.dart';
import '../../../core/services/service_failure.dart';
import '../domain/backup_models.dart';
import '../domain/backup_services.dart';

/// Volatile configuration storage used by the Settings demo.
///
/// A production implementation can persist the same domain object without
/// changing any of the widgets that consume this repository.
class DemoBackupConfigurationRepository
    implements BackupConfigurationRepository {
  DemoBackupConfigurationRepository({BackupConfiguration? initialValue})
      : _configurations = initialValue == null
            ? <String, BackupConfiguration>{}
            : {initialValue.deviceId: initialValue};

  final Map<String, BackupConfiguration> _configurations;

  @override
  Future<BackupConfiguration> load(String deviceId) async {
    if (deviceId.trim().isEmpty) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.validation,
        message: 'معرّف الجهاز مطلوب',
      );
    }
    final normalizedDeviceId = deviceId.trim();
    return _configurations.putIfAbsent(
      normalizedDeviceId,
      () => BackupConfiguration(
        deviceId: normalizedDeviceId,
        localPath: r'D:\Almumayaz\Backups',
        schedule: const BackupSchedule(
          isEnabled: true,
          frequency: BackupFrequency.daily,
        ),
      ),
    );
  }

  @override
  Future<void> save(BackupConfiguration configuration) async {
    _configurations[configuration.deviceId] = configuration;
  }
}

class DemoBackupFileSelectionService
    implements BackupFileSelectionService {
  DemoBackupFileSelectionService({
    Iterable<String?> directorySelections = const [],
    Iterable<ExternalBackupSource?> restoreSelections = const [],
  })  : _directorySelections = List<String?>.of(directorySelections),
        _restoreSelections =
            List<ExternalBackupSource?>.of(restoreSelections);

  final List<String?> _directorySelections;
  final List<ExternalBackupSource?> _restoreSelections;

  @override
  Future<String?> selectBackupDirectory({String? initialDirectory}) async {
    if (_directorySelections.isNotEmpty) {
      return _directorySelections.removeAt(0);
    }
    return r'D:\Almumayaz\Backups\Local';
  }

  @override
  Future<ExternalBackupSource?> selectRestoreSource({
    String? initialDirectory,
  }) async {
    if (_restoreSelections.isNotEmpty) {
      return _restoreSelections.removeAt(0);
    }
    return ExternalBackupSource(
      localPath: r'D:\Almumayaz\Backups\external_demo.backup',
    );
  }
}

/// Deterministic, in-memory Google Drive adapter.
///
/// It never opens OAuth or performs network I/O. [failNextUpload] is exposed
/// solely so the UI and tests can demonstrate that a failed cloud copy does
/// not discard the successful local backup.
class DemoGoogleDriveBackupService implements GoogleDriveBackupService {
  DemoGoogleDriveBackupService({bool failNextUpload = false})
      : _failNextUpload = failNextUpload;

  static const defaultFolder = CloudFolder(
    id: 'demo-drive-folder-backups',
    name: 'Almumayaz ERP Backups',
    parentId: null,
  );

  static const folders = <CloudFolder>[
    defaultFolder,
    CloudFolder(
      id: 'demo-drive-folder-monthly',
      name: 'Monthly Backups',
      parentId: null,
    ),
  ];

  CloudConnection _connection = const CloudConnection(
    status: CloudConnectionStatus.disconnected,
  );
  bool _failNextUpload;
  int _nextRemoteSequence = 1;

  void failNextUpload() => _failNextUpload = true;

  @override
  Future<CloudConnection> connection() async => _connection;

  @override
  Future<CloudConnection> connect() async {
    _connection = CloudConnection(
      status: CloudConnectionStatus.connected,
      accountLabel: 'demo.backup@almumayaz.local',
      selectedFolder: defaultFolder,
      message: 'اتصال تجريبي محلي؛ لم يتم فتح Google OAuth.',
    );
    return _connection;
  }

  @override
  Future<void> disconnect() async {
    _connection = const CloudConnection(
      status: CloudConnectionStatus.disconnected,
    );
  }

  @override
  Future<List<CloudFolder>> listFolders({String? parentId}) async {
    _requireConnected();
    return List.unmodifiable(
      folders.where((folder) => folder.parentId == parentId),
    );
  }

  @override
  Future<CloudConnection> selectFolder(CloudFolder folder) async {
    _requireConnected();
    final knownFolder = folders.any((candidate) => candidate.id == folder.id);
    if (!knownFolder) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.notFound,
        code: 'drive_folder_not_found',
        message: 'مجلد Google Drive التجريبي غير موجود',
      );
    }
    _connection = CloudConnection(
      status: CloudConnectionStatus.connected,
      accountLabel: _connection.accountLabel,
      selectedFolder: folder,
      message: 'تم اختيار مجلد تجريبي؛ لا توجد مزامنة خارجية.',
    );
    return _connection;
  }

  @override
  Future<String> uploadEncryptedBackup(BackupRecord backup) async {
    _requireConnected();
    if (_connection.selectedFolder == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.validation,
        code: 'drive_folder_required',
        message: 'اختر مجلد Google Drive قبل الرفع',
      );
    }
    if (!backup.isEncrypted || backup.checksum == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.securityRejected,
        code: 'unencrypted_backup',
        message: 'رفضت النسخة لأنها غير مشفرة أو غير موثقة',
      );
    }
    if (_failNextUpload) {
      _failNextUpload = false;
      throw const ServiceFailure(
        kind: ServiceFailureKind.unavailable,
        code: 'demo_drive_upload_failed',
        message: 'تعذر الرفع التجريبي؛ بقيت النسخة المحلية محفوظة',
      );
    }
    return 'demo-drive-file-${_nextRemoteSequence++}';
  }

  void _requireConnected() {
    if (_connection.status != CloudConnectionStatus.connected) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.authenticationRequired,
        code: 'drive_not_connected',
        message: 'اربط حساب Google Drive التجريبي أولاً',
      );
    }
  }
}

/// In-memory backup engine that simulates local creation and verification.
class DemoBackupService implements BackupService {
  DemoBackupService({
    GoogleDriveBackupService? googleDriveService,
    AuditTimestamp Function()? clock,
  })  : _googleDriveService = googleDriveService,
        _clock = clock ?? _DemoBackupClock().call,
        _history = _initialHistory();

  final GoogleDriveBackupService? _googleDriveService;
  final AuditTimestamp Function() _clock;
  final List<BackupRecord> _history;
  int _nextSequence = 4;

  @override
  Future<List<BackupRecord>> listHistory() async =>
      List.unmodifiable(_history);

  @override
  Future<BackupRecord> createBackup({
    required BackupConfiguration configuration,
    required bool uploadToGoogleDrive,
  }) async {
    final sequence = _nextSequence++;
    final createdAt = _clock();
    final localPath = '${configuration.localPath}\\'
        'almumayaz_demo_$sequence.backup';
    final checksum = _checksumFor(localPath);
    var record = BackupRecord(
      id: EntityId.demo('backup', sequence),
      createdAt: createdAt,
      destination: uploadToGoogleDrive
          ? BackupDestination.localAndGoogleDrive
          : BackupDestination.local,
      status: BackupStatus.completed,
      localPath: localPath,
      byteSize: 19503513 + sequence,
      isEncrypted: true,
      checksum: checksum,
    );

    if (uploadToGoogleDrive) {
      try {
        final drive = _googleDriveService;
        if (drive == null) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.unavailable,
            code: 'drive_adapter_missing',
            message: 'خدمة Google Drive التجريبية غير متاحة',
          );
        }
        final remoteFileId = await drive.uploadEncryptedBackup(record);
        record = _copyRecord(
          record,
          remoteFileId: remoteFileId,
        );
      } on Object catch (failure) {
        record = _copyRecord(
          record,
          status: BackupStatus.uploadFailed,
          failureMessage: failure is ServiceFailure
              ? failure.message
              : 'تعذر الرفع؛ بقيت النسخة المحلية محفوظة',
        );
      }
    }

    _history.insert(0, record);
    return record;
  }

  @override
  Future<BackupVerification> verifyRestoreSource(
    BackupRestoreSource source,
  ) async {
    if (source is StoredBackupSource) {
      final backupId = source.backupId;
      final record = _history.where((item) => item.id == backupId).firstOrNull;
      if (record == null) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.notFound,
          code: 'backup_not_found',
          message: 'النسخة الاحتياطية غير موجودة',
        );
      }
      final canRestore = record.isEncrypted &&
          record.checksum != null &&
          (record.status == BackupStatus.completed ||
              record.status == BackupStatus.uploadFailed);
      return BackupVerification(
        status: canRestore
            ? BackupVerificationStatus.valid
            : BackupVerificationStatus.invalid,
        checksumMatches: canRestore,
        canRestore: canRestore,
        message: canRestore
            ? 'التوقيع والتشفير سليميْن؛ النسخة قابلة للاستعادة.'
            : 'فشل التحقق من سلامة النسخة.',
      );
    }

    final external = source as ExternalBackupSource;
    final hasSupportedExtension =
        external.localPath.toLowerCase().endsWith('.backup');
    final computedChecksum = _checksumFor(external.localPath);
    final checksumMatches = external.expectedChecksum == null ||
        external.expectedChecksum == computedChecksum;
    final canRestore = hasSupportedExtension && checksumMatches;
    return BackupVerification(
      status: canRestore
          ? BackupVerificationStatus.valid
          : BackupVerificationStatus.invalid,
      checksumMatches: checksumMatches,
      canRestore: canRestore,
      message: canRestore
          ? 'تم التحقق من النسخة الخارجية التجريبية.'
          : 'امتداد النسخة أو قيمة التحقق غير صالحة.',
    );
  }

  @override
  Future<RestoreResult> restore(RestoreRequest request) async {
    if (!request.confirmedByUser) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.validation,
        code: 'restore_confirmation_required',
        message: 'تتطلب الاستعادة تأكيد المستخدم',
      );
    }
    final verification = await verifyRestoreSource(request.source);
    if (!verification.canRestore) {
      throw ServiceFailure(
        kind: ServiceFailureKind.securityRejected,
        code: 'restore_verification_failed',
        message: verification.message ?? 'تعذر التحقق من النسخة',
      );
    }
    return RestoreResult(
      source: request.source,
      completedAt: _clock(),
      restartRequired: true,
    );
  }

  static List<BackupRecord> _initialHistory() => [
        BackupRecord(
          id: EntityId.demo('backup', 1),
          createdAt: AuditTimestamp(DateTime.utc(2026, 7, 29, 6, 15)),
          destination: BackupDestination.local,
          status: BackupStatus.completed,
          localPath: r'D:\Almumayaz\Backups\almumayaz_demo_1.backup',
          byteSize: 19293798,
          isEncrypted: true,
          checksum: 'demo-sha256-backup-0001',
        ),
        BackupRecord(
          id: EntityId.demo('backup', 2),
          createdAt: AuditTimestamp(DateTime.utc(2026, 7, 28, 15)),
          destination: BackupDestination.localAndGoogleDrive,
          status: BackupStatus.completed,
          localPath: r'D:\Almumayaz\Backups\almumayaz_demo_2.backup',
          byteSize: 18979225,
          isEncrypted: true,
          checksum: 'demo-sha256-backup-0002',
          remoteFileId: 'demo-drive-file-seed-2',
        ),
        BackupRecord(
          id: EntityId.demo('backup', 3),
          createdAt: AuditTimestamp(DateTime.utc(2026, 7, 27, 15)),
          destination: BackupDestination.localAndGoogleDrive,
          status: BackupStatus.uploadFailed,
          localPath: r'D:\Almumayaz\Backups\almumayaz_demo_3.backup',
          byteSize: 18769510,
          isEncrypted: true,
          checksum: 'demo-sha256-backup-0003',
          failureMessage: 'تعذر الرفع؛ النسخة المحلية سليمة ومتاحة',
        ),
      ];
}

class _DemoBackupClock {
  var _minute = 0;

  AuditTimestamp call() => AuditTimestamp(
        DateTime.utc(2026, 7, 29, 7, 30 + _minute++),
      );
}

BackupRecord _copyRecord(
  BackupRecord source, {
  BackupStatus? status,
  String? remoteFileId,
  String? failureMessage,
}) {
  return BackupRecord(
    id: source.id,
    createdAt: source.createdAt,
    destination: source.destination,
    status: status ?? source.status,
    localPath: source.localPath,
    byteSize: source.byteSize,
    isEncrypted: source.isEncrypted,
    checksum: source.checksum,
    remoteFileId: remoteFileId ?? source.remoteFileId,
    failureMessage: failureMessage ?? source.failureMessage,
  );
}

String _checksumFor(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final chunk = hash.toRadixString(16).padLeft(8, '0');
  return 'demo-sha256-$chunk$chunk$chunk$chunk';
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
