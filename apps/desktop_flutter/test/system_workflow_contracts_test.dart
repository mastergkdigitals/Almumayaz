import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/backup_restore/domain/backup_models.dart';
import 'package:erp/features/electronic_archive/domain/archive_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('archive upload requires an authoritative clean security report', () {
    final file = ArchiveFileCandidate(
      localPath: r'C:\Temp\invoice.pdf',
      fileName: 'invoice.pdf',
      byteSize: 1024,
      declaredMimeType: 'application/pdf',
    );
    final draft = ArchiveDocumentDraft(
      displayName: 'فاتورة تجهيز',
      file: file,
    );
    final localReport = ArchiveSecurityReport(
      authority: SecurityCheckAuthority.localPreflight,
      scanStatus: MalwareScanStatus.clean,
      checksumSha256: 'demo-checksum',
      detectedMimeType: 'application/pdf',
      detectedFileType: ArchiveFileType.pdf,
      issues: const [],
    );

    expect(localReport.isUploadAllowed, isFalse);
    expect(
      () => ArchiveUploadRequest(
        draft: draft,
        securityReport: localReport,
      ),
      throwsArgumentError,
    );

    final authoritativeReport = ArchiveSecurityReport(
      authority: SecurityCheckAuthority.serverAuthoritative,
      scanStatus: MalwareScanStatus.clean,
      checksumSha256: 'demo-checksum',
      detectedMimeType: 'application/pdf',
      detectedFileType: ArchiveFileType.pdf,
      issues: const [],
    );
    expect(authoritativeReport.isUploadAllowed, isTrue);
    expect(
      ArchiveUploadRequest(
        draft: draft,
        securityReport: authoritativeReport,
      ).draft,
      same(draft),
    );
  });

  test('locked sessions require a lock reason', () {
    expect(
      () => AppSession(
        id: EntityId.demo('session', 1),
        userId: EntityId.demo('user', 1),
        issuedAt: AuditTimestamp(DateTime.utc(2026, 8, 5, 8)),
        lastActivityAt: AuditTimestamp(DateTime.utc(2026, 8, 5, 9)),
        state: SessionState.locked,
        permissions: const {},
      ),
      throwsArgumentError,
    );
  });

  test('audit query rejects a reversed time range', () {
    expect(
      () => AuditQuery(
        from: AuditTimestamp(DateTime.utc(2026, 8, 6)),
        to: AuditTimestamp(DateTime.utc(2026, 8, 5)),
      ),
      throwsArgumentError,
    );
  });

  test('external backup source requires a real local path', () {
    expect(
      () => ExternalBackupSource(localPath: '   '),
      throwsArgumentError,
    );
    expect(
      ExternalBackupSource(localPath: r'D:\Backups\almumayaz.backup').localPath,
      r'D:\Backups\almumayaz.backup',
    );
  });
}
