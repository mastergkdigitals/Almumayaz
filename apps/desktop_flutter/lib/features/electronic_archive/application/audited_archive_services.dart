import 'dart:async';

import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/services/app_operation_gate.dart';
import '../../audit_log/application/audit_write_support.dart';
import '../../audit_log/domain/audit_models.dart';
import '../../audit_log/domain/audit_repository.dart';
import '../domain/archive_models.dart';
import '../domain/archive_services.dart';

final EntityId _pendingArchiveDocumentId =
    EntityId('archive-document-pending');

class AuditedArchiveSecurityService implements ArchiveSecurityService {
  const AuditedArchiveSecurityService({
    required ArchiveSecurityService delegate,
    required AuditEventWriter auditWriter,
    AuditActorProvider? actorProvider,
    AppOperationGate? operationGate,
  })  : _delegate = delegate,
        _auditWriter = auditWriter,
        _actorProvider = actorProvider,
        _operationGate = operationGate;

  final ArchiveSecurityService _delegate;
  final AuditEventWriter _auditWriter;
  final AuditActorProvider? _actorProvider;
  final AppOperationGate? _operationGate;

  @override
  Future<ArchiveSecurityReport> validateLocally({
    required ArchiveFileCandidate file,
    required ArchiveValidationPolicy policy,
  }) =>
      _runArchiveOperation(
        _operationGate,
        () => _validateLocally(file: file, policy: policy),
      );

  Future<ArchiveSecurityReport> _validateLocally({
    required ArchiveFileCandidate file,
    required ArchiveValidationPolicy policy,
  }) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    try {
      final report = await _delegate.validateLocally(
        file: file,
        policy: policy,
      );
      if (report.issues.isNotEmpty) {
        await _writeBlockedReport(
          file: file,
          report: report,
          stage: 'localPreflight',
          summary: 'رُفض ملف الأرشيف في التحقق المحلي',
          actor: actor,
        );
      }
      return report;
    } on Object catch (error) {
      await _writeFailure(
        file: file,
        stage: 'localPreflight',
        error: error,
        actor: actor,
      );
      rethrow;
    }
  }

  @override
  Future<ArchiveSecurityReport> scanAuthoritatively({
    required ArchiveFileCandidate file,
    required ArchiveValidationPolicy policy,
  }) =>
      _runArchiveOperation(
        _operationGate,
        () => _scanAuthoritatively(file: file, policy: policy),
      );

  Future<ArchiveSecurityReport> _scanAuthoritatively({
    required ArchiveFileCandidate file,
    required ArchiveValidationPolicy policy,
  }) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    try {
      final report = await _delegate.scanAuthoritatively(
        file: file,
        policy: policy,
      );
      if (!report.isUploadAllowed) {
        await _writeBlockedReport(
          file: file,
          report: report,
          stage: 'authoritativeScan',
          summary: 'رُفض ملف الأرشيف في فحص الخادم التجريبي',
          actor: actor,
        );
      }
      return report;
    } on Object catch (error) {
      await _writeFailure(
        file: file,
        stage: 'authoritativeScan',
        error: error,
        actor: actor,
      );
      rethrow;
    }
  }

  Future<void> _writeBlockedReport({
    required ArchiveFileCandidate file,
    required ArchiveSecurityReport report,
    required String stage,
    required String summary,
    required AuditActor? actor,
  }) {
    return writeAuditBestEffort(
      _auditWriter,
      AuditEvent(
        action: AuditAction.create,
        outcome: AuditOutcome.blocked,
        summary: summary,
        actor: actor,
        details: {
          'workflow': 'archiveUpload',
          'stage': stage,
          'byteSize': file.byteSize,
          'detectedFileType': report.detectedFileType?.name,
          'scanStatus': report.scanStatus.name,
          'issues': [for (final issue in report.issues) issue.code.name],
        },
        entityType: 'archiveDocument',
        entityId: _pendingArchiveDocumentId,
      ),
    );
  }

  Future<void> _writeFailure({
    required ArchiveFileCandidate file,
    required String stage,
    required Object error,
    required AuditActor? actor,
  }) {
    return writeAuditBestEffort(
      _auditWriter,
      AuditEvent(
        action: AuditAction.create,
        outcome: auditFailureOutcome(error),
        summary: 'تعذر فحص ملف الأرشيف',
        actor: actor,
        details: {
          'workflow': 'archiveUpload',
          'stage': stage,
          'byteSize': file.byteSize,
          ...safeAuditFailureDetails(error),
        },
        entityType: 'archiveDocument',
        entityId: _pendingArchiveDocumentId,
      ),
    );
  }
}

class AuditedArchiveRepository implements ArchiveRepository {
  const AuditedArchiveRepository({
    required ArchiveRepository delegate,
    required AuditEventWriter auditWriter,
    AuditActorProvider? actorProvider,
    AppOperationGate? operationGate,
  })  : _delegate = delegate,
        _auditWriter = auditWriter,
        _actorProvider = actorProvider,
        _operationGate = operationGate;

  final ArchiveRepository _delegate;
  final AuditEventWriter _auditWriter;
  final AuditActorProvider? _actorProvider;
  final AppOperationGate? _operationGate;

  @override
  Future<List<ArchiveDocument>> search(ArchiveQuery query) =>
      _runArchiveOperation(_operationGate, () => _delegate.search(query));

  @override
  Future<ArchiveDocument?> getById(EntityId id) =>
      _runArchiveOperation(_operationGate, () => _delegate.getById(id));

  @override
  Future<ArchiveDocument> upload(
    ArchiveUploadRequest request, {
    ArchiveUploadProgressCallback? onProgress,
  }) =>
      _runArchiveOperation(
        _operationGate,
        () => _upload(request, onProgress: onProgress),
      );

  Future<ArchiveDocument> _upload(
    ArchiveUploadRequest request, {
    ArchiveUploadProgressCallback? onProgress,
  }) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    try {
      final document = await _delegate.upload(
        request,
        onProgress: onProgress,
      );
      await writeAuditBestEffort(
        _auditWriter,
        AuditEvent(
          action: AuditAction.create,
          outcome: AuditOutcome.success,
          summary: 'تم رفع مستند إلى الأرشيف الإلكتروني التجريبي',
          actor: actor,
          details: const {'storage': 'demoInMemory'},
          after: _archiveSnapshot(document),
          entityType: 'archiveDocument',
          entityId: document.id,
        ),
      );
      return document;
    } on Object catch (error) {
      await writeAuditBestEffort(
        _auditWriter,
        AuditEvent(
          action: AuditAction.create,
          outcome: auditFailureOutcome(error),
          summary: 'فشل رفع مستند إلى الأرشيف الإلكتروني التجريبي',
          actor: actor,
          details: {
            'byteSize': request.draft.file.byteSize,
            'detectedFileType':
                request.securityReport.detectedFileType?.name,
            ...safeAuditFailureDetails(error),
          },
          entityType: 'archiveDocument',
          entityId: _pendingArchiveDocumentId,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<ArchiveDocument> rename(EntityId id, String displayName) =>
      _runArchiveOperation(
        _operationGate,
        () => _rename(id, displayName),
      );

  Future<ArchiveDocument> _rename(EntityId id, String displayName) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    final previous = await _getByIdBestEffort(id);
    try {
      final renamed = await _delegate.rename(id, displayName);
      await _writeMutation(
        id: id,
        action: AuditAction.update,
        outcome: AuditOutcome.success,
        summary: 'تم تعديل اسم مستند في الأرشيف الإلكتروني',
        before: previous == null ? const {} : _archiveSnapshot(previous),
        after: _archiveSnapshot(renamed),
        actor: actor,
      );
      return renamed;
    } on Object catch (error) {
      await _writeMutation(
        id: id,
        action: AuditAction.update,
        outcome: auditFailureOutcome(error),
        summary: 'فشل تعديل اسم مستند في الأرشيف الإلكتروني',
        before: previous == null ? const {} : _archiveSnapshot(previous),
        after: {'displayName': displayName.trim()},
        details: safeAuditFailureDetails(error),
        actor: actor,
      );
      rethrow;
    }
  }

  @override
  Future<ArchivePreviewSource> preparePreview(EntityId id) =>
      _runArchiveOperation(
        _operationGate,
        () => _delegate.preparePreview(id),
      );

  @override
  Future<DeleteDecision> canDelete(EntityId id) =>
      _runArchiveOperation(_operationGate, () => _canDelete(id));

  Future<DeleteDecision> _canDelete(EntityId id) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    try {
      final decision = await _delegate.canDelete(id);
      if (!decision.isAllowed) {
        final previous = await _getByIdBestEffort(id);
        await _writeMutation(
          id: id,
          action: AuditAction.delete,
          outcome: AuditOutcome.blocked,
          summary: 'تم منع حذف مستند من الأرشيف الإلكتروني',
          before: previous == null ? const {} : _archiveSnapshot(previous),
          details: const {'reason': 'deleteNotAllowed'},
          actor: actor,
        );
      }
      return decision;
    } on Object catch (error) {
      final previous = await _getByIdBestEffort(id);
      await _writeMutation(
        id: id,
        action: AuditAction.delete,
        outcome: auditFailureOutcome(error),
        summary: 'تعذر التحقق من إمكانية حذف مستند الأرشيف',
        before: previous == null ? const {} : _archiveSnapshot(previous),
        details: safeAuditFailureDetails(error),
        actor: actor,
      );
      rethrow;
    }
  }

  @override
  Future<void> delete(EntityId id) =>
      _runArchiveOperation(_operationGate, () => _delete(id));

  Future<void> _delete(EntityId id) async {
    final actor = captureAuditActor(
      _auditWriter,
      provider: _actorProvider,
    );
    final previous = await _getByIdBestEffort(id);
    try {
      await _delegate.delete(id);
      await _writeMutation(
        id: id,
        action: AuditAction.delete,
        outcome: AuditOutcome.success,
        summary: 'تم حذف مستند من الأرشيف الإلكتروني',
        before: previous == null ? const {} : _archiveSnapshot(previous),
        details: const {'storage': 'demoInMemory'},
        actor: actor,
      );
    } on Object catch (error) {
      await _writeMutation(
        id: id,
        action: AuditAction.delete,
        outcome: auditFailureOutcome(error),
        summary: 'فشل حذف مستند من الأرشيف الإلكتروني',
        before: previous == null ? const {} : _archiveSnapshot(previous),
        details: safeAuditFailureDetails(error),
        actor: actor,
      );
      rethrow;
    }
  }

  Future<ArchiveDocument?> _getByIdBestEffort(EntityId id) async {
    try {
      return await _delegate.getById(id);
    } on Object {
      return null;
    }
  }

  Future<void> _writeMutation({
    required EntityId id,
    required AuditAction action,
    required AuditOutcome outcome,
    required String summary,
    required AuditActor? actor,
    Map<String, Object?> before = const {},
    Map<String, Object?> after = const {},
    Map<String, Object?> details = const {},
  }) {
    return writeAuditBestEffort(
      _auditWriter,
      AuditEvent(
        action: action,
        outcome: outcome,
        summary: summary,
        actor: actor,
        details: details,
        before: before,
        after: after,
        entityType: 'archiveDocument',
        entityId: id,
      ),
    );
  }
}

Map<String, Object?> _archiveSnapshot(ArchiveDocument document) {
  return {
    'displayName': document.displayName,
    'fileName': document.originalFileName,
    'fileType': document.fileType.name,
    'byteSize': document.byteSize,
    'checksumSha256': document.checksumSha256,
    'createdByUserId': document.createdByUserId.value,
  };
}

Future<T> _runArchiveOperation<T>(
  AppOperationGate? gate,
  FutureOr<T> Function() operation,
) {
  return gate == null ? Future<T>.sync(operation) : gate.run(operation);
}
