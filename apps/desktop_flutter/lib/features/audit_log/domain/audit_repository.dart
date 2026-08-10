import 'audit_models.dart';

/// Audit data is append-only: the contract intentionally exposes no update or
/// delete operation.
abstract interface class AuditRepository {
  Future<AuditPage> search(AuditQuery query);

  Future<AuditRecord> append(AuditRecord record);
}

/// Allocates audit identity, timestamp and request metadata outside widgets.
/// When [AuditEvent.actor] is omitted, implementations use the current
/// authenticated actor.
abstract interface class AuditEventWriter {
  Future<AuditRecord> write(AuditEvent event);
}
