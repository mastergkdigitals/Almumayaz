import '../../../core/services/service_failure.dart';
import '../domain/audit_models.dart';
import '../domain/audit_repository.dart';

typedef AuditActorProvider = AuditActor Function();

AuditActor? captureAuditActor(
  AuditEventWriter writer, {
  AuditActorProvider? provider,
}) {
  try {
    if (provider != null) return provider();
    if (writer is AuditActorSnapshotProvider) {
      return (writer as AuditActorSnapshotProvider).captureAuditActor();
    }
  } on Object {
    // Actor context is optional for generic/test writers. The writer can still
    // apply its own authoritative context when the event is persisted.
  }
  return null;
}

/// Writes demo audit telemetry without replacing the operation's own result.
///
/// The API-backed implementation will persist the business mutation and its
/// audit record in one authoritative server transaction. The Flutter demo has
/// separate in-memory adapters, so a failed audit write must not turn a
/// completed print, backup, or archive operation into an apparent failure.
Future<void> writeAuditBestEffort(
  AuditEventWriter writer,
  AuditEvent event,
) async {
  try {
    await writer.write(event);
  } on Object {
    // Intentionally isolated from the originating demo operation.
  }
}

AuditOutcome auditFailureOutcome(Object error) {
  if (error is ServiceFailure &&
      (error.kind == ServiceFailureKind.permissionDenied ||
          error.kind == ServiceFailureKind.authenticationRequired ||
          error.kind == ServiceFailureKind.securityRejected ||
          error.kind == ServiceFailureKind.cancelled)) {
    return AuditOutcome.blocked;
  }
  return AuditOutcome.failure;
}

Map<String, Object?> safeAuditFailureDetails(Object error) {
  if (error is ServiceFailure) {
    return {
      'failureKind': error.kind.name,
      if (error.code != null) 'failureCode': error.code,
    };
  }
  return const {'failureKind': 'unknown'};
}
