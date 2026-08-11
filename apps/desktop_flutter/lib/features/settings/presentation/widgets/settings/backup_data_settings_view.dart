part of '../settings_sections.dart';

extension _BackupDataSettingsView on _BackupDataSettingsSectionState {
  Widget _buildBackupContent(BuildContext context) {
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
          AppResponsiveGrid(
            preferredColumns: 2,
            minimumChildHeight: 360,
            children: [
              AppSectionPanel(
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
                        _setBackupViewState(() {
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
                        _setBackupViewState(() => _backupFrequency = value);
                      },
                    ),
                  ],
                ),
              ),
              AppSectionPanel(
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
          AppSectionPanel(
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
          AppSectionPanel(
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

}
