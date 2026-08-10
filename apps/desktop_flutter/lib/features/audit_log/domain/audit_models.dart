import '../../../core/domain/business_values.dart';

enum AuditAction {
  signIn,
  signOut,
  sessionLock,
  sessionUnlock,
  activity,
  create,
  update,
  delete,
  restore,
  print,
  export,
  permissionChange,
  accountStatusChange,
  passwordChange,
  backup,
  other,
}

enum AuditOutcome { success, failure, blocked }

class AuditMetadata {
  AuditMetadata({
    required String deviceId,
    required String requestId,
    this.ipAddress,
    this.macAddress,
    Map<String, Object?> before = const <String, Object?>{},
    Map<String, Object?> after = const <String, Object?>{},
  })  : deviceId = deviceId.trim(),
        requestId = requestId.trim(),
        before = Map<String, Object?>.unmodifiable(before),
        after = Map<String, Object?>.unmodifiable(after) {
    if (this.deviceId.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Must not be empty');
    }
    if (this.requestId.isEmpty) {
      throw ArgumentError.value(requestId, 'requestId', 'Must not be empty');
    }
  }

  const AuditMetadata.unspecified()
      : deviceId = 'unspecified',
        requestId = 'unspecified',
        ipAddress = null,
        macAddress = null,
        before = const <String, Object?>{},
        after = const <String, Object?>{};

  final String deviceId;
  final String requestId;
  final String? ipAddress;
  final String? macAddress;
  final Map<String, Object?> before;
  final Map<String, Object?> after;
}

class AuditRecord {
  AuditRecord({
    required this.id,
    required this.occurredAt,
    required this.actorUserId,
    required String actorUsername,
    required this.action,
    required this.outcome,
    required String summary,
    required Map<String, Object?> details,
    this.metadata = const AuditMetadata.unspecified(),
    this.entityType,
    this.entityId,
  })  : summary = summary.trim(),
        actorUsername = actorUsername.trim(),
        details = Map.unmodifiable(details) {
    if (this.summary.isEmpty) {
      throw ArgumentError.value(summary, 'summary', 'Must not be empty');
    }
    if ((entityType == null) != (entityId == null)) {
      throw ArgumentError(
        'entityType and entityId must either both be set or both be null',
      );
    }
    if (this.actorUsername.isEmpty) {
      throw ArgumentError.value(
        actorUsername,
        'actorUsername',
        'Must not be empty',
      );
    }
  }

  final EntityId id;
  final AuditTimestamp occurredAt;
  /// Null for an authentication attempt whose username has no user record.
  final EntityId? actorUserId;
  final String actorUsername;
  final AuditAction action;
  final AuditOutcome outcome;
  final String summary;
  final Map<String, Object?> details;
  final AuditMetadata metadata;
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

class AuditActor {
  const AuditActor({required this.userId, required this.username})
      : assert(username != '');

  /// An attempted username can be retained even when it has no user record.
  const AuditActor.unknownUsername(String username)
      : assert(username != ''),
        userId = null,
        username = username;

  final EntityId? userId;
  final String username;
}

class AuditEvent {
  AuditEvent({
    required this.action,
    required this.outcome,
    required String summary,
    this.actor,
    Map<String, Object?> details = const {},
    Map<String, Object?> before = const {},
    Map<String, Object?> after = const {},
    this.entityType,
    this.entityId,
  })  : summary = summary.trim(),
        details = Map<String, Object?>.unmodifiable(details),
        before = Map<String, Object?>.unmodifiable(before),
        after = Map<String, Object?>.unmodifiable(after) {
    if (this.summary.isEmpty) {
      throw ArgumentError.value(summary, 'summary', 'Must not be empty');
    }
    if ((entityType == null) != (entityId == null)) {
      throw ArgumentError(
        'entityType and entityId must either both be set or both be null',
      );
    }
  }

  final AuditAction action;
  final AuditOutcome outcome;
  final String summary;
  final AuditActor? actor;
  final Map<String, Object?> details;
  final Map<String, Object?> before;
  final Map<String, Object?> after;
  final String? entityType;
  final EntityId? entityId;
}
