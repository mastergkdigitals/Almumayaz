import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/app_state/app_services.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/config/app_configuration.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/services/service_failure.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/authentication/data/demo_authentication_service.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/authentication/presentation/session_activity_guard.dart';
import 'package:erp/features/dashboard/presentation/dashboard_screen.dart';
import 'package:erp/features/permissions/domain/permission_models.dart';
import 'package:erp/features/settings/presentation/settings_screen.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shared AppServices identity composition', () {
    test(
      'user, credential, role, authentication, and audit changes stay coherent',
      () async {
        final store = _demoStoreWithIdleMonitoringSuspended();
        addTearDown(store.dispose);
        final services = store.services;

        await store.signIn(
          SignInCredentials(username: 'admin', password: 'password'),
        );
        final limitedRole = await services.administration.saveRole(
          RoleSaveRequest(
            name: 'مبيعات محدودة',
            permissions: {
              PermissionCode(
                module: 'sales',
                action: PermissionAction.view,
              ),
            },
          ),
        );
        final limitedUser = await services.administration.createUser(
          UserCreateRequest(
            fullName: 'مستخدم محدود',
            username: 'limited.user',
            roleIds: {limitedRole.id},
            initialPassword: 'first-password',
          ),
        );
        await services.administration.resetUserPassword(
          AdminPasswordResetRequest(
            userId: limitedUser.id,
            newPassword: 'second-password',
          ),
        );
        await services.administration.setUserStatus(
          limitedUser.id,
          UserAccountStatus.disabled,
        );
        await store.signOut();

        await expectLater(
          store.signIn(
            SignInCredentials(
              username: limitedUser.username,
              password: 'second-password',
            ),
          ),
          throwsA(
            isA<ServiceFailure>().having(
              (failure) => failure.code,
              'code',
              'account_disabled',
            ),
          ),
        );

        await store.signIn(
          SignInCredentials(username: 'admin', password: 'password'),
        );
        await services.administration.setUserStatus(
          limitedUser.id,
          UserAccountStatus.active,
        );
        await store.signOut();

        await expectLater(
          store.signIn(
            SignInCredentials(
              username: limitedUser.username,
              password: 'first-password',
            ),
          ),
          throwsA(
            isA<ServiceFailure>().having(
              (failure) => failure.code,
              'code',
              'invalid_credentials',
            ),
          ),
        );
        final limitedSession = await store.signIn(
          SignInCredentials(
            username: limitedUser.username,
            password: 'second-password',
          ),
        );

        expect(
          await services.users.getByUsername(limitedUser.username),
          isA<AppUser>()
              .having((user) => user.id, 'id', limitedUser.id)
              .having(
                (user) => user.status,
                'status',
                UserAccountStatus.active,
              ),
        );
        expect(
          limitedSession.allows(
            PermissionCode(
              module: 'sales',
              action: PermissionAction.view,
            ),
          ),
          isTrue,
        );
        expect(
          limitedSession.allows(
            PermissionCode(
              module: 'reports',
              action: PermissionAction.view,
            ),
          ),
          isFalse,
        );

        final auditPage = await services.audit.search(AuditQuery(limit: 200));
        expect(
          auditPage.records,
          contains(
            isA<AuditRecord>()
                .having(
                  (record) => record.action,
                  'action',
                  AuditAction.permissionChange,
                )
                .having(
                  (record) => record.entityId,
                  'role id',
                  limitedRole.id,
                ),
          ),
        );
        final userAuditActions = auditPage.records
            .where((record) => record.entityId == limitedUser.id)
            .map((record) => record.action);
        expect(
          userAuditActions,
          containsAll([
            AuditAction.create,
            AuditAction.passwordChange,
            AuditAction.accountStatusChange,
          ]),
        );
        expect(
          auditPage.records,
          contains(
            isA<AuditRecord>()
                .having(
                  (record) => record.actorUserId,
                  'actor',
                  limitedUser.id,
                )
                .having(
                  (record) => record.action,
                  'action',
                  AuditAction.signIn,
                )
                .having(
                  (record) => record.outcome,
                  'outcome',
                  AuditOutcome.blocked,
                ),
          ),
        );
      },
    );
  });

  group('AppStore session state', () {
    test('lock, failed unlock, unlock, and hydration remain synchronized',
        () async {
      final services = AppServices.demo();
      final store = AppStore(
        repositories: AppRepositories.demo(),
        services: services,
      )..suspendIdleMonitoring();
      final hydratedStore = AppStore(
        repositories: AppRepositories.demo(),
        services: services,
      )..suspendIdleMonitoring();
      addTearDown(store.dispose);
      addTearDown(hydratedStore.dispose);

      final signedIn = await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final locked = await store.lock(SessionLockReason.userRequest);

      expect(locked.state, SessionState.locked);
      expect(store.requiresAuthentication, isTrue);
      await expectLater(
        store.unlock('wrong-password'),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'unlock_password_invalid',
          ),
        ),
      );
      expect(store.session?.state, SessionState.locked);
      expect(
        (await services.authentication.currentSession())?.state,
        SessionState.locked,
      );

      final unlocked = await store.unlock('password');
      expect(unlocked.id, signedIn.id);
      expect(unlocked.state, SessionState.active);
      expect(store.requiresAuthentication, isFalse);

      await hydratedStore.refreshSession();
      expect(hydratedStore.session?.id, signedIn.id);
      expect(hydratedStore.session?.state, SessionState.active);
      expect(hydratedStore.requiresAuthentication, isFalse);

      await services.authentication.lock(
        signedIn.id,
        SessionLockReason.systemLock,
      );
      await hydratedStore.refreshSession();
      expect(hydratedStore.session?.state, SessionState.locked);
      expect(hydratedStore.requiresAuthentication, isTrue);
    });

    test('activity refresh adopts an authoritative expiry or sign-out',
        () async {
      final store = _demoStoreWithIdleMonitoringSuspended();
      addTearDown(store.dispose);
      final active = await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final authentication =
          store.services.authentication as DemoAuthenticationService;

      authentication.identityState.currentSession = AppSession(
        id: active.id,
        userId: active.userId,
        issuedAt: active.issuedAt,
        lastActivityAt: active.lastActivityAt,
        state: SessionState.expired,
        permissions: active.permissions,
      );
      await store.recordActivity();
      expect(store.session?.state, SessionState.expired);
      expect(store.requiresAuthentication, isTrue);

      await store.signOut();
      await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      authentication.identityState.currentSession = null;
      await store.recordActivity();
      expect(store.session, isNull);
      expect(store.requiresAuthentication, isTrue);
    });

    test('activity refresh rejects a different authoritative session',
        () async {
      final services = AppServices.demo();
      final oldStore = AppStore(
        repositories: AppRepositories.demo(),
        services: services,
      )..suspendIdleMonitoring();
      final replacementStore = AppStore(
        repositories: AppRepositories.demo(),
        services: services,
      )..suspendIdleMonitoring();
      addTearDown(oldStore.dispose);
      addTearDown(replacementStore.dispose);

      final oldSession = await oldStore.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final replacement = await replacementStore.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      expect(replacement.id, isNot(oldSession.id));
      final replacementActivity = replacement.lastActivityAt;

      await oldStore.recordActivity();
      expect(oldStore.session, isNull);
      expect(oldStore.requiresAuthentication, isTrue);
      expect(replacementStore.session?.id, replacement.id);
      expect(
        (await services.authentication.currentSession())?.lastActivityAt,
        replacementActivity,
      );

      await oldStore.refreshSession();
      expect(oldStore.session, isNull);
      expect(oldStore.requiresAuthentication, isTrue);
    });

    test('stale stores cannot sign out or lock a replacement session',
        () async {
      Future<({
        AppStore stale,
        AppStore replacement,
        AppServices services,
        AppSession replacementSession,
      })> createPair() async {
        final services = AppServices.demo();
        final stale = AppStore(
          repositories: AppRepositories.demo(),
          services: services,
        )..suspendIdleMonitoring();
        final replacement = AppStore(
          repositories: AppRepositories.demo(),
          services: services,
        )..suspendIdleMonitoring();
        addTearDown(stale.dispose);
        addTearDown(replacement.dispose);
        await stale.signIn(
          SignInCredentials(username: 'admin', password: 'password'),
        );
        final replacementSession = await replacement.signIn(
          SignInCredentials(username: 'admin', password: 'password'),
        );
        return (
          stale: stale,
          replacement: replacement,
          services: services,
          replacementSession: replacementSession,
        );
      }

      final signOutPair = await createPair();
      await signOutPair.stale.signOut();
      expect(signOutPair.stale.session, isNull);
      expect(
        (await signOutPair.services.authentication.currentSession())?.id,
        signOutPair.replacementSession.id,
      );

      final lockPair = await createPair();
      await expectLater(
        lockPair.stale.lock(SessionLockReason.userRequest),
        throwsA(
          isA<ServiceFailure>().having(
            (failure) => failure.code,
            'code',
            'session_replaced',
          ),
        ),
      );
      expect(lockPair.stale.session, isNull);
      expect(lockPair.stale.requiresAuthentication, isTrue);
      expect(
        (await lockPair.services.authentication.currentSession())?.id,
        lockPair.replacementSession.id,
      );
      expect(lockPair.replacement.session?.state, SessionState.active);
    });

    test('an explicitly signed-out store cannot hydrate another session',
        () async {
      final services = AppServices.demo();
      final signedOutStore = AppStore(
        repositories: AppRepositories.demo(),
        services: services,
      )..suspendIdleMonitoring();
      final otherStore = AppStore(
        repositories: AppRepositories.demo(),
        services: services,
      )..suspendIdleMonitoring();
      addTearDown(signedOutStore.dispose);
      addTearDown(otherStore.dispose);

      await signedOutStore.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      await signedOutStore.signOut();
      final otherSession = await otherStore.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );

      await signedOutStore.refreshSession();
      expect(signedOutStore.session, isNull);
      expect(signedOutStore.requiresAuthentication, isFalse);
      expect(
        (await services.authentication.currentSession())?.id,
        otherSession.id,
      );
    });

    test('failed idle lock adopts an authoritative remote sign-out',
        () async {
      final store = _demoStoreWithIdleMonitoringSuspended();
      addTearDown(store.dispose);
      await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      await store.services.authentication.signOut(store.session!.id);

      await expectLater(
        store.lock(SessionLockReason.idleTimeout),
        throwsA(isA<ServiceFailure>()),
      );
      expect(store.session, isNull);
      expect(store.requiresAuthentication, isTrue);
    });
  });

  group('SessionActivityGuard', () {
    testWidgets('locked overlay rejects a wrong password and accepts the right one',
        (tester) async {
      final store = _demoStoreWithIdleMonitoringSuspended();
      addTearDown(store.dispose);
      await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      await store.lock(SessionLockReason.userRequest);
      var requireSignInCalls = 0;

      await tester.pumpWidget(
        _guardHarness(
          store: store,
          onRequireSignIn: () async {
            requireSignInCalls++;
          },
        ),
      );

      expect(find.byKey(const Key('sessionLockOverlay')), findsOneWidget);
      expect(find.text('الجلسة مقفلة'), findsOneWidget);
      expect(
        find.byKey(const Key('sessionUnlockPasswordField')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('sessionUnlockPasswordField')),
        'wrong-password',
      );
      await tester.tap(find.byKey(const Key('sessionUnlockButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const Key('sessionUnlockError')), findsOneWidget);
      expect(store.session?.state, SessionState.locked);

      await tester.enterText(
        find.byKey(const Key('sessionUnlockPasswordField')),
        'password',
      );
      await tester.tap(find.byKey(const Key('sessionUnlockButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const Key('sessionLockOverlay')), findsNothing);
      expect(find.byKey(const Key('protectedSessionContent')), findsOneWidget);
      expect(store.session?.state, SessionState.active);
      expect(requireSignInCalls, 0);
      store.suspendIdleMonitoring();
    });

    testWidgets('missing session blocks content and returns to sign in',
        (tester) async {
      final store = _demoStoreWithIdleMonitoringSuspended();
      addTearDown(store.dispose);
      await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      await store.services.authentication.signOut(store.session!.id);
      await store.refreshSession();
      var requireSignInCalls = 0;

      await tester.pumpWidget(
        _guardHarness(
          store: store,
          onRequireSignIn: () async {
            requireSignInCalls++;
          },
        ),
      );

      expect(store.session, isNull);
      expect(store.requiresAuthentication, isTrue);
      expect(find.text('الجلسة غير نشطة'), findsOneWidget);
      expect(
        find.byKey(const Key('sessionUnlockPasswordField')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('sessionUnlockButton')));
      await tester.pump();
      expect(requireSignInCalls, 1);
    });

    testWidgets('expired session uses the non-unlockable sign-in path',
        (tester) async {
      final store = _demoStoreWithIdleMonitoringSuspended();
      addTearDown(store.dispose);
      final active = await store.signIn(
        SignInCredentials(username: 'admin', password: 'password'),
      );
      final authentication =
          store.services.authentication as DemoAuthenticationService;
      authentication.identityState.currentSession = AppSession(
        id: active.id,
        userId: active.userId,
        issuedAt: active.issuedAt,
        lastActivityAt: active.lastActivityAt,
        state: SessionState.expired,
        permissions: active.permissions,
      );
      await store.refreshSession();
      var requireSignInCalls = 0;

      await tester.pumpWidget(
        _guardHarness(
          store: store,
          onRequireSignIn: () async {
            requireSignInCalls++;
          },
        ),
      );

      expect(store.session?.state, SessionState.expired);
      expect(find.text('الجلسة غير نشطة'), findsOneWidget);
      expect(
        find.byKey(const Key('sessionUnlockPasswordField')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('sessionUnlockButton')));
      await tester.pump();
      expect(requireSignInCalls, 1);
    });
  });

  testWidgets('Dashboard only shows modules granted to a limited user',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _demoStoreWithIdleMonitoringSuspended();
    addTearDown(store.dispose);

    await store.signIn(
      SignInCredentials(username: 'admin', password: 'password'),
    );
    final role = await store.services.administration.saveRole(
      RoleSaveRequest(
        name: 'عرض المبيعات فقط',
        permissions: {
          PermissionCode(
            module: 'sales',
            action: PermissionAction.view,
          ),
        },
      ),
    );
    final user = await store.services.administration.createUser(
      UserCreateRequest(
        fullName: 'مستخدم لوحة محدود',
        username: 'dashboard.limited',
        roleIds: {role.id},
        initialPassword: 'limited-password',
      ),
    );
    await store.signOut();
    await store.signIn(
      SignInCredentials(
        username: user.username,
        password: 'limited-password',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppConfigurationScope(
          configuration: AppConfiguration.internal(),
          child: AppStoreScope(
            store: store,
            child: DashboardScreen(username: user.fullName),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('dashboardCard_sales')), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_company')), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_about')), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_cashbox')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_parties')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_warehouses')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_reports')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_settings')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStoreScope(
          store: store,
          child: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('settingsViewPermissionRequired')),
      findsOneWidget,
    );
  });

  testWidgets(
      'settings.view exposes the hub while management sections stay gated',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _demoStoreWithIdleMonitoringSuspended();
    addTearDown(store.dispose);
    await store.signIn(
      SignInCredentials(username: 'admin', password: 'password'),
    );
    final viewer = await store.services.administration.createUser(
      UserCreateRequest(
        fullName: 'مستخدم عرض الإعدادات',
        username: 'settings.viewer.test',
        roleIds: {EntityId.demo('role', 4)},
        initialPassword: 'viewer-password',
      ),
    );
    await store.signOut();
    await store.signIn(
      SignInCredentials(
        username: viewer.username,
        password: 'viewer-password',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppStoreScope(
          store: store,
          child: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settingsHub')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('settingsSectionCard_backup')),
    );
    await tester.pump();
    expect(find.byKey(const Key('settingsHub')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('settingsSectionCard_usersSecurity')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('usersSecuritySettingsContent')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsAddUserButton')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('settingsAddUserButton')));
    await tester.pump();
    expect(
      find.byKey(const Key('settingsUserDialog_new')),
      findsNothing,
    );
  });
}

AppStore _demoStoreWithIdleMonitoringSuspended() {
  return AppStore(
    repositories: AppRepositories.demo(),
    services: AppServices.demo(),
  )..suspendIdleMonitoring();
}

Widget _guardHarness({
  required AppStore store,
  required Future<void> Function() onRequireSignIn,
}) {
  return MaterialApp(
    home: AppStoreScope(
      store: store,
      child: SessionActivityGuard(
        onRequireSignIn: onRequireSignIn,
        child: const Scaffold(
          body: Center(
            child: Text(
              'محتوى محمي',
              key: Key('protectedSessionContent'),
            ),
          ),
        ),
      ),
    ),
  );
}
