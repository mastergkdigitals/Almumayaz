import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/printing/desktop_document_output_service.dart';
import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/backup_restore/domain/backup_models.dart';
import 'package:erp/features/reports/application/document_report_output_service.dart';
import 'package:erp/features/reports/application/report_output_service.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppStore keeps one authenticated session and signs it out', () async {
    final store = AppStore.demo();

    final session = await store.signIn(
      SignInCredentials(username: 'admin', password: 'password'),
    );

    expect(store.session, same(session));
    expect(
      await store.services.authentication.currentSession(),
      same(session),
    );

    await store.signOut();

    expect(store.session, isNull);
    expect(await store.services.authentication.currentSession(), isNull);
  });

  test('workflow services are shared for the lifetime of the store', () async {
    final store = AppStore.demo();
    final services = store.services;

    expect(store.services, same(services));
    expect(
      store.services.backupConfiguration,
      same(services.backupConfiguration),
    );
    expect(store.services.backups, same(services.backups));
    expect(
      store.services.googleDriveBackups,
      same(services.googleDriveBackups),
    );
    expect(store.services.archive, same(services.archive));
    expect(store.services.users, same(services.users));
    expect(store.services.roles, same(services.roles));
    expect(store.services.audit, same(services.audit));
    expect(services.documentOutput, isA<DemoDocumentOutputService>());
    expect(services.reportOutput, isA<DemoReportOutputService>());

    await services.googleDriveBackups.connect();
    await services.users.setStatus(
      EntityId.demo('user', 2),
      UserAccountStatus.disabled,
    );

    expect(
      (await store.services.googleDriveBackups.connection()).status,
      CloudConnectionStatus.connected,
    );
    expect(
      (await store.services.users.search(const UserQuery()))
          .singleWhere((user) => user.id == EntityId.demo('user', 2))
          .status,
      UserAccountStatus.disabled,
    );
  });

  test('desktop composition replaces only output adapters', () {
    final store = AppStore.desktop();

    expect(store.services.documentOutput, isA<DesktopDocumentOutputService>());
    expect(
      store.services.reportOutput,
      isA<DocumentBackedReportOutputService>(),
    );
  });

  testWidgets('Login reports invalid credentials and Dashboard signs out', (
    tester,
  ) async {
    final store = AppStore.demo();
    await tester.pumpWidget(AlmumayazApp(store: store));

    await tester.enterText(
      find.byKey(const Key('usernameField')),
      'admin',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('loginAuthenticationError')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dashboardCard_settings')), findsNothing);
    expect(store.session, isNull);

    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password',
    );
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboardCard_settings')), findsOneWidget);
    expect(store.session?.state, SessionState.active);

    await tester.tap(find.byKey(const Key('dashboardLogout')));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(store.session, isNull);
    expect(await store.services.authentication.currentSession(), isNull);
  });

  testWidgets('Settings reuses workflow services after reopening a section', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore.demo();
    await tester.pumpWidget(AlmumayazApp(store: store));

    await tester.enterText(
      find.byKey(const Key('usernameField')),
      'admin',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password',
    );
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboardCard_settings')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settingsSectionCard_backup')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('settingsToggleDriveConnectionButton')),
    );
    await tester.pumpAndSettle();
    expect(find.text('الحساب مرتبط وجاهز للنسخ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settingsSectionCard_backup')),
    );
    await tester.pumpAndSettle();

    expect(find.text('الحساب مرتبط وجاهز للنسخ'), findsOneWidget);
    expect(
      (await store.services.googleDriveBackups.connection()).status,
      CloudConnectionStatus.connected,
    );
  });
}
