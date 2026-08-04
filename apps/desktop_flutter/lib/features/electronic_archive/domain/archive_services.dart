import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'archive_models.dart';

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

  Future<ArchiveDocument> upload(ArchiveUploadRequest request);

  Future<ArchiveDocument> rename(EntityId id, String displayName);

  /// Makes a managed, read-only local copy available for PDF/PNG preview.
  Future<ArchivePreviewSource> preparePreview(EntityId id);

  Future<DeleteDecision> canDelete(EntityId id);

  Future<void> delete(EntityId id);
}
