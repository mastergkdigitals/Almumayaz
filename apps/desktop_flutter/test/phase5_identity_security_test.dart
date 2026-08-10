import 'dart:async';

import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/services/service_failure.dart';
import 'package:erp/features/audit_log/data/demo_audit_repository.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/authentication/data/demo_authentication_service.dart';
import 'package:erp/features/authentication/data/demo_identity_state.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/permissions/data/demo_role_repository.dart';
import 'package:erp/features/permissions/domain/permission_models.dart';
import 'package:erp/features/users/data/demo_user_repository.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shared demo identity state', () {
    test('created users authenticate with permissions from assigned roles',
        () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      final authentication = DemoAuthenticationService(state: state);
      final administration =
          DemoSecurityAdministrationService(state: state);
      final users = DemoUserRepository(state: state);

      final created = await administration.createUser(
        UserCreateRequest(
          fullName: 'مستخدم مبيعات',
          username: 'sales.user',
          roleIds: {
            EntityId.demo('role', 2),
            EntityId.demo('role', 3),
          },
          initialPassword: 'sales-password',
        ),
      );
      await authentication.signOut(
        (await authentication.currentSession())!.id,
      );
      final session = await authentication.signIn(
        SignInCredentials(
          username: 'sales.user',
          password: 'sales-password',
        ),
      );

      expect(session.userId, created.id);
      expect(
        session.allows(
          PermissionCode(
            module: 'sales',
            action: PermissionAction.create,
          ),
        ),
        isTrue,
      );
      expect(
        session.allows(
          PermissionCode(
            module: 'cashbox',
            action: PermissionAction.create,
          ),
        ),
        isTrue,
      );
      expect(
        session.allows(
          PermissionCode(
            module: 'purchases',
            action: PermissionAction.create,
          ),
        ),
        isFalse,
      );
      expect((await users.getById(created.id))!.lastLoginAt, isNotNull);
    });

    test('stale profile saves preserve the authentication-owned last login',
        () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      final authentication = DemoAuthenticationService(state: state);
      final users = DemoUserRepository(state: state);
      final userId = EntityId.demo('user', 2);
      final staleProfile = (await users.getById(userId))!;

      await authentication.signOut(
        (await authentication.currentSession())!.id,
      );
      await authentication.signIn(
        SignInCredentials(username: 'ahmed', password: 'demo123'),
      );
      final signedInProfile = (await users.getById(userId))!;
      expect(
        signedInProfile.lastLoginAt,
        isNot(staleProfile.lastLoginAt),
      );

      await users.save(staleProfile.copyWith(fullName: 'أحمد المحدّث'));
      final saved = (await users.getById(userId))!;
      expect(saved.fullName, 'أحمد المحدّث');
      expect(saved.lastLoginAt, signedInProfile.lastLoginAt);
    });

    test('locked users are blocked and unknown usernames retain no fake ID',
        () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      final authentication = DemoAuthenticationService(
        state: state,
        startsAuthenticated: false,
      );

      await expectLater(
        authentication.signIn(
          SignInCredentials(username: 'sara', password: 'demo123'),
        ),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'account_locked',
          ),
        ),
      );
      await expectLater(
        authentication.signIn(
          SignInCredentials(username: 'ghost', password: 'not-valid'),
        ),
        throwsA(isA<ServiceFailure>()),
      );

      expect(state.auditRecords, hasLength(2));
      expect(state.auditRecords.first.outcome, AuditOutcome.blocked);
      expect(state.auditRecords.last.actorUserId, isNull);
      expect(state.auditRecords.last.actorUsername, 'ghost');
    });

    test('administrator reset never requires the target current password',
        () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      final authentication = DemoAuthenticationService(state: state);
      final administration =
          DemoSecurityAdministrationService(state: state);

      await administration.resetUserPassword(
        AdminPasswordResetRequest(
          userId: EntityId.demo('user', 2),
          newPassword: 'replacement-password',
        ),
      );
      await authentication.signOut(
        (await authentication.currentSession())!.id,
      );

      await expectLater(
        authentication.signIn(
          SignInCredentials(username: 'ahmed', password: 'demo123'),
        ),
        throwsA(isA<ServiceFailure>()),
      );
      final session = await authentication.signIn(
        SignInCredentials(
          username: 'ahmed',
          password: 'replacement-password',
        ),
      );
      expect(session.userId, EntityId.demo('user', 2));
      expect(
        state.auditRecords.map((record) => record.action),
        contains(AuditAction.passwordChange),
      );
    });

    test('stored disabled state blocks sign-in without activity audit spam',
        () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      final authentication = DemoAuthenticationService(state: state);
      final administration =
          DemoSecurityAdministrationService(state: state);

      await administration.setUserStatus(
        EntityId.demo('user', 2),
        UserAccountStatus.disabled,
      );
      await authentication.recordActivity(
        (await authentication.currentSession())!.id,
      );
      expect(
        state.auditRecords
            .where((record) => record.action == AuditAction.activity),
        isEmpty,
      );
      await authentication.signOut(
        (await authentication.currentSession())!.id,
      );
      await expectLater(
        authentication.signIn(
          SignInCredentials(username: 'ahmed', password: 'demo123'),
        ),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'account_disabled',
          ),
        ),
      );
      expect(state.auditRecords.last.outcome, AuditOutcome.blocked);
    });

    test('session policy management requires settings.manage in shared state',
        () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      final authentication = DemoAuthenticationService(state: state);
      final administration =
          DemoSecurityAdministrationService(state: state);
      final policies = DemoSessionPolicyRepository(state: state);

      await policies.saveAutoLockPolicy(
        AutoLockPolicy(
          isEnabled: true,
          idleTimeout: const Duration(minutes: 30),
        ),
      );
      final viewer = await administration.createUser(
        UserCreateRequest(
          fullName: 'مستخدم عرض',
          username: 'settings.viewer',
          roleIds: {EntityId.demo('role', 4)},
          initialPassword: 'viewer-password',
        ),
      );
      await authentication.signOut(
        (await authentication.currentSession())!.id,
      );
      await authentication.signIn(
        SignInCredentials(
          username: viewer.username,
          password: 'viewer-password',
        ),
      );

      await expectLater(
        policies.saveAutoLockPolicy(
          AutoLockPolicy(
            isEnabled: true,
            idleTimeout: const Duration(minutes: 5),
          ),
        ),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'manage_session_policy_permission_required',
          ),
        ),
      );
      expect(
        (await policies.loadAutoLockPolicy()).idleTimeout,
        const Duration(minutes: 30),
      );
    });
  });

  group('identity invariants', () {
    test('missing role references and system-flag replacement are rejected',
        () async {
      final state = DemoIdentityState();
      final users = DemoUserRepository(state: state);
      final roles = DemoRoleRepository(state: state);
      final systemUser = (await users.getById(EntityId.demo('user', 1)))!;
      final systemRole = (await roles.getById(EntityId.demo('role', 1)))!;

      await expectLater(
        users.save(
          AppUser(
            id: EntityId.demo('user', 20),
            fullName: 'مرجع مفقود',
            username: 'missing.role',
            roleIds: {EntityId.demo('role', 999)},
            status: UserAccountStatus.active,
            isSystemUser: false,
          ),
        ),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'user_role_not_found',
          ),
        ),
      );
      await expectLater(
        users.save(systemUser.copyWith(isSystemUser: false)),
        throwsA(isA<ServiceFailure>()),
      );
      await expectLater(
        users.save(
          systemUser.copyWith(
            roleIds: {
              ...systemUser.roleIds,
              EntityId.demo('role', 2),
            },
          ),
        ),
        throwsA(isA<ServiceFailure>()),
      );
      await expectLater(
        roles.save(systemRole.copyWith(isSystemRole: false)),
        throwsA(isA<ServiceFailure>()),
      );
    });

    test('assigned roles are protected by the shared relationship check',
        () async {
      final state = DemoIdentityState();
      final authentication = DemoAuthenticationService(state: state);
      final administration =
          DemoSecurityAdministrationService(state: state);

      await expectLater(
        administration.deleteRole(EntityId.demo('role', 2)),
        throwsA(
          isA<ServiceFailure>()
              .having((failure) => failure.code, 'code', 'role_has_users')
              .having(
                (failure) => failure.message,
                'message',
                'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
              ),
        ),
      );

      final unused = await administration.saveRole(
        RoleSaveRequest(
          name: 'دور غير مستخدم',
          permissions: {
            PermissionCode(
              module: 'reports',
              action: PermissionAction.view,
            ),
          },
        ),
      );
      await administration.deleteRole(unused.id);
      expect(state.rolesById.containsKey(unused.id), isFalse);
      expect(await authentication.currentSession(), isNotNull);
    });

    test('deleted identities never cause stable IDs to be reused', () async {
      final state = DemoIdentityState(initialAuditRecords: const []);
      DemoAuthenticationService(state: state);
      final administration =
          DemoSecurityAdministrationService(state: state);

      final first = await administration.createUser(
        UserCreateRequest(
          fullName: 'مستخدم أول',
          username: 'stable.first',
          roleIds: {EntityId.demo('role', 2)},
          initialPassword: 'password-one',
        ),
      );
      await administration.deleteUser(first.id);
      final second = await administration.createUser(
        UserCreateRequest(
          fullName: 'مستخدم ثان',
          username: 'stable.second',
          roleIds: {EntityId.demo('role', 2)},
          initialPassword: 'password-two',
        ),
      );

      expect(first.id, EntityId.demo('user', 4));
      expect(second.id, EntityId.demo('user', 5));
      expect(second.id, isNot(first.id));
    });
  });

  test('audit writer allocates monotonic metadata from the current actor',
      () async {
    final state = DemoIdentityState(initialAuditRecords: const []);
    DemoAuthenticationService(state: state);
    final writer = DemoIdentityAuditWriter(state: state);

    final first = await writer.write(
      AuditEvent(
        action: AuditAction.backup,
        outcome: AuditOutcome.success,
        summary: 'إنشاء نسخة اختبارية',
      ),
    );
    final second = await writer.write(
      AuditEvent(
        action: AuditAction.export,
        outcome: AuditOutcome.success,
        summary: 'تصدير اختبار',
      ),
    );

    expect(first.actorUsername, 'admin');
    expect(first.metadata.deviceId, 'demo-windows-device');
    expect(first.metadata.requestId, isNot(second.metadata.requestId));
    expect(first.id, EntityId.demo('audit', 6));
    expect(second.id, EntityId.demo('audit', 7));
  });

  test('append-only audit metadata cannot be changed by caller maps',
      () async {
    final state = DemoIdentityState(initialAuditRecords: const []);
    final repository = DemoAuditRepository(state: state);
    final before = <String, Object?>{'name': 'قبل'};
    final after = <String, Object?>{'name': 'بعد'};
    final record = AuditRecord(
      id: EntityId.demo('audit', 20),
      occurredAt: AuditTimestamp(DateTime.utc(2026, 8, 10)),
      actorUserId: EntityId.demo('user', 1),
      actorUsername: 'admin',
      action: AuditAction.update,
      outcome: AuditOutcome.success,
      summary: 'اختبار ثبات بيانات التدقيق',
      details: const {},
      metadata: AuditMetadata(
        deviceId: 'test-device',
        requestId: 'test-request',
        before: before,
        after: after,
      ),
    );

    await repository.append(record);
    before['name'] = 'تم العبث';
    after['name'] = 'تم العبث';
    final stored = (await repository.search(AuditQuery())).records.single;
    expect(stored.metadata.before['name'], 'قبل');
    expect(stored.metadata.after['name'], 'بعد');
    expect(
      () => stored.metadata.before['name'] = 'غير مسموح',
      throwsUnsupportedError,
    );
  });

  test('queued audit writes snapshot event maps at construction', () async {
    final state = DemoIdentityState(initialAuditRecords: const []);
    DemoAuthenticationService(state: state);
    final writer = DemoIdentityAuditWriter(state: state);
    final release = Completer<void>();
    final blocker = state.mutate(() => release.future);
    final details = <String, Object?>{'mode': 'before'};
    final before = <String, Object?>{'value': 1};
    final after = <String, Object?>{'value': 2};
    final pending = writer.write(
      AuditEvent(
        action: AuditAction.update,
        outcome: AuditOutcome.success,
        summary: 'اختبار لقطة حدث التدقيق',
        details: details,
        before: before,
        after: after,
      ),
    );

    details['mode'] = 'mutated';
    before['value'] = 99;
    after['value'] = 100;
    release.complete();
    await blocker;
    final stored = await pending;

    expect(stored.details['mode'], 'before');
    expect(stored.metadata.before['value'], 1);
    expect(stored.metadata.after['value'], 2);
  });
}
