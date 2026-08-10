import 'dart:async';

import '../../../core/data/demo_transaction_runner.dart';
import '../../../core/domain/business_values.dart';
import '../../audit_log/domain/audit_models.dart';
import '../../permissions/domain/permission_models.dart';
import '../../users/domain/user_models.dart';
import '../domain/session_models.dart';

/// One coherent in-memory identity projection for the Flutter demo.
///
/// Every identity adapter in an application composition must receive the same
/// instance. The API-backed implementation will replace this state with
/// authoritative server transactions without changing presentation code.
class DemoIdentityState {
  DemoIdentityState({
    Iterable<AppUser>? initialUsers,
    Iterable<AppRole>? initialRoles,
    Iterable<AuditRecord>? initialAuditRecords,
    AutoLockPolicy? initialPolicy,
    AuditTimestamp Function()? clock,
  })  : usersById = {
          for (final user in initialUsers ?? demoIdentityUsers()) user.id: user,
        },
        rolesById = {
          for (final role in initialRoles ?? demoIdentityRoles()) role.id: role,
        },
        auditRecords = List<AuditRecord>.of(
          initialAuditRecords ?? demoIdentityAuditRecords(),
        ),
        autoLockPolicy = initialPolicy ??
            AutoLockPolicy(
              isEnabled: true,
              idleTimeout: const Duration(minutes: 15),
            ),
        _clock = clock ?? _DemoIdentityClock().call {
    if (initialUsers == null) {
      credentialsByUserId.addAll(_seedCredentials());
    }
    _nextUserSequence = _nextSequence(usersById.keys, fallback: 4);
    _nextRoleSequence = _nextSequence(rolesById.keys, fallback: 5);
    _nextAuditSequence = _nextSequence(
      auditRecords.map((record) => record.id),
      fallback: 6,
    );
  }

  final DemoTransactionRunner transactionRunner = DemoTransactionRunner();
  final Map<EntityId, AppUser> usersById;
  final Map<EntityId, AppRole> rolesById;
  final Map<EntityId, DemoPasswordCredential> credentialsByUserId = {};
  final List<AuditRecord> auditRecords;
  final AuditTimestamp Function() _clock;

  AutoLockPolicy autoLockPolicy;
  AppSession? currentSession;
  late int _nextUserSequence;
  late int _nextRoleSequence;
  late int _nextAuditSequence;
  var _nextSessionSequence = 1;
  var _nextRequestSequence = 1;

  AuditTimestamp now() => _clock();

  EntityId nextUserId() => EntityId.demo('user', _nextUserSequence++);

  EntityId nextRoleId() => EntityId.demo('role', _nextRoleSequence++);

  EntityId nextSessionId() =>
      EntityId.demo('session', _nextSessionSequence++);

  void observeUserId(EntityId id) {
    _nextUserSequence = _sequenceAfter(id, current: _nextUserSequence);
  }

  void observeRoleId(EntityId id) {
    _nextRoleSequence = _sequenceAfter(id, current: _nextRoleSequence);
  }

  void observeAuditId(EntityId id) {
    _nextAuditSequence = _sequenceAfter(id, current: _nextAuditSequence);
  }

  Set<PermissionCode> permissionsFor(AppUser user) {
    return {
      for (final roleId in user.roleIds)
        ...?rolesById[roleId]?.permissions,
    };
  }

  List<EntityId> missingRoleIds(AppUser user) {
    return [
      for (final roleId in user.roleIds)
        if (!rolesById.containsKey(roleId)) roleId,
    ];
  }

  AuditRecord appendAudit({
    required EntityId? actorUserId,
    required String actorUsername,
    required AuditAction action,
    required AuditOutcome outcome,
    required String summary,
    Map<String, Object?> details = const {},
    Map<String, Object?> before = const {},
    Map<String, Object?> after = const {},
    String? entityType,
    EntityId? entityId,
  }) {
    final record = AuditRecord(
      id: EntityId.demo('audit', _nextAuditSequence++),
      occurredAt: now(),
      actorUserId: actorUserId,
      actorUsername: actorUsername,
      action: action,
      outcome: outcome,
      summary: summary,
      details: details,
      metadata: AuditMetadata(
        deviceId: 'demo-windows-device',
        requestId: 'demo-request-${_nextRequestSequence++}',
        before: Map<String, Object?>.unmodifiable(before),
        after: Map<String, Object?>.unmodifiable(after),
      ),
      entityType: entityType,
      entityId: entityId,
    );
    auditRecords.add(record);
    return record;
  }

  Future<T> mutate<T>(FutureOr<T> Function() action) {
    return transactionRunner.run(action);
  }
}

class DemoPasswordCredential {
  const DemoPasswordCredential({
    required this.salt,
    required this.digest,
  });

  factory DemoPasswordCredential.fromPassword({
    required String salt,
    required String password,
  }) {
    return DemoPasswordCredential(
      salt: salt,
      digest: _demoPasswordDigest(salt, password),
    );
  }

  final String salt;
  final String digest;

  bool verifies(String password) =>
      digest == _demoPasswordDigest(salt, password);
}

List<AppUser> demoIdentityUsers() => [
      AppUser(
        id: EntityId.demo('user', 1),
        fullName: 'مدير النظام',
        username: 'admin',
        roleIds: {EntityId.demo('role', 1)},
        status: UserAccountStatus.active,
        isSystemUser: true,
        lastLoginAt: AuditTimestamp(DateTime.utc(2026, 7, 29, 6, 2)),
      ),
      AppUser(
        id: EntityId.demo('user', 2),
        fullName: 'أحمد كريم',
        username: 'ahmed',
        roleIds: {EntityId.demo('role', 2)},
        status: UserAccountStatus.active,
        isSystemUser: false,
        lastLoginAt: AuditTimestamp(DateTime.utc(2026, 7, 28, 14, 40)),
      ),
      AppUser(
        id: EntityId.demo('user', 3),
        fullName: 'سارة علي',
        username: 'sara',
        roleIds: {EntityId.demo('role', 3)},
        status: UserAccountStatus.locked,
        isSystemUser: false,
        lastLoginAt: AuditTimestamp(DateTime.utc(2026, 7, 26, 8, 20)),
      ),
    ];

List<AppRole> demoIdentityRoles() => [
      AppRole(
        id: EntityId.demo('role', 1),
        name: 'مدير النظام',
        permissions: _permissionsFor(
          modules: _demoModules,
          actions: PermissionAction.values,
        ),
        isSystemRole: true,
      ),
      AppRole(
        id: EntityId.demo('role', 2),
        name: 'المبيعات',
        permissions: {
          ..._permissionsFor(
            modules: const ['sales'],
            actions: PermissionAction.values,
          ),
          ..._permissionsFor(
            modules: const ['parties'],
            actions: const [PermissionAction.view, PermissionAction.update],
          ),
          ..._permissionsFor(
            modules: const ['reports'],
            actions: const [PermissionAction.view, PermissionAction.print],
          ),
        },
        isSystemRole: false,
      ),
      AppRole(
        id: EntityId.demo('role', 3),
        name: 'الحسابات',
        permissions: {
          ..._permissionsFor(
            modules: const ['cashbox'],
            actions: PermissionAction.values,
          ),
          ..._permissionsFor(
            modules: const ['parties'],
            actions: const [PermissionAction.view],
          ),
          ..._permissionsFor(
            modules: const ['reports'],
            actions: const [PermissionAction.view, PermissionAction.print],
          ),
        },
        isSystemRole: false,
      ),
      AppRole(
        id: EntityId.demo('role', 4),
        name: 'عرض فقط',
        permissions: _permissionsFor(
          modules: _demoModules,
          actions: const [PermissionAction.view],
        ),
        isSystemRole: false,
      ),
    ];

List<AuditRecord> demoIdentityAuditRecords() => [
      _seedAudit(
        sequence: 1,
        occurredAt: DateTime.utc(2026, 7, 29, 6, 2),
        actorUserId: EntityId.demo('user', 1),
        actorUsername: 'admin',
        action: AuditAction.signIn,
        outcome: AuditOutcome.success,
        summary: 'تسجيل دخول ناجح من جهاز المكتب الرئيسي',
      ),
      _seedAudit(
        sequence: 2,
        occurredAt: DateTime.utc(2026, 7, 29, 6, 18),
        actorUserId: EntityId.demo('user', 1),
        actorUsername: 'admin',
        action: AuditAction.update,
        outcome: AuditOutcome.success,
        summary: 'تعديل بيانات المادة: ورق A4',
        entityType: 'item',
        entityId: EntityId.demo('item', 1),
      ),
      _seedAudit(
        sequence: 3,
        occurredAt: DateTime.utc(2026, 7, 29, 6, 27),
        actorUserId: EntityId.demo('user', 2),
        actorUsername: 'ahmed',
        action: AuditAction.delete,
        outcome: AuditOutcome.success,
        summary: 'حذف قائمة بيع تجريبية رقم 1042',
        entityType: 'sale',
        entityId: EntityId.demo('sale', 1),
      ),
      _seedAudit(
        sequence: 4,
        occurredAt: DateTime.utc(2026, 7, 29, 6, 31),
        actorUserId: EntityId.demo('user', 1),
        actorUsername: 'admin',
        action: AuditAction.restore,
        outcome: AuditOutcome.success,
        summary: 'استعادة قائمة البيع رقم 1042',
        entityType: 'sale',
        entityId: EntityId.demo('sale', 1),
      ),
      _seedAudit(
        sequence: 5,
        occurredAt: DateTime.utc(2026, 7, 28, 13, 12),
        actorUserId: EntityId.demo('user', 3),
        actorUsername: 'sara',
        action: AuditAction.signIn,
        outcome: AuditOutcome.failure,
        summary: 'محاولة دخول بكلمة مرور غير صحيحة',
      ),
    ];

const _demoModules = [
  'sales',
  'purchases',
  'parties',
  'cashbox',
  'warehouses',
  'items',
  'reports',
  'settings',
];

Map<EntityId, DemoPasswordCredential> _seedCredentials() => {
      EntityId.demo('user', 1): const DemoPasswordCredential(
        salt: 'almumayaz-demo-user-1',
        digest: 'dada67c523069e45',
      ),
      EntityId.demo('user', 2): const DemoPasswordCredential(
        salt: 'almumayaz-demo-user-2',
        digest: 'e5141f0e261bdf10',
      ),
      EntityId.demo('user', 3): const DemoPasswordCredential(
        salt: 'almumayaz-demo-user-3',
        digest: '3820044c0a7546ef',
      ),
    };

Set<PermissionCode> _permissionsFor({
  required Iterable<String> modules,
  required Iterable<PermissionAction> actions,
}) {
  return {
    for (final module in modules)
      for (final action in actions)
        PermissionCode(module: module, action: action),
  };
}

AuditRecord _seedAudit({
  required int sequence,
  required DateTime occurredAt,
  required EntityId actorUserId,
  required String actorUsername,
  required AuditAction action,
  required AuditOutcome outcome,
  required String summary,
  String? entityType,
  EntityId? entityId,
}) {
  return AuditRecord(
    id: EntityId.demo('audit', sequence),
    occurredAt: AuditTimestamp(occurredAt),
    actorUserId: actorUserId,
    actorUsername: actorUsername,
    action: action,
    outcome: outcome,
    summary: summary,
    details: const {'device': 'desktop-demo-01'},
    metadata: AuditMetadata(
      deviceId: 'desktop-demo-01',
      requestId: 'demo-seed-request-$sequence',
    ),
    entityType: entityType,
    entityId: entityId,
  );
}

int _nextSequence(Iterable<EntityId> ids, {required int fallback}) {
  var next = fallback;
  for (final id in ids) {
    final sequence = int.tryParse(id.value.split('-').last);
    if (sequence != null && sequence >= next) next = sequence + 1;
  }
  return next;
}

int _sequenceAfter(EntityId id, {required int current}) {
  final sequence = int.tryParse(id.value.split('-').last);
  return sequence != null && sequence >= current ? sequence + 1 : current;
}

String _demoPasswordDigest(String salt, String password) {
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.from(0x100000001b3);
  final unsigned64Mask = (BigInt.one << 64) - BigInt.one;
  for (final unit in '$salt:$password'.codeUnits) {
    hash ^= BigInt.from(unit);
    hash = (hash * prime) & unsigned64Mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

class _DemoIdentityClock {
  var _minute = 0;

  AuditTimestamp call() => AuditTimestamp(
        DateTime.utc(2026, 8, 10, 12).add(Duration(minutes: _minute++)),
      );
}
