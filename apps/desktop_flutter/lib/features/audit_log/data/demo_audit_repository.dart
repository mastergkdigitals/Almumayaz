import '../../../core/services/service_failure.dart';
import '../../authentication/data/demo_identity_state.dart';
import '../domain/audit_models.dart';
import '../domain/audit_repository.dart';

class DemoAuditRepository implements AuditRepository {
  DemoAuditRepository({
    DemoIdentityState? state,
    Iterable<AuditRecord>? initialRecords,
  })  : assert(
          state == null || initialRecords == null,
          'Do not combine shared state with adapter-specific seeds.',
        ),
        _state = state ?? DemoIdentityState(
          initialAuditRecords: initialRecords,
        );

  final DemoIdentityState _state;

  DemoIdentityState get identityState => _state;

  @override
  Future<AuditPage> search(AuditQuery query) async {
    final searchText = query.searchText.trim().toLowerCase();
    final matches = _state.auditRecords.where((record) {
      final detailsText = record.details.entries
          .map((entry) => '${entry.key} ${entry.value ?? ''}')
          .join(' ');
      final metadataText = '${record.metadata.deviceId} '
          '${record.metadata.requestId} '
          '${record.metadata.before} ${record.metadata.after}';
      final haystack = '${record.actorUsername} ${record.summary} '
              '${record.entityType ?? ''} ${record.entityId ?? ''} '
              '$detailsText $metadataText'
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
      ..sort((a, b) {
        final byTime = b.occurredAt.compareTo(a.occurredAt);
        return byTime != 0 ? byTime : b.id.value.compareTo(a.id.value);
      });
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
  Future<AuditRecord> append(AuditRecord record) {
    return _state.mutate(() {
      if (_state.auditRecords.any((entry) => entry.id == record.id)) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.conflict,
          code: 'duplicate_audit_id',
          message: 'معرّف سجل التدقيق مستخدم مسبقاً',
        );
      }
      _state.auditRecords.add(record);
      _state.observeAuditId(record.id);
      return record;
    });
  }
}

List<AuditRecord> demoAuditRecords() => demoIdentityAuditRecords();

class DemoIdentityAuditWriter implements AuditEventWriter {
  DemoIdentityAuditWriter({required DemoIdentityState state}) : _state = state;

  final DemoIdentityState _state;

  @override
  Future<AuditRecord> write(AuditEvent event) {
    return _state.mutate(() {
      final session = _state.currentSession;
      final currentUser = session == null
          ? null
          : _state.usersById[session.userId];
      final actor = event.actor ??
          (currentUser == null
              ? const AuditActor(userId: null, username: 'system')
              : AuditActor(
                  userId: currentUser.id,
                  username: currentUser.username,
                ));
      return _state.appendAudit(
        actorUserId: actor.userId,
        actorUsername: actor.username,
        action: event.action,
        outcome: event.outcome,
        summary: event.summary,
        details: event.details,
        before: event.before,
        after: event.after,
        entityType: event.entityType,
        entityId: event.entityId,
      );
    });
  }
}
