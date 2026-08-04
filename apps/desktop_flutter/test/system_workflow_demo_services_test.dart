import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/services/service_failure.dart';
import 'package:erp/features/audit_log/data/demo_audit_repository.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/authentication/data/demo_authentication_service.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/backup_restore/data/demo_backup_services.dart';
import 'package:erp/features/backup_restore/domain/backup_models.dart';
import 'package:erp/features/electronic_archive/data/demo_archive_services.dart';
import 'package:erp/features/electronic_archive/domain/archive_models.dart';
import 'package:erp/features/permissions/data/demo_role_repository.dart';
import 'package:erp/features/permissions/domain/permission_models.dart';
import 'package:erp/features/users/data/demo_user_repository.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('backup and Google Drive demo', () {
    test('cloud failure preserves a verified local backup', () async {
      final drive = DemoGoogleDriveBackupService();
      await drive.connect();
      drive.failNextUpload();
      final service = DemoBackupService(googleDriveService: drive);
      final configuration = BackupConfiguration(
        deviceId: 'test-device',
        localPath: r'D:\Backups',
        schedule: const BackupSchedule(
          isEnabled: true,
          frequency: BackupFrequency.daily,
        ),
        googleDriveFolderId: DemoGoogleDriveBackupService.folders.first.id,
      );

      final record = await service.createBackup(
        configuration: configuration,
        uploadToGoogleDrive: true,
      );

      expect(record.status, BackupStatus.uploadFailed);
      expect(record.localPath, endsWith('.backup'));
      expect(record.checksum, isNotEmpty);
      expect(record.failureMessage, contains('بقيت النسخة المحلية'));

      final verification = await service.verifyRestoreSource(
        StoredBackupSource(record.id),
      );
      expect(verification.canRestore, isTrue);
      expect(verification.checksumMatches, isTrue);

      await expectLater(
        service.restore(
          RestoreRequest(
            source: StoredBackupSource(record.id),
            confirmedByUser: false,
          ),
        ),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'restore_confirmation_required',
          ),
        ),
      );
    });

    test('Drive requires a connection before folder access', () async {
      final drive = DemoGoogleDriveBackupService();
      await expectLater(
        drive.listFolders(),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.kind,
            'kind',
            ServiceFailureKind.authenticationRequired,
          ),
        ),
      );
    });
  });

  group('electronic archive demo', () {
    final policy = ArchiveValidationPolicy(
      maximumByteSize: 10 * 1024 * 1024,
    );

    test('local preflight never authorizes upload', () async {
      final security = DemoArchiveSecurityService();
      final file = ArchiveFileCandidate(
        localPath: r'C:\Demo\invoice.pdf',
        fileName: 'invoice.pdf',
        byteSize: 1024,
        declaredMimeType: 'application/pdf',
      );

      final local = await security.validateLocally(
        file: file,
        policy: policy,
      );
      final authoritative = await security.scanAuthoritatively(
        file: file,
        policy: policy,
      );

      expect(local.authority, SecurityCheckAuthority.localPreflight);
      expect(local.isUploadAllowed, isFalse);
      expect(local.checksumSha256, hasLength(64));
      expect(
        authoritative.authority,
        SecurityCheckAuthority.serverAuthoritative,
      );
      expect(authoritative.scanStatus, MalwareScanStatus.clean);
      expect(authoritative.isUploadAllowed, isTrue);
    });

    test('simulated authoritative malware result gates upload', () async {
      final security = DemoArchiveSecurityService();
      final infected = ArchiveFileCandidate(
        localPath: r'C:\Demo\infected.png',
        fileName: 'infected.png',
        byteSize: 2048,
        declaredMimeType: 'image/png',
      );

      final report = await security.scanAuthoritatively(
        file: infected,
        policy: policy,
      );

      expect(report.scanStatus, MalwareScanStatus.infected);
      expect(report.isUploadAllowed, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains(ArchiveValidationIssueCode.malwareDetected),
      );
    });

    test('size and MIME-signature mismatches are reported', () async {
      final security = DemoArchiveSecurityService();
      final invalid = ArchiveFileCandidate(
        localPath: r'C:\Demo\oversized.pdf',
        fileName: 'oversized.pdf',
        byteSize: policy.maximumByteSize + 1,
        declaredMimeType: 'image/png',
      );

      final report = await security.validateLocally(
        file: invalid,
        policy: policy,
      );
      final codes = report.issues.map((issue) => issue.code);

      expect(codes, contains(ArchiveValidationIssueCode.fileTooLarge));
      expect(
        codes,
        contains(ArchiveValidationIssueCode.mimeSignatureMismatch),
      );
      expect(report.isUploadAllowed, isFalse);
    });

    test('repository supports upload search rename preview and delete',
        () async {
      final security = DemoArchiveSecurityService();
      final repository = DemoArchiveRepository(initialDocuments: const []);
      final file = ArchiveFileCandidate(
        localPath: r'C:\Demo\contract.pdf',
        fileName: 'contract.pdf',
        byteSize: 4096,
        declaredMimeType: 'application/pdf',
      );
      final report = await security.scanAuthoritatively(
        file: file,
        policy: policy,
      );
      final uploaded = await repository.upload(
        ArchiveUploadRequest(
          draft: ArchiveDocumentDraft(
            displayName: 'عقد اختبار',
            file: file,
            tags: const {'عقد'},
          ),
          securityReport: report,
        ),
      );

      expect(
        await repository.search(const ArchiveQuery(searchText: 'اختبار')),
        hasLength(1),
      );
      final renamed = await repository.rename(uploaded.id, 'عقد معدل');
      expect(renamed.displayName, 'عقد معدل');
      final preview = await repository.preparePreview(uploaded.id);
      expect(preview.localPath, file.localPath);
      expect((await repository.canDelete(uploaded.id)).isAllowed, isTrue);
      await repository.delete(uploaded.id);
      expect(await repository.getById(uploaded.id), isNull);
    });
  });

  group('users, permissions, sessions, and audit demo', () {
    test('user status is explicit and the system user is protected', () async {
      final users = DemoUserRepository();
      final updated = await users.setStatus(
        EntityId.demo('user', 2),
        UserAccountStatus.disabledAndLocked,
      );
      expect(updated.status, UserAccountStatus.disabledAndLocked);
      await expectLater(
        users.setStatus(
          EntityId.demo('user', 1),
          UserAccountStatus.disabled,
        ),
        throwsA(isA<ServiceFailure>()),
      );
    });

    test('role repository retains typed permissions', () async {
      final roles = DemoRoleRepository();
      final role = AppRole(
        id: EntityId.demo('role', 5),
        name: 'مدقق',
        permissions: {
          PermissionCode(
            module: 'reports',
            action: PermissionAction.view,
          ),
        },
        isSystemRole: false,
      );
      await roles.save(role);
      expect((await roles.getById(role.id))!.allows(role.permissions.single),
          isTrue);
    });

    test('password, session, and auto-lock operations use interfaces',
        () async {
      final authentication = DemoAuthenticationService();
      final policies = DemoSessionPolicyRepository();
      final locked = await authentication.lock(SessionLockReason.userRequest);
      expect(locked.state, SessionState.locked);
      expect((await authentication.unlock('password')).state,
          SessionState.active);

      await authentication.changePassword(
        PasswordChangeRequest(
          userId: EntityId.demo('user', 1),
          currentPassword: 'password',
          newPassword: 'new-password',
        ),
      );
      await authentication.signOut();
      expect(
        (await authentication.signIn(
          SignInCredentials(username: 'admin', password: 'new-password'),
        ))
            .state,
        SessionState.active,
      );

      await policies.saveAutoLockPolicy(
        AutoLockPolicy(
          isEnabled: true,
          idleTimeout: const Duration(minutes: 30),
        ),
      );
      expect(
        (await policies.loadAutoLockPolicy()).idleTimeout,
        const Duration(minutes: 30),
      );
    });

    test('audit records are append-only and searchable', () async {
      final audit = DemoAuditRepository(initialRecords: const []);
      final record = AuditRecord(
        id: EntityId.demo('audit', 20),
        occurredAt: AuditTimestamp(DateTime.utc(2026, 8, 5, 12)),
        actorUserId: EntityId.demo('user', 1),
        actorUsername: 'admin',
        action: AuditAction.permissionChange,
        outcome: AuditOutcome.success,
        summary: 'تحديث صلاحيات المدقق',
        details: const {'role': 'مدقق'},
      );
      await audit.append(record);

      final page = await audit.search(
        AuditQuery(
          searchText: 'المدقق',
          action: AuditAction.permissionChange,
        ),
      );
      expect(page.totalCount, 1);
      expect(page.records.single, same(record));
      await expectLater(audit.append(record), throwsA(isA<ServiceFailure>()));
    });
  });
}
