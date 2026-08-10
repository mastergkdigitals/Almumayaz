import '../../../core/domain/business_values.dart';
import '../../../core/services/service_failure.dart';
import '../domain/audit_models.dart';
import '../domain/audit_repository.dart';

class DemoAuditRepository implements AuditRepository {
  DemoAuditRepository({Iterable<AuditRecord>? initialRecords})
      : _records = List<AuditRecord>.of(
          initialRecords ?? demoAuditRecords(),
        );

  final List<AuditRecord> _records;

  @override
  Future<AuditPage> search(AuditQuery query) async {
    final searchText = query.searchText.trim().toLowerCase();
    final matches = _records.where((record) {
      final detailsText = record.details.entries
          .map((entry) => '${entry.key} ${entry.value ?? ''}')
          .join(' ');
      final haystack = '${record.actorUsername} ${record.summary} '
              '${record.entityType ?? ''} ${record.entityId ?? ''} '
              '$detailsText'
          .toLowerCase();
      return (searchText.isEmpty || haystack.contains(searchText)) &&
          (query.actorUserId == null ||
              record.actorUserId == query.actorUserId) &&
          (query.action == null || record.action == query.action) &&
          (query.outcome == null || record.outcome == query.outcome) &&
          (query.entityType == null ||
              record.entityType == query.entityType) &&
          (query.from == null ||
              record.occurredAt.compareTo(query.from!) >= 0) &&
          (query.to == null || record.occurredAt.compareTo(query.to!) <= 0);
    }).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final start = query.offset > matches.length ? matches.length : query.offset;
    final requestedEnd = start + query.limit;
    final end = requestedEnd > matches.length ? matches.length : requestedEnd;
    return AuditPage(
      records: matches.sublist(start, end),
      totalCount: matches.length,
      offset: query.offset,
      limit: query.limit,
    );
  }

  @override
  Future<AuditRecord> append(AuditRecord record) async {
    if (_records.any((entry) => entry.id == record.id)) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        code: 'duplicate_audit_id',
        message: 'معرّف سجل التدقيق مستخدم مسبقاً',
      );
    }
    _records.add(record);
    return record;
  }
}

List<AuditRecord> demoAuditRecords() => [
      AuditRecord(
        id: EntityId.demo('audit', 1),
        occurredAt: AuditTimestamp(DateTime.utc(2026, 7, 29, 6, 2)),
        actorUserId: EntityId.demo('user', 1),
        actorUsername: 'admin',
        action: AuditAction.signIn,
        outcome: AuditOutcome.success,
        summary: 'تسجيل دخول ناجح من جهاز المكتب الرئيسي',
        details: const {'device': 'desktop-demo-01'},
      ),
      AuditRecord(
        id: EntityId.demo('audit', 2),
        occurredAt: AuditTimestamp(DateTime.utc(2026, 7, 29, 6, 18)),
        actorUserId: EntityId.demo('user', 1),
        actorUsername: 'admin',
        action: AuditAction.update,
        outcome: AuditOutcome.success,
        summary: 'تعديل بيانات المادة: ورق A4',
        details: const {'field': 'name'},
        entityType: 'item',
        entityId: EntityId.demo('item', 1),
      ),
      AuditRecord(
        id: EntityId.demo('audit', 3),
        occurredAt: AuditTimestamp(DateTime.utc(2026, 7, 29, 6, 27)),
        actorUserId: EntityId.demo('user', 2),
        actorUsername: 'ahmed',
        action: AuditAction.delete,
        outcome: AuditOutcome.success,
        summary: 'حذف قائمة بيع تجريبية رقم 1042',
        details: const {'invoiceNumber': 1042},
        entityType: 'sale',
        entityId: EntityId.demo('sale', 1),
      ),
      AuditRecord(
        id: EntityId.demo('audit', 4),
        occurredAt: AuditTimestamp(DateTime.utc(2026, 7, 29, 6, 31)),
        actorUserId: EntityId.demo('user', 1),
        actorUsername: 'admin',
        action: AuditAction.restore,
        outcome: AuditOutcome.success,
        summary: 'استعادة قائمة البيع رقم 1042',
        details: const {'invoiceNumber': 1042},
        entityType: 'sale',
        entityId: EntityId.demo('sale', 1),
      ),
      AuditRecord(
        id: EntityId.demo('audit', 5),
        occurredAt: AuditTimestamp(DateTime.utc(2026, 7, 28, 13, 12)),
        actorUserId: EntityId.demo('user', 3),
        actorUsername: 'sara',
        action: AuditAction.signIn,
        outcome: AuditOutcome.failure,
        summary: 'محاولة دخول بكلمة مرور غير صحيحة',
        details: const {'device': 'desktop-demo-02'},
      ),
    ];
