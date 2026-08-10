import 'dart:convert';

import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/services/service_failure.dart';
import '../domain/archive_models.dart';
import '../domain/archive_services.dart';

const _demoUploadStepDelay = Duration(milliseconds: 80);

class DemoArchiveFileSelectionService
    implements ArchiveFileSelectionService {
  DemoArchiveFileSelectionService({
    Iterable<ArchiveFileCandidate?> selections = const [],
  }) : _selections = List<ArchiveFileCandidate?>.of(selections);

  final List<ArchiveFileCandidate?> _selections;

  @override
  Future<ArchiveFileCandidate?> selectFile({
    required ArchiveValidationPolicy policy,
  }) async {
    if (_selections.isNotEmpty) return _selections.removeAt(0);
    final bytes = utf8.encode('%PDF-1.7\nAlmumayaz demo archive document');
    return ArchiveFileCandidate(
      localPath: r'C:\Almumayaz\DemoUpload\document_example.pdf',
      fileName: 'document_example.pdf',
      byteSize: bytes.length,
      declaredMimeType: ArchiveFileType.pdf.mimeType,
      contentBytes: bytes,
    );
  }
}

/// Byte-validating archive security demo.
///
/// It performs real local signature/size/checksum validation but no real
/// malware inspection. Only [scanAuthoritatively] returns the explicitly
/// simulated authoritative result required by [ArchiveUploadRequest].
class DemoArchiveSecurityService implements ArchiveSecurityService {
  @override
  Future<ArchiveSecurityReport> validateLocally({
    required ArchiveFileCandidate file,
    required ArchiveValidationPolicy policy,
  }) async {
    return _buildReport(
      file: file,
      policy: policy,
      authority: SecurityCheckAuthority.localPreflight,
      includeMalwareResult: false,
    );
  }

  @override
  Future<ArchiveSecurityReport> scanAuthoritatively({
    required ArchiveFileCandidate file,
    required ArchiveValidationPolicy policy,
  }) async {
    return _buildReport(
      file: file,
      policy: policy,
      authority: SecurityCheckAuthority.serverAuthoritative,
      includeMalwareResult: true,
    );
  }

  ArchiveSecurityReport _buildReport({
    required ArchiveFileCandidate file,
    required ArchiveValidationPolicy policy,
    required SecurityCheckAuthority authority,
    required bool includeMalwareResult,
  }) {
    final normalizedName = file.fileName.toLowerCase();
    final extension = normalizedName.contains('.')
        ? normalizedName.split('.').last
        : '';
    final extensionType = switch (extension) {
      'pdf' => ArchiveFileType.pdf,
      'png' => ArchiveFileType.png,
      _ => null,
    };
    final detectedType = file.signatureFileType;
    final issues = <ArchiveValidationIssue>[];

    if (!file.contentIsComplete &&
        file.byteSize <= policy.maximumByteSize) {
      issues.add(
        const ArchiveValidationIssue(
          code: ArchiveValidationIssueCode.unreadable,
          message: 'تعذر قراءة محتوى الملف المحدد',
        ),
      );
    }
    if (file.byteSize == 0) {
      issues.add(
        const ArchiveValidationIssue(
          code: ArchiveValidationIssueCode.emptyFile,
          message: 'الملف فارغ',
        ),
      );
    }
    if (file.byteSize > policy.maximumByteSize) {
      issues.add(
        ArchiveValidationIssue(
          code: ArchiveValidationIssueCode.fileTooLarge,
          message: 'يتجاوز الملف الحد المسموح '
              '(${policy.maximumByteSize} بايت)',
        ),
      );
    }
    if (extensionType == null ||
        !policy.allowedTypes.contains(extensionType)) {
      issues.add(
        const ArchiveValidationIssue(
          code: ArchiveValidationIssueCode.unsupportedExtension,
          message: 'الامتداد غير مدعوم؛ المسموح PDF وPNG فقط',
        ),
      );
    }

    final detectedMime = detectedType?.mimeType;
    final declaredMime = file.declaredMimeType?.trim().toLowerCase();
    if (detectedType == null ||
        extensionType != detectedType ||
        (declaredMime != null && declaredMime != detectedMime)) {
      issues.add(
        const ArchiveValidationIssue(
          code: ArchiveValidationIssueCode.mimeSignatureMismatch,
          message: 'لا يطابق توقيع الملف نوعه المعلن',
        ),
      );
    }
    final computedChecksum = file.contentChecksumSha256;
    final checksumFailed = computedChecksum == null &&
        file.byteSize <= policy.maximumByteSize;
    if (checksumFailed) {
      issues.add(
        const ArchiveValidationIssue(
          code: ArchiveValidationIssueCode.checksumFailed,
          message: 'تعذر حساب قيمة التحقق',
        ),
      );
    }

    var scanStatus = MalwareScanStatus.notScanned;
    if (includeMalwareResult && issues.isEmpty) {
      if (normalizedName.contains('infected')) {
        scanStatus = MalwareScanStatus.infected;
        issues.add(
          const ArchiveValidationIssue(
            code: ArchiveValidationIssueCode.malwareDetected,
            message: 'رفض الفحص التجريبي الملف باعتباره مصاباً',
          ),
        );
      } else if (normalizedName.contains('scan_unavailable')) {
        scanStatus = MalwareScanStatus.failed;
        issues.add(
          const ArchiveValidationIssue(
            code: ArchiveValidationIssueCode.malwareScanUnavailable,
            message: 'خدمة الفحص التجريبية غير متاحة',
          ),
        );
      } else {
        scanStatus = MalwareScanStatus.clean;
      }
    }

    return ArchiveSecurityReport(
      authority: authority,
      scanStatus: scanStatus,
      checksumSha256: checksumFailed ? null : computedChecksum,
      detectedMimeType: detectedMime,
      detectedFileType: detectedType,
      issues: issues,
      candidateBindingSha256: file.contentBindingSha256,
    );
  }
}

class DemoArchiveRepository implements ArchiveRepository {
  factory DemoArchiveRepository({
    Iterable<ArchiveDocument>? initialDocuments,
    bool failNextUpload = false,
    EntityId? Function()? currentUserId,
  }) {
    return DemoArchiveRepository._(
      List<ArchiveDocument>.of(initialDocuments ?? _seedDocuments()),
      failNextUpload: failNextUpload,
      currentUserId: currentUserId,
    );
  }

  DemoArchiveRepository._(
    List<ArchiveDocument> initialDocuments, {
    required bool failNextUpload,
    required EntityId? Function()? currentUserId,
  })  : _failNextUpload = failNextUpload,
        _currentUserId =
            currentUserId ?? (() => EntityId.demo('user', 1)),
        _documents = {
          for (final document in initialDocuments) document.id: document,
        },
        _previewPaths = {
          for (final document in initialDocuments)
            document.id:
                'C:\\Almumayaz\\DemoArchive\\${document.originalFileName}',
        } {
    for (final document in initialDocuments) {
      final sequence = int.tryParse(document.id.value.split('-').last);
      if (sequence != null && sequence >= _nextSequence) {
        _nextSequence = sequence + 1;
      }
    }
  }

  final Map<EntityId, ArchiveDocument> _documents;
  final Map<EntityId, String> _previewPaths;
  final EntityId? Function() _currentUserId;
  bool _failNextUpload;
  int _nextSequence = 1;

  void failNextUpload() => _failNextUpload = true;

  @override
  Future<List<ArchiveDocument>> search(ArchiveQuery query) async {
    final searchText = query.searchText.trim().toLowerCase();
    final result = _documents.values.where((document) {
      final createdDate = BusinessDate.fromDateTime(document.createdAt.value);
      final matchesText = searchText.isEmpty ||
          '${document.displayName} ${document.originalFileName} '
                  '${document.fileType.name} ${document.tags.join(' ')}'
              .toLowerCase()
              .contains(searchText);
      return matchesText &&
          (query.fileType == null || document.fileType == query.fileType) &&
          (query.createdFrom == null ||
              createdDate.compareTo(query.createdFrom!) >= 0) &&
          (query.createdTo == null ||
              createdDate.compareTo(query.createdTo!) <= 0);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<ArchiveDocument>.unmodifiable(result);
  }

  @override
  Future<ArchiveDocument?> getById(EntityId id) async => _documents[id];

  @override
  Future<ArchiveDocument> upload(
    ArchiveUploadRequest request, {
    ArchiveUploadProgressCallback? onProgress,
  }) async {
    final currentUserId = _currentUserId();
    if (currentUserId == null) {
      onProgress?.call(
        ArchiveUploadProgress(
          stage: ArchiveUploadStage.failed,
          fraction: 0,
          message: 'يجب تسجيل الدخول قبل رفع ملف إلى الأرشيف',
        ),
      );
      throw const ServiceFailure(
        kind: ServiceFailureKind.authenticationRequired,
        code: 'archive_session_required',
        message: 'يجب تسجيل الدخول قبل رفع ملف إلى الأرشيف',
      );
    }
    final sequence = _nextSequence++;
    onProgress?.call(
      ArchiveUploadProgress(
        stage: ArchiveUploadStage.queued,
        fraction: 0,
        message: 'تمت جدولة الرفع التجريبي',
      ),
    );
    await Future<void>.delayed(_demoUploadStepDelay);
    onProgress?.call(
      ArchiveUploadProgress(
        stage: ArchiveUploadStage.uploading,
        fraction: 0.45,
        message: 'جارٍ رفع الملف إلى التخزين التجريبي',
      ),
    );
    await Future<void>.delayed(_demoUploadStepDelay);
    if (_failNextUpload) {
      _failNextUpload = false;
      onProgress?.call(
        ArchiveUploadProgress(
          stage: ArchiveUploadStage.failed,
          fraction: 0.45,
          message: 'تعذر رفع الملف التجريبي؛ يمكنك إعادة المحاولة',
        ),
      );
      throw const ServiceFailure(
        kind: ServiceFailureKind.unavailable,
        code: 'demo_archive_upload_failed',
        message: 'تعذر رفع الملف التجريبي؛ يمكنك إعادة المحاولة',
      );
    }
    final report = request.securityReport;
    final type = report.detectedFileType;
    final checksum = report.checksumSha256;
    if (type == null || checksum == null || !report.isUploadAllowed) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.securityRejected,
        code: 'archive_security_report_rejected',
        message: 'رفض تقرير الأمان الملف',
      );
    }
    onProgress?.call(
      ArchiveUploadProgress(
        stage: ArchiveUploadStage.finalizing,
        fraction: 0.85,
        message: 'جارٍ تثبيت بيانات المستند التجريبية',
      ),
    );
    await Future<void>.delayed(_demoUploadStepDelay);
    final document = ArchiveDocument(
      id: EntityId.demo('archive', sequence),
      displayName: request.draft.displayName,
      originalFileName: request.draft.file.fileName,
      fileType: type,
      byteSize: request.draft.file.byteSize,
      checksumSha256: checksum,
      createdAt: AuditTimestamp(
        DateTime.utc(2026, 7, 29, 8).add(Duration(minutes: sequence)),
      ),
      createdByUserId: currentUserId,
      tags: request.draft.tags,
    );
    _documents[document.id] = document;
    _previewPaths[document.id] = request.draft.file.localPath;
    onProgress?.call(
      ArchiveUploadProgress(
        stage: ArchiveUploadStage.completed,
        fraction: 1,
        message: 'اكتمل الرفع التجريبي',
      ),
    );
    return document;
  }

  @override
  Future<ArchiveDocument> rename(EntityId id, String displayName) async {
    final existing = _documents[id];
    if (existing == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.notFound,
        code: 'archive_document_not_found',
        message: 'المستند غير موجود',
      );
    }
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.validation,
        message: 'اسم المستند مطلوب',
      );
    }
    final renamed = ArchiveDocument(
      id: existing.id,
      displayName: trimmedName,
      originalFileName: existing.originalFileName,
      fileType: existing.fileType,
      byteSize: existing.byteSize,
      checksumSha256: existing.checksumSha256,
      createdAt: existing.createdAt,
      createdByUserId: existing.createdByUserId,
      tags: existing.tags,
    );
    _documents[id] = renamed;
    return renamed;
  }

  @override
  Future<ArchivePreviewSource> preparePreview(EntityId id) async {
    final document = _documents[id];
    final localPath = _previewPaths[id];
    if (document == null || localPath == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.notFound,
        code: 'archive_document_not_found',
        message: 'المستند غير موجود',
      );
    }
    return ArchivePreviewSource(
      documentId: id,
      localPath: localPath,
      fileType: document.fileType,
    );
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async =>
      _documents.containsKey(id)
          ? const DeleteDecision.allowed()
          : const DeleteDecision.blocked('المستند غير موجود');

  @override
  Future<void> delete(EntityId id) async {
    final decision = await canDelete(id);
    if (!decision.isAllowed) {
      throw ServiceFailure(
        kind: ServiceFailureKind.notFound,
        message: decision.reason ?? 'المستند غير موجود',
      );
    }
    _documents.remove(id);
    _previewPaths.remove(id);
  }

  static List<ArchiveDocument> _seedDocuments() => [
        ArchiveDocument(
          id: EntityId.demo('archive', 1),
          displayName: 'عقد تجهيز شركة النور',
          originalFileName: 'noor_contract.pdf',
          fileType: ArchiveFileType.pdf,
          byteSize: 1887437,
          checksumSha256: 'demo-sha256-archive-seed-0001',
          createdAt: AuditTimestamp(DateTime.utc(2026, 7, 29, 7)),
          createdByUserId: EntityId.demo('user', 1),
          tags: const {'عقود', 'تجهيز'},
        ),
        ArchiveDocument(
          id: EntityId.demo('archive', 2),
          displayName: 'وصل استلام المخزن الرئيسي',
          originalFileName: 'warehouse_receipt.png',
          fileType: ArchiveFileType.png,
          byteSize: 655360,
          checksumSha256: 'demo-sha256-archive-seed-0002',
          createdAt: AuditTimestamp(DateTime.utc(2026, 7, 28, 7)),
          createdByUserId: EntityId.demo('user', 2),
          tags: const {'مخزن', 'وصولات'},
        ),
        ArchiveDocument(
          id: EntityId.demo('archive', 3),
          displayName: 'اتفاقية الزبون أحمد كريم',
          originalFileName: 'customer_agreement.pdf',
          fileType: ArchiveFileType.pdf,
          byteSize: 2202009,
          checksumSha256: 'demo-sha256-archive-seed-0003',
          createdAt: AuditTimestamp(DateTime.utc(2026, 7, 26, 7)),
          createdByUserId: EntityId.demo('user', 1),
          tags: const {'اتفاقيات', 'زبائن'},
        ),
      ];
}
