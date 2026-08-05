part of '../settings_sections.dart';

class BackupDataSettingsSection extends StatefulWidget {
  const BackupDataSettingsSection({
    required this.accentColor,
    super.key,
    this.configurationRepository,
    this.backupService,
    this.googleDriveService,
  });

  final Color accentColor;
  final BackupConfigurationRepository? configurationRepository;
  final BackupService? backupService;
  final GoogleDriveBackupService? googleDriveService;

  @override
  State<BackupDataSettingsSection> createState() =>
      _BackupDataSettingsSectionState();
}
class _BackupDataSettingsSectionState
    extends State<BackupDataSettingsSection> {
  static const _deviceId = 'desktop-demo-01';
  final _localPathController = TextEditingController(
    text: r'D:\Almumayaz\Backups',
  );
  final _driveFolderController = TextEditingController(
    text: 'Almumayaz ERP Backups',
  );
  var _automaticBackup = true;
  var _backupFrequency = 'يومياً';
  var _driveConnected = false;
  var _isBusy = false;
  var _isLoading = true;
  String? _loadError;
  String? _operationMessage;
  BackupVerification? _lastVerification;
  late final BackupConfigurationRepository _configurationRepository;
  late final BackupService _backupService;
  late final GoogleDriveBackupService _googleDriveService;
  CloudConnection _driveConnection = const CloudConnection(
    status: CloudConnectionStatus.disconnected,
  );
  final _history = <_BackupHistoryEntry>[
    const _BackupHistoryEntry(
      id: 1,
      createdAt: '2026/07/29 09:15 ص',
      destination: 'محلي',
      size: '18.4 MB',
      status: 'مكتملة',
      isSuccessful: true,
    ),
    const _BackupHistoryEntry(
      id: 2,
      createdAt: '2026/07/28 06:00 م',
      destination: 'محلي + Google Drive',
      size: '18.1 MB',
      status: 'مكتملة',
      isSuccessful: true,
    ),
    const _BackupHistoryEntry(
      id: 3,
      createdAt: '2026/07/27 06:00 م',
      destination: 'Google Drive',
      size: '17.9 MB',
      status: 'تعذر الرفع',
      isSuccessful: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _configurationRepository = widget.configurationRepository ??
        DemoBackupConfigurationRepository();
    _googleDriveService =
        widget.googleDriveService ?? DemoGoogleDriveBackupService();
    _backupService = widget.backupService ??
        DemoBackupService(googleDriveService: _googleDriveService);
    _loadBackupState();
  }

  @override
  void dispose() {
    _localPathController.dispose();
    _driveFolderController.dispose();
    super.dispose();
  }

  Future<void> _loadBackupState() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final configuration = await _configurationRepository.load(_deviceId);
      final history = await _backupService.listHistory();
      final connection = await _googleDriveService.connection();
      if (!mounted) return;
      setState(() {
        _localPathController.text = configuration.localPath;
        _automaticBackup = configuration.schedule.isEnabled;
        _backupFrequency = _backupFrequencyLabel(
          configuration.schedule.frequency,
        );
        _driveConnection = connection;
        _driveConnected =
            connection.status == CloudConnectionStatus.connected;
        if (connection.selectedFolder != null) {
          _driveFolderController.text = connection.selectedFolder!.name;
        }
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
    setState(() => _isBusy = true);
    try {
      if (_driveConnected) {
        await _googleDriveService.disconnect();
        if (!mounted) return;
        setState(() {
          _driveConnected = false;
          _driveConnection = const CloudConnection(
            status: CloudConnectionStatus.disconnected,
          );
        });
        AppToast.showWarning(context, 'تم فصل اتصال Google Drive التجريبي');
      } else {
        final connection = await _googleDriveService.connect();
        if (!mounted) return;
        setState(() {
          _driveConnection = connection;
          _driveConnected =
              connection.status == CloudConnectionStatus.connected;
          if (connection.selectedFolder != null) {
            _driveFolderController.text = connection.selectedFolder!.name;
          }
        });
        AppToast.showSuccess(
          context,
          'تم ربط Google Drive في الوضع التجريبي فقط',
        );
      }
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
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
        final folderName = _driveFolderController.text.trim();
        selectedFolder = folders.where(
          (folder) => folder.name.toLowerCase() == folderName.toLowerCase(),
        ).firstOrNull;
        if (selectedFolder == null) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.validation,
            message: 'اختر أحد مجلدات Google Drive التجريبية المتاحة',
          );
        }
        _driveConnection =
            await _googleDriveService.selectFolder(selectedFolder);
      }
      final configuration = BackupConfiguration(
        deviceId: _deviceId,
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
      _operationMessage = 'جارٍ إنشاء نسخة محلية مشفرة...';
    });
    try {
      final configuration = await _saveConfiguration(
        showConfirmation: false,
      );
      if (configuration == null) return;
      final record = await _backupService.createBackup(
        configuration: configuration,
        uploadToGoogleDrive: _driveConnected,
      );
      final verification = await _backupService.verifyRestoreSource(
        StoredBackupSource(record.id),
      );
      final history = await _backupService.listHistory();
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

  Future<void> _restoreBackup([_BackupHistoryEntry? entry]) async {
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'استعادة نسخة احتياطية',
      message: entry == null
          ? 'سيتم اختيار ملف نسخة احتياطية ثم استعادته. هل تريد المتابعة؟'
          : 'هل تريد استعادة نسخة ${entry.createdAt}؟',
      confirmLabel: 'استعادة',
      cancelLabel: 'إلغاء',
      isDanger: true,
      size: AppDialogSize.medium,
    );
    if (!confirmed || !mounted) return;
    final source = entry?.backupId == null
        ? ExternalBackupSource(
            localPath: r'D:\Almumayaz\Backups\external_demo.backup',
          )
        : StoredBackupSource(entry!.backupId!);
    try {
      final verification = await _backupService.verifyRestoreSource(source);
      if (!verification.canRestore) {
        throw ServiceFailure(
          kind: ServiceFailureKind.securityRejected,
          message: verification.message ?? 'النسخة غير قابلة للاستعادة',
        );
      }
      final result = await _backupService.restore(
        RestoreRequest(source: source, confirmedByUser: true),
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
      if (mounted) AppToast.showError(context, _serviceMessage(error));
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
              'يُنشأ النسخ التلقائي محلياً دائماً، وتُرفع نسخة إضافية إلى Google Drive عند ربط الحساب.',
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
                      onPressed: () {
                        _localPathController.text =
                            r'D:\Almumayaz\Backups\Local';
                        AppToast.showInfo(
                          context,
                          'تم اختيار مسار تجريبي',
                        );
                      },
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
                      setState(() => _automaticBackup = value);
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
                    options: const [
                      AppDropdownOption(
                        value: 'يدوياً',
                        label: 'يدوياً',
                      ),
                      AppDropdownOption(value: 'يومياً', label: 'يومياً'),
                      AppDropdownOption(
                        value: 'أسبوعياً',
                        label: 'أسبوعياً',
                      ),
                      AppDropdownOption(
                        value: 'شهرياً',
                        label: 'شهرياً',
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
                          _driveConnected
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          color: _driveConnected
                              ? AppColors.green
                              : AppColors.grey,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _driveConnected
                                ? 'الحساب مرتبط وجاهز للنسخ'
                                : 'لم يتم ربط حساب Google Drive',
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
                          onPressed: _toggleDriveConnection,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    fieldKey:
                        const Key('settingsDriveFolderField'),
                    controller: _driveFolderController,
                    label: 'مجلد Google Drive',
                    icon: Icons.drive_folder_upload_outlined,
                    suffixIcon: _driveConnected &&
                            _googleDriveService
                                is DemoGoogleDriveBackupService
                        ? AppFieldIconButton(
                            buttonKey: const Key(
                              'settingsFailNextDriveUploadButton',
                            ),
                            icon: Icons.cloud_off_outlined,
                            tooltip: 'محاكاة فشل الرفع التالي',
                            color: AppColors.warning,
                            onPressed: _failNextDriveUpload,
                          )
                        : null,
                    accentColor: widget.accentColor,
                    enabled: _driveConnected,
                    readOnly: !_driveConnected,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppInfoBanner(
                    message: _driveConnected
                        ? '${_driveConnection.accountLabel ?? 'حساب تجريبي'} — '
                            'سيتم رفع نسخة إضافية محاكاةً، مع بقاء النسخة المحلية عند الفشل.'
                        : 'اربط الحساب لتفعيل مجلد Google Drive والرفع السحابي.',
                    icon: Icons.info_outline_rounded,
                    foregroundColor: _driveConnected
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
          child: Wrap(
            textDirection: TextDirection.rtl,
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton(
                key: const Key('settingsSaveBackupConfigurationButton'),
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
                  AppTableColumn(label: 'التاريخ والوقت', flex: 1.5),
                  AppTableColumn(label: 'الوجهة', flex: 1.3),
                  AppTableColumn(label: 'الحجم', flex: 0.8),
                  AppTableColumn(label: 'الحالة', flex: 0.9),
                  AppTableColumn(label: 'الإجراء', flex: 0.65),
                ],
                rows: [
                  for (final entry in _history)
                    AppTableRow(
                      rowKey: Key('settingsBackupHistoryRow_${entry.id}'),
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
                                  'settingsVerifyHistory_${entry.id}',
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
                                  'settingsRestoreHistory_${entry.id}',
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
    required this.id,
    required this.createdAt,
    required this.destination,
    required this.size,
    required this.status,
    required this.isSuccessful,
    this.backupId,
    this.isRestorable = false,
  });

  final int id;
  final String createdAt;
  final String destination;
  final String size;
  final String status;
  final bool isSuccessful;
  final EntityId? backupId;
  final bool isRestorable;
}

_BackupHistoryEntry _backupHistoryEntry(BackupRecord record) {
  final sequence = int.tryParse(record.id.value.split('-').last) ??
      record.id.value.hashCode.abs();
  final isRestorable = record.isEncrypted &&
      record.checksum != null &&
      (record.status == BackupStatus.completed ||
          record.status == BackupStatus.uploadFailed);
  return _BackupHistoryEntry(
    id: sequence,
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
