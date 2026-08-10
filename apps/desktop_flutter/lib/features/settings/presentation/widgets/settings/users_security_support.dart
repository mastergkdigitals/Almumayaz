part of '../settings_sections.dart';

class _SettingsUser {
  const _SettingsUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.isEnabled,
    required this.isLocked,
    required this.lastLogin,
  });

  final int id;
  final String fullName;
  final String username;
  final String role;
  final bool isEnabled;
  final bool isLocked;
  final String lastLogin;

  _SettingsUser copyWith({
    String? role,
    bool? isEnabled,
    bool? isLocked,
  }) {
    return _SettingsUser(
      id: id,
      fullName: fullName,
      username: username,
      role: role ?? this.role,
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      lastLogin: lastLogin,
    );
  }
}
class _SettingsRole {
  _SettingsRole({
    required this.id,
    required this.name,
    required this.permissions,
  });

  final int id;
  final String name;
  final Map<String, Set<String>> permissions;
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

Map<String, Set<String>> _allSettingsRolePermissions() {
  return {
    for (final screen in _settingsPermissionScreens)
      screen.id: {..._allPermissionActionIds},
  };
}

Map<String, Set<String>> _viewOnlySettingsRolePermissions() {
  return {
    for (final screen in _settingsPermissionScreens) screen.id: {'view'},
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
  });

  final int id;
  final String createdAt;
  final String username;
  final String type;
  final String details;
  final String status;
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
    id: int.tryParse(role.id.value.split('-').last) ?? 1,
    name: role.name,
    permissions: permissions,
  );
}

AppRole _appRoleFromSettings(_SettingsRole role) {
  final permissions = <PermissionCode>{};
  for (final entry in role.permissions.entries) {
    for (final actionId in entry.value) {
      final action = _permissionActionValue(actionId);
      if (action != null) {
        permissions.add(PermissionCode(module: entry.key, action: action));
      }
    }
  }
  return AppRole(
    id: EntityId.demo('role', role.id),
    name: role.name,
    permissions: permissions,
    isSystemRole: role.id == 1,
  );
}

_SettingsUser _settingsUserFromDomain(
  AppUser user,
  Map<EntityId, String> roleNames,
) {
  final roleName = user.roleIds
          .map((roleId) => roleNames[roleId])
          .whereType<String>()
          .firstOrNull ??
      'دور غير معروف';
  final (isEnabled, isLocked) = switch (user.status) {
    UserAccountStatus.active => (true, false),
    UserAccountStatus.disabled => (false, false),
    UserAccountStatus.locked => (true, true),
    UserAccountStatus.disabledAndLocked => (false, true),
  };
  return _SettingsUser(
    id: int.tryParse(user.id.value.split('-').last) ?? 1,
    fullName: user.fullName,
    username: user.username,
    role: roleName,
    isEnabled: isEnabled,
    isLocked: isLocked,
    lastLogin: user.lastLoginAt == null
        ? 'لم يسجل الدخول'
        : _formatAuditTimestamp(user.lastLoginAt!),
  );
}

AppUser _appUserFromSettings(_SettingsUser user, int roleId) {
  return AppUser(
    id: EntityId.demo('user', user.id),
    fullName: user.fullName,
    username: user.username,
    roleIds: {EntityId.demo('role', roleId)},
    status: _userStatusValue(
      isEnabled: user.isEnabled,
      isLocked: user.isLocked,
    ),
    isSystemUser: user.username == 'admin',
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
    id: int.tryParse(record.id.value.split('-').last) ??
        record.id.value.hashCode.abs(),
    createdAt: _formatAuditTimestamp(record.occurredAt),
    username: record.actorUsername,
    type: _auditActionLabel(record.action),
    details: record.summary,
    status: switch (record.outcome) {
      AuditOutcome.success => 'مكتمل',
      AuditOutcome.failure => 'فشل',
      AuditOutcome.blocked => 'محظور',
    },
  );
}

String _auditActionLabel(AuditAction action) => switch (action) {
      AuditAction.signIn => 'تسجيل الدخول',
      AuditAction.signOut => 'تسجيل الخروج',
      AuditAction.create => 'إضافة',
      AuditAction.update => 'تعديل',
      AuditAction.delete => 'حذف',
      AuditAction.restore => 'استعادة',
      AuditAction.print => 'طباعة',
      AuditAction.export => 'تصدير',
      AuditAction.permissionChange => 'صلاحيات',
      AuditAction.accountStatusChange => 'حالة حساب',
      AuditAction.backup => 'نسخ احتياطي',
      AuditAction.other => 'أخرى',
    };

AuditAction? _auditActionForLabel(String label) => switch (label) {
      'تسجيل الدخول' => AuditAction.signIn,
      'تعديل' => AuditAction.update,
      'حذف' => AuditAction.delete,
      'استعادة' => AuditAction.restore,
      _ => null,
    };

String _sessionStateLabel(SessionState state) => switch (state) {
      SessionState.active => 'نشطة',
      SessionState.locked => 'مقفلة',
      SessionState.expired => 'منتهية',
      SessionState.signedOut => 'مسجل خروجها',
    };

class _SettingsUserDraft {
  const _SettingsUserDraft({
    required this.fullName,
    required this.username,
    required this.role,
  });

  final String fullName;
  final String username;
  final String role;
}

class _SettingsUserPasswordDraft {
  const _SettingsUserPasswordDraft({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
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
  late final TextEditingController _currentPasswordController;
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
      _currentPasswordController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _passwordController.text.length >= 6 &&
      _confirmationController.text.isNotEmpty &&
      _confirmationError == null;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController(
      text: widget.user.username == 'admin' ? 'password' : 'demo123',
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsUserPasswordDraft(
        currentPassword: _currentPasswordController.text,
        newPassword: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.id;
    return AppModuleDialog(
      key: Key('settingsUserPasswordDialog_$userId'),
      title: 'تغيير كلمة مرور المستخدم',
      subtitle: '${widget.user.fullName} — بيانات اعتماد تجريبية فقط',
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
            fieldKey: Key('settingsUserPasswordCurrentField_$userId'),
            controller: _currentPasswordController,
            label: 'كلمة المرور الحالية',
            icon: Icons.lock_outline_rounded,
            accentColor: widget.accentColor,
            obscureText: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
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
    required this.roleNames,
    required this.existingUsernames,
  }) : assert(roleNames.length > 0);

  final Color accentColor;
  final List<String> roleNames;
  final Set<String> existingUsernames;

  @override
  State<_SettingsUserDialog> createState() =>
      _SettingsUserDialogState();
}

class _SettingsUserDialogState extends State<_SettingsUserDialog> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  late String _role;

  String? get _usernameError {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) return null;
    return widget.existingUsernames.contains(username)
        ? 'اسم المستخدم مستخدم مسبقاً'
        : null;
  }

  bool get _canSave =>
      _fullNameController.text.trim().isNotEmpty &&
      _usernameController.text.trim().isNotEmpty &&
      _usernameError == null;

  @override
  void initState() {
    super.initState();
    _role = widget.roleNames.contains('المبيعات')
        ? 'المبيعات'
        : widget.roleNames.first;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsUserDraft(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('settingsAddUserDialog'),
      title: 'إضافة مستخدم',
      subtitle: 'نموذج تجريبي لبيانات الحساب الأساسية',
      icon: Icons.person_add_alt_1_rounded,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 620,
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
          key: const Key('settingsAddUserConfirmButton'),
          label: 'إضافة',
          icon: Icons.add_rounded,
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
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<String>(
            fieldKey: const Key('settingsAddUserRoleField'),
            label: 'الدور',
            icon: Icons.admin_panel_settings_outlined,
            accentColor: widget.accentColor,
            value: _role,
            options: [
              for (final roleName in widget.roleNames)
                AppDropdownOption(value: roleName, label: roleName),
            ],
            useIntrinsicHeight: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            menuTextDirection: TextDirection.rtl,
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
          ),
        ],
      ),
    );
  }
}
