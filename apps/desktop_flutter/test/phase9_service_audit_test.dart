import 'dart:async';
import 'dart:convert';

import 'package:erp/core/app_state/app_data_composition.dart';
import 'package:erp/core/app_state/app_data_profile.dart';
import 'package:erp/core/app_state/app_services.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/data/demo_transaction_runner.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/printing/audited_document_output_service.dart';
import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/core/services/app_operation_gate.dart';
import 'package:erp/core/services/service_failure.dart';
import 'package:erp/features/audit_log/data/demo_audit_repository.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/audit_log/domain/audit_repository.dart';
import 'package:erp/features/authentication/data/demo_authentication_service.dart';
import 'package:erp/features/authentication/data/demo_identity_state.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/backup_restore/domain/backup_models.dart';
import 'package:erp/features/electronic_archive/domain/archive_models.dart';
import 'package:erp/features/reports/application/report_output_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 9 audit value safety', () {
    test('recursively snapshots nested event and record payloads', () {
      final nestedList = <Object?>[
        <String, Object?>{'status': 'before'},
      ];
      final nestedMap = <String, Object?>{'items': nestedList};
      final event = AuditEvent(
        action: AuditAction.update,
        outcome: AuditOutcome.success,
        summary: 'اختبار ثبات لقطة التدقيق',
        details: nestedMap,
        before: nestedMap,
        after: nestedMap,
      );

      (nestedList.single as Map<String, Object?>)['status'] = 'mutated';
      nestedList.add('mutated');
      nestedMap['extra'] = true;

      final frozenItems = event.details['items']! as List<Object?>;
      expect(frozenItems, hasLength(1));
      expect(
        (frozenItems.single as Map<Object?, Object?>)['status'],
        'before',
      );
      expect(() => frozenItems.add('blocked'), throwsUnsupportedError);
      expect(
        () => (frozenItems.single as Map<Object?, Object?>)['status'] =
            'blocked',
        throwsUnsupportedError,
      );

      final record = AuditRecord(
        id: EntityId.demo('audit', 1),
        occurredAt: AuditTimestamp(DateTime.utc(2026, 8, 14)),
        actorUserId: EntityId.demo('user', 1),
        actorUsername: 'admin',
        action: event.action,
        outcome: event.outcome,
        summary: event.summary,
        details: event.details,
        metadata: AuditMetadata(
          deviceId: 'test-device',
          requestId: 'test-request',
          before: event.before,
          after: event.after,
        ),
      );
      expect(
        () => (record.metadata.before['items']! as List<Object?>).clear(),
        throwsUnsupportedError,
      );
    });

    test('audit writer failure never replaces a completed output result',
        () async {
      final output = AuditedDocumentOutputService(
        delegate: const DemoDocumentOutputService(),
        auditWriter: _ThrowingAuditWriter(),
      );

      final result = await output.createPreview(_documentRequest());

      expect(result.action, DocumentOutputAction.print);
      expect(result.rowCount, 1);
    });
  });

  group('Phase 9 application operation gate', () {
    test('retirement drains admitted nested work and rejects a stale lease',
        () async {
      final gate = AppOperationGate();
      final outerStarted = Completer<void>();
      final allowNested = Completer<void>();
      final finishOuter = Completer<void>();
      final delayedTrigger = Completer<void>();
      late Future<int> delayedNested;
      var nestedRan = false;

      final outer = gate.run(() async {
        delayedNested = delayedTrigger.future.then(
          (_) => gate.run(() => 99),
        );
        outerStarted.complete();
        await allowNested.future;
        await gate.run(() {
          nestedRan = true;
        });
        await finishOuter.future;
      });
      await outerStarted.future;

      final retirement = gate.beginRetirement();
      var drained = false;
      unawaited(retirement.drained.then((_) => drained = true));
      allowNested.complete();
      await Future<void>.delayed(Duration.zero);
      expect(nestedRan, isTrue);
      expect(drained, isFalse);

      finishOuter.complete();
      await outer;
      await retirement.drained;
      retirement.commit();
      expect(gate.isRetired, isTrue);
      delayedTrigger.complete();
      await expectLater(
        delayedNested,
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'application_data_replacement_in_progress',
          ),
        ),
      );
    });
  });

  group('Phase 9 output audit', () {
    test('captures actor before await and omits document content', () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      final authentication = DemoAuthenticationService(state: state);
      final writer = DemoIdentityAuditWriter(state: state);
      final output = AuditedDocumentOutputService(
        delegate: const DemoDocumentOutputService(
          delay: Duration(milliseconds: 20),
        ),
        auditWriter: writer,
      );
      final session = (await authentication.currentSession())!;

      final pending = output.createPreview(
        _documentRequest(
          auditTarget: DocumentOutputAuditTarget(
            entityType: 'sale',
            entityId: EntityId.demo('sale', 1),
          ),
        ),
      );
      await authentication.signOut(session.id);
      await pending;

      final printRecord = state.auditRecords.singleWhere(
        (record) => record.action == AuditAction.print,
      );
      expect(printRecord.actorUsername, 'admin');
      expect(printRecord.actorUserId, EntityId.demo('user', 1));
      expect(printRecord.entityType, 'sale');
      expect(printRecord.entityId, EntityId.demo('sale', 1));
      expect(printRecord.metadata.ipAddress, isNull);
      expect(printRecord.metadata.macAddress, isNull);
      expect(printRecord.details.toString(), isNot(contains('SECRET-CELL')));
    });

    test('records validation failure without replacing the original error',
        () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      DemoAuthenticationService(state: state);
      final output = AuditedDocumentOutputService(
        delegate: const DemoDocumentOutputService(),
        auditWriter: DemoIdentityAuditWriter(state: state),
      );

      await expectLater(
        output.export(
          _documentRequest(title: ''),
          DocumentExportFormat.pdf,
        ),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'document_title_required',
          ),
        ),
      );

      final record = state.auditRecords.single;
      expect(record.action, AuditAction.export);
      expect(record.outcome, AuditOutcome.failure);
      expect(record.details['failureCode'], 'document_title_required');
    });

    test('demo report output is audited once without row or metric content',
        () async {
      final services = AppServices.demo();
      await services.authentication.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );

      final result = await services.reportOutput.createPreview(
        const ReportOutputRequest(
          reportTitle: 'تقرير اختبار',
          variantLabel: 'الملخص',
          columnLabels: ['القيمة'],
          rowValues: [
            ['SECRET-REPORT-CELL'],
          ],
          metrics: {'إجمالي سري': 'SECRET-METRIC'},
        ),
      );

      expect(result.rowCount, 1);
      final audit = await services.audit.search(AuditQuery(limit: 1000));
      final outputEvents = audit.records.where(
        (record) => record.action == AuditAction.print,
      );
      expect(outputEvents, hasLength(1));
      expect(outputEvents.single.details['reportTitle'], 'تقرير اختبار');
      expect(
        outputEvents.single.details.toString(),
        isNot(contains('SECRET-REPORT-CELL')),
      );
      expect(
        outputEvents.single.details.toString(),
        isNot(contains('SECRET-METRIC')),
      );
    });
  });

  group('Phase 9 backup and archive audit', () {
    test('service composition logs configuration, backup, restore, and Drive',
        () async {
      final services = AppServices.demo();
      await services.authentication.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final original = await services.backupConfiguration.load(
        almumayazWindowsDeviceId,
      );
      final updated = BackupConfiguration(
        deviceId: original.deviceId,
        localPath: r'E:\Private\BackupFolder',
        schedule: const BackupSchedule(
          isEnabled: true,
          frequency: BackupFrequency.weekly,
        ),
      );

      await services.backupConfiguration.save(updated);
      await services.googleDriveBackups.connect();
      final created = await services.backups.createBackup(
        configuration: updated,
        uploadToGoogleDrive: false,
      );
      await services.backups.restore(
        RestoreRequest(
          source: StoredBackupSource(created.id),
          confirmedByUser: true,
        ),
      );

      final audit = await services.audit.search(AuditQuery(limit: 1000));
      final configuration = audit.records.singleWhere(
        (record) => record.entityType == 'backupConfiguration',
      );
      expect(configuration.metadata.before, isNotEmpty);
      expect(configuration.metadata.after['frequency'], 'weekly');
      expect(configuration.metadata.after['localPathConfigured'], isTrue);
      final backup = audit.records.singleWhere(
        (record) =>
            record.action == AuditAction.backup &&
            record.entityId == created.id,
      );
      expect(backup.outcome, AuditOutcome.success);
      expect(backup.details['localBackupAvailable'], isTrue);
      expect(
        audit.records,
        contains(
          isA<AuditRecord>()
              .having(
                (record) => record.action,
                'action',
                AuditAction.restore,
              )
              .having(
                (record) => record.entityId,
                'backup id',
                created.id,
              ),
        ),
      );
      expect(
        audit.records.where(
          (record) => record.entityType == 'backupCloudConnection',
        ),
        hasLength(1),
      );
      expect(
        [
          for (final record in audit.records)
            '${record.details}${record.metadata.before}'
                '${record.metadata.after}',
        ].join(),
        isNot(contains(r'E:\Private\BackupFolder')),
      );
    });

    test('rejected external restore source is audited without its path',
        () async {
      final services = AppServices.demo();
      await services.authentication.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final verification = await services.backups.verifyRestoreSource(
        ExternalBackupSource(
          localPath: r'C:\Private\invalid-restore.txt',
        ),
      );

      expect(verification.canRestore, isFalse);
      final audit = await services.audit.search(AuditQuery(limit: 1000));
      final blocked = audit.records.where(
        (record) =>
            record.action == AuditAction.restore &&
            record.outcome == AuditOutcome.blocked &&
            record.details['operation'] == 'verifyRestoreSource',
      );
      expect(blocked, hasLength(1));
      expect(blocked.single.entityType, 'backup');
      expect(
        blocked.single.details.toString(),
        isNot(contains(r'C:\Private')),
      );
    });

    test('archive mutations are exactly-once and deletion keeps a snapshot',
        () async {
      final services = AppServices.demo();
      await services.authentication.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final bytes = utf8.encode('%PDF-1.7\nSECRET ARCHIVE CONTENT');
      final file = ArchiveFileCandidate(
        localPath: r'C:\Private\secret-document.pdf',
        fileName: 'document.pdf',
        byteSize: bytes.length,
        declaredMimeType: ArchiveFileType.pdf.mimeType,
        contentBytes: bytes,
      );
      final policy = ArchiveValidationPolicy(maximumByteSize: 1024 * 1024);
      final local = await services.archiveSecurity.validateLocally(
        file: file,
        policy: policy,
      );
      expect(local.issues, isEmpty);
      final authoritative =
          await services.archiveSecurity.scanAuthoritatively(
        file: file,
        policy: policy,
      );
      final uploaded = await services.archive.upload(
        ArchiveUploadRequest(
          draft: ArchiveDocumentDraft(
            displayName: 'وثيقة اختبار',
            file: file,
          ),
          securityReport: authoritative,
        ),
      );
      await services.archive.rename(uploaded.id, 'وثيقة معدلة');
      await services.archive.delete(uploaded.id);

      final audit = await services.audit.search(AuditQuery(limit: 1000));
      final mutations = audit.records
          .where(
            (record) =>
                record.entityType == 'archiveDocument' &&
                record.entityId == uploaded.id,
          )
          .toList();
      expect(mutations, hasLength(3));
      expect(
        mutations.map((record) => record.action).toSet(),
        {AuditAction.create, AuditAction.update, AuditAction.delete},
      );
      final deletion = mutations.singleWhere(
        (record) => record.action == AuditAction.delete,
      );
      expect(deletion.metadata.before['displayName'], 'وثيقة معدلة');
      expect(deletion.metadata.before['checksumSha256'], isNotNull);
      expect(
        mutations.map((record) => record.details.toString()).join(),
        isNot(contains(r'C:\Private')),
      );
      expect(
        mutations.map((record) => record.details.toString()).join(),
        isNot(contains('SECRET ARCHIVE CONTENT')),
      );
    });

    test('archive security rejection is one blocked event without a path',
        () async {
      final services = AppServices.demo();
      await services.authentication.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final bytes = utf8.encode('not an allowed archive file');
      final file = ArchiveFileCandidate(
        localPath: r'C:\Private\malware.exe',
        fileName: 'malware.exe',
        byteSize: bytes.length,
        contentBytes: bytes,
      );

      final report = await services.archiveSecurity.validateLocally(
        file: file,
        policy: ArchiveValidationPolicy(maximumByteSize: 1024),
      );
      expect(report.issues, isNotEmpty);

      final audit = await services.audit.search(AuditQuery(limit: 1000));
      final blocked = audit.records.where(
        (record) =>
            record.outcome == AuditOutcome.blocked &&
            record.details['workflow'] == 'archiveUpload',
      );
      expect(blocked, hasLength(1));
      expect(blocked.single.details.toString(), isNot(contains(r'C:\Private')));
    });

    test('concurrent archive deletion records one success only', () async {
      final services = AppServices.demo();
      await services.authentication.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final documentId = EntityId.demo('archive', 1);

      Future<Object?> captureDelete() async {
        try {
          await services.archive.delete(documentId);
          return null;
        } on Object catch (error) {
          return error;
        }
      }

      final results = await Future.wait([
        captureDelete(),
        captureDelete(),
      ]);
      expect(results.where((result) => result == null), hasLength(1));
      expect(results.whereType<ServiceFailure>(), hasLength(1));

      final audit = await services.audit.search(AuditQuery(limit: 1000));
      final deletionEvents = audit.records.where(
        (record) =>
            record.entityType == 'archiveDocument' &&
            record.entityId == documentId &&
            record.action == AuditAction.delete,
      );
      expect(
        deletionEvents.where(
          (record) => record.outcome == AuditOutcome.success,
        ),
        hasLength(1),
      );
      expect(
        deletionEvents.where(
          (record) => record.outcome != AuditOutcome.success,
        ),
        hasLength(1),
      );
    });
  });

  group('Phase 9 authentication and application audit', () {
    test('sensitive authentication failures are logged without passwords',
        () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      final authentication = DemoAuthenticationService(state: state);
      final administration =
          DemoSecurityAdministrationService(state: state);

      await expectLater(
        authentication.changePassword(
          PasswordChangeRequest(
            userId: EntityId.demo('user', 1),
            currentPassword: 'wrong-current-password',
            newPassword: 'replacement-password',
          ),
        ),
        throwsA(isA<ServiceFailure>()),
      );
      await expectLater(
        administration.deleteUser(EntityId.demo('user', 1)),
        throwsA(isA<ServiceFailure>()),
      );

      final failures = state.auditRecords.where(
        (record) => record.outcome != AuditOutcome.success,
      );
      expect(failures, hasLength(2));
      expect(
        failures.map((record) => record.details.toString()).join(),
        isNot(contains('wrong-current-password')),
      );
      expect(
        failures.map((record) => record.details.toString()).join(),
        isNot(contains('replacement-password')),
      );
      final deletion = failures.singleWhere(
        (record) => record.action == AuditAction.delete,
      );
      expect(deletion.outcome, AuditOutcome.blocked);
      expect(deletion.metadata.before['username'], 'admin');
    });

    test('session policy stores before/after and blocked attempts', () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      final authentication = DemoAuthenticationService(state: state);
      final policies = DemoSessionPolicyRepository(state: state);
      await policies.saveAutoLockPolicy(
        AutoLockPolicy(
          isEnabled: true,
          idleTimeout: const Duration(minutes: 30),
        ),
      );
      await authentication.signOut(
        (await authentication.currentSession())!.id,
      );
      await authentication.signIn(
        SignInCredentials(username: 'ahmed', password: 'demo123'),
      );

      await expectLater(
        policies.saveAutoLockPolicy(
          AutoLockPolicy(
            isEnabled: true,
            idleTimeout: const Duration(minutes: 5),
          ),
        ),
        throwsA(isA<ServiceFailure>()),
      );

      final policyEvents = state.auditRecords.where(
        (record) => record.entityType == 'session_policy',
      );
      expect(policyEvents, hasLength(2));
      final success = policyEvents.singleWhere(
        (record) => record.outcome == AuditOutcome.success,
      );
      expect(success.metadata.before['idleMinutes'], 15);
      expect(success.metadata.after['idleMinutes'], 30);
      final blocked = policyEvents.singleWhere(
        (record) => record.outcome == AuditOutcome.blocked,
      );
      expect(blocked.actorUsername, 'ahmed');
      expect(blocked.metadata.before['idleMinutes'], 30);
      expect(blocked.metadata.after['idleMinutes'], 5);
    });

    testWidgets('rapid activity is coalesced and never fills the audit log',
        (tester) async {
      final store = AppStore.demo();
      try {
        await store.signIn(
          SignInCredentials(username: 'admin', password: 'password'),
        );
        final authentication =
            store.services.authentication as DemoAuthenticationService;
        final before = (await authentication.currentSession())!.lastActivityAt;

        await store.recordActivity();
        final afterFirst =
            (await authentication.currentSession())!.lastActivityAt;
        expect(afterFirst.compareTo(before), greaterThan(0));
        await Future.wait([
          for (var index = 0; index < 20; index++) store.recordActivity(),
        ]);
        expect(
          (await authentication.currentSession())!.lastActivityAt,
          afterFirst,
        );

        await tester.pump(const Duration(milliseconds: 1100));
        await store.recordActivity();
        expect(
          (await authentication.currentSession())!
              .lastActivityAt
              .compareTo(afterFirst),
          greaterThan(0),
        );
        final audit = await store.services.audit.search(
          AuditQuery(limit: 1000),
        );
        expect(
          audit.records.where(
            (record) => record.action == AuditAction.activity,
          ),
          isEmpty,
        );
      } finally {
        // Widget-test fake timers are verified before addTearDown callbacks.
        // Dispose here so both the idle deadline and activity cooldown are
        // cancelled inside the test callback, even when an assertion fails.
        store.dispose();
      }
    });

    test('clear carries permanent history and advances audit identities',
        () async {
      final store = AppStore.demo()..suspendIdleMonitoring();
      addTearDown(store.dispose);
      await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final before = await store.services.audit.search(AuditQuery(limit: 1000));
      final beforeIds = {for (final record in before.records) record.id};
      final latestBefore = before.records
          .map((record) => record.occurredAt)
          .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);

      await store.clearAllData();

      final audit = await store.services.audit.search(AuditQuery(limit: 1000));
      expect(audit.records, hasLength(before.records.length + 1));
      expect(
        audit.records.map((record) => record.id),
        containsAll(beforeIds),
      );
      expect(
        audit.records.map((record) => record.id).toSet(),
        hasLength(audit.records.length),
      );
      expect(
        audit.records.map((record) => record.metadata.requestId).toSet(),
        hasLength(audit.records.length),
      );
      final transition = audit.records.singleWhere(
        (record) => !beforeIds.contains(record.id),
      );
      expect(transition.actorUsername, 'admin');
      expect(transition.actorUserId, EntityId.demo('user', 1));
      expect(transition.action, AuditAction.delete);
      expect(transition.outcome, AuditOutcome.success);
      expect(transition.entityType, 'applicationData');
      expect(transition.details['deletionScope'], isNotEmpty);
      expect(transition.metadata.deviceId, isNotEmpty);
      expect(transition.metadata.requestId, isNotEmpty);
      expect(transition.occurredAt.compareTo(latestBefore), greaterThan(0));
      expect(transition.metadata.ipAddress, isNull);
      expect(transition.metadata.macAddress, isNull);
    });

    test('clear drains an accepted mutation and retires the old graph',
        () async {
      final store = AppStore.demo()..suspendIdleMonitoring();
      addTearDown(store.dispose);
      await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final oldAuthentication =
          store.services.authentication as DemoAuthenticationService;
      final oldState = oldAuthentication.identityState;
      final started = Completer<void>();
      final release = Completer<void>();
      final pending = oldState.mutate(() async {
        started.complete();
        await release.future;
        oldState.appendAudit(
          actorUserId: EntityId.demo('user', 1),
          actorUsername: 'admin',
          action: AuditAction.other,
          outcome: AuditOutcome.success,
          summary: 'معاملة مقبولة قبل استبدال البيانات',
          details: const {'testMarker': 'drained-before-replacement'},
        );
      });
      await started.future;

      var clearCompleted = false;
      final clear = store.clearAllData().whenComplete(() {
        clearCompleted = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(clearCompleted, isFalse);
      release.complete();
      await pending;
      await clear;

      final audit = await store.services.audit.search(AuditQuery(limit: 1000));
      expect(
        audit.records.where(
          (record) =>
              record.details['testMarker'] == 'drained-before-replacement',
        ),
        hasLength(1),
      );
      await expectLater(oldState.mutate(() {}), throwsStateError);
    });

    test('failed retirement final turn reopens the live runner', () async {
      final runner = DemoTransactionRunner();

      await expectLater(
        runner.retireAfterDrain<void>(
          () => throw StateError('injected final-turn failure'),
        ),
        throwsStateError,
      );

      expect(await runner.run(() => 42), 42);
    });

    test('clear drains gated output, carries its audit, and retires stale service',
        () async {
      late _BlockingDocumentOutputService blockingOutput;
      AppDataComposition builder(AppDataProfile profile) {
        final composition = AppDataComposition.demo(profile);
        if (profile != AppDataProfile.originalDemo) return composition;
        blockingOutput = _BlockingDocumentOutputService();
        final services = composition.services;
        return AppDataComposition(
          repositories: composition.repositories,
          services: _copyServicesWithDocumentOutput(
            services,
            AuditedDocumentOutputService(
              delegate: blockingOutput,
              auditWriter: services.auditWriter,
              operationGate: services.operationGate,
            ),
          ),
        );
      }

      final store = AppStore.demo(compositionBuilder: builder)
        ..suspendIdleMonitoring();
      addTearDown(store.dispose);
      await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final oldServices = store.services;
      final targetId = EntityId('blocking-output-document');
      final request = _documentRequest(
        auditTarget: DocumentOutputAuditTarget(
          entityType: 'testDocument',
          entityId: targetId,
        ),
      );
      final output = oldServices.documentOutput.createPreview(request);
      await blockingOutput.started.future;

      var clearCompleted = false;
      final clear = store.clearAllData().whenComplete(() {
        clearCompleted = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(clearCompleted, isFalse);
      expect(oldServices.operationGate!.acceptsNewOperations, isFalse);
      blockingOutput.release.complete();
      await output;
      await clear;

      final audit = await store.services.audit.search(AuditQuery(limit: 1000));
      expect(
        audit.records.where(
          (record) =>
              record.entityType == 'testDocument' &&
              record.entityId == targetId &&
              record.action == AuditAction.print &&
              record.outcome == AuditOutcome.success,
        ),
        hasLength(1),
      );
      expect(oldServices.operationGate!.isRetired, isTrue);
      expect(store.services.operationGate!.acceptsNewOperations, isTrue);
      await expectLater(
        oldServices.documentOutput.export(
          request,
          DocumentExportFormat.pdf,
        ),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'application_data_replacement_in_progress',
          ),
        ),
      );
    });
  });
}

DocumentOutputRequest _documentRequest({
  String title = 'مستند اختبار',
  DocumentOutputAuditTarget? auditTarget,
}) {
  return DocumentOutputRequest(
    title: title,
    columns: const [DocumentColumn(label: 'القيمة')],
    rows: const [
      ['SECRET-CELL'],
    ],
    auditTarget: auditTarget,
  );
}

class _ThrowingAuditWriter implements AuditEventWriter {
  @override
  Future<AuditRecord> write(AuditEvent event) {
    throw StateError('injected audit writer failure');
  }
}

AppServices _copyServicesWithDocumentOutput(
  AppServices source,
  DocumentOutputService documentOutput,
) {
  return AppServices(
    authentication: source.authentication,
    sessionPolicies: source.sessionPolicies,
    administration: source.administration,
    auditWriter: source.auditWriter,
    backupConfiguration: source.backupConfiguration,
    backups: source.backups,
    backupFileSelection: source.backupFileSelection,
    googleDriveBackups: source.googleDriveBackups,
    archiveSecurity: source.archiveSecurity,
    archive: source.archive,
    archiveFileSelection: source.archiveFileSelection,
    archiveValidationPolicy: source.archiveValidationPolicy,
    users: source.users,
    roles: source.roles,
    audit: source.audit,
    operationGate: source.operationGate,
    documentOutput: documentOutput,
    reportOutput: source.reportOutput,
  );
}

class _BlockingDocumentOutputService implements DocumentOutputService {
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  final DemoDocumentOutputService _delegate = const DemoDocumentOutputService();

  @override
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  }) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    return _delegate.createPreview(request, includePrices: includePrices);
  }

  @override
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) {
    return _delegate.export(request, format);
  }
}
