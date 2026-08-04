import 'audit_models.dart';

/// Audit data is append-only: the contract intentionally exposes no update or
/// delete operation.
abstract interface class AuditRepository {
  Future<AuditPage> search(AuditQuery query);

  Future<AuditRecord> append(AuditRecord record);
}
