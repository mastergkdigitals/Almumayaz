import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'archive_models.dart';

typedef ArchiveUploadProgressCallback = void Function(
  ArchiveUploadProgress progress,
);

abstract interface class ArchiveFileSelectionService {
  /// Selects and reads a local candidate without storing it in the archive.
  /// Desktop implementations must avoid fully reading oversized files.
  Future<ArchiveFileCandidate?> selectFile({
    required ArchiveValidationPolicy policy,
  });
}

abstract interface class ArchiveSecurityService {
  /// Performs quick client-side validation for immediate UI feedback.
  Future<ArchiveSecurityReport> validateLocally({
    required ArchiveFileCandidate file,
    required ArchiveValidationPolicy policy,
  });

  /// Requests the authoritative validation and malware scan before upload.
  Future<ArchiveSecurityReport> scanAuthoritatively({
    required ArchiveFileCandidate file,
    required ArchiveValidationPolicy policy,
  });
}

abstract interface class ArchiveRepository {
  Future<List<ArchiveDocument>> search(ArchiveQuery query);

  Future<ArchiveDocument?> getById(EntityId id);

  Future<ArchiveDocument> upload(
    ArchiveUploadRequest request, {
    ArchiveUploadProgressCallback? onProgress,
  });

  Future<ArchiveDocument> rename(EntityId id, String displayName);

  /// Makes a managed, read-only local copy available for PDF/PNG preview.
  Future<ArchivePreviewSource> preparePreview(EntityId id);

  Future<DeleteDecision> canDelete(EntityId id);

  Future<void> delete(EntityId id);
}
