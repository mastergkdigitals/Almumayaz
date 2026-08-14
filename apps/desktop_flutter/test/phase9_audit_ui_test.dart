import 'dart:async';

import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/audit_log/domain/audit_repository.dart';
import 'package:erp/features/authentication/data/demo_authentication_service.dart';
import 'package:erp/features/authentication/data/demo_identity_state.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/authentication/presentation/session_activity_guard.dart';
import 'package:erp/features/settings/presentation/widgets/settings_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('audit log exposes every 100-record page and clamps navigation',
      (tester) async {
    final records = List<AuditRecord>.generate(
      205,
      (index) => _auditRecord(index + 1),
    );
    final bundle = DemoIdentityServiceBundle(
      state: DemoIdentityState(initialAuditRecords: records),
    );
    final audit = _CascadeShrinkAuditRepository(
      state: bundle.state,
      delegate: bundle.audit,
    );
    await _pumpSecuritySection(
      tester,
      bundle: bundle,
      auditRepository: audit,
    );
    await _openLogs(tester);

    AppDataTable table() => tester.widget<AppDataTable>(
          find.byKey(const Key('settingsSecurityLogsTable')),
        );

    expect(table().rows, hasLength(100));
    expect(find.text('عرض 1–100 من 205 — الصفحة 1 من 3'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const Key('settingsSecurityLogNextPageButton')),
    );
    expect(table().rows, hasLength(100));
    expect(find.text('عرض 101–200 من 205 — الصفحة 2 من 3'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const Key('settingsSecurityLogLastPageButton')),
    );
    expect(table().rows, hasLength(5));
    expect(find.text('عرض 201–205 من 205 — الصفحة 3 من 3'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('settingsSecurityLogNextPageButton')),
          )
          .onPressed,
      isNull,
    );

    audit.shrinkAcrossCorrectiveSearches = true;
    _scrollSecurityToTop(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settingsSecurityLogRefreshButton')),
    );
    await tester.pumpAndSettle();
    expect(table().rows, hasLength(50));
    expect(find.text('عرض 1–50 من 50 — الصفحة 1 من 1'), findsOneWidget);

    bundle.state.auditRecords.clear();
    await tester.tap(
      find.byKey(const Key('settingsSecurityLogRefreshButton')),
    );
    await tester.pumpAndSettle();
    expect(table().rows, isEmpty);
    expect(find.text('عرض 0–0 من 0 — الصفحة 1 من 1'), findsOneWidget);
  });

  testWidgets('newer filter wins and refresh errors stay inside audit panel',
      (tester) async {
    final state = DemoIdentityState(
      initialAuditRecords: [
        _auditRecord(1, summary: 'سجل قديم'),
        _auditRecord(2, summary: 'سجل أحدث'),
      ],
    );
    final bundle = DemoIdentityServiceBundle(state: state);
    final audit = _ControlledAuditRepository(bundle.audit);
    await _pumpSecuritySection(
      tester,
      bundle: bundle,
      auditRepository: audit,
    );
    await _openLogs(tester);

    audit.delaySearchText = 'قديم';
    await tester.enterText(
      find.byKey(const Key('settingsSecurityLogSearchField')),
      'قديم',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('settingsSecurityLogsTable')),
          )
          .isLoading,
      isTrue,
    );

    await tester.enterText(
      find.byKey(const Key('settingsSecurityLogSearchField')),
      'أحدث',
    );
    await tester.pump();
    await tester.pump();
    expect(_auditSummaries(tester), ['سجل أحدث']);

    await audit.completeDelayedSearch();
    await tester.pump();
    expect(_auditSummaries(tester), ['سجل أحدث']);

    audit.failNextSearch = true;
    _scrollSecurityToTop(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settingsSecurityLogRefreshButton')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settingsSecurityLogRefreshError')),
      findsOneWidget,
    );
    expect(_auditSummaries(tester), ['سجل أحدث']);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settingsSecurityLogRefreshError')),
      findsNothing,
    );
  });

  testWidgets('initial audit failure is terminal and retry-only',
      (tester) async {
    final bundle = DemoIdentityServiceBundle();
    await _pumpSecuritySection(
      tester,
      bundle: bundle,
      auditRepository: _FailingAuditRepository(bundle.audit),
    );

    expect(
      find.byKey(const Key('settingsUsersSecurityLoadError')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('usersSecurityTab_users')), findsNothing);
    expect(find.byKey(const Key('settingsUsersTable')), findsNothing);
  });

  testWidgets('deleted audit actor remains selectable by historical snapshot',
      (tester) async {
    final bundle = DemoIdentityServiceBundle();
    await _pumpSecuritySection(tester, bundle: bundle);
    await _openLogs(tester);

    await tester.tap(
      find.byKey(const Key('settingsSecurityLogUserField')),
    );
    await tester.pump();
    await tester.tap(find.text('أحمد كريم (ahmed)').last);
    await tester.pumpAndSettle();

    _scrollSecurityToTop(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usersSecurityTab_users')));
    await tester.pump();
    tester
        .widget<AppTableActionButton>(
          find.byKey(const Key('settingsUserDelete_demo-user-2')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('usersSecurityTab_logs')));
    await tester.pumpAndSettle();
    final userFilterFinder = find.ancestor(
      of: find.byKey(const Key('settingsSecurityLogUserField')),
      matching: find.byType(AppDropdownField<String>),
    );
    expect(userFilterFinder, findsOneWidget);
    final userFilter = tester.widget<AppDropdownField<String>>(
      userFilterFinder,
    );
    expect(userFilter.value, 'demo-user-2');
    expect(
      userFilter.options
          .singleWhere((option) => option.value == 'demo-user-2')
          .label,
      contains('محذوف'),
    );
  });

  testWidgets('audit details are complete, localized, RTL-safe, and semantic',
      (tester) async {
    final handle = tester.ensureSemantics();
    final record = _auditRecord(
      20,
      summary: 'تحديث حساب الاختبار',
      ipAddress: '192.168.1.10',
      macAddress: '00-11-22-33-44-55',
    );
    final bundle = DemoIdentityServiceBundle(
      state: DemoIdentityState(initialAuditRecords: [record]),
    );
    await _pumpSecuritySection(tester, bundle: bundle);
    await _openLogs(tester);

    await tester.enterText(
      find.byKey(const Key('settingsSecurityLogSearchField')),
      '192.168.1.10',
    );
    await tester.pumpAndSettle();

    expect(find.semantics.byLabel('سجل التدقيق'), findsOne);
    expect(
      find.semantics.byLabel(RegExp('تحديث حساب الاختبار')),
      findsOne,
    );
    await tester.tap(
      find.byKey(const Key('settingsAuditRow_demo-audit-20')),
    );
    await tester.pumpAndSettle();

    final detailsDialog = find.byKey(
      const Key('settingsAuditDetailsDialog_demo-audit-20'),
    );
    expect(detailsDialog, findsOneWidget);
    expect(find.text('معرّف سجل التدقيق:'), findsOneWidget);
    expect(find.text('demo-audit-20'), findsOneWidget);
    expect(find.text('التاريخ والوقت:'), findsOneWidget);
    expect(find.text('معرّف المستخدم:'), findsOneWidget);
    expect(find.text('demo-user-1'), findsWidgets);
    expect(find.text('عنوان IP:'), findsOneWidget);
    expect(
      find.descendant(
        of: detailsDialog,
        matching: find.text('192.168.1.10'),
      ),
      findsOneWidget,
    );
    expect(find.text('عنوان MAC:'), findsOneWidget);
    expect(find.text('00-11-22-33-44-55'), findsOneWidget);
    expect(find.text('الحالة: نشط'), findsWidgets);
    expect(find.textContaining('status='), findsNothing);
    handle.dispose();
  });

  testWidgets('unlock announces empty password and refreshes live session UI',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore.demo();
    addTearDown(store.dispose);
    await store.signIn(
      SignInCredentials(username: 'admin', password: 'password'),
    );
    store.suspendIdleMonitoring();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStoreScope(
          store: store,
          child: SessionActivityGuard(
            onRequireSignIn: store.signOut,
            child: Scaffold(
              body: UsersSecuritySettingsSection(
                accentColor: AppModulePalettes.settings.middle,
                userRepository: store.services.users,
                roleRepository: store.services.roles,
                authenticationService: store.services.authentication,
                sessionPolicyRepository: store.services.sessionPolicies,
                auditRepository: store.services.audit,
                administrationService: store.services.administration,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usersSecurityTab_security')));
    await tester.pump();
    await _tapVisible(
      tester,
      find.byKey(const Key('settingsToggleDemoSessionLockButton')),
    );
    expect(find.byKey(const Key('sessionLockOverlay')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sessionUnlockButton')));
    await tester.pump();
    expect(find.text('أدخل كلمة المرور للمتابعة'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('sessionUnlockPasswordField')),
      'password',
    );
    await tester.tap(find.byKey(const Key('sessionUnlockButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sessionLockOverlay')), findsNothing);
    expect(store.session?.state, SessionState.active);

    final sessionBanner = tester.widget<AppInfoBanner>(
      find.byKey(const Key('settingsCurrentSessionState')),
    );
    expect(sessionBanner.message, contains('نشطة'));
    expect(
      tester
          .widget<AppRegularButton>(
            find.byKey(const Key('settingsToggleDemoSessionLockButton')),
          )
          .onPressed,
      isNotNull,
    );

    _scrollSecurityToTop(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usersSecurityTab_logs')));
    await tester.pumpAndSettle();
    final table = tester.widget<AppDataTable>(
      find.byKey(const Key('settingsSecurityLogsTable')),
    );
    expect(
      table.rows.any(
        (row) => (row.cells[2] as Text).data == 'فتح الجلسة',
      ),
      isTrue,
    );
  });
}

AuditRecord _auditRecord(
  int sequence, {
  String? summary,
  String? ipAddress,
  String? macAddress,
}) {
  return AuditRecord(
    id: EntityId.demo('audit', sequence),
    occurredAt: AuditTimestamp(
      DateTime.utc(2026, 8, 14, 8).add(Duration(minutes: sequence)),
    ),
    actorUserId: EntityId.demo('user', 1),
    actorUsername: 'admin',
    action: AuditAction.update,
    outcome: AuditOutcome.success,
    summary: summary ?? 'سجل التدقيق $sequence',
    details: const {'status': 'active'},
    metadata: AuditMetadata(
      deviceId: 'windows-test-device',
      requestId: 'request-$sequence',
      ipAddress: ipAddress,
      macAddress: macAddress,
      before: const {'status': 'disabled'},
      after: const {'status': 'active'},
    ),
    entityType: 'user',
    entityId: EntityId.demo('user', 1),
  );
}

Future<void> _pumpSecuritySection(
  WidgetTester tester, {
  required DemoIdentityServiceBundle bundle,
  AuditRepository? auditRepository,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: UsersSecuritySettingsSection(
            accentColor: AppModulePalettes.settings.middle,
            userRepository: bundle.users,
            roleRepository: bundle.roles,
            authenticationService: bundle.authentication,
            sessionPolicyRepository: bundle.sessionPolicies,
            auditRepository: auditRepository ?? bundle.audit,
            administrationService: bundle.administration,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openLogs(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('usersSecurityTab_logs')));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _scrollSecurityToTop(WidgetTester tester) {
  final scrollable = tester.state<ScrollableState>(
    find.descendant(
      of: find.byKey(const Key('usersSecuritySettingsContent')),
      matching: find.byType(Scrollable),
    ).first,
  );
  scrollable.position.jumpTo(0);
}

List<String?> _auditSummaries(WidgetTester tester) {
  final table = tester.widget<AppDataTable>(
    find.byKey(const Key('settingsSecurityLogsTable')),
  );
  return [
    for (final row in table.rows) (row.cells[3] as Text).data,
  ];
}

class _ControlledAuditRepository implements AuditRepository {
  _ControlledAuditRepository(this.delegate);

  final AuditRepository delegate;
  String? delaySearchText;
  var failNextSearch = false;
  Completer<AuditPage>? _delayed;
  AuditQuery? _delayedQuery;

  @override
  Future<AuditPage> search(AuditQuery query) {
    if (failNextSearch) {
      failNextSearch = false;
      return Future<AuditPage>.error(StateError('audit refresh failed'));
    }
    if (query.searchText == delaySearchText) {
      _delayed = Completer<AuditPage>();
      _delayedQuery = query;
      return _delayed!.future;
    }
    return delegate.search(query);
  }

  Future<void> completeDelayedSearch() async {
    final completer = _delayed;
    final query = _delayedQuery;
    if (completer == null || query == null) return;
    completer.complete(await delegate.search(query));
    _delayed = null;
    _delayedQuery = null;
  }

  @override
  Future<AuditRecord> append(AuditRecord record) => delegate.append(record);
}

class _CascadeShrinkAuditRepository implements AuditRepository {
  _CascadeShrinkAuditRepository({
    required this.state,
    required this.delegate,
  });

  final DemoIdentityState state;
  final AuditRepository delegate;
  var shrinkAcrossCorrectiveSearches = false;

  @override
  Future<AuditPage> search(AuditQuery query) async {
    if (shrinkAcrossCorrectiveSearches && query.offset == 200) {
      shrinkAcrossCorrectiveSearches = false;
      state.auditRecords.removeRange(150, state.auditRecords.length);
      final firstInvalidPage = await delegate.search(query);
      state.auditRecords.removeRange(50, state.auditRecords.length);
      return firstInvalidPage;
    }
    return delegate.search(query);
  }

  @override
  Future<AuditRecord> append(AuditRecord record) => delegate.append(record);
}

class _FailingAuditRepository implements AuditRepository {
  _FailingAuditRepository(this.delegate);

  final AuditRepository delegate;

  @override
  Future<AuditPage> search(AuditQuery query) {
    return Future<AuditPage>.error(StateError('initial audit load failed'));
  }

  @override
  Future<AuditRecord> append(AuditRecord record) => delegate.append(record);
}
