import '../../../core/domain/business_values.dart';

enum AuditAction {
  signIn,
  signOut,
  create,
  update,
  delete,
  restore,
  print,
  export,
  permissionChange,
  accountStatusChange,
  backup,
  other,
}

enum AuditOutcome { success, failure, blocked }

class AuditRecord {
  AuditRecord({
    required this.id,
    required this.occurredAt,
    required this.actorUserId,
    required this.actorUsername,
    required this.action,
    required this.outcome,
    required String summary,
    required Map<String, Object?> details,
    this.entityType,
    this.entityId,
  })  : summary = summary.trim(),
        details = Map.unmodifiable(details) {
    if (this.summary.isEmpty) {
      throw ArgumentError.value(summary, 'summary', 'Must not be empty');
    }
    if ((entityType == null) != (entityId == null)) {
      throw ArgumentError(
        'entityType and entityId must either both be set or both be null',
      );
    }
  }

  final EntityId id;
  final AuditTimestamp occurredAt;
  final EntityId actorUserId;
  final String actorUsername;
  final AuditAction action;
  final AuditOutcome outcome;
  final String summary;
  final Map<String, Object?> details;
  final String? entityType;
  final EntityId? entityId;
}

class AuditQuery {
  AuditQuery({
    this.searchText = '',
    this.actorUserId,
    this.action,
    this.outcome,
    this.entityType,
    this.from,
    this.to,
    this.offset = 0,
    this.limit = 100,
  }) {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Must not be negative');
    }
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive');
    }
    if (from != null && to != null && from!.compareTo(to!) > 0) {
      throw ArgumentError('from must not be after to');
    }
  }

  final String searchText;
  final EntityId? actorUserId;
  final AuditAction? action;
  final AuditOutcome? outcome;
  final String? entityType;
  final AuditTimestamp? from;
  final AuditTimestamp? to;
  final int offset;
  final int limit;
}

class AuditPage {
  AuditPage({
    required List<AuditRecord> records,
    required this.totalCount,
    required this.offset,
    required this.limit,
  }) : records = List.unmodifiable(records);

  final List<AuditRecord> records;
  final int totalCount;
  final int offset;
  final int limit;
}
