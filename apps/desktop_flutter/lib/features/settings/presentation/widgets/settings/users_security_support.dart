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

class _SettingsAuditActorSnapshot {
  const _SettingsAuditActorSnapshot({
    required this.id,
    required this.username,
    this.fullName,
  });

  final EntityId id;
  final String username;
  final String? fullName;
}

const _settingsAuditEntityTypes = <({String id, String label})>[
  (id: 'user', label: 'مستخدم'),
  (id: 'role', label: 'دور وصلاحيات'),
  (id: 'session', label: 'جلسة'),
  (id: 'session_policy', label: 'سياسة الجلسة'),
  (id: 'party', label: 'طرف'),
  (id: 'item', label: 'مادة'),
  (id: 'warehouse', label: 'مخزن'),
  (id: 'inventory_transfer', label: 'نقل مخزني'),
  (id: 'sales_invoice', label: 'قائمة بيع'),
  (id: 'purchase_invoice', label: 'قائمة شراء'),
  (id: 'cashbox_voucher', label: 'سند صندوق'),
  (id: 'installment_entry', label: 'دفعة قسط'),
  (id: 'operational_master_data', label: 'بيانات أساسية'),
  (id: 'business_policy_settings', label: 'سياسات العمل'),
  (id: 'operational_defaults', label: 'إعدادات افتراضية'),
  (id: 'device_settings', label: 'إعدادات الجهاز'),
  (id: 'backupConfiguration', label: 'إعدادات النسخ الاحتياطي'),
  (id: 'backupCloudConnection', label: 'اتصال النسخ السحابي'),
  (id: 'backup', label: 'نسخة احتياطية'),
  (id: 'archiveDocument', label: 'مستند أرشيف'),
  (id: 'applicationData', label: 'بيانات التطبيق'),
];

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
    final ipAddress = record.metadata.ipAddress;
    final macAddress = record.metadata.macAddress;
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
            _AuditDetailLine(
              label: 'معرّف سجل التدقيق',
              value: record.id.value,
              valueTextDirection: TextDirection.ltr,
            ),
            _AuditDetailLine(
              label: 'التاريخ والوقت',
              value: _formatAuditTimestamp(record.occurredAt),
              valueTextDirection: TextDirection.ltr,
            ),
            _AuditDetailLine(
              label: 'المستخدم',
              value: record.actorUsername,
              valueTextDirection: _auditTextDirection(record.actorUsername),
            ),
            _AuditDetailLine(
              label: 'معرّف المستخدم',
              value: record.actorUserId?.value ??
                  'غير مرتبط بمستخدم مسجل',
              valueTextDirection: record.actorUserId == null
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            ),
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
              valueTextDirection: TextDirection.ltr,
            ),
            _AuditDetailLine(
              label: 'معرّف الطلب',
              value: record.metadata.requestId,
              valueTextDirection: TextDirection.ltr,
            ),
            if (ipAddress != null && ipAddress.trim().isNotEmpty)
              _AuditDetailLine(
                label: 'عنوان IP',
                value: ipAddress,
                valueTextDirection: TextDirection.ltr,
              ),
            if (macAddress != null && macAddress.trim().isNotEmpty)
              _AuditDetailLine(
                label: 'عنوان MAC',
                value: macAddress,
                valueTextDirection: TextDirection.ltr,
              ),
            if (record.entityType != null)
              _AuditDetailLine(
                label: 'نوع السجل المرتبط',
                value: _auditEntityTypeLabel(record.entityType!),
              ),
            if (record.entityId != null)
              _AuditDetailLine(
                label: 'معرّف السجل المرتبط',
                value: record.entityId!.value,
                valueTextDirection: TextDirection.ltr,
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
  const _AuditDetailLine({
    required this.label,
    required this.value,
    this.valueTextDirection = TextDirection.rtl,
  });

  final String label;
  final String value;
  final TextDirection valueTextDirection;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: Text(
                  '$label:',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Directionality(
                  textDirection: valueTextDirection,
                  child: Text(
                    value,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _auditMapText(Map<String, Object?> values) {
  if (values.isEmpty) return 'لا توجد بيانات';
  return values.entries
      .map(
        (entry) =>
            '${_auditDetailKeyLabel(entry.key)}: '
            '${_auditDetailValueText(entry.value)}',
      )
      .join('، ');
}

String _auditRowSemanticLabel(_SettingsAuditEntry entry) {
  return '${entry.createdAt}، المستخدم ${entry.username}، '
      'العملية ${entry.type}، ${entry.details}، '
      'النتيجة ${entry.status}';
}

TextDirection _auditTextDirection(String value) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(value)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

String _auditEntityTypeLabel(String entityType) {
  return _settingsAuditEntityTypes
          .where((option) => option.id == entityType)
          .firstOrNull
          ?.label ??
      _ltrAuditText(entityType);
}

String _auditDetailKeyLabel(String key) => switch (key) {
      'reason' => 'السبب',
      'fullName' => 'الاسم الكامل',
      'username' => 'اسم المستخدم',
      'roleIds' => 'الأدوار',
      'permissions' => 'الصلاحيات',
      'status' => 'الحالة',
      'lastLoginAt' => 'آخر دخول',
      'enabled' => 'مفعّل',
      'idleMinutes' => 'مدة الخمول بالدقائق',
      'mode' => 'الوضع',
      'name' => 'الاسم',
      'number' => 'الرقم',
      'documentNumber' => 'رقم المستند',
      'currency' => 'العملة',
      'amount' => 'المبلغ',
      'total' => 'المجموع',
      'fileName' => 'اسم الملف',
      'path' => 'المسار',
      _ => _ltrAuditText(key),
    };

String _auditDetailValueText(Object? value) {
  if (value == null) return '—';
  if (value is bool) return value ? 'نعم' : 'لا';
  if (value is EntityId) return _ltrAuditText(value.value);
  if (value is Map<Object?, Object?>) {
    return value.entries
        .map(
          (entry) =>
              '${_auditDetailKeyLabel(entry.key.toString())} '
              '${_auditDetailValueText(entry.value)}',
        )
        .join('، ');
  }
  if (value is Iterable<Object?>) {
    return value.map(_auditDetailValueText).join('، ');
  }
  final text = value.toString();
  final localized = switch (text) {
    'invalid_credentials' => 'بيانات الاعتماد غير صحيحة',
    'account_disabled' => 'الحساب معطل',
    'account_locked' => 'الحساب مقفل',
    'account_disabled_locked' => 'الحساب معطل ومقفل',
    'missing_role_reference' => 'مرجع دور مفقود',
    'active' => 'نشط',
    'disabled' => 'معطل',
    'locked' => 'مقفل',
    'disabledAndLocked' => 'معطل ومقفل',
    'userRequest' => 'طلب المستخدم',
    'idleTimeout' => 'انتهاء مدة الخمول',
    'systemLock' => 'قفل النظام',
    'securityPolicy' => 'سياسة الأمان',
    'administrator_reset' => 'إعادة تعيين بواسطة المدير',
    _ => null,
  };
  if (localized != null) return localized;
  return _auditTextDirection(text) == TextDirection.ltr
      ? _ltrAuditText(text)
      : text;
}

String _ltrAuditText(String value) => '\u2066$value\u2069';
