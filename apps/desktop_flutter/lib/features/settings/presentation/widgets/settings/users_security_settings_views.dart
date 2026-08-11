part of '../settings_sections.dart';

extension _UsersSecuritySettingsSectionViews
    on _UsersSecuritySettingsSectionState {
  Widget _buildUsersTemplate() {
    return AppSectionPanel(
      key: const Key('settingsUsersPanel'),
      title: 'المستخدمون',
      icon: Icons.people_alt_outlined,
      accentColor: widget.accentColor,
      actions: [
        AppRegularButton(
          key: const Key('settingsAddUserButton'),
          label: 'مستخدم جديد',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: _canManageSecurity ? _openAddUserDialog : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            message:
                'يمكن تفعيل الحساب أو تعطيله أو قفله، وتغيير كلمة مروره من قائمة المستخدمين.',
            icon: Icons.info_outline_rounded,
            foregroundColor: widget.accentColor,
            backgroundColor: Color.alphaBlend(
              widget.accentColor.withAlpha(18),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('settingsUsersTable'),
            height: 430,
            rowHeight: 58,
            minimumColumnWidth: 150,
            accentColor: widget.accentColor,
            showShadow: false,
            emptyState: const AppStatePanel(
              type: AppStateType.empty,
              title: 'لا يوجد مستخدمون',
              message: 'أضف مستخدماً جديداً لبدء إدارة الحسابات.',
            ),
            columns: const [
              AppTableColumn(label: 'الاسم الكامل', flex: 1.3),
              AppTableColumn(
                label: 'اسم المستخدم',
                textDirection: TextDirection.ltr,
                flex: 1,
              ),
              AppTableColumn(label: 'الدور', flex: 1),
              AppTableColumn(label: 'الحالة', flex: 0.8),
              AppTableColumn(label: 'آخر دخول', numeric: true, flex: 1.35),
              AppTableColumn(label: 'الإجراءات', flex: 1.7),
            ],
            rows: [
              for (final user in _users)
                AppTableRow(
                  rowKey: Key('settingsUserRow_${user.keySuffix}'),
                  cells: [
                    Text(user.fullName),
                    Text(user.username, textDirection: TextDirection.ltr),
                    Builder(
                      builder: (context) {
                        final label = _settingsUserRoleLabel(user, _roles);
                        final missing = label == 'مرجع دور مفقود';
                        return Text(
                          label,
                          key: missing
                              ? Key(
                                  'settingsUserMissingRole_'
                                  '${user.keySuffix}',
                                )
                              : null,
                          style: missing
                              ? const TextStyle(color: AppColors.danger)
                              : null,
                        );
                      },
                    ),
                    Center(
                      key: Key('settingsUserStatus_${user.keySuffix}'),
                      child: _userStatusBadge(user),
                    ),
                    Text(
                      user.lastLoginAt == null
                          ? 'لم يسجل الدخول'
                          : _formatAuditTimestamp(user.lastLoginAt!),
                    ),
                    Center(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          AppTableActionButton(
                            key: Key(
                              'settingsUserEnable_${user.keySuffix}',
                            ),
                            icon: user.isEnabled
                                ? Icons.person_off_outlined
                                : Icons.person_outline_rounded,
                            tooltip: user.isEnabled
                                ? 'تعطيل الحساب'
                                : 'تفعيل الحساب',
                            variant: user.isEnabled
                                ? AppButtonVariant.warning
                                : AppButtonVariant.success,
                            onPressed: user.isSystemUser || !_canManageSecurity
                                ? null
                                : () => _toggleUserEnabled(user),
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsUserLock_${user.keySuffix}',
                            ),
                            icon: user.isLocked
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            tooltip: user.isLocked
                                ? 'فتح القفل'
                                : 'قفل الحساب',
                            variant: AppButtonVariant.warning,
                            onPressed: user.isSystemUser || !_canManageSecurity
                                ? null
                                : () => _toggleUserLock(user),
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsUserPassword_${user.keySuffix}',
                            ),
                            icon: Icons.password_rounded,
                            tooltip: 'إعادة تعيين كلمة المرور',
                            onPressed: _canManageSecurity
                                ? () => _openUserPasswordDialog(user)
                                : null,
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsUserEdit_${user.keySuffix}',
                            ),
                            icon: Icons.edit_outlined,
                            tooltip: 'تعديل المستخدم',
                            onPressed: _canManageSecurity
                                ? () => _openEditUserDialog(user)
                                : null,
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsUserDelete_${user.keySuffix}',
                            ),
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'حذف المستخدم',
                            variant: AppButtonVariant.danger,
                            onPressed: user.isSystemUser || !_canManageSecurity
                                ? null
                                : () => _deleteUser(user),
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
    );
  }

  Widget _buildRolesTemplate() {
    return AppSectionPanel(
      key: const Key('settingsRolesPanel'),
      title: 'الأدوار والصلاحيات',
      icon: Icons.admin_panel_settings_outlined,
      accentColor: widget.accentColor,
      actions: [
        AppRegularButton(
          key: const Key('settingsAddRoleButton'),
          label: 'دور جديد',
          icon: Icons.add_moderator_outlined,
          onPressed: _canManageSecurity ? _openRoleDialog : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            message:
                'هذا نموذج لتجميع صلاحيات العرض والإضافة والتعديل والحذف والطباعة والتصدير والإدارة ضمن أدوار واضحة.',
            icon: Icons.verified_user_outlined,
            foregroundColor: widget.accentColor,
            backgroundColor: Color.alphaBlend(
              widget.accentColor.withAlpha(18),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('settingsRolesTable'),
            height: 390,
            rowHeight: 62,
            minimumColumnWidth: 160,
            accentColor: widget.accentColor,
            showShadow: false,
            emptyState: const AppStatePanel(
              type: AppStateType.empty,
              title: 'لا توجد أدوار',
              message: 'أضف دوراً جديداً وحدد صلاحياته.',
            ),
            columns: const [
              AppTableColumn(label: 'ت', flex: 0.4, numeric: true),
              AppTableColumn(label: 'الدور', flex: 1.1),
              AppTableColumn(
                label: 'عدد المستخدمين',
                numeric: true,
                flex: 0.9,
              ),
              AppTableColumn(label: 'ملخص الصلاحيات', flex: 2),
              AppTableColumn(label: 'الإجراءات', flex: 0.9),
            ],
            rows: [
              for (final role in _roles)
                AppTableRow(
                  rowKey: Key('settingsRoleRow_${role.keySuffix}'),
                  cells: [
                    Text(role.displayNumber, textAlign: TextAlign.center),
                    Text(role.name),
                    Text(
                      '${_roleUsersCount(role.id)}',
                      key: Key(
                        'settingsRoleUserCount_${role.keySuffix}',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _rolePermissionSummary(role.permissions),
                      key: Key('settingsRoleSummary_${role.keySuffix}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Center(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          AppTableActionButton(
                            key: Key(
                              'settingsRolePermissions_${role.keySuffix}',
                            ),
                            icon: Icons.rule_rounded,
                            tooltip: role.isSystemRole
                                ? 'دور النظام محمي'
                                : 'تعديل الصلاحيات',
                            onPressed: role.isSystemRole || !_canManageSecurity
                                ? null
                                : () => _openRoleDialog(role: role),
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsRoleDelete_${role.keySuffix}',
                            ),
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'حذف الدور',
                            variant: AppButtonVariant.danger,
                            onPressed: role.isSystemRole || !_canManageSecurity
                                ? null
                                : () => _deleteRole(role),
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
    );
  }

  Widget _buildSecurityTemplate() {
    return AppResponsiveGrid(
      key: const Key('settingsPasswordLockTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 430,
      children: [
        AppSectionPanel(
          key: const Key('settingsChangePasswordPanel'),
          title: 'تغيير كلمة المرور',
          icon: Icons.password_rounded,
          accentColor: widget.accentColor,
          child: Column(
            children: [
              AppTextField(
                fieldKey: const Key('settingsCurrentPasswordField'),
                controller: _currentPasswordController,
                label: 'كلمة المرور الحالية',
                icon: Icons.lock_outline_rounded,
                accentColor: widget.accentColor,
                obscureText: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                fieldKey: const Key('settingsNewPasswordField'),
                controller: _newPasswordController,
                label: 'كلمة المرور الجديدة',
                icon: Icons.key_rounded,
                accentColor: widget.accentColor,
                obscureText: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                fieldKey: const Key('settingsConfirmPasswordField'),
                controller: _confirmPasswordController,
                label: 'تأكيد كلمة المرور الجديدة',
                icon: Icons.verified_user_outlined,
                accentColor: widget.accentColor,
                obscureText: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                onSubmitted: (_) => _savePassword(),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  key: const Key('settingsSavePasswordButton'),
                  label: 'تغيير كلمة المرور',
                  icon: Icons.save_outlined,
                  minWidth: 190,
                  onPressed: _savePassword,
                ),
              ),
            ],
          ),
        ),
        AppSectionPanel(
          key: const Key('settingsIdleLockPanel'),
          title: 'القفل التلقائي',
          icon: Icons.lock_clock_outlined,
          accentColor: widget.accentColor,
          child: Column(
            children: [
              AppSwitchField(
                key: const Key('settingsIdleLockSwitch'),
                title: 'قفل التطبيق بعد الخمول',
                subtitle:
                    'يعيد المستخدم إلى شاشة الدخول بعد مدة دون استخدام',
                icon: Icons.timer_outlined,
                value: _idleLockEnabled,
                onChanged: (value) {
                  _setSecurityViewState(() => _idleLockEnabled = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdownField<String>(
                fieldKey: const Key('settingsIdleLockDurationField'),
                label: 'مدة الخمول',
                icon: Icons.schedule_rounded,
                accentColor: widget.accentColor,
                value: _idleLockDuration,
                enabled: _idleLockEnabled,
                options: const [
                  AppDropdownOption(value: '5 دقائق', label: '5 دقائق'),
                  AppDropdownOption(
                    value: '15 دقيقة',
                    label: '15 دقيقة',
                  ),
                  AppDropdownOption(
                    value: '30 دقيقة',
                    label: '30 دقيقة',
                  ),
                  AppDropdownOption(value: '60 دقيقة', label: '60 دقيقة'),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value == null || value == _idleLockDuration) return;
                  _setSecurityViewState(() => _idleLockDuration = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppInfoBanner(
                key: const Key('settingsCurrentSessionState'),
                message: _currentSession == null
                    ? 'لا توجد جلسة تجريبية حالية.'
                    : 'الجلسة ${_sessionStateLabel(_currentSession!.state)} — '
                        'آخر نشاط ${_formatAuditTimestamp(_currentSession!.lastActivityAt)}',
                icon: Icons.devices_outlined,
                foregroundColor: widget.accentColor,
                backgroundColor: Color.alphaBlend(
                  widget.accentColor.withAlpha(18),
                  AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppInfoBanner(
                message:
                    'القفل لا يغلق التطبيق ولا يفقد العمل المحفوظ؛ يطلب تسجيل الدخول فقط.',
                icon: Icons.security_rounded,
                foregroundColor: widget.accentColor,
                backgroundColor: Color.alphaBlend(
                  widget.accentColor.withAlpha(18),
                  AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: AppRegularButton(
                  key: const Key('settingsToggleDemoSessionLockButton'),
                  label: 'قفل الجلسة الآن',
                  icon: Icons.lock_clock_outlined,
                  onPressed: _currentSession?.state == SessionState.active
                      ? _toggleCurrentSessionLock
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  key: const Key('settingsSaveIdleLockButton'),
                  label: 'حفظ إعداد القفل',
                  icon: Icons.save_outlined,
                  minWidth: 180,
                  onPressed: _canManageSecurity ? _saveIdleLock : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAuditDetails(AuditRecord record) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsAuditDetailsDialog(
          record: record,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  Widget _buildLogsTemplate() {
    return AppSectionPanel(
      key: const Key('settingsSecurityLogsPanel'),
      title: 'سجل الدخول والنشاط والتعديلات',
      icon: Icons.receipt_long_outlined,
      accentColor: widget.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppResponsiveGrid(
            preferredColumns: 3,
            children: [
              AppSearchField(
                fieldKey: const Key('settingsSecurityLogSearchField'),
                controller: _logSearchController,
                label: 'بحث في السجل',
                hint: 'المستخدم أو العملية أو التفاصيل',
                accentColor: widget.accentColor,
                focusNode: _logSearchFocusNode,
                onChanged: (_) => _refreshAudit(),
              ),
              AppDropdownField<String>(
                fieldKey: const Key('settingsSecurityLogTypeField'),
                label: 'نوع العملية',
                icon: Icons.filter_alt_outlined,
                accentColor: widget.accentColor,
                value: _logType,
                options: const [
                  AppDropdownOption(value: 'الكل', label: 'الكل'),
                  AppDropdownOption(value: 'تسجيل الدخول', label: 'تسجيل الدخول'),
                  AppDropdownOption(value: 'تسجيل الخروج', label: 'تسجيل الخروج'),
                  AppDropdownOption(value: 'قفل الجلسة', label: 'قفل الجلسة'),
                  AppDropdownOption(value: 'فتح الجلسة', label: 'فتح الجلسة'),
                  AppDropdownOption(value: 'نشاط الجلسة', label: 'نشاط الجلسة'),
                  AppDropdownOption(value: 'إضافة', label: 'إضافة'),
                  AppDropdownOption(value: 'تعديل', label: 'تعديل'),
                  AppDropdownOption(value: 'حذف', label: 'حذف'),
                  AppDropdownOption(value: 'استعادة', label: 'استعادة'),
                  AppDropdownOption(value: 'طباعة', label: 'طباعة'),
                  AppDropdownOption(value: 'تصدير', label: 'تصدير'),
                  AppDropdownOption(value: 'صلاحيات', label: 'صلاحيات'),
                  AppDropdownOption(value: 'حالة حساب', label: 'حالة حساب'),
                  AppDropdownOption(value: 'كلمة المرور', label: 'كلمة المرور'),
                  AppDropdownOption(value: 'نسخ احتياطي', label: 'نسخ احتياطي'),
                  AppDropdownOption(value: 'أخرى', label: 'أخرى'),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value == null) return;
                  _setSecurityViewState(() => _logType = value);
                  _refreshAudit();
                },
              ),
              AppDropdownField<String>(
                fieldKey: const Key('settingsSecurityLogOutcomeField'),
                label: 'نتيجة العملية',
                icon: Icons.fact_check_outlined,
                accentColor: widget.accentColor,
                value: _logOutcome,
                options: const [
                  AppDropdownOption(value: 'الكل', label: 'الكل'),
                  AppDropdownOption(value: 'مكتمل', label: 'مكتمل'),
                  AppDropdownOption(value: 'فشل', label: 'فشل'),
                  AppDropdownOption(value: 'محظور', label: 'محظور'),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value == null) return;
                  _setSecurityViewState(() => _logOutcome = value);
                  _refreshAudit();
                },
              ),
              AppDropdownField<String>(
                fieldKey: const Key('settingsSecurityLogUserField'),
                label: 'المستخدم',
                icon: Icons.person_search_outlined,
                accentColor: widget.accentColor,
                value: _logUserId?.value ?? 'all',
                options: [
                  const AppDropdownOption(value: 'all', label: 'الكل'),
                  for (final user in _users)
                    AppDropdownOption(
                      value: user.id.value,
                      label: '${user.fullName} (${user.username})',
                    ),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value == null) return;
                  _setSecurityViewState(() {
                    _logUserId = value == 'all' ? null : EntityId(value);
                  });
                  _refreshAudit();
                },
              ),
              AppDateRangeField(
                fieldKey: const Key('settingsSecurityLogDateRangeField'),
                label: 'الفترة الزمنية',
                value: _logDateRange,
                accentColor: widget.accentColor,
                onChanged: (value) {
                  _setSecurityViewState(() => _logDateRange = value);
                  _refreshAudit();
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AppRegularButton(
                  key: const Key('settingsSecurityLogResetFiltersButton'),
                  label: 'إعادة ضبط المرشحات',
                  icon: Icons.filter_alt_off_outlined,
                  onPressed: () {
                    _logSearchController.clear();
                    _setSecurityViewState(() {
                      _logType = 'الكل';
                      _logOutcome = 'الكل';
                      _logUserId = null;
                      _logDateRange = null;
                    });
                    _refreshAudit();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'عدد النتائج: $_auditTotalCount',
            key: const Key('settingsSecurityLogResultCount'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDataTable(
            key: const Key('settingsSecurityLogsTable'),
            height: 430,
            rowHeight: 58,
            minimumColumnWidth: 155,
            accentColor: widget.accentColor,
            showShadow: false,
            emptyState: const AppStatePanel(
              type: AppStateType.empty,
              title: 'لا توجد نتائج',
              message: 'غيّر عبارة البحث أو نوع العملية.',
            ),
            columns: const [
              AppTableColumn(
                label: 'التاريخ والوقت',
                numeric: true,
                flex: 1.4,
              ),
              AppTableColumn(label: 'المستخدم', flex: 0.8),
              AppTableColumn(label: 'العملية', flex: 0.9),
              AppTableColumn(label: 'التفاصيل', flex: 2.2),
              AppTableColumn(label: 'الحالة', flex: 0.75),
            ],
            rows: [
              for (final entry in _auditEntries)
                AppTableRow(
                  rowKey: Key(
                    'settingsAuditRow_${_entityKeySuffix(entry.id)}',
                  ),
                  onTap: () => _showAuditDetails(entry.record),
                  cells: [
                    Text(entry.createdAt),
                    Text(
                      entry.username,
                      textDirection: TextDirection.ltr,
                    ),
                    Text(entry.type),
                    Text(entry.details, overflow: TextOverflow.ellipsis),
                    Center(
                      child: AppStatusBadge(
                        label: entry.status,
                        tone: switch (entry.record.outcome) {
                          AuditOutcome.success => AppStatusTone.success,
                          AuditOutcome.failure => AppStatusTone.danger,
                          AuditOutcome.blocked => AppStatusTone.warning,
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userStatusBadge(_SettingsUser user) {
    final (label, tone) = switch ((user.isEnabled, user.isLocked)) {
      (false, true) => ('معطل ومقفل', AppStatusTone.danger),
      (true, true) => ('مقفل', AppStatusTone.danger),
      (false, false) => ('معطل', AppStatusTone.warning),
      (true, false) => ('نشط', AppStatusTone.success),
    };
    return AppStatusBadge(
      label: label,
      tone: tone,
    );
  }
}
