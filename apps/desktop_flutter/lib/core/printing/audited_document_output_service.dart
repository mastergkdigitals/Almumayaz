import 'dart:async';

import '../../features/audit_log/application/audit_write_support.dart';
import '../../features/audit_log/domain/audit_models.dart';
import '../../features/audit_log/domain/audit_repository.dart';
import '../services/app_operation_gate.dart';
import 'document_output_service.dart';

/// Adds safe, exactly-once audit events around the shared output boundary.
/// Document contents, output paths, and printer names are never recorded.
class AuditedDocumentOutputService implements DocumentOutputService {
  const AuditedDocumentOutputService({
    required DocumentOutputService delegate,
    required AuditEventWriter auditWriter,
    AuditActorProvider? actorProvider,
    AppOperationGate? operationGate,
  })  : _delegate = delegate,
        _auditWriter = auditWriter,
        _actorProvider = actorProvider,
        _operationGate = operationGate;

  final DocumentOutputService _delegate;
  final AuditEventWriter _auditWriter;
  final AuditActorProvider? _actorProvider;
  final AppOperationGate? _operationGate;

  @override
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  }) =>
      _runDocumentOutputOperation(
        _operationGate,
        () => _createPreview(request, includePrices: includePrices),
      );

  Future<DocumentOutputResult> _createPreview(
    DocumentOutputRequest request, {
    required bool includePrices,
  }) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    try {
      final result = await _delegate.createPreview(
        request,
        includePrices: includePrices,
      );
      await _write(
        request: request,
        action: AuditAction.print,
        outcome: AuditOutcome.success,
        summary: includePrices
            ? 'اكتملت معاينة أو طباعة مستند'
            : 'اكتملت معاينة أو طباعة مستند بدون أسعار',
        details: {
          'outputAction': result.action.name,
          'rowCount': result.rowCount,
          'includePrices': includePrices,
          'isDemo': result.isDemo,
        },
        actor: actor,
      );
      return result;
    } on Object catch (error) {
      await _write(
        request: request,
        action: AuditAction.print,
        outcome: auditFailureOutcome(error),
        summary: 'تعذر إكمال معاينة أو طباعة مستند',
        details: {
          'includePrices': includePrices,
          ...safeAuditFailureDetails(error),
        },
        actor: actor,
      );
      rethrow;
    }
  }

  @override
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) =>
      _runDocumentOutputOperation(
        _operationGate,
        () => _export(request, format),
      );

  Future<DocumentOutputResult> _export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    try {
      final result = await _delegate.export(request, format);
      await _write(
        request: request,
        action: AuditAction.export,
        outcome: AuditOutcome.success,
        summary: 'اكتمل تصدير مستند',
        details: {
          'format': format.name,
          'outputAction': result.action.name,
          'rowCount': result.rowCount,
          'isDemo': result.isDemo,
        },
        actor: actor,
      );
      return result;
    } on Object catch (error) {
      await _write(
        request: request,
        action: AuditAction.export,
        outcome: auditFailureOutcome(error),
        summary: 'تعذر تصدير مستند',
        details: {
          'format': format.name,
          ...safeAuditFailureDetails(error),
        },
        actor: actor,
      );
      rethrow;
    }
  }

  Future<void> _write({
    required DocumentOutputRequest request,
    required AuditAction action,
    required AuditOutcome outcome,
    required String summary,
    required Map<String, Object?> details,
    required AuditActor? actor,
  }) {
    final target = request.auditTarget;
    return writeAuditBestEffort(
      _auditWriter,
      AuditEvent(
        action: action,
        outcome: outcome,
        summary: summary,
        actor: actor,
        details: {
          'documentTitle': request.title,
          if (request.subtitle != null)
            'documentSubtitle': request.subtitle,
          ...details,
        },
        entityType: target?.entityType,
        entityId: target?.entityId,
      ),
    );
  }
}

Future<T> _runDocumentOutputOperation<T>(
  AppOperationGate? gate,
  FutureOr<T> Function() operation,
) {
  return gate == null ? Future<T>.sync(operation) : gate.run(operation);
}
