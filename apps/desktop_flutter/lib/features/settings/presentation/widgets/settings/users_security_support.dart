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
