part of '../settings_sections.dart';

class BackupDataSettingsSection extends StatefulWidget {
  const BackupDataSettingsSection({
    required this.accentColor,
    super.key,
    this.configurationRepository,
    this.backupService,
    this.googleDriveService,
    this.fileSelectionService,
    this.auditWriter,
    this.deviceId = 'desktop-demo-01',
  });

  final Color accentColor;
  final BackupConfigurationRepository? configurationRepository;
  final BackupService? backupService;
  final GoogleDriveBackupService? googleDriveService;
  final BackupFileSelectionService? fileSelectionService;
  final AuditEventWriter? auditWriter;
  final String deviceId;

  @override
  State<BackupDataSettingsSection> createState() =>
      _BackupDataSettingsSectionState();
}
class _BackupDataSettingsSectionState
    extends State<BackupDataSettingsSection> {
  final _localPathController = TextEditingController(
    text: r'D:\Almumayaz\Backups',
  );
  var _automaticBackup = true;
  var _backupFrequency = 'يومياً';
  var _isBusy = false;
  var _isLoading = true;
  String? _loadError;
  String? _operationMessage;
  BackupVerification? _lastVerification;
  late final BackupConfigurationRepository _configurationRepository;
  late final BackupService _backupService;
  late final GoogleDriveBackupService _googleDriveService;
  late final BackupFileSelectionService _fileSelectionService;
  CloudConnection _driveConnection = const CloudConnection(
    status: CloudConnectionStatus.disconnected,
  );
  List<CloudFolder> _driveFolders = const [];

  bool get _driveConnected =>
      _driveConnection.status == CloudConnectionStatus.connected;
  final _history = <_BackupHistoryEntry>[];

  @override
  void initState() {
    super.initState();
    _configurationRepository = widget.configurationRepository ??
        DemoBackupConfigurationRepository();
    _googleDriveService =
        widget.googleDriveService ?? DemoGoogleDriveBackupService();
    _fileSelectionService = widget.fileSelectionService ??
        DemoBackupFileSelectionService();
    _backupService = widget.backupService ??
        DemoBackupService(googleDriveService: _googleDriveService);
    _loadBackupState();
  }

  @override
  void dispose() {
    _localPathController.dispose();
    super.dispose();
  }

  Future<void> _writeAudit(AuditEvent event) async {
    final writer = widget.auditWriter;
    if (writer == null) return;
    try {
      await writer.write(event);
    } on Object {
      // Auditing is best-effort in the Flutter demo and must never replace the
      // workflow's original success or failure result.
      debugPrint('Backup workflow audit write failed.');
    }
  }

  Future<void> _loadBackupState() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final configuration =
          await _configurationRepository.load(widget.deviceId);
      final history = await _backupService.listHistory();
      var connection = await _googleDriveService.connection();
      final folders = connection.status == CloudConnectionStatus.connected
          ? await _googleDriveService.listFolders()
          : const <CloudFolder>[];
      if (connection.status == CloudConnectionStatus.connected &&
          configuration.googleDriveFolderId != null) {
        final configuredFolder = folders
            .where(
              (folder) => folder.id == configuration.googleDriveFolderId,
            )
            .firstOrNull;
        if (configuredFolder != null &&
            connection.selectedFolder?.id != configuredFolder.id) {
          connection =
              await _googleDriveService.selectFolder(configuredFolder);
        }
      }
      if (!mounted) return;
      setState(() {
        _localPathController.text = configuration.localPath;
        _automaticBackup = configuration.schedule.isEnabled;
        _backupFrequency = _backupFrequencyLabel(
          configuration.schedule.frequency,
        );
        _driveConnection = connection;
        _driveFolders = List<CloudFolder>.unmodifiable(folders);
        _replaceHistory(history);
        _isLoading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        final message = _serviceMessage(error);
        setState(() {
          _isLoading = false;
          _loadError = message;
        });
        AppToast.showError(context, message);
      }
    }
  }

  Future<void> _toggleDriveConnection() async {
    if (_isBusy) return;
    final operation = _driveConnected ? 'disconnect' : 'connect';
    setState(() => _isBusy = true);
    try {
      if (_driveConnected) {
        await _googleDriveService.disconnect();
        await _writeAudit(
          AuditEvent(
            action: AuditAction.update,
            outcome: AuditOutcome.success,
            summary: 'فصل اتصال Google Drive التجريبي',
            details: const {
              'workflow': 'googleDriveBackup',
              'operation': 'disconnect',
            },
          ),
        );
        if (!mounted) return;
        setState(() {
          _driveConnection = const CloudConnection(
            status: CloudConnectionStatus.disconnected,
          );
          _driveFolders = const [];
        });
        AppToast.showWarning(context, 'تم فصل اتصال Google Drive التجريبي');
      } else {
        setState(() {
          _driveConnection = const CloudConnection(
            status: CloudConnectionStatus.connecting,
            message: 'جارٍ ربط حساب Google Drive التجريبي',
          );
        });
        var connection = await _googleDriveService.connect();
        final folders = await _googleDriveService.listFolders();
        final configuration =
            await _configurationRepository.load(widget.deviceId);
        final configuredFolder = folders
            .where(
              (folder) => folder.id == configuration.googleDriveFolderId,
            )
            .firstOrNull;
        if (configuredFolder != null &&
            configuredFolder.id != connection.selectedFolder?.id) {
          connection =
              await _googleDriveService.selectFolder(configuredFolder);
        }
        await _writeAudit(
          AuditEvent(
            action: AuditAction.update,
            outcome: AuditOutcome.success,
            summary: 'ربط Google Drive في الوضع التجريبي',
            details: {
              'workflow': 'googleDriveBackup',
              'operation': 'connect',
              'folderId': connection.selectedFolder?.id,
            },
          ),
        );
        if (!mounted) return;
        setState(() {
          _driveConnection = connection;
          _driveFolders = List<CloudFolder>.unmodifiable(folders);
        });
        AppToast.showSuccess(
          context,
          'تم ربط Google Drive في الوضع التجريبي فقط',
        );
      }
    } on Object catch (error) {
      await _writeAudit(
        AuditEvent(
          action: AuditAction.update,
          outcome: AuditOutcome.failure,
          summary: operation == 'connect'
              ? 'فشل ربط Google Drive التجريبي'
              : 'فشل فصل Google Drive التجريبي',
          details: {
            'workflow': 'googleDriveBackup',
            'operation': operation,
            ..._auditFailureDetails(error),
          },
        ),
      );
      if (mounted) {
        final message = _serviceMessage(error);
        setState(() {
          _driveConnection = CloudConnection(
            status: CloudConnectionStatus.error,
            message: message,
          );
          _driveFolders = const [];
        });
        AppToast.showError(context, message);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<BackupConfiguration?> _saveConfiguration({
    bool showConfirmation = true,
  }) async {
    final localPath = _localPathController.text.trim();
    if (localPath.isEmpty) {
      AppToast.showWarning(context, 'اكتب مسار النسخ المحلي');
      return null;
    }
    try {
      CloudFolder? selectedFolder = _driveConnection.selectedFolder;
      if (_driveConnected) {
        final folders = await _googleDriveService.listFolders();
        final selectedId = selectedFolder?.id;
        selectedFolder = folders
            .where((folder) => folder.id == selectedId)
            .firstOrNull;
        if (selectedFolder == null) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.validation,
            message: 'اختر مجلد Google Drive قبل حفظ الإعدادات',
          );
        }
        _driveConnection =
            await _googleDriveService.selectFolder(selectedFolder);
      }
      final configuration = BackupConfiguration(
        deviceId: widget.deviceId,
        localPath: localPath,
        schedule: BackupSchedule(
          isEnabled: _automaticBackup,
          frequency: _automaticBackup
              ? _backupFrequencyValue(_backupFrequency)
              : BackupFrequency.manual,
        ),
        googleDriveFolderId: selectedFolder?.id,
      );
      await _configurationRepository.save(configuration);
      if (showConfirmation && mounted) {
        AppToast.showSuccess(context, 'تم حفظ إعدادات النسخ التجريبية');
      }
      return configuration;
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
      return null;
    }
  }

  Future<void> _createBackup() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _operationMessage = 'جارٍ محاكاة إنشاء نسخة محلية مشفرة...';
    });
    BackupRecord? createdRecord;
    try {
      final configuration = await _saveConfiguration(
        showConfirmation: false,
      );
      if (configuration == null) {
        await _writeAudit(
          AuditEvent(
            action: AuditAction.backup,
            outcome: AuditOutcome.failure,
            summary: 'تعذر بدء النسخ بسبب إعدادات غير صالحة',
            details: const {'failureKind': 'configurationRejected'},
          ),
        );
        return;
      }
      final record = await _backupService.createBackup(
        configuration: configuration,
        uploadToGoogleDrive: _driveConnected,
      );
      createdRecord = record;
      final verification = await _backupService.verifyRestoreSource(
        StoredBackupSource(record.id),
      );
      final history = await _backupService.listHistory();
      final cloudFailed = record.status == BackupStatus.uploadFailed;
      await _writeAudit(
        AuditEvent(
          action: AuditAction.backup,
          outcome:
              cloudFailed ? AuditOutcome.failure : AuditOutcome.success,
          summary: cloudFailed
              ? 'اكتملت النسخة المحلية وتعذر رفع نسخة Google Drive'
              : 'اكتمل إنشاء النسخة الاحتياطية التجريبية',
          entityType: 'backup',
          entityId: record.id,
          details: {
            'destination': record.destination.name,
            'status': record.status.name,
            'byteSize': record.byteSize,
            'localBackupAvailable': true,
          },
        ),
      );
      if (!mounted) return;
      setState(() {
        _replaceHistory(history);
        _lastVerification = verification;
        _operationMessage = record.status == BackupStatus.uploadFailed
            ? '${record.failureMessage} — النسخة المحلية قابلة للاستعادة.'
            : 'اكتملت النسخة والتحقق من التوقيع وقيمة checksum.';
      });
      if (record.status == BackupStatus.uploadFailed) {
        AppToast.showWarning(
          context,
          record.failureMessage ?? 'تعذر الرفع وبقيت النسخة المحلية',
        );
      } else {
        AppToast.showSuccess(context, 'تم إنشاء نسخة تجريبية والتحقق منها');
      }
    } on Object catch (error) {
      await _writeAudit(
        AuditEvent(
          action: AuditAction.backup,
          outcome: AuditOutcome.failure,
          summary: 'فشل إنشاء النسخة الاحتياطية التجريبية',
          entityType: createdRecord == null ? null : 'backup',
          entityId: createdRecord?.id,
          details: _auditFailureDetails(error),
        ),
      );
      if (mounted) {
        setState(() => _operationMessage = _serviceMessage(error));
        AppToast.showError(context, _serviceMessage(error));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _failNextDriveUpload() {
    final service = _googleDriveService;
    if (service is! DemoGoogleDriveBackupService) return;
    service.failNextUpload();
    AppToast.showInfo(
      context,
      'سيُحاكى فشل الرفع التالي مع الاحتفاظ بالنسخة المحلية',
    );
  }

  Future<void> _chooseBackupDirectory() async {
    if (_isBusy) return;
    try {
      final selected = await _fileSelectionService.selectBackupDirectory(
        initialDirectory: _localPathController.text.trim(),
      );
      if (!mounted || selected == null) return;
      final normalized = selected.trim();
      if (normalized.isEmpty) {
        AppToast.showError(context, 'مسار النسخ المحلي غير صالح');
        return;
      }
      setState(() => _localPathController.text = normalized);
      AppToast.showInfo(context, 'تم اختيار مجلد النسخ المحلي');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _selectDriveFolder(String? folderId) async {
    if (folderId == null || _isBusy || !_driveConnected) return;
    final folder = _driveFolders
        .where((candidate) => candidate.id == folderId)
        .firstOrNull;
    if (folder == null) {
      AppToast.showError(context, 'مجلد Google Drive غير موجود');
      return;
    }
    setState(() => _isBusy = true);
    try {
      final connection = await _googleDriveService.selectFolder(folder);
      if (!mounted) return;
      setState(() => _driveConnection = connection);
      AppToast.showSuccess(context, 'تم اختيار مجلد Google Drive');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restoreBackup([_BackupHistoryEntry? entry]) async {
    final BackupRestoreSource restoreSource;
    if (entry?.backupId == null) {
      ExternalBackupSource? selectedSource;
      try {
        selectedSource = await _fileSelectionService.selectRestoreSource(
          initialDirectory: _localPathController.text.trim(),
        );
      } on Object catch (error) {
        await _writeAudit(
          AuditEvent(
            action: AuditAction.restore,
            outcome: AuditOutcome.failure,
            summary: 'تعذر اختيار ملف النسخة المراد استعادتها',
            details: _auditFailureDetails(error),
          ),
        );
        if (mounted) AppToast.showError(context, _serviceMessage(error));
        return;
      }
      if (selectedSource == null || !mounted) return;
      restoreSource = selectedSource;
    } else {
      restoreSource = StoredBackupSource(entry!.backupId!);
    }
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'استعادة نسخة احتياطية',
      message: entry == null
          ? 'تم التحقق من اختيار ملف النسخة. هل تريد بدء الاستعادة؟'
          : 'هل تريد استعادة نسخة ${entry.createdAt}؟',
      confirmLabel: 'استعادة',
      cancelLabel: 'إلغاء',
      isDanger: true,
      size: AppDialogSize.medium,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _isBusy = true;
      _operationMessage = 'جارٍ التحقق من النسخة قبل الاستعادة...';
    });
    try {
      final verification =
          await _backupService.verifyRestoreSource(restoreSource);
      if (!verification.canRestore) {
        throw ServiceFailure(
          kind: ServiceFailureKind.securityRejected,
          message: verification.message ?? 'النسخة غير قابلة للاستعادة',
        );
      }
      final result = await _backupService.restore(
        RestoreRequest(source: restoreSource, confirmedByUser: true),
      );
      await _writeAudit(
        AuditEvent(
          action: AuditAction.restore,
          outcome: AuditOutcome.success,
          summary: 'اكتملت استعادة النسخة الاحتياطية التجريبية',
          entityType:
              restoreSource is StoredBackupSource ? 'backup' : null,
          entityId: restoreSource is StoredBackupSource
              ? restoreSource.backupId
              : null,
          details: {
            'source': restoreSource is StoredBackupSource
                ? 'storedBackup'
                : 'externalBackup',
            'restartRequired': result.restartRequired,
          },
        ),
      );
      if (!mounted) return;
      setState(() {
        _lastVerification = verification;
        _operationMessage = result.restartRequired
            ? 'اكتملت الاستعادة التجريبية ويلزم إعادة تشغيل التطبيق.'
            : 'اكتملت الاستعادة التجريبية.';
      });
      AppToast.showWarning(context, _operationMessage!);
    } on Object catch (error) {
      await _writeAudit(
        AuditEvent(
          action: AuditAction.restore,
          outcome: AuditOutcome.failure,
          summary: 'فشلت استعادة النسخة الاحتياطية التجريبية',
          entityType:
              restoreSource is StoredBackupSource ? 'backup' : null,
          entityId: restoreSource is StoredBackupSource
              ? restoreSource.backupId
              : null,
          details: {
            'source': restoreSource is StoredBackupSource
                ? 'storedBackup'
                : 'externalBackup',
            ..._auditFailureDetails(error),
          },
        ),
      );
      if (mounted) {
        setState(() => _operationMessage = _serviceMessage(error));
        AppToast.showError(context, _serviceMessage(error));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _verifyBackup(_BackupHistoryEntry entry) async {
    final backupId = entry.backupId;
    if (backupId == null) return;
    try {
      final verification = await _backupService.verifyRestoreSource(
        StoredBackupSource(backupId),
      );
      if (!mounted) return;
      setState(() {
        _lastVerification = verification;
        _operationMessage = verification.message;
      });
      if (verification.canRestore) {
        AppToast.showSuccess(context, 'النسخة سليمة وقابلة للاستعادة');
      } else {
        AppToast.showError(context, 'فشل التحقق من النسخة');
      }
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  void _setBackupViewState(VoidCallback update) => setState(update);

  @override
  Widget build(BuildContext context) => this._buildBackupContent(context);

  void _replaceHistory(List<BackupRecord> records) {
    _history
      ..clear()
      ..addAll(records.map(_backupHistoryEntry));
  }
}

class _BackupHistoryEntry {
  const _BackupHistoryEntry({
    required this.keySuffix,
    required this.createdAt,
    required this.destination,
    required this.size,
    required this.status,
    required this.isSuccessful,
    this.backupId,
    this.isRestorable = false,
  });

  final String keySuffix;
  final String createdAt;
  final String destination;
  final String size;
  final String status;
  final bool isSuccessful;
  final EntityId? backupId;
  final bool isRestorable;
}

_BackupHistoryEntry _backupHistoryEntry(BackupRecord record) {
  final isRestorable = record.isEncrypted &&
      record.checksum != null &&
      (record.status == BackupStatus.completed ||
          record.status == BackupStatus.uploadFailed);
  return _BackupHistoryEntry(
    keySuffix: record.id.value,
    backupId: record.id,
    createdAt: _formatAuditTimestamp(record.createdAt),
    destination: switch (record.destination) {
      BackupDestination.local => 'محلي',
      BackupDestination.googleDrive => 'Google Drive',
      BackupDestination.localAndGoogleDrive => 'محلي + Google Drive',
    },
    size: _formatByteSize(record.byteSize),
    status: switch (record.status) {
      BackupStatus.queued => 'في الانتظار',
      BackupStatus.creating => 'جارٍ الإنشاء',
      BackupStatus.verifying => 'جارٍ التحقق',
      BackupStatus.completed => 'مكتملة',
      BackupStatus.uploadFailed => 'تعذر الرفع (المحلي سليم)',
      BackupStatus.verificationFailed => 'فشل التحقق',
      BackupStatus.restoreFailed => 'فشل الاستعادة',
      BackupStatus.cancelled => 'ملغاة',
    },
    isSuccessful: record.status == BackupStatus.completed,
    isRestorable: isRestorable,
  );
}

Map<String, Object?> _auditFailureDetails(Object error) =>
    error is ServiceFailure
        ? {
            'failureKind': error.kind.name,
            if (error.code != null) 'failureCode': error.code,
          }
        : {'failureKind': 'unknown'};
