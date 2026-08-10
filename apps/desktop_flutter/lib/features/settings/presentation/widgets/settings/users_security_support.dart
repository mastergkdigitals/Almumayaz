part of '../settings_sections.dart';

class _SettingsUser {
  const _SettingsUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.roleIds,
    required this.status,
    required this.isSystemUser,
    required this.lastLoginAt,
  });

  final EntityId id;
  final String fullName;
  final String username;
  final Set<EntityId> roleIds;
  final UserAccountStatus status;
  final bool isSystemUser;
  final AuditTimestamp? lastLoginAt;

  bool get isEnabled => switch (status) {
        UserAccountStatus.active || UserAccountStatus.locked => true,
        UserAccountStatus.disabled || UserAccountStatus.disabledAndLocked =>
          false,
      };

  bool get isLocked => switch (status) {
        UserAccountStatus.locked || UserAccountStatus.disabledAndLocked => true,
        UserAccountStatus.active || UserAccountStatus.disabled => false,
      };

  String get keySuffix => _entityKeySuffix(id);
  String get displayNumber => _entityDisplayNumber(id);
}
class _SettingsRole {
  _SettingsRole({
    required this.id,
    required this.name,
    required this.permissions,
    required this.isSystemRole,
  });

  final EntityId id;
  final String name;
  final Map<String, Set<String>> permissions;
  final bool isSystemRole;

  String get keySuffix => _entityKeySuffix(id);
  String get displayNumber => _entityDisplayNumber(id);
}

const _settingsPermissionScreens = <({String id, String label})>[
  (id: 'sales', label: 'المبيعات'),
  (id: 'purchases', label: 'المشتريات'),
  (id: 'parties', label: 'الأطراف'),
  (id: 'cashbox', label: 'الصندوق'),
  (id: 'warehouses', label: 'المخازن'),
  (id: 'items', label: 'المواد'),
  (id: 'reports', label: 'التقارير'),
  (id: 'settings', label: 'الإعدادات'),
];

const _settingsPermissionActions = <({String id, String label})>[
  (id: 'view', label: 'عرض'),
  (id: 'add', label: 'إضافة'),
  (id: 'edit', label: 'تعديل'),
  (id: 'delete', label: 'حذف'),
  (id: 'print', label: 'طباعة'),
  (id: 'export', label: 'تصدير'),
  (id: 'manage', label: 'إدارة'),
];

const _allPermissionActionIds = <String>{
  'view',
  'add',
  'edit',
  'delete',
  'print',
  'export',
  'manage',
};

Map<String, Set<String>> _settingsRolePermissions({
  Set<String> sales = const {},
  Set<String> purchases = const {},
  Set<String> parties = const {},
  Set<String> cashbox = const {},
  Set<String> warehouses = const {},
  Set<String> items = const {},
  Set<String> reports = const {},
  Set<String> settings = const {},
}) {
  return {
    'sales': {...sales},
    'purchases': {...purchases},
    'parties': {...parties},
    'cashbox': {...cashbox},
    'warehouses': {...warehouses},
    'items': {...items},
    'reports': {...reports},
    'settings': {...settings},
  };
}

Map<String, Set<String>> _copySettingsRolePermissions(
  Map<String, Set<String>> source,
) {
  return {
    for (final screen in _settingsPermissionScreens)
      screen.id: {...?source[screen.id]},
  };
}

String _rolePermissionSummary(Map<String, Set<String>> permissions) {
  final hasAllPermissions = _settingsPermissionScreens.every(
    (screen) =>
        permissions[screen.id]?.containsAll(_allPermissionActionIds) ??
        false,
  );
  if (hasAllPermissions) return 'كامل الصلاحيات';

  final summaries = <String>[];
  for (final screen in _settingsPermissionScreens) {
    final selected = permissions[screen.id] ?? const <String>{};
    if (selected.isEmpty) continue;
    final actionLabels = [
      for (final action in _settingsPermissionActions)
        if (selected.contains(action.id)) action.label,
    ];
    summaries.add('${screen.label}: ${actionLabels.join('، ')}');
  }
  return summaries.isEmpty ? 'بدون صلاحيات' : summaries.join(' | ');
}

class _SettingsAuditEntry {
  const _SettingsAuditEntry({
    required this.id,
    required this.createdAt,
    required this.username,
    required this.type,
    required this.details,
    required this.status,
    required this.record,
  });

  final EntityId id;
  final String createdAt;
  final String username;
  final String type;
  final String details;
  final String status;
  final AuditRecord record;
}

_SettingsRole _settingsRoleFromDomain(AppRole role) {
  final permissions = _settingsRolePermissions();
  for (final permission in role.permissions) {
    final action = _settingsPermissionActionId(permission.action);
    if (action != null && permissions.containsKey(permission.module)) {
      permissions[permission.module]!.add(action);
    }
  }
  return _SettingsRole(
    id: role.id,
    name: role.name,
    permissions: permissions,
    isSystemRole: role.isSystemRole,
  );
}

Set<PermissionCode> _permissionCodesFromSettings(
  Map<String, Set<String>> source,
) {
  final permissions = <PermissionCode>{};
  for (final entry in source.entries) {
    for (final actionId in entry.value) {
      final action = _permissionActionValue(actionId);
      if (action != null) {
        permissions.add(PermissionCode(module: entry.key, action: action));
      }
    }
  }
  return permissions;
}

_SettingsUser _settingsUserFromDomain(
  AppUser user,
) {
  return _SettingsUser(
    id: user.id,
    fullName: user.fullName,
    username: user.username,
    roleIds: user.roleIds,
    status: user.status,
    isSystemUser: user.isSystemUser,
    lastLoginAt: user.lastLoginAt,
  );
}

UserAccountStatus _userStatusValue({
  required bool isEnabled,
  required bool isLocked,
}) =>
    switch ((isEnabled, isLocked)) {
      (true, false) => UserAccountStatus.active,
      (false, false) => UserAccountStatus.disabled,
      (true, true) => UserAccountStatus.locked,
      (false, true) => UserAccountStatus.disabledAndLocked,
    };

PermissionAction? _permissionActionValue(String id) => switch (id) {
      'view' => PermissionAction.view,
      'add' => PermissionAction.create,
      'edit' => PermissionAction.update,
      'delete' => PermissionAction.delete,
      'print' => PermissionAction.print,
      'export' => PermissionAction.export,
      'manage' => PermissionAction.manage,
      _ => null,
    };

String? _settingsPermissionActionId(
  PermissionAction action,
) =>
    switch (action) {
      PermissionAction.view => 'view',
      PermissionAction.create => 'add',
      PermissionAction.update => 'edit',
      PermissionAction.delete => 'delete',
      PermissionAction.print => 'print',
      PermissionAction.export => 'export',
      PermissionAction.manage => 'manage',
    };

_SettingsAuditEntry _settingsAuditFromDomain(AuditRecord record) {
  return _SettingsAuditEntry(
    id: record.id,
    createdAt: _formatAuditTimestamp(record.occurredAt),
    username: record.actorUsername,
    type: _auditActionLabel(record.action),
    details: record.summary,
    status: switch (record.outcome) {
      AuditOutcome.success => 'مكتمل',
      AuditOutcome.failure => 'فشل',
      AuditOutcome.blocked => 'محظور',
    },
    record: record,
  );
}

String _entityKeySuffix(EntityId id) {
  return id.value;
}

String _entityDisplayNumber(EntityId id) =>
    int.tryParse(id.value.split('-').last)?.toString() ?? id.value;

String _settingsUserRoleLabel(
  _SettingsUser user,
  Iterable<_SettingsRole> roles,
) {
  final roleNames = [
    for (final roleId in user.roleIds)
      roles.where((role) => role.id == roleId).firstOrNull?.name,
  ].whereType<String>().toList();
  if (roleNames.length != user.roleIds.length) return 'مرجع دور مفقود';
  return roleNames.join('، ');
}

String _auditActionLabel(AuditAction action) => switch (action) {
      AuditAction.signIn => 'تسجيل الدخول',
      AuditAction.signOut => 'تسجيل الخروج',
      AuditAction.sessionLock => 'قفل الجلسة',
      AuditAction.sessionUnlock => 'فتح الجلسة',
      AuditAction.activity => 'نشاط الجلسة',
      AuditAction.create => 'إضافة',
      AuditAction.update => 'تعديل',
      AuditAction.delete => 'حذف',
      AuditAction.restore => 'استعادة',
      AuditAction.print => 'طباعة',
      AuditAction.export => 'تصدير',
      AuditAction.permissionChange => 'صلاحيات',
      AuditAction.accountStatusChange => 'حالة حساب',
      AuditAction.passwordChange => 'كلمة المرور',
      AuditAction.backup => 'نسخ احتياطي',
      AuditAction.other => 'أخرى',
    };

AuditAction? _auditActionForLabel(String label) => switch (label) {
      'تسجيل الدخول' => AuditAction.signIn,
      'تسجيل الخروج' => AuditAction.signOut,
      'قفل الجلسة' => AuditAction.sessionLock,
      'فتح الجلسة' => AuditAction.sessionUnlock,
      'نشاط الجلسة' => AuditAction.activity,
      'إضافة' => AuditAction.create,
      'تعديل' => AuditAction.update,
      'حذف' => AuditAction.delete,
      'استعادة' => AuditAction.restore,
      'طباعة' => AuditAction.print,
      'تصدير' => AuditAction.export,
      'صلاحيات' => AuditAction.permissionChange,
      'حالة حساب' => AuditAction.accountStatusChange,
      'كلمة المرور' => AuditAction.passwordChange,
      'نسخ احتياطي' => AuditAction.backup,
      'أخرى' => AuditAction.other,
      _ => null,
    };

AuditOutcome? _auditOutcomeForLabel(String label) => switch (label) {
      'مكتمل' => AuditOutcome.success,
      'فشل' => AuditOutcome.failure,
      'محظور' => AuditOutcome.blocked,
      _ => null,
    };

String _sessionStateLabel(SessionState state) => switch (state) {
      SessionState.active => 'نشطة',
      SessionState.locked => 'مقفلة',
      SessionState.expired => 'منتهية',
      SessionState.signedOut => 'مسجل خروجها',
    };

class _SettingsAuditDetailsDialog extends StatelessWidget {
  const _SettingsAuditDetailsDialog({
    required this.record,
    required this.accentColor,
  });

  final AuditRecord record;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: Key(
        'settingsAuditDetailsDialog_${_entityKeySuffix(record.id)}',
      ),
      title: 'تفاصيل سجل التدقيق',
      subtitle: record.summary,
      icon: Icons.manage_search_rounded,
      accentColor: accentColor,
      onClose: () => Navigator.of(context).pop(),
      width: 760,
      actions: [
        AppButton(
          key: const Key('settingsAuditDetailsCloseButton'),
          label: 'إغلاق',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuditDetailLine(label: 'المستخدم', value: record.actorUsername),
            _AuditDetailLine(
              label: 'العملية',
              value: _auditActionLabel(record.action),
            ),
            _AuditDetailLine(
              label: 'النتيجة',
              value: switch (record.outcome) {
                AuditOutcome.success => 'مكتمل',
                AuditOutcome.failure => 'فشل',
                AuditOutcome.blocked => 'محظور',
              },
            ),
            _AuditDetailLine(
              label: 'الجهاز',
              value: record.metadata.deviceId,
            ),
            _AuditDetailLine(
              label: 'معرّف الطلب',
              value: record.metadata.requestId,
            ),
            if (record.entityType != null)
              _AuditDetailLine(
                label: 'السجل المرتبط',
                value: '${record.entityType}: ${record.entityId}',
              ),
            _AuditDetailLine(
              label: 'التفاصيل',
              value: _auditMapText(record.details),
            ),
            _AuditDetailLine(
              label: 'قبل',
              value: _auditMapText(record.metadata.before),
            ),
            _AuditDetailLine(
              label: 'بعد',
              value: _auditMapText(record.metadata.after),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditDetailLine extends StatelessWidget {
  const _AuditDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text('$label: $value'),
    );
  }
}

String _auditMapText(Map<String, Object?> values) {
  if (values.isEmpty) return 'لا توجد بيانات';
  return values.entries
      .map((entry) => '${entry.key}=${entry.value ?? '-'}')
      .join('، ');
}

class _SettingsUserDraft {
  const _SettingsUserDraft({
    required this.fullName,
    required this.username,
    required this.roleIds,
    this.initialPassword,
  });

  final String fullName;
  final String username;
  final Set<EntityId> roleIds;
  final String? initialPassword;
}

class _SettingsUserPasswordDraft {
  const _SettingsUserPasswordDraft({
    required this.newPassword,
  });

  final String newPassword;
}

class _SettingsUserPasswordDialog extends StatefulWidget {
  const _SettingsUserPasswordDialog({
    required this.user,
    required this.accentColor,
  });

  final _SettingsUser user;
  final Color accentColor;

  @override
  State<_SettingsUserPasswordDialog> createState() =>
      _SettingsUserPasswordDialogState();
}

class _SettingsUserPasswordDialogState
    extends State<_SettingsUserPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  String? get _confirmationError {
    final confirmation = _confirmationController.text;
    if (confirmation.isEmpty || confirmation == _passwordController.text) {
      return null;
    }
    return 'كلمتا المرور غير متطابقتين';
  }

  bool get _canSave =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text.length >= 6 &&
      _confirmationController.text.isNotEmpty &&
      _confirmationError == null;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsUserPasswordDraft(
        newPassword: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.keySuffix;
    return AppModuleDialog(
      key: Key('settingsUserPasswordDialog_$userId'),
      title: 'إعادة تعيين كلمة مرور المستخدم',
      subtitle: '${widget.user.fullName} — لن تظهر كلمة المرور الحالية',
      icon: Icons.password_rounded,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 620,
      actions: [
        AppButton(
          key: Key('settingsUserPasswordCancel_$userId'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: Key('settingsUserPasswordConfirm_$userId'),
          label: 'تحديث',
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.success,
          width: 145,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: Column(
        children: [
          AppTextField(
            fieldKey: Key('settingsUserPasswordNewField_$userId'),
            controller: _passwordController,
            label: 'كلمة المرور الجديدة',
            icon: Icons.key_rounded,
            accentColor: widget.accentColor,
            obscureText: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: Key('settingsUserPasswordConfirmField_$userId'),
            controller: _confirmationController,
            label: 'تأكيد كلمة المرور',
            icon: Icons.verified_user_outlined,
            accentColor: widget.accentColor,
            obscureText: true,
            errorText: _confirmationError,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
    );
  }
}
class _SettingsRoleDraft {
  const _SettingsRoleDraft({
    required this.name,
    required this.permissions,
  });

  final String name;
  final Map<String, Set<String>> permissions;
}

class _SettingsRoleDialog extends StatefulWidget {
  const _SettingsRoleDialog({
    required this.accentColor,
    required this.existingRoleNames,
    this.initialRole,
  });

  final Color accentColor;
  final Set<String> existingRoleNames;
  final _SettingsRole? initialRole;

  @override
  State<_SettingsRoleDialog> createState() =>
      _SettingsRoleDialogState();
}

class _SettingsRoleDialogState extends State<_SettingsRoleDialog> {
  late final TextEditingController _nameController;
  late final Map<String, Set<String>> _permissions;

  bool get _isEditing => widget.initialRole != null;

  String? get _nameError {
    final name = _nameController.text.trim().toLowerCase();
    if (name.isEmpty) return null;
    return widget.existingRoleNames.contains(name)
        ? 'اسم الدور مستخدم مسبقاً'
        : null;
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _nameError == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialRole?.name ?? '',
    );
    _permissions = widget.initialRole == null
        ? _settingsRolePermissions()
        : _copySettingsRolePermissions(
            widget.initialRole!.permissions,
          );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsRoleDraft(
        name: _nameController.text.trim(),
        permissions: _copySettingsRolePermissions(_permissions),
      ),
    );
  }

  void _setAllPermissions(bool selected) {
    setState(() {
      for (final screen in _settingsPermissionScreens) {
        _permissions[screen.id] = selected
            ? {..._allPermissionActionIds}
            : <String>{};
      }
    });
  }

  void _togglePermission(
    String screenId,
    String actionId,
    bool selected,
  ) {
    setState(() {
      final actions = _permissions.putIfAbsent(
        screenId,
        () => <String>{},
      );
      if (selected) {
        actions.add(actionId);
      } else {
        actions.remove(actionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleId = widget.initialRole?.id;
    return AppModuleDialog(
      key: Key(
        roleId == null
            ? 'settingsRoleDialog_new'
            : 'settingsRoleDialog_$roleId',
      ),
      title: _isEditing ? 'تعديل الدور والصلاحيات' : 'إضافة دور',
      subtitle: 'حدد صلاحيات كل شاشة وإجراء بشكل مستقل',
      icon: Icons.admin_panel_settings_outlined,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 980,
      maxHeightFactor: 0.94,
      actions: [
        AppButton(
          key: const Key('settingsRoleDialogCancelButton'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: const Key('settingsRoleDialogConfirmButton'),
          label: _isEditing ? 'تحديث' : 'إضافة',
          icon: _isEditing ? Icons.refresh_rounded : Icons.add_rounded,
          variant: _isEditing
              ? AppButtonVariant.success
              : AppButtonVariant.primary,
          width: 145,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            fieldKey: const Key('settingsRoleNameField'),
            controller: _nameController,
            label: 'اسم الدور',
            icon: Icons.badge_outlined,
            accentColor: widget.accentColor,
            errorText: _nameError,
            autofocus: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'مصفوفة صلاحيات الشاشات والإجراءات',
                  style: AppTypography.sectionTitle,
                ),
              ),
              AppRegularButton(
                key: const Key('settingsRoleSelectAllButton'),
                label: 'تحديد الكل',
                icon: Icons.done_all_rounded,
                onPressed: () => _setAllPermissions(true),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppRegularButton(
                key: const Key('settingsRoleClearAllButton'),
                label: 'إلغاء الكل',
                icon: Icons.remove_done_rounded,
                onPressed: () => _setAllPermissions(false),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPermissionMatrix(),
        ],
      ),
    );
  }

  Widget _buildPermissionMatrix() {
    final borderColor = Color.lerp(
      widget.accentColor,
      AppColors.surface,
      0.62,
    )!;
    final headerColor = Color.alphaBlend(
      widget.accentColor.withAlpha(18),
      AppColors.surface,
    );

    Widget cell(Widget child, {double height = 46}) {
      return SizedBox(
        height: height,
        child: Center(child: child),
      );
    }

    return ClipRRect(
      key: const Key('settingsRolePermissionMatrix'),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1040,
          child: Table(
            textDirection: TextDirection.rtl,
            border: TableBorder.all(color: borderColor),
            columnWidths: const {
              0: FixedColumnWidth(190),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
              5: FlexColumnWidth(),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: headerColor),
                children: [
                  cell(
                    const Text(
                      'الشاشة',
                      style: AppTypography.tableHeader,
                    ),
                    height: 50,
                  ),
                  for (final action in _settingsPermissionActions)
                    cell(
                      Text(
                        action.label,
                        style: AppTypography.tableHeader,
                      ),
                      height: 50,
                    ),
                ],
              ),
              for (final screen in _settingsPermissionScreens)
                TableRow(
                  children: [
                    cell(
                      Text(
                        screen.label,
                        style: AppTypography.fieldText,
                      ),
                    ),
                    for (final action in _settingsPermissionActions)
                      cell(
                        Checkbox(
                          key: Key(
                            'settingsRolePermission_'
                            '${screen.id}_${action.id}',
                          ),
                          value: _permissions[screen.id]?.contains(
                                action.id,
                              ) ??
                              false,
                          activeColor: widget.accentColor,
                          onChanged: (value) => _togglePermission(
                            screen.id,
                            action.id,
                            value ?? false,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsUserDialog extends StatefulWidget {
  const _SettingsUserDialog({
    required this.accentColor,
    required this.roles,
    required this.existingUsernames,
    this.initialUser,
  }) : assert(roles.length > 0);

  final Color accentColor;
  final List<_SettingsRole> roles;
  final Set<String> existingUsernames;
  final _SettingsUser? initialUser;

  @override
  State<_SettingsUserDialog> createState() =>
      _SettingsUserDialogState();
}

class _SettingsUserDialogState extends State<_SettingsUserDialog> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late final Set<EntityId> _roleIds;

  bool get _isEditing => widget.initialUser != null;

  String? get _usernameError {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) return null;
    if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(username)) {
      return 'استخدم أحرفاً إنجليزية وأرقاماً و . _ - فقط';
    }
    if (widget.existingUsernames.contains(username)) {
      return 'اسم المستخدم مستخدم مسبقاً';
    }
    return null;
  }

  String? get _passwordError {
    if (_isEditing || _passwordController.text.isEmpty) return null;
    return PasswordPolicy.validationMessage(_passwordController.text);
  }

  String? get _confirmationError {
    if (_isEditing || _confirmationController.text.isEmpty) return null;
    return _confirmationController.text == _passwordController.text
        ? null
        : 'كلمتا المرور غير متطابقتين';
  }

  bool get _canSave =>
      _fullNameController.text.trim().isNotEmpty &&
      _usernameController.text.trim().isNotEmpty &&
      _usernameError == null &&
      _roleIds.isNotEmpty &&
      (_isEditing ||
          (_passwordController.text.isNotEmpty &&
              _confirmationController.text.isNotEmpty &&
              _passwordError == null &&
              _confirmationError == null));

  @override
  void initState() {
    super.initState();
    final initial = widget.initialUser;
    _fullNameController = TextEditingController(text: initial?.fullName ?? '');
    _usernameController = TextEditingController(text: initial?.username ?? '');
    _roleIds = initial == null
        ? {widget.roles.firstWhere(
            (role) => role.name == 'المبيعات',
            orElse: () => widget.roles.first,
          ).id}
        : {...initial.roleIds};
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsUserDraft(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        roleIds: Set.unmodifiable(_roleIds),
        initialPassword: _isEditing ? null : _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: Key(_isEditing ? 'settingsEditUserDialog' : 'settingsAddUserDialog'),
      title: _isEditing ? 'تعديل المستخدم' : 'إضافة مستخدم',
      subtitle: _isEditing
          ? 'حدّث بيانات الحساب وأدواره باستخدام المعرّف المستقر نفسه'
          : 'أنشئ الحساب وكلمة مروره الأولية ضمن عملية واحدة',
      icon: Icons.person_add_alt_1_rounded,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 720,
      actions: [
        AppButton(
          key: const Key('settingsAddUserCancelButton'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: Key(
            _isEditing
                ? 'settingsEditUserConfirmButton'
                : 'settingsAddUserConfirmButton',
          ),
          label: _isEditing ? 'تحديث' : 'إضافة',
          icon: _isEditing ? Icons.refresh_rounded : Icons.add_rounded,
          variant: _isEditing
              ? AppButtonVariant.success
              : AppButtonVariant.primary,
          width: 145,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: Column(
        children: [
          AppTextField(
            fieldKey: const Key('settingsAddUserFullNameField'),
            controller: _fullNameController,
            label: 'الاسم الكامل',
            icon: Icons.badge_outlined,
            accentColor: widget.accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('settingsAddUserUsernameField'),
            controller: _usernameController,
            label: 'اسم المستخدم',
            icon: Icons.alternate_email_rounded,
            accentColor: widget.accentColor,
            errorText: _usernameError,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            enabled: !(widget.initialUser?.isSystemUser ?? false),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'الأدوار',
              prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
              errorText: _roleIds.isEmpty ? 'اختر دوراً واحداً على الأقل' : null,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final role in widget.roles)
                  FilterChip(
                    key: Key('settingsUserRole_${role.keySuffix}'),
                    label: Text(role.name),
                    selected: _roleIds.contains(role.id),
                    onSelected: widget.initialUser?.isSystemUser ?? false
                        ? null
                        : (selected) => setState(() {
                            if (selected) {
                              _roleIds.add(role.id);
                            } else {
                              _roleIds.remove(role.id);
                            }
                          }),
                  ),
              ],
            ),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('settingsAddUserPasswordField'),
              controller: _passwordController,
              label: 'كلمة المرور الأولية',
              icon: Icons.password_rounded,
              accentColor: widget.accentColor,
              obscureText: true,
              errorText: _passwordError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('settingsAddUserPasswordConfirmField'),
              controller: _confirmationController,
              label: 'تأكيد كلمة المرور',
              icon: Icons.verified_user_outlined,
              accentColor: widget.accentColor,
              obscureText: true,
              errorText: _confirmationError,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
          ],
        ],
      ),
    );
  }
}
