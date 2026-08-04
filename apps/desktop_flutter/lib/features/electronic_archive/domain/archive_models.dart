import '../../../core/domain/business_values.dart';

enum ArchiveFileType {
  pdf(extension: 'pdf', mimeType: 'application/pdf'),
  png(extension: 'png', mimeType: 'image/png');

  const ArchiveFileType({required this.extension, required this.mimeType});

  final String extension;
  final String mimeType;
}

enum MalwareScanStatus { notScanned, scanning, clean, infected, failed }

enum SecurityCheckAuthority { localPreflight, serverAuthoritative }

enum ArchiveValidationIssueCode {
  unreadable,
  emptyFile,
  fileTooLarge,
  unsupportedExtension,
  mimeSignatureMismatch,
  checksumFailed,
  malwareDetected,
  malwareScanUnavailable,
}

class ArchiveValidationPolicy {
  ArchiveValidationPolicy({
    required this.maximumByteSize,
    Set<ArchiveFileType> allowedTypes = const {
      ArchiveFileType.pdf,
      ArchiveFileType.png,
    },
  }) : allowedTypes = Set.unmodifiable(allowedTypes) {
    if (maximumByteSize < 1) {
      throw ArgumentError.value(
        maximumByteSize,
        'maximumByteSize',
        'Must be positive',
      );
    }
    if (this.allowedTypes.isEmpty) {
      throw ArgumentError.value(
        allowedTypes,
        'allowedTypes',
        'At least one file type is required',
      );
    }
  }

  final int maximumByteSize;
  final Set<ArchiveFileType> allowedTypes;
}

class ArchiveFileCandidate {
  ArchiveFileCandidate({
    required String localPath,
    required String fileName,
    required this.byteSize,
    this.declaredMimeType,
  })  : localPath = localPath.trim(),
        fileName = fileName.trim() {
    if (this.localPath.isEmpty) {
      throw ArgumentError.value(localPath, 'localPath', 'Must not be empty');
    }
    if (this.fileName.isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'Must not be empty');
    }
    if (byteSize < 0) {
      throw ArgumentError.value(byteSize, 'byteSize', 'Must not be negative');
    }
  }

  final String localPath;
  final String fileName;
  final int byteSize;
  final String? declaredMimeType;
}

class ArchiveValidationIssue {
  const ArchiveValidationIssue({
    required this.code,
    required this.message,
  });

  final ArchiveValidationIssueCode code;
  final String message;
}

class ArchiveSecurityReport {
  ArchiveSecurityReport({
    required this.authority,
    required this.scanStatus,
    required this.checksumSha256,
    required this.detectedMimeType,
    required this.detectedFileType,
    required List<ArchiveValidationIssue> issues,
  }) : issues = List.unmodifiable(issues);

  final SecurityCheckAuthority authority;
  final MalwareScanStatus scanStatus;
  final String? checksumSha256;
  final String? detectedMimeType;
  final ArchiveFileType? detectedFileType;
  final List<ArchiveValidationIssue> issues;

  bool get isUploadAllowed =>
      authority == SecurityCheckAuthority.serverAuthoritative &&
      scanStatus == MalwareScanStatus.clean &&
      checksumSha256 != null &&
      detectedFileType != null &&
      issues.isEmpty;
}

class ArchiveDocumentDraft {
  ArchiveDocumentDraft({
    required String displayName,
    required this.file,
    Set<String> tags = const {},
  })  : displayName = displayName.trim(),
        tags = Set.unmodifiable(
          tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty),
        ) {
    if (this.displayName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Must not be empty',
      );
    }
  }

  final String displayName;
  final ArchiveFileCandidate file;
  final Set<String> tags;
}

class ArchiveUploadRequest {
  ArchiveUploadRequest({
    required this.draft,
    required this.securityReport,
  }) {
    if (!securityReport.isUploadAllowed) {
      throw ArgumentError.value(
        securityReport,
        'securityReport',
        'An authoritative clean security report is required',
      );
    }
  }

  final ArchiveDocumentDraft draft;
  final ArchiveSecurityReport securityReport;
}

class ArchiveDocument {
  ArchiveDocument({
    required this.id,
    required String displayName,
    required this.originalFileName,
    required this.fileType,
    required this.byteSize,
    required this.checksumSha256,
    required this.createdAt,
    required this.createdByUserId,
    required Set<String> tags,
  })  : displayName = displayName.trim(),
        tags = Set.unmodifiable(tags) {
    if (this.displayName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Must not be empty',
      );
    }
  }

  final EntityId id;
  final String displayName;
  final String originalFileName;
  final ArchiveFileType fileType;
  final int byteSize;
  final String checksumSha256;
  final AuditTimestamp createdAt;
  final EntityId createdByUserId;
  final Set<String> tags;
}

class ArchivePreviewSource {
  const ArchivePreviewSource({
    required this.documentId,
    required this.localPath,
    required this.fileType,
  });

  final EntityId documentId;
  final String localPath;
  final ArchiveFileType fileType;
}

class ArchiveQuery {
  const ArchiveQuery({
    this.searchText = '',
    this.fileType,
    this.createdFrom,
    this.createdTo,
  });

  final String searchText;
  final ArchiveFileType? fileType;
  final BusinessDate? createdFrom;
  final BusinessDate? createdTo;
}
