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
    Map<EntityId, DemoPasswordCredential>? initialCredentials,
    AutoLockPolicy? initialPolicy,
    AuditTimestamp Function()? clock,
    DemoTransactionRunner? transactionRunner,
    int nextUserSequenceFallback = 4,
    int nextRoleSequenceFallback = 5,
    int nextAuditSequenceFallback = 6,
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
        transactionRunner = transactionRunner ?? DemoTransactionRunner(),
        _clock = clock ?? _DemoIdentityClock().call {
    if (initialCredentials != null) {
      credentialsByUserId.addAll(initialCredentials);
    } else if (initialUsers == null) {
      credentialsByUserId.addAll(_seedCredentials());
    }
    _nextUserSequence = _nextSequence(
      usersById.keys,
      fallback: nextUserSequenceFallback,
    );
    _nextRoleSequence = _nextSequence(
      rolesById.keys,
      fallback: nextRoleSequenceFallback,
    );
    _nextAuditSequence = _nextSequence(
      auditRecords.map((record) => record.id),
      fallback: nextAuditSequenceFallback,
    );
    _nextRequestSequence = _nextDemoRequestSequence(
      auditRecords,
      fallback: 1,
    );
    _lastIssuedTimestamp = _latestAuditTimestamp(auditRecords);
  }

  /// Minimal identity seed retained after an internal full-data clear.
  ///
  /// It intentionally contains no session or audit trail, but preserves the
  /// protected administrator credential so the application is recoverable
  /// immediately after the successful operation signs the current user out.
  factory DemoIdentityState.bootstrap({
    AuditTimestamp Function()? clock,
    DemoTransactionRunner? transactionRunner,
  }) {
    final administratorId = EntityId.demo('user', 1);
    final administratorRoleId = EntityId.demo('role', 1);
    return DemoIdentityState(
      initialUsers: [
        AppUser(
          id: administratorId,
          fullName: 'مدير النظام',
          username: 'admin',
          roleIds: {administratorRoleId},
          status: UserAccountStatus.active,
          isSystemUser: true,
          lastLoginAt: null,
        ),
      ],
      initialRoles: [
        AppRole(
          id: administratorRoleId,
          name: 'مدير النظام',
          permissions: _permissionsFor(
            modules: _demoModules,
            actions: PermissionAction.values,
          ),
          isSystemRole: true,
        ),
      ],
      initialAuditRecords: const [],
      initialCredentials: {
        administratorId: _seedCredentials()[administratorId]!,
      },
      nextUserSequenceFallback: 2,
      nextRoleSequenceFallback: 2,
      nextAuditSequenceFallback: 1,
      clock: clock,
      transactionRunner: transactionRunner,
    );
  }

  final DemoTransactionRunner transactionRunner;
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
  AuditTimestamp? _lastIssuedTimestamp;

  AuditTimestamp now() {
    final candidate = _clock();
    final last = _lastIssuedTimestamp;
    final resolved = last != null && candidate.compareTo(last) <= 0
        ? AuditTimestamp(last.value.add(const Duration(microseconds: 1)))
        : candidate;
    _lastIssuedTimestamp = resolved;
    return resolved;
  }

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

  /// Returns the immutable records that must survive an internal graph swap.
  List<AuditRecord> auditHistorySnapshot() =>
      List<AuditRecord>.unmodifiable(auditRecords);

  /// Installs permanent history into an offline replacement identity graph.
  ///
  /// The replacement must not own a session yet. Sequence cursors are rebuilt
  /// from the carried records so the transition event appended next receives
  /// fresh audit and request identifiers.
  void replaceAuditHistoryForDataReplacement(
    Iterable<AuditRecord> records,
  ) {
    if (currentSession != null) {
      throw StateError(
        'Audit history can only be installed into an offline identity graph.',
      );
    }
    final snapshot = List<AuditRecord>.unmodifiable(records);
    final auditIds = {for (final record in snapshot) record.id};
    if (auditIds.length != snapshot.length) {
      throw StateError('Cannot carry audit history with duplicate record IDs.');
    }
    final requestIds = {
      for (final record in snapshot) record.metadata.requestId,
    };
    if (requestIds.length != snapshot.length) {
      throw StateError('Cannot carry audit history with duplicate request IDs.');
    }
    auditRecords
      ..clear()
      ..addAll(snapshot);
    _nextAuditSequence = _nextSequence(
      auditRecords.map((record) => record.id),
      fallback: 1,
    );
    _nextRequestSequence = _nextDemoRequestSequence(
      auditRecords,
      fallback: 1,
    );
    _lastIssuedTimestamp = _latestAuditTimestamp(auditRecords);
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
    final record = prepareAudit(
      actorUserId: actorUserId,
      actorUsername: actorUsername,
      action: action,
      outcome: outcome,
      summary: summary,
      details: details,
      before: before,
      after: after,
      entityType: entityType,
      entityId: entityId,
    );
    return commitPreparedAudit(record);
  }

  /// Allocates and validates an immutable record before a no-fail business
  /// projection swap. Callers owning [transactionRunner] may then make the
  /// record visible with [commitPreparedAudit] in the same synchronous turn.
  AuditRecord prepareAudit({
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
    return record;
  }

  /// No-fail journal insertion paired with [prepareAudit].
  AuditRecord commitPreparedAudit(AuditRecord record) {
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
        summary: 'تعديل بيانات المادة: ورق تصوير A4',
        entityType: 'item',
        entityId: EntityId('item-003'),
        before: const {
          'id': 'item-003',
          'name': 'ورق تصوير A4',
          'notes': '',
        },
        after: const {
          'id': 'item-003',
          'name': 'ورق تصوير A4',
          'notes': 'رزمة 500 ورقة',
        },
      ),
      _seedAudit(
        sequence: 3,
        occurredAt: DateTime.utc(2026, 7, 29, 6, 27),
        actorUserId: EntityId.demo('user', 2),
        actorUsername: 'ahmed',
        action: AuditAction.delete,
        outcome: AuditOutcome.success,
        summary: 'حذف قائمة بيع تجريبية رقم 101',
        entityType: 'sales_invoice',
        entityId: EntityId('sales-invoice-101'),
        before: _seedSalesInvoice101Snapshot,
        details: const {'permanent': true, 'demoSeed': true},
      ),
      _seedAudit(
        sequence: 4,
        occurredAt: DateTime.utc(2026, 7, 29, 6, 31),
        actorUserId: EntityId.demo('user', 1),
        actorUsername: 'admin',
        action: AuditAction.restore,
        outcome: AuditOutcome.success,
        summary: 'استعادة قائمة البيع رقم 101',
        entityType: 'sales_invoice',
        entityId: EntityId('sales-invoice-101'),
        after: _seedSalesInvoice101Snapshot,
        details: const {'demoSeed': true},
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

const _seedSalesInvoice101Snapshot = <String, Object?>{
  'id': 'sales-invoice-101',
  'documentNumber': 101,
  'date': '2026-07-25',
  'minuteOfDay': 555,
  'customerId': 'party-001',
  'customerNameSnapshot': 'شركة النخيل للتجارة',
  'defaultWarehouseId': 'warehouse-003',
  'currency': 'IQD',
  'exchangeRateTenThousandths': 13100000,
  'settlementKind': 'credit',
  'invoiceDiscountMinorUnits': 0,
  'invoiceDiscountCurrency': 'IQD',
  'receivedMinorUnits': 0,
  'receivedCurrency': 'IQD',
  'receivedAtSaleMinorUnits': 0,
  'receivedAtSaleCurrency': 'IQD',
  'installmentReceivedMinorUnits': 0,
  'installmentReceivedCurrency': 'IQD',
  'balanceAfterInvoiceMinorUnits': 625000,
  'balanceAfterInvoiceCurrency': 'IQD',
  'driverName': 'كرار مهدي',
  'notes': 'تضاف إلى حساب الزبون',
  'searchDetailsSnapshot': '25/07/2026 • 3 مواد • آجل',
  'lineCount': 3,
  'line.0.id': 'sales-line-1011',
  'line.0.itemId': 'item-003',
  'line.0.warehouseId': 'warehouse-003',
  'line.0.quantity': 5,
  'line.0.unitPriceMinorUnits': 12000,
  'line.0.discountPerUnitMinorUnits': 0,
  'line.0.currency': 'IQD',
  'line.0.itemCodeSnapshot': '3001',
  'line.0.itemNameSnapshot': 'ورق طباعة',
  'line.0.warehouseNameSnapshot': 'الرصافة',
  'line.1.id': 'sales-line-1012',
  'line.1.itemId': 'item-002',
  'line.1.warehouseId': 'warehouse-003',
  'line.1.quantity': 2,
  'line.1.unitPriceMinorUnits': 45000,
  'line.1.discountPerUnitMinorUnits': 0,
  'line.1.currency': 'IQD',
  'line.1.itemCodeSnapshot': '3002',
  'line.1.itemNameSnapshot': 'حبر طابعة',
  'line.1.warehouseNameSnapshot': 'الرصافة',
  'line.2.id': 'sales-line-1013',
  'line.2.itemId': 'item-009',
  'line.2.warehouseId': 'warehouse-001',
  'line.2.quantity': 3,
  'line.2.unitPriceMinorUnits': 10000,
  'line.2.discountPerUnitMinorUnits': 1000,
  'line.2.currency': 'IQD',
  'line.2.itemCodeSnapshot': '3003',
  'line.2.itemNameSnapshot': 'دباسة',
  'line.2.warehouseNameSnapshot': 'الرئيسي',
};

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
  Map<String, Object?> details = const {'device': 'desktop-demo-01'},
  Map<String, Object?> before = const {},
  Map<String, Object?> after = const {},
}) {
  return AuditRecord(
    id: EntityId.demo('audit', sequence),
    occurredAt: AuditTimestamp(occurredAt),
    actorUserId: actorUserId,
    actorUsername: actorUsername,
    action: action,
    outcome: outcome,
    summary: summary,
    details: details,
    metadata: AuditMetadata(
      deviceId: 'desktop-demo-01',
      requestId: 'demo-seed-request-$sequence',
      before: before,
      after: after,
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

int _nextDemoRequestSequence(
  Iterable<AuditRecord> records, {
  required int fallback,
}) {
  const prefix = 'demo-request-';
  var next = fallback;
  for (final record in records) {
    final requestId = record.metadata.requestId;
    if (!requestId.startsWith(prefix)) continue;
    final sequence = int.tryParse(requestId.substring(prefix.length));
    if (sequence != null && sequence >= next) next = sequence + 1;
  }
  return next;
}

AuditTimestamp? _latestAuditTimestamp(Iterable<AuditRecord> records) {
  AuditTimestamp? latest;
  for (final record in records) {
    final occurredAt = record.occurredAt;
    if (latest == null || occurredAt.compareTo(latest) > 0) {
      latest = occurredAt;
    }
  }
  return latest;
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
