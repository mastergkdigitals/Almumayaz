import 'dart:convert';

import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/audit_log/domain/audit_repository.dart';
import 'package:erp/features/electronic_archive/data/demo_archive_services.dart';
import 'package:erp/features/electronic_archive/domain/archive_models.dart';
import 'package:erp/features/electronic_archive/domain/archive_sha256.dart';
import 'package:erp/features/settings/presentation/widgets/settings_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 5 archive security', () {
    final policy = ArchiveValidationPolicy(maximumByteSize: 1024 * 1024);

    test('SHA-256 matches published empty and abc vectors', () {
      expect(
        archiveSha256Hex(const []),
        'e3b0c44298fc1c149afbf4c8996fb924'
        '27ae41e4649b934ca495991b7852b855',
      );
      expect(
        archiveSha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223'
        'b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('selected bytes determine PDF MIME and bind the clean report',
        () async {
      final bytes = utf8.encode('%PDF-1.7\nphase-five');
      final file = ArchiveFileCandidate(
        localPath: r'C:\Archive\phase-five.pdf',
        fileName: 'phase-five.pdf',
        byteSize: bytes.length,
        declaredMimeType: 'application/pdf',
        contentBytes: bytes,
      );
      final originalChecksum = file.contentChecksumSha256;
      bytes[0] = 0;
      final security = DemoArchiveSecurityService();

      final local = await security.validateLocally(
        file: file,
        policy: policy,
      );
      final authoritative = await security.scanAuthoritatively(
        file: file,
        policy: policy,
      );

      expect(local.detectedFileType, ArchiveFileType.pdf);
      expect(local.detectedMimeType, 'application/pdf');
      expect(local.checksumSha256, originalChecksum);
      expect(
        () => file.contentBytes[0] = 0,
        throwsUnsupportedError,
      );
      expect(local.isUploadAllowed, isFalse);
      expect(authoritative.isUploadAllowed, isTrue);
      expect(
        authoritative.candidateBindingSha256,
        file.contentBindingSha256,
      );
    });

    test('metadata-only and signature-mismatched files fail closed', () async {
      final security = DemoArchiveSecurityService();
      final metadataOnly = ArchiveFileCandidate(
        localPath: r'C:\Archive\metadata.pdf',
        fileName: 'metadata.pdf',
        byteSize: 12,
        declaredMimeType: 'application/pdf',
      );
      final pngBytes = <int>[
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        1,
      ];
      final mismatched = ArchiveFileCandidate(
        localPath: r'C:\Archive\wrong.pdf',
        fileName: 'wrong.pdf',
        byteSize: pngBytes.length,
        declaredMimeType: 'application/pdf',
        contentBytes: pngBytes,
      );

      final metadataReport = await security.scanAuthoritatively(
        file: metadataOnly,
        policy: policy,
      );
      final mismatchReport = await security.validateLocally(
        file: mismatched,
        policy: policy,
      );

      expect(metadataReport.isUploadAllowed, isFalse);
      expect(metadataReport.candidateBindingSha256, isNull);
      expect(
        metadataReport.issues.map((issue) => issue.code),
        contains(ArchiveValidationIssueCode.unreadable),
      );
      expect(
        mismatchReport.issues.map((issue) => issue.code),
        contains(ArchiveValidationIssueCode.mimeSignatureMismatch),
      );
      expect(mismatchReport.detectedFileType, ArchiveFileType.png);
    });

    test('a clean report cannot authorize a different immutable selection',
        () async {
      ArchiveFileCandidate pdf(String suffix) {
        final bytes = utf8.encode('%PDF-1.7\n$suffix');
        return ArchiveFileCandidate(
          localPath: r'C:\Archive\bound.pdf',
          fileName: 'bound.pdf',
          byteSize: bytes.length,
          declaredMimeType: 'application/pdf',
          contentBytes: bytes,
        );
      }

      final inspected = pdf('first');
      final replaced = pdf('other');
      final report = await DemoArchiveSecurityService().scanAuthoritatively(
        file: inspected,
        policy: policy,
      );

      expect(
        () => ArchiveUploadRequest(
          draft: ArchiveDocumentDraft(
            displayName: 'مستند مبدل',
            file: replaced,
          ),
          securityReport: report,
        ),
        throwsArgumentError,
      );
    });

    test('size, extension, malware, and unavailable scan reject clearly',
        () async {
      final pdfBytes = utf8.encode('%PDF-1.7\nsecurity');
      final security = DemoArchiveSecurityService();
      final oversized = ArchiveFileCandidate(
        localPath: r'C:\Archive\large.pdf',
        fileName: 'large.pdf',
        byteSize: policy.maximumByteSize + 1,
        declaredMimeType: 'application/pdf',
        contentBytes: pdfBytes.take(8).toList(),
        contentIsComplete: false,
      );
      final unsupported = ArchiveFileCandidate(
        localPath: r'C:\Archive\document.exe',
        fileName: 'document.exe',
        byteSize: pdfBytes.length,
        contentBytes: pdfBytes,
      );
      ArchiveFileCandidate named(String name) => ArchiveFileCandidate(
            localPath: 'C:\\Archive\\$name',
            fileName: name,
            byteSize: pdfBytes.length,
            declaredMimeType: 'application/pdf',
            contentBytes: pdfBytes,
          );

      final oversizedReport = await security.validateLocally(
        file: oversized,
        policy: policy,
      );
      final unsupportedReport = await security.validateLocally(
        file: unsupported,
        policy: policy,
      );
      final infectedReport = await security.scanAuthoritatively(
        file: named('infected.pdf'),
        policy: policy,
      );
      final unavailableReport = await security.scanAuthoritatively(
        file: named('scan_unavailable.pdf'),
        policy: policy,
      );

      expect(
        oversizedReport.issues.map((issue) => issue.code),
        contains(ArchiveValidationIssueCode.fileTooLarge),
      );
      expect(
        unsupportedReport.issues.map((issue) => issue.code),
        contains(ArchiveValidationIssueCode.unsupportedExtension),
      );
      expect(infectedReport.scanStatus, MalwareScanStatus.infected);
      expect(infectedReport.isUploadAllowed, isFalse);
      expect(unavailableReport.scanStatus, MalwareScanStatus.failed);
      expect(unavailableReport.isUploadAllowed, isFalse);
    });

    test('demo repository emits progress and supports a retryable failure',
        () async {
      final bytes = utf8.encode('%PDF-1.7\nupload');
      final file = ArchiveFileCandidate(
        localPath: r'C:\Archive\upload.pdf',
        fileName: 'upload.pdf',
        byteSize: bytes.length,
        declaredMimeType: 'application/pdf',
        contentBytes: bytes,
      );
      final report = await DemoArchiveSecurityService().scanAuthoritatively(
        file: file,
        policy: policy,
      );
      final request = ArchiveUploadRequest(
        draft: ArchiveDocumentDraft(displayName: 'رفع اختباري', file: file),
        securityReport: report,
      );
      final repository = DemoArchiveRepository(
        initialDocuments: const [],
        failNextUpload: true,
        currentUserId: () => EntityId.demo('user', 8),
      );
      final failedStages = <ArchiveUploadStage>[];

      await expectLater(
        repository.upload(
          request,
          onProgress: (progress) => failedStages.add(progress.stage),
        ),
        throwsA(anything),
      );
      expect(
        failedStages,
        [
          ArchiveUploadStage.queued,
          ArchiveUploadStage.uploading,
          ArchiveUploadStage.failed,
        ],
      );

      final completedStages = <ArchiveUploadStage>[];
      final uploaded = await repository.upload(
        request,
        onProgress: (progress) => completedStages.add(progress.stage),
      );
      expect(uploaded.displayName, 'رفع اختباري');
      expect(uploaded.createdByUserId, EntityId.demo('user', 8));
      expect(
        completedStages,
        [
          ArchiveUploadStage.queued,
          ArchiveUploadStage.uploading,
          ArchiveUploadStage.finalizing,
          ArchiveUploadStage.completed,
        ],
      );
    });

    test('archive upload requires a current session user', () async {
      final bytes = utf8.encode('%PDF-1.7\nsession');
      final file = ArchiveFileCandidate(
        localPath: r'C:\Archive\session.pdf',
        fileName: 'session.pdf',
        byteSize: bytes.length,
        declaredMimeType: 'application/pdf',
        contentBytes: bytes,
      );
      final report = await DemoArchiveSecurityService().scanAuthoritatively(
        file: file,
        policy: policy,
      );
      final request = ArchiveUploadRequest(
        draft: ArchiveDocumentDraft(displayName: 'جلسة', file: file),
        securityReport: report,
      );
      final repository = DemoArchiveRepository(
        initialDocuments: const [],
        currentUserId: () => null,
      );
      final stages = <ArchiveUploadStage>[];

      await expectLater(
        repository.upload(
          request,
          onProgress: (progress) => stages.add(progress.stage),
        ),
        throwsA(anything),
      );
      expect(stages, [ArchiveUploadStage.failed]);
    });
  });

  testWidgets('archive keeps stable IDs and retries a failed upload',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stableId = EntityId('server/archive:stable-uuid');
    final seeded = ArchiveDocument(
      id: stableId,
      displayName: 'مستند ثابت',
      originalFileName: 'stable.pdf',
      fileType: ArchiveFileType.pdf,
      byteSize: 10,
      checksumSha256: 'seed-checksum',
      createdAt: AuditTimestamp(DateTime.utc(2026, 8, 10)),
      createdByUserId: EntityId.demo('user', 1),
      tags: const {},
    );
    final repository = DemoArchiveRepository(
      initialDocuments: [seeded],
      failNextUpload: true,
    );
    final audit = _RecordingAuditWriter();

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ElectronicArchiveSettingsSection(
              accentColor: AppModulePalettes.sales.middle,
              repository: repository,
              securityService: DemoArchiveSecurityService(),
              fileSelectionService: DemoArchiveFileSelectionService(),
              validationPolicy: ArchiveValidationPolicy(
                maximumByteSize: 10 * 1024 * 1024,
              ),
              auditWriter: audit,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key('settingsArchiveRow_server/archive:stable-uuid'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('settingsArchiveUploadButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('settingsArchiveDocumentNameField')),
      'مستند رفع تجريبي',
    );
    await tester.tap(
      find.byKey(const Key('settingsArchiveChooseFileButton')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settingsArchiveUploadConfirmButton')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settingsArchiveUploadDialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsArchiveUploadProgressState')),
      findsOneWidget,
    );
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('settingsArchiveUploadConfirmButton')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settingsArchiveUploadDialog')),
      findsNothing,
    );
    expect(find.text('مستند رفع تجريبي'), findsOneWidget);
    final uploadEvents = audit.events
        .where((event) => event.action == AuditAction.create)
        .toList();
    expect(uploadEvents.map((event) => event.outcome), [
      AuditOutcome.failure,
      AuditOutcome.success,
    ]);
    expect(uploadEvents.last.entityId, isNotNull);

    await tester.tap(
      find.byKey(
        const Key('settingsArchiveRename_server/archive:stable-uuid'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('settingsArchiveRenameField')),
      'مستند ثابت معدل',
    );
    await tester.tap(
      find.byKey(const Key('settingsArchiveRenameConfirmButton')),
    );
    await tester.pumpAndSettle();
    expect(
      audit.events.where((event) => event.action == AuditAction.update),
      hasLength(1),
    );

    await tester.tap(
      find.byKey(
        const Key('settingsArchiveDelete_server/archive:stable-uuid'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();
    expect(
      audit.events.where((event) => event.action == AuditAction.delete),
      hasLength(1),
    );
  });
}

class _RecordingAuditWriter implements AuditEventWriter {
  final events = <AuditEvent>[];

  @override
  Future<AuditRecord> write(AuditEvent event) async {
    events.add(event);
    final sequence = events.length;
    return AuditRecord(
      id: EntityId.demo('audit', sequence),
      occurredAt: AuditTimestamp(DateTime.utc(2026, 8, 10, 13, sequence)),
      actorUserId: EntityId.demo('user', 1),
      actorUsername: 'admin',
      action: event.action,
      outcome: event.outcome,
      summary: event.summary,
      details: event.details,
      metadata: AuditMetadata(
        deviceId: 'test-device',
        requestId: 'phase5-$sequence',
        before: event.before,
        after: event.after,
      ),
      entityType: event.entityType,
      entityId: event.entityId,
    );
  }
}
