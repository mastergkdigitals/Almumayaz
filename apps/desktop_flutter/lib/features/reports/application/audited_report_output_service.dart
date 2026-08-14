import 'dart:async';

import '../../../core/services/app_operation_gate.dart';
import '../../audit_log/application/audit_write_support.dart';
import '../../audit_log/domain/audit_models.dart';
import '../../audit_log/domain/audit_repository.dart';
import 'report_output_service.dart';

/// Audits the demo report generator, which does not pass through the shared
/// document output service. Desktop report composition should use either this
/// decorator or an audited document dependency, never both.
class AuditedReportOutputService implements ReportOutputService {
  const AuditedReportOutputService({
    required ReportOutputService delegate,
    required AuditEventWriter auditWriter,
    AuditActorProvider? actorProvider,
    AppOperationGate? operationGate,
  })  : _delegate = delegate,
        _auditWriter = auditWriter,
        _actorProvider = actorProvider,
        _operationGate = operationGate;

  final ReportOutputService _delegate;
  final AuditEventWriter _auditWriter;
  final AuditActorProvider? _actorProvider;
  final AppOperationGate? _operationGate;

  @override
  Future<ReportOutputResult> createPreview(
    ReportOutputRequest request,
  ) =>
      _runReportOutputOperation(
        _operationGate,
        () => _createPreview(request),
      );

  Future<ReportOutputResult> _createPreview(
    ReportOutputRequest request,
  ) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    try {
      final result = await _delegate.createPreview(request);
      await _write(
        request: request,
        action: AuditAction.print,
        outcome: AuditOutcome.success,
        summary: 'اكتملت معاينة أو طباعة تقرير',
        details: {
          'rowCount': result.rowCount,
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
        summary: 'تعذر إكمال معاينة أو طباعة تقرير',
        details: safeAuditFailureDetails(error),
        actor: actor,
      );
      rethrow;
    }
  }

  @override
  Future<ReportOutputResult> export(
    ReportOutputRequest request,
    ReportExportFormat format,
  ) =>
      _runReportOutputOperation(
        _operationGate,
        () => _export(request, format),
      );

  Future<ReportOutputResult> _export(
    ReportOutputRequest request,
    ReportExportFormat format,
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
        summary: 'اكتمل تصدير تقرير',
        details: {
          'format': format.name,
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
        summary: 'تعذر تصدير تقرير',
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
    required ReportOutputRequest request,
    required AuditAction action,
    required AuditOutcome outcome,
    required String summary,
    required Map<String, Object?> details,
    required AuditActor? actor,
  }) {
    return writeAuditBestEffort(
      _auditWriter,
      AuditEvent(
        action: action,
        outcome: outcome,
        summary: summary,
        actor: actor,
        details: {
          'reportTitle': request.reportTitle,
          'variant': request.variantLabel,
          ...details,
        },
      ),
    );
  }
}

Future<T> _runReportOutputOperation<T>(
  AppOperationGate? gate,
  FutureOr<T> Function() operation,
) {
  return gate == null ? Future<T>.sync(operation) : gate.run(operation);
}
