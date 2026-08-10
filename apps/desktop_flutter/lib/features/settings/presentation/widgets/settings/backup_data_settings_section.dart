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

  @override
  Widget build(BuildContext context) {
    return AppLoadingOverlay(
      key: const Key('settingsBackupLoadingOverlay'),
      isLoading: _isLoading,
      message: 'جاري تحميل إعدادات النسخ',
      child: ListView(
        key: const Key('backupDataSettingsContent'),
        primary: false,
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_loadError != null) ...[
            AppStatePanel(
              key: const Key('settingsBackupLoadError'),
              type: AppStateType.error,
              title: 'تعذر تحميل إعدادات النسخ',
              message: _loadError!,
              actionLabel: 'إعادة المحاولة',
              onAction: _loadBackupState,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        AppInfoBanner(
          key: const Key('settingsBackupPolicyBanner'),
          message:
              'هذه محاكاة لسياسة النسخ: تبقى النسخة المحلية عند فشل Google Drive. '
              'لا تُنشأ ملفات أو جدولة أو استعادة بيانات حقيقية حالياً.',
          icon: Icons.shield_outlined,
          foregroundColor: widget.accentColor,
          backgroundColor: Color.alphaBlend(
            widget.accentColor.withAlpha(18),
            AppColors.surface,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsResponsiveGrid(
          preferredColumns: 2,
          minimumChildHeight: 360,
          children: [
            SettingsTemplatePanel(
              key: const Key('settingsLocalBackupPanel'),
              title: 'النسخ المحلي والتلقائي',
              icon: Icons.save_alt_rounded,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  AppTextField(
                    fieldKey: const Key('settingsLocalBackupPathField'),
                    controller: _localPathController,
                    label: 'مسار النسخ المحلي',
                    icon: Icons.folder_outlined,
                    suffixIcon: AppFieldIconButton(
                      buttonKey:
                          const Key('settingsBrowseLocalBackupPath'),
                      icon: Icons.folder_open_rounded,
                      tooltip: 'اختيار مجلد',
                      color: widget.accentColor,
                      onPressed: _isBusy ? null : _chooseBackupDirectory,
                    ),
                    accentColor: widget.accentColor,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSwitchField(
                    key: const Key('settingsAutomaticBackupSwitch'),
                    title: 'النسخ التلقائي',
                    subtitle: 'إنشاء النسخة حسب التكرار المحدد',
                    icon: Icons.autorenew_rounded,
                    accentColor: widget.accentColor,
                    value: _automaticBackup,
                    onChanged: (value) {
                      setState(() {
                        _automaticBackup = value;
                        if (!value) {
                          _backupFrequency = 'يدوياً';
                        } else if (_backupFrequency == 'يدوياً') {
                          _backupFrequency = 'يومياً';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdownField<String>(
                    fieldKey:
                        const Key('settingsBackupFrequencyField'),
                    label: 'تكرار النسخ',
                    icon: Icons.schedule_rounded,
                    accentColor: widget.accentColor,
                    value: _backupFrequency,
                    enabled: _automaticBackup,
                    options: _automaticBackup
                        ? const [
                            AppDropdownOption(
                              value: 'يومياً',
                              label: 'يومياً',
                            ),
                            AppDropdownOption(
                              value: 'أسبوعياً',
                              label: 'أسبوعياً',
                            ),
                            AppDropdownOption(
                              value: 'شهرياً',
                              label: 'شهرياً',
                            ),
                          ]
                        : const [
                            AppDropdownOption(
                              value: 'يدوياً',
                              label: 'يدوياً',
                            ),
                          ],
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    onChanged: (value) {
                      if (value == null || value == _backupFrequency) return;
                      setState(() => _backupFrequency = value);
                    },
                  ),
                ],
              ),
            ),
            SettingsTemplatePanel(
              key: const Key('settingsDriveBackupPanel'),
              title: 'Google Drive',
              icon: Icons.cloud_outlined,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _driveConnected
                          ? AppColors.successSurface
                          : AppColors.neutralSurface,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: Color.lerp(
                          widget.accentColor,
                          AppColors.surface,
                          0.62,
                        )!,
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          switch (_driveConnection.status) {
                            CloudConnectionStatus.connected =>
                              Icons.cloud_done_rounded,
                            CloudConnectionStatus.connecting =>
                              Icons.cloud_sync_rounded,
                            CloudConnectionStatus.error =>
                              Icons.cloud_off_rounded,
                            CloudConnectionStatus.disconnected =>
                              Icons.cloud_off_rounded,
                          },
                          color: switch (_driveConnection.status) {
                            CloudConnectionStatus.connected => AppColors.green,
                            CloudConnectionStatus.error => AppColors.danger,
                            _ => AppColors.grey,
                          },
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            switch (_driveConnection.status) {
                              CloudConnectionStatus.connected =>
                                'الحساب مرتبط وجاهز للنسخ',
                              CloudConnectionStatus.connecting =>
                                'جارٍ ربط حساب Google Drive...',
                              CloudConnectionStatus.error =>
                                _driveConnection.message ??
                                    'تعذر ربط Google Drive',
                              CloudConnectionStatus.disconnected =>
                                'لم يتم ربط حساب Google Drive',
                            },
                            style: AppTypography.fieldText,
                          ),
                        ),
                        AppRegularButton(
                          key: const Key(
                            'settingsToggleDriveConnectionButton',
                          ),
                          label: _driveConnected ? 'فصل' : 'ربط',
                          icon: _driveConnected
                              ? Icons.link_off_rounded
                              : Icons.link_rounded,
                          onPressed: _isBusy ? null : _toggleDriveConnection,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdownField<String>(
                    fieldKey:
                        const Key('settingsDriveFolderField'),
                    label: 'مجلد Google Drive',
                    icon: Icons.drive_folder_upload_outlined,
                    accentColor: widget.accentColor,
                    value: _driveConnection.selectedFolder?.id,
                    options: [
                      for (final folder in _driveFolders)
                        AppDropdownOption(
                          value: folder.id,
                          label: folder.name,
                        ),
                    ],
                    enabled: _driveConnected && !_isBusy,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    onChanged: _selectDriveFolder,
                  ),
                  if (_driveConnected &&
                      _googleDriveService is DemoGoogleDriveBackupService) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppRegularButton(
                        key: const Key(
                          'settingsFailNextDriveUploadButton',
                        ),
                        label: 'محاكاة فشل الرفع التالي',
                        icon: Icons.cloud_off_outlined,
                        onPressed: _isBusy ? null : _failNextDriveUpload,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppInfoBanner(
                    message: switch (_driveConnection.status) {
                      CloudConnectionStatus.connected =>
                        '${_driveConnection.accountLabel ?? 'حساب تجريبي'} — '
                            'سيتم رفع نسخة إضافية محاكاةً، مع بقاء النسخة المحلية عند الفشل.',
                      CloudConnectionStatus.connecting =>
                        'جارٍ تجهيز الاتصال التجريبي...',
                      CloudConnectionStatus.error =>
                        _driveConnection.message ??
                            'تعذر اتصال Google Drive التجريبي.',
                      CloudConnectionStatus.disconnected =>
                        'اربط الحساب لتفعيل مجلد Google Drive والرفع السحابي.',
                    },
                    icon: Icons.info_outline_rounded,
                    foregroundColor:
                        _driveConnection.status == CloudConnectionStatus.error
                            ? AppColors.danger
                            : _driveConnected
                                ? widget.accentColor
                                : AppColors.grey,
                    backgroundColor: _driveConnected
                        ? Color.alphaBlend(
                            widget.accentColor.withAlpha(18),
                            AppColors.surface,
                          )
                        : AppColors.neutralSurface,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsTemplatePanel(
          key: const Key('settingsBackupActionsPanel'),
          title: 'الإجراءات',
          icon: Icons.settings_backup_restore_rounded,
          accentColor: widget.accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                textDirection: TextDirection.rtl,
                alignment: WrapAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  AppButton(
                    key: const Key(
                      'settingsSaveBackupConfigurationButton',
                    ),
                    label: 'حفظ إعدادات النسخ',
                    icon: Icons.save_outlined,
                    minWidth: 200,
                    onPressed: _isBusy ? null : () => _saveConfiguration(),
                  ),
                  AppButton(
                    key: const Key('settingsRunBackupButton'),
                    label: 'إنشاء نسخة الآن',
                    icon: Icons.backup_rounded,
                    minWidth: 190,
                    onPressed: _isBusy ? null : _createBackup,
                  ),
                  AppButton(
                    key: const Key('settingsRestoreBackupButton'),
                    label: 'استعادة نسخة',
                    icon: Icons.restore_rounded,
                    variant: AppButtonVariant.warning,
                    minWidth: 190,
                    onPressed: _isBusy ? null : _restoreBackup,
                  ),
                ],
              ),
              if (_operationMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppInfoBanner(
                  key: const Key('settingsBackupOperationState'),
                  message: _operationMessage!,
                  icon: _lastVerification?.canRestore == false
                      ? Icons.error_outline_rounded
                      : Icons.verified_outlined,
                  foregroundColor: _lastVerification?.canRestore == false
                      ? AppColors.danger
                      : widget.accentColor,
                  backgroundColor: Color.alphaBlend(
                    widget.accentColor.withAlpha(18),
                    AppColors.surface,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsTemplatePanel(
          key: const Key('settingsBackupHistoryPanel'),
          title: 'سجل النسخ وآخر حالة',
          icon: Icons.history_rounded,
          accentColor: widget.accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'آخر نسخة ناجحة:',
                    style: AppTypography.fieldText,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _latestSuccessfulBackup?.createdAt ?? 'لا توجد',
                    style: AppTypography.fieldText.copyWith(
                      color: AppColors.green,
                    ),
                  ),
                  const Spacer(),
                  AppStatusBadge(
                    label: _latestSuccessfulBackup == null
                        ? 'غير متوفر'
                        : 'مكتملة',
                    tone: _latestSuccessfulBackup == null
                        ? AppStatusTone.neutral
                        : AppStatusTone.success,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppDataTable(
                key: const Key('settingsBackupHistoryTable'),
                height: 300,
                rowHeight: 56,
                minimumColumnWidth: 150,
                accentColor: widget.accentColor,
                showShadow: false,
                emptyState: const AppStatePanel(
                  type: AppStateType.empty,
                  title: 'لا توجد نسخ احتياطية',
                  message: 'أنشئ نسخة جديدة لتظهر في السجل.',
                ),
                columns: const [
                  AppTableColumn(
                    label: 'التاريخ والوقت',
                    numeric: true,
                    flex: 1.5,
                  ),
                  AppTableColumn(label: 'الوجهة', flex: 1.3),
                  AppTableColumn(label: 'الحجم', numeric: true, flex: 0.8),
                  AppTableColumn(label: 'الحالة', flex: 0.9),
                  AppTableColumn(label: 'الإجراء', flex: 0.65),
                ],
                rows: [
                  for (final entry in _history)
                    AppTableRow(
                      rowKey: Key(
                        'settingsBackupHistoryRow_${entry.keySuffix}',
                      ),
                      cells: [
                        Text(entry.createdAt),
                        Text(entry.destination),
                        Text(entry.size, textDirection: TextDirection.ltr),
                        Center(
                          child: AppStatusBadge(
                            label: entry.status,
                            tone: entry.isSuccessful
                                ? AppStatusTone.success
                                : AppStatusTone.danger,
                          ),
                        ),
                        Center(
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            children: [
                              AppTableActionButton(
                                key: Key(
                                  'settingsVerifyHistory_${entry.keySuffix}',
                                ),
                                icon: Icons.verified_outlined,
                                tooltip: 'التحقق من النسخة',
                                variant: AppButtonVariant.success,
                                onPressed: entry.isRestorable
                                    ? () => _verifyBackup(entry)
                                    : null,
                              ),
                              AppTableActionButton(
                                key: Key(
                                  'settingsRestoreHistory_${entry.keySuffix}',
                                ),
                                icon: Icons.restore_rounded,
                                tooltip: 'استعادة هذه النسخة',
                                variant: AppButtonVariant.warning,
                                onPressed: entry.isRestorable
                                    ? () => _restoreBackup(entry)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  _BackupHistoryEntry? get _latestSuccessfulBackup {
    for (final entry in _history) {
      if (entry.isSuccessful) return entry;
    }
    return null;
  }

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
