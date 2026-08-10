import 'dart:convert';

import '../../../core/domain/business_values.dart';
import 'archive_sha256.dart';

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
  }) : allowedTypes = Set<ArchiveFileType>.unmodifiable(allowedTypes) {
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
    List<int>? contentBytes,
    bool? contentIsComplete,
  })  : localPath = localPath.trim(),
        fileName = fileName.trim(),
        contentBytes = List<int>.unmodifiable(contentBytes ?? const <int>[]),
        contentIsComplete = contentIsComplete ?? contentBytes != null {
    if (this.localPath.isEmpty) {
      throw ArgumentError.value(localPath, 'localPath', 'Must not be empty');
    }
    if (this.fileName.isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'Must not be empty');
    }
    if (byteSize < 0) {
      throw ArgumentError.value(byteSize, 'byteSize', 'Must not be negative');
    }
    if (this.contentIsComplete && this.contentBytes.length != byteSize) {
      throw ArgumentError.value(
        contentBytes,
        'contentBytes',
        'Complete content length must equal byteSize',
      );
    }
    if (this.contentBytes.any((byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(
        contentBytes,
        'contentBytes',
        'Content values must be bytes',
      );
    }
  }

  final String localPath;
  final String fileName;
  final int byteSize;
  final String? declaredMimeType;
  final List<int> contentBytes;
  final bool contentIsComplete;

  ArchiveFileType? get signatureFileType {
    const pdfSignature = <int>[0x25, 0x50, 0x44, 0x46, 0x2d];
    const pngSignature = <int>[
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ];
    if (_startsWithBytes(contentBytes, pdfSignature)) {
      return ArchiveFileType.pdf;
    }
    if (_startsWithBytes(contentBytes, pngSignature)) {
      return ArchiveFileType.png;
    }
    return null;
  }

  /// SHA-256 over immutable file bytes. Metadata-only candidates return null
  /// and must never be authorized for upload.
  late final String? contentChecksumSha256 =
      contentIsComplete ? archiveSha256Hex(contentBytes) : null;

  /// Binds a security report to this exact immutable selection, including its
  /// path, name, declared size, MIME declaration, and byte content.
  late final String? contentBindingSha256 = contentIsComplete
      ? archiveSha256Hex(<int>[
          ...utf8.encode(
            '$localPath\u0000$fileName\u0000$byteSize\u0000'
            '${declaredMimeType?.trim().toLowerCase() ?? ''}\u0000',
          ),
          ...contentBytes,
        ])
      : null;
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
    this.candidateBindingSha256,
  }) : issues = List<ArchiveValidationIssue>.unmodifiable(issues);

  final SecurityCheckAuthority authority;
  final MalwareScanStatus scanStatus;
  final String? checksumSha256;
  final String? detectedMimeType;
  final ArchiveFileType? detectedFileType;
  final List<ArchiveValidationIssue> issues;
  final String? candidateBindingSha256;

  bool get isUploadAllowed =>
      authority == SecurityCheckAuthority.serverAuthoritative &&
      scanStatus == MalwareScanStatus.clean &&
      checksumSha256 != null &&
      candidateBindingSha256 != null &&
      detectedFileType != null &&
      issues.isEmpty;
}

class ArchiveDocumentDraft {
  ArchiveDocumentDraft({
    required String displayName,
    required this.file,
    Set<String> tags = const {},
  })  : displayName = displayName.trim(),
        tags = Set<String>.unmodifiable(
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
    if (draft.file.contentBindingSha256 == null ||
        draft.file.contentBindingSha256 !=
            securityReport.candidateBindingSha256 ||
        draft.file.contentChecksumSha256 != securityReport.checksumSha256 ||
        draft.file.signatureFileType != securityReport.detectedFileType) {
      throw ArgumentError.value(
        securityReport,
        'securityReport',
        'The report does not belong to the selected immutable file',
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
        tags = Set<String>.unmodifiable(tags) {
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

enum ArchiveUploadStage {
  queued,
  uploading,
  finalizing,
  completed,
  failed,
}

class ArchiveUploadProgress {
  ArchiveUploadProgress({
    required this.stage,
    required this.fraction,
    required String message,
  }) : message = message.trim() {
    if (!fraction.isFinite || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'Must be from 0 to 1');
    }
    if (this.message.isEmpty) {
      throw ArgumentError.value(message, 'message', 'Must not be empty');
    }
  }

  final ArchiveUploadStage stage;
  final double fraction;
  final String message;
}

bool _startsWithBytes(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) return false;
  }
  return true;
}
