import 'dart:async';

import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_data_composition.dart';
import 'package:erp/core/app_state/app_data_profile.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/app_state/app_services.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/services/service_failure.dart';
import 'package:erp/features/audit_log/domain/audit_models.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/backup_restore/domain/backup_models.dart';
import 'package:erp/features/cashbox/domain/cashbox_repository.dart';
import 'package:erp/features/electronic_archive/domain/archive_models.dart';
import 'package:erp/features/items/domain/item_repository.dart';
import 'package:erp/features/permissions/domain/permission_models.dart';
import 'package:erp/features/settings/data/demo_operational_settings_repositories.dart';
import 'package:erp/features/settings/domain/operational_master_data.dart';
import 'package:erp/features/settings/domain/operational_master_data_repository.dart';
import 'package:erp/features/settings/domain/settings_models.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 7 whole-data replacement', () {
    test('clear swaps the whole graph and keeps only bootstrap identity',
        () async {
      final canonical = AppDataComposition.demo(AppDataProfile.originalDemo);
      final canonicalSignature = await _compositionSignature(
        canonical.repositories,
        canonical.services,
      );
      final store = AppStore.demo();
      addTearDown(store.dispose);
      await _signInAdmin(store);
      await store.services.googleDriveBackups.connect();

      final oldRepositories = store.repositories;
      final oldServices = store.services;
      final revisionBeforeClear = store.revision;
      final generationBeforeClear = store.dataGeneration;
      var clearNotifications = 0;
      void countClearNotification() => clearNotifications++;
      store.addListener(countClearNotification);

      await store.clearAllData();
      store.removeListener(countClearNotification);

      expect(store.repositories, isNot(same(oldRepositories)));
      expect(store.services, isNot(same(oldServices)));
      expect(store.session, isNull);
      expect(store.requiresAuthentication, isFalse);
      expect(await store.services.authentication.currentSession(), isNull);
      expect(await oldServices.authentication.currentSession(), isNull);
      expect(store.revision, revisionBeforeClear + 1);
      expect(store.dataGeneration, generationBeforeClear + 1);
      expect(clearNotifications, 1);
      await _expectClearedComposition(store.repositories, store.services);

      expect(await store.repositories.parties.nextPartyNumber(), 1);
      expect(await store.repositories.sales.nextDocumentNumber(), 1);
      expect(await store.repositories.purchases.nextDocumentNumber(), 1);
      expect(
        await (store.repositories.cashbox as CashboxIssuedNumberRepository)
            .nextVoucherNumber(),
        1,
      );

      final bootstrapSession = await _signInAdmin(store);
      expect(bootstrapSession.state, SessionState.active);
      expect(store.canManageInternalData, isTrue);
      final bootstrapAudit = await store.services.audit.search(
        AuditQuery(limit: 1000),
      );
      expect(bootstrapAudit.totalCount, 1);
      expect(bootstrapAudit.records.single.id, EntityId.demo('audit', 1));
      expect(bootstrapAudit.records.single.action, AuditAction.signIn);

      final firstRole = await store.services.administration.saveRole(
        RoleSaveRequest(
          name: 'أول دور بعد المسح',
          permissions: {
            PermissionCode(
              module: 'settings',
              action: PermissionAction.view,
            ),
          },
        ),
      );
      expect(firstRole.id, EntityId.demo('role', 2));
      final firstUser = await store.services.administration.createUser(
        UserCreateRequest(
          fullName: 'أول مستخدم بعد المسح',
          username: 'first_after_clear',
          roleIds: {firstRole.id},
          initialPassword: 'secret1',
        ),
      );
      expect(firstUser.id, EntityId.demo('user', 2));

      final firstGroup = await store.repositories.operationalMasterData
          .createNamedRecord(
        const CreateOperationalMasterDataRequest(
          kind: OperationalMasterDataKind.itemGroup,
          name: 'أول مجموعة بعد المسح',
        ),
      );
      expect(firstGroup.number, 1);
      expect(firstGroup.id.value, 'local-itemGroup-000001');
      final firstType = await store.repositories.operationalMasterData
          .createNamedRecord(
        CreateOperationalMasterDataRequest(
          kind: OperationalMasterDataKind.itemType,
          name: 'أول نوع بعد المسح',
          parentId: firstGroup.id,
        ),
      );
      expect(firstType.number, 1);
      final firstItem = await store.repositories.items.quickCreate(
        ItemQuickCreateRequest(
          code: 'FIRST-1',
          name: 'أول مادة بعد المسح',
          groupId: firstGroup.id,
          typeId: firstType.id,
        ),
      );
      expect(firstItem.id, 'local-item-000001');

      final backupConfiguration = await store.services.backupConfiguration
          .load(almumayazWindowsDeviceId);
      final firstBackup = await store.services.backups.createBackup(
        configuration: backupConfiguration,
        uploadToGoogleDrive: false,
      );
      expect(firstBackup.id, EntityId.demo('backup', 1));

      final clearedRepositories = store.repositories;
      final clearedServices = store.services;
      final revisionBeforeRestore = store.revision;
      final generationBeforeRestore = store.dataGeneration;
      var restoreNotifications = 0;
      void countRestoreNotification() => restoreNotifications++;
      store.addListener(countRestoreNotification);

      await store.restoreDemoData();
      store.removeListener(countRestoreNotification);

      expect(store.repositories, isNot(same(clearedRepositories)));
      expect(store.services, isNot(same(clearedServices)));
      expect(store.session, isNull);
      expect(store.revision, revisionBeforeRestore + 1);
      expect(store.dataGeneration, generationBeforeRestore + 1);
      expect(restoreNotifications, 1);
      expect(
        await _compositionSignature(store.repositories, store.services),
        canonicalSignature,
      );
    });

    test('authorization rejects unavailable, signed-out, and non-admin use',
        () async {
      final customerStore = AppStore.demo(internalToolsEnabled: false);
      final signedOutStore = AppStore.demo();
      final ordinaryStore = AppStore.demo();
      addTearDown(customerStore.dispose);
      addTearDown(signedOutStore.dispose);
      addTearDown(ordinaryStore.dispose);

      await _signInAdmin(customerStore);
      await _expectFailureCode(
        customerStore.clearAllData(),
        'internal_tools_unavailable',
      );
      await _expectFailureCode(
        signedOutStore.clearAllData(),
        'active_session_required',
      );

      await ordinaryStore.signIn(
        SignInCredentials(username: 'ahmed', password: 'demo123'),
      );
      expect(ordinaryStore.canManageInternalData, isFalse);
      await _expectFailureCode(
        ordinaryStore.restoreDemoData(),
        'settings_manage_required',
      );
    });

    test('settings manager must also be the protected system user', () async {
      final store = AppStore.demo();
      addTearDown(store.dispose);
      await _signInAdmin(store);
      final managerRole = await store.services.administration.saveRole(
        RoleSaveRequest(
          name: 'مدير بيانات اختباري',
          permissions: {
            PermissionCode(
              module: 'settings',
              action: PermissionAction.manage,
            ),
          },
        ),
      );
      await store.services.administration.createUser(
        UserCreateRequest(
          fullName: 'مدير بيانات غير محمي',
          username: 'data_manager',
          roleIds: {managerRole.id},
          initialPassword: 'secret1',
        ),
      );
      await store.signOut();
      await store.signIn(
        SignInCredentials(username: 'data_manager', password: 'secret1'),
      );

      expect(
        store.allows('settings', PermissionAction.manage),
        isTrue,
      );
      expect(store.canManageInternalData, isFalse);
      await _expectFailureCode(
        store.clearAllData(),
        'system_user_required',
      );
    });

    test('authoritative session revocation rejects clear without a swap',
        () async {
      final store = AppStore.demo();
      addTearDown(store.dispose);
      await _signInAdmin(store);
      final repositoriesBefore = store.repositories;
      final servicesBefore = store.services;
      final localSessionBefore = store.session;
      final revisionBefore = store.revision;
      final generationBefore = store.dataGeneration;
      var notifications = 0;
      void countNotification() => notifications++;
      store.addListener(countNotification);

      await store.services.authentication.signOut(store.session!.id);
      expect(await store.services.authentication.currentSession(), isNull);
      expect(store.session, same(localSessionBefore));
      await _expectFailureCode(
        store.clearAllData(),
        'authoritative_session_required',
      );
      store.removeListener(countNotification);

      expect(store.repositories, same(repositoriesBefore));
      expect(store.services, same(servicesBefore));
      expect(store.session, same(localSessionBefore));
      expect(store.revision, revisionBefore);
      expect(store.dataGeneration, generationBefore);
      expect(store.isReplacingData, isFalse);
      expect(notifications, 0);
    });

    test('composition failure rolls back identities, session, and counters',
        () async {
      AppDataComposition builder(AppDataProfile profile) {
        if (profile == AppDataProfile.cleared) {
          throw StateError('injected replacement failure');
        }
        return AppDataComposition.demo(profile);
      }

      final store = AppStore.demo(compositionBuilder: builder);
      addTearDown(store.dispose);
      await _signInAdmin(store);
      final repositoriesBefore = store.repositories;
      final servicesBefore = store.services;
      final sessionBefore = store.session;
      final revisionBefore = store.revision;
      final generationBefore = store.dataGeneration;
      var notifications = 0;
      void countNotification() => notifications++;
      store.addListener(countNotification);

      await expectLater(
        store.clearAllData(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'injected replacement failure',
          ),
        ),
      );
      store.removeListener(countNotification);

      expect(store.repositories, same(repositoriesBefore));
      expect(store.services, same(servicesBefore));
      expect(store.session, same(sessionBefore));
      expect(store.revision, revisionBefore);
      expect(store.dataGeneration, generationBefore);
      expect(store.isReplacingData, isFalse);
      expect(notifications, 0);
    });

    test('a concurrent replacement is rejected while the first completes',
        () async {
      final store = AppStore.demo();
      addTearDown(store.dispose);
      await _signInAdmin(store);

      final first = store.clearAllData();
      expect(store.isReplacingData, isTrue);
      await _expectFailureCode(
        store.restoreDemoData(),
        'data_replacement_in_progress',
      );
      await first;

      expect(store.isReplacingData, isFalse);
      expect(store.dataGeneration, 1);
      expect(await store.repositories.sales.getAll(), isEmpty);
    });
  });

  group('Phase 7 About tools', () {
    testWidgets(
        'internal admin sees tools under Design System and exact confirmation',
        (tester) async {
      await _setDesktopSurface(tester);
      final store = AppStore.demo();
      addTearDown(store.dispose);
      await tester.pumpWidget(AlmumayazApp(store: store));
      await _login(tester);
      await _openAbout(tester);

      final guide = find.byKey(const Key('openDesignSystemGallery'));
      final tools = find.byKey(const Key('aboutInternalDataTools'));
      expect(guide, findsOneWidget);
      expect(tools, findsOneWidget);
      expect(
        tester.getTopLeft(tools).dy,
        greaterThan(tester.getBottomLeft(guide).dy),
      );

      await _openDataDialog(
        tester,
        const Key('aboutRestoreDemoDataButton'),
      );
      final field = find.byKey(const Key('aboutDataConfirmationField'));
      final confirm =
          find.byKey(const Key('aboutDataConfirmationConfirmButton'));
      expect(_button(tester, confirm).onPressed, isNull);

      await tester.enterText(field, 'استعادة البيانات التجريبية ');
      await tester.pump();
      expect(_button(tester, confirm).onPressed, isNull);
      await tester.enterText(field, 'استعادة البيانات التجريبية');
      await tester.pump();
      expect(_button(tester, confirm).onPressed, isNotNull);

      await tester.tap(
        find.byKey(const Key('aboutDataConfirmationCancelButton')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aboutDataConfirmationDialog')), findsNothing);
      expect(store.dataGeneration, 0);

      await _openDataDialog(
        tester,
        const Key('aboutDeleteAllDataButton'),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aboutDataConfirmationDialog')), findsNothing);
      expect(store.dataGeneration, 0);
    });

    testWidgets('busy confirmation blocks cancel, Escape, and route back',
        (tester) async {
      final completion = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const Key('openBusyConfirmation'),
                onPressed: () => AppTypedConfirmationDialog.show(
                  context: context,
                  title: 'عملية طويلة',
                  message: 'اختبار الحماية أثناء التنفيذ',
                  confirmationPhrase: 'تأكيد نهائي',
                  confirmLabel: 'تنفيذ',
                  progressMessage: 'جارٍ التنفيذ...',
                  dialogKey: const Key('aboutDataConfirmationDialog'),
                  fieldKey: const Key('aboutDataConfirmationField'),
                  cancelButtonKey:
                      const Key('aboutDataConfirmationCancelButton'),
                  confirmButtonKey:
                      const Key('aboutDataConfirmationConfirmButton'),
                  progressKey: const Key('aboutDataOperationProgress'),
                  onConfirm: () => completion.future,
                ),
                child: const Text('فتح'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('openBusyConfirmation')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('aboutDataConfirmationField')),
        'تأكيد نهائي',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('aboutDataConfirmationConfirmButton')),
      );
      await tester.pump();

      expect(find.byKey(const Key('aboutDataOperationProgress')), findsOneWidget);
      expect(
        _button(
          tester,
          find.byKey(const Key('aboutDataConfirmationCancelButton')),
        ).onPressed,
        isNull,
      );
      expect(
        _button(
          tester,
          find.byKey(const Key('aboutDataConfirmationConfirmButton')),
        ).isLoading,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(const Key('aboutDataConfirmationDialog')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byKey(const Key('aboutDataConfirmationDialog')), findsOneWidget);

      completion.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aboutDataConfirmationDialog')), findsNothing);
    });

    testWidgets('clear forces Login; admin can restore demo and is signed out',
        (tester) async {
      await _setDesktopSurface(tester);
      final store = AppStore.demo();
      addTearDown(store.dispose);
      await tester.pumpWidget(AlmumayazApp(store: store));
      await _login(tester);
      await _openAbout(tester);

      await _confirmDataOperation(
        tester,
        buttonKey: const Key('aboutDeleteAllDataButton'),
        phrase: 'حذف جميع البيانات',
      );

      expect(find.byKey(const Key('usernameField')), findsOneWidget);
      expect(find.byKey(const Key('aboutScreen')), findsNothing);
      expect(find.byKey(const Key('aboutDataConfirmationDialog')), findsNothing);
      expect(await store.repositories.parties.getAll(), isEmpty);
      expect(await store.repositories.sales.getAll(), isEmpty);

      await _login(tester);
      expect(find.byKey(const Key('dashboardCard_about')), findsOneWidget);
      await _openAbout(tester);
      await _confirmDataOperation(
        tester,
        buttonKey: const Key('aboutRestoreDemoDataButton'),
        phrase: 'استعادة البيانات التجريبية',
      );

      expect(find.byKey(const Key('usernameField')), findsOneWidget);
      expect(find.byKey(const Key('aboutScreen')), findsNothing);
      expect(await store.repositories.sales.getAll(), hasLength(3));
      expect(await store.repositories.purchases.getAll(), hasLength(3));
      expect(await store.repositories.parties.getAll(), isNotEmpty);
    });

    testWidgets('replacement failure keeps the dialog, session, and data',
        (tester) async {
      await _setDesktopSurface(tester);
      AppDataComposition builder(AppDataProfile profile) {
        if (profile == AppDataProfile.cleared) {
          throw StateError('injected UI replacement failure');
        }
        return AppDataComposition.demo(profile);
      }

      final store = AppStore.demo(compositionBuilder: builder);
      addTearDown(store.dispose);
      await tester.pumpWidget(AlmumayazApp(store: store));
      await _login(tester);
      await _openAbout(tester);
      final repositoriesBefore = store.repositories;
      final servicesBefore = store.services;
      final salesBefore = await store.repositories.sales.getAll();

      await _openDataDialog(
        tester,
        const Key('aboutDeleteAllDataButton'),
      );
      await tester.enterText(
        find.byKey(const Key('aboutDataConfirmationField')),
        'حذف جميع البيانات',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('aboutDataConfirmationConfirmButton')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('aboutDataConfirmationDialog')), findsOneWidget);
      expect(
        find.text('تعذر إكمال العملية. لم يتم تغيير البيانات.'),
        findsWidgets,
      );
      expect(store.repositories, same(repositoriesBefore));
      expect(store.services, same(servicesBefore));
      expect(store.session?.state, SessionState.active);
      expect(store.dataGeneration, 0);
      expect(await store.repositories.sales.getAll(), salesBefore);
    });

    testWidgets('ordinary internal user cannot see destructive tools',
        (tester) async {
      await _setDesktopSurface(tester);
      final store = AppStore.demo();
      addTearDown(store.dispose);
      await tester.pumpWidget(AlmumayazApp(store: store));
      await _login(tester, username: 'ahmed', password: 'demo123');
      await _openAbout(tester);

      expect(find.byKey(const Key('openDesignSystemGallery')), findsOneWidget);
      expect(find.byKey(const Key('aboutInternalDataTools')), findsNothing);
      expect(find.byKey(const Key('aboutRestoreDemoDataButton')), findsNothing);
      expect(find.byKey(const Key('aboutDeleteAllDataButton')), findsNothing);
    });
  });
}

Future<AppSession> _signInAdmin(AppStore store) {
  return store.signIn(
    SignInCredentials(username: 'admin', password: 'password'),
  );
}

Future<void> _expectFailureCode(Future<void> operation, String code) {
  return expectLater(
    operation,
    throwsA(
      isA<ServiceFailure>().having(
        (failure) => failure.code,
        'code',
        code,
      ),
    ),
  );
}

Future<void> _expectClearedComposition(
  AppRepositories repositories,
  AppServices services,
) async {
  expect(await repositories.parties.getAll(), isEmpty);
  expect(await repositories.items.getAll(), isEmpty);
  expect(await repositories.warehouses.getAll(), isEmpty);
  expect(await repositories.warehouses.getTransfers(), isEmpty);
  expect(await repositories.inventoryCosts.getBalances(), isEmpty);
  expect(await repositories.inventoryCosts.getSalesLineCosts(), isEmpty);
  expect(await repositories.cashbox.getAll(), isEmpty);
  expect(await repositories.cashbox.getMainAccounts(), isEmpty);
  final opening = await repositories.cashbox.getOpeningBalance();
  expect(opening.iqd, Money.zero(AppCurrency.iqd));
  expect(opening.usd, Money.zero(AppCurrency.usd));
  expect(await repositories.sales.getAll(), isEmpty);
  expect(await repositories.purchases.getAll(), isEmpty);
  expect(await repositories.installments.getAll(), isEmpty);
  expect(await repositories.operationalMasterData.getAll(), isEmpty);

  final policies = await repositories.businessSettings.loadBusinessPolicies();
  final canonicalPolicies = demoBusinessPolicies();
  expect(policies.defaultExchangeRate, canonicalPolicies.defaultExchangeRate);
  expect(
    policies.allowSaleWithInsufficientStock,
    canonicalPolicies.allowSaleWithInsufficientStock,
  );
  expect(
    policies.defaultCustomerDebtLimit,
    canonicalPolicies.defaultCustomerDebtLimit,
  );
  expect(policies.defaultDebtDueDays, canonicalPolicies.defaultDebtDueDays);
  expect(
    policies.overdueDebtAlertsEnabled,
    canonicalPolicies.overdueDebtAlertsEnabled,
  );
  final defaults = await repositories.businessSettings.loadOperationalDefaults();
  final canonicalDefaults = demoOperationalDefaults();
  expect(defaults.purchases.warehouseId, canonicalDefaults.purchases.warehouseId);
  expect(defaults.sales.warehouseId, canonicalDefaults.sales.warehouseId);
  expect(defaults.cashbox.mainAccountId, canonicalDefaults.cashbox.mainAccountId);

  final device = await repositories.deviceSettings.loadDeviceSettings(
    almumayazWindowsDeviceId,
  );
  expect(device.defaultPrinterName, isNull);
  expect(device.paperSize, PrintPaperSize.a4);
  expect(device.printCopies, 1);
  expect(device.printPreviewEnabled, isTrue);

  expect(await services.backups.listHistory(), isEmpty);
  final drive = await services.googleDriveBackups.connection();
  expect(drive.status, CloudConnectionStatus.disconnected);
  expect(drive.accountLabel, isNull);
  expect(drive.selectedFolder, isNull);
  expect(await services.archive.search(const ArchiveQuery()), isEmpty);
  expect(await services.authentication.currentSession(), isNull);

  final users = await services.users.search(const UserQuery());
  expect(users, hasLength(1));
  expect(users.single.id, EntityId.demo('user', 1));
  expect(users.single.username, 'admin');
  expect(users.single.isSystemUser, isTrue);
  expect(users.single.lastLoginAt, isNull);
  final roles = await services.roles.getAll();
  expect(roles, hasLength(1));
  expect(roles.single.id, EntityId.demo('role', 1));
  expect(roles.single.isSystemRole, isTrue);
  final audit = await services.audit.search(AuditQuery(limit: 1000));
  expect(audit.totalCount, 0);

  final backupConfiguration = await services.backupConfiguration.load(
    almumayazWindowsDeviceId,
  );
  expect(backupConfiguration.deviceId, almumayazWindowsDeviceId);
  expect(backupConfiguration.localPath, r'D:\Almumayaz\Backups');
  expect(backupConfiguration.schedule.isEnabled, isTrue);
  expect(backupConfiguration.schedule.frequency, BackupFrequency.daily);
}

Future<Map<String, Object?>> _compositionSignature(
  AppRepositories repositories,
  AppServices services,
) async {
  final parties = [...await repositories.parties.getAll()]
    ..sort((a, b) => a.id.compareTo(b.id));
  final items = [...await repositories.items.getAll()]
    ..sort((a, b) => a.id.compareTo(b.id));
  final warehouses = [...await repositories.warehouses.getAll()]
    ..sort((a, b) => a.id.compareTo(b.id));
  final transfers = [...await repositories.warehouses.getTransfers()]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final costs = [...await repositories.inventoryCosts.getBalances()]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final lineCosts = [
    ...await repositories.inventoryCosts.getSalesLineCosts(),
  ]..sort((a, b) => a.id.value.compareTo(b.id.value));
  final cashbox = [...await repositories.cashbox.getAll()]
    ..sort((a, b) => a.id.compareTo(b.id));
  final sales = [...await repositories.sales.getAll()]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final purchases = [...await repositories.purchases.getAll()]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final installments = [...await repositories.installments.getAll()]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final master = [...await repositories.operationalMasterData.getAll()]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final policies = await repositories.businessSettings.loadBusinessPolicies();
  final defaults = await repositories.businessSettings.loadOperationalDefaults();
  final device = await repositories.deviceSettings.loadDeviceSettings(
    almumayazWindowsDeviceId,
  );
  final backupConfiguration = await services.backupConfiguration.load(
    almumayazWindowsDeviceId,
  );
  final backupHistory = [...await services.backups.listHistory()]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final drive = await services.googleDriveBackups.connection();
  final archive = [...await services.archive.search(const ArchiveQuery())]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final users = [...await services.users.search(const UserQuery())]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final roles = [...await services.roles.getAll()]
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  final audit = await services.audit.search(AuditQuery(limit: 1000));

  final inventory = <String>[];
  for (final warehouse in warehouses) {
    final balances = [
      ...await repositories.warehouses.getInventory(warehouse.entityId),
    ]..sort((a, b) => a.id.value.compareTo(b.id.value));
    inventory.addAll(
      balances.map(
        (balance) => '${balance.id}|${balance.warehouseId}|'
            '${balance.itemId}|${balance.quantity.value}',
      ),
    );
  }

  return <String, Object?>{
    'parties': [
      for (final party in parties)
        '${party.entityId}|${party.number}|${party.createdTimestamp}|'
            '${party.name}|${party.type.name}|${party.workplace}|'
            '${party.branch}|${party.phone}|${party.alternatePhone}|'
            '${party.city}|${party.address}|${party.notes}|'
            '${party.iqdBalance}|${party.usdBalance}',
    ],
    'items': [
      for (final item in items)
        '${item.entityId}|${item.code}|${item.name}|${item.barcode}|'
            '${item.groupEntityId}|${item.groupName}|${item.typeEntityId}|'
            '${item.typeName}|${item.iqdSalePrice}|${item.usdSalePrice}|'
            '${item.notes}',
    ],
    'warehouses': [
      for (final warehouse in warehouses)
        '${warehouse.entityId}|${warehouse.number}|${warehouse.name}|'
            '${warehouse.location}|${warehouse.notes}|${warehouse.isMain}',
    ],
    'inventory': inventory,
    'transfers': [
      for (final transfer in transfers)
        '${transfer.id}|${transfer.documentNumber}|${transfer.createdAt}|'
            '${transfer.fromWarehouseId}|${transfer.toWarehouseId}|'
            '${transfer.reversalOfId}|'
            '${transfer.lines.map((line) => '${line.itemId}:${line.quantity.value}').join(',')}',
    ],
    'inventoryCosts': [
      for (final cost in costs)
        '${cost.id}|${cost.warehouseId}|${cost.itemId}|'
            '${cost.quantity.value}|${cost.totalCostIqd}',
    ],
    'salesLineCosts': [
      for (final cost in lineCosts)
        '${cost.id}|${cost.salesInvoiceId}|${cost.salesLineId}|'
            '${cost.warehouseId}|${cost.itemId}|${cost.quantity.value}|'
            '${cost.allocatedRevenue}|${cost.totalCostIqd}|${cost.totalCost}|'
            '${cost.availability.name}|${cost.method.name}',
    ],
    'cashbox': [
      for (final voucher in cashbox)
        '${voucher.entityId}|${voucher.number}|${voucher.createdTimestamp}|'
            '${voucher.type.name}|${voucher.mainAccountEntityId}|'
            '${voucher.mainAccountLabel}|${voucher.subaccountEntityId}|'
            '${voucher.subaccountLabel}|${voucher.exchangeRateValue}|'
            '${voucher.iqdAmount}|${voucher.usdAmount}|'
            '${voucher.iqdBalanceBefore}|${voucher.iqdBalanceAfter}|'
            '${voucher.usdBalanceBefore}|${voucher.usdBalanceAfter}|'
            '${voucher.notes}|${voucher.source?.kind.name}|'
            '${voucher.source?.sourceId}|${voucher.source?.partyId}',
    ],
    'sales': [
      for (final invoice in sales)
        '${invoice.id}|${invoice.documentNumber}|${invoice.date}|'
            '${invoice.minuteOfDay}|${invoice.customerId}|'
            '${invoice.defaultWarehouseId}|${invoice.currency.name}|'
            '${invoice.exchangeRate}|${invoice.settlementKind.name}|'
            '${invoice.invoiceDiscount}|${invoice.received}|'
            '${invoice.receivedAtSale}|${invoice.installmentReceived}|'
            '${invoice.customerNameSnapshot}|${invoice.searchDetailsSnapshot}|'
            '${invoice.balanceAfterInvoice}|${invoice.driverName}|${invoice.notes}|'
            '${invoice.lines.map((line) => '${line.id}:${line.itemId}:${line.warehouseId}:${line.quantity.value}:${line.unitPrice}:${line.discountPerUnit}:${line.itemCodeSnapshot}:${line.itemNameSnapshot}:${line.warehouseNameSnapshot}').join(',')}',
    ],
    'purchases': [
      for (final invoice in purchases)
        '${invoice.id}|${invoice.documentNumber}|${invoice.date}|'
            '${invoice.minuteOfDay}|${invoice.supplierId}|'
            '${invoice.defaultWarehouseId}|${invoice.currency.name}|'
            '${invoice.exchangeRate}|${invoice.purchaseKind.name}|'
            '${invoice.settlementKind.name}|${invoice.expenses}|'
            '${invoice.invoiceDiscount}|${invoice.paid}|'
            '${invoice.supplierNameSnapshot}|${invoice.searchDetailsSnapshot}|'
            '${invoice.balanceAfterInvoice}|${invoice.notes}|'
            '${invoice.lines.map((line) => '${line.id}:${line.itemId}:${line.warehouseId}:${line.quantity.value}:${line.containerQuantity.value}:${line.purchasePrice}:${line.lineDiscount}:${line.salePrice}:${line.itemCodeSnapshot}:${line.itemNameSnapshot}:${line.warehouseNameSnapshot}').join(',')}',
    ],
    'installments': [
      for (final plan in installments)
        '${plan.id}|${plan.salesInvoiceId}|${plan.customerId}|'
            '${plan.currency.name}|'
            '${plan.entries.map((entry) => '${entry.id}:${entry.number}:${entry.dueDate}:${entry.amount}:${entry.status.name}:${entry.paidAt}:${entry.notes}').join(',')}',
    ],
    'master': [
      for (final record in master)
        '${record.id}|${record.kind.name}|${record.number}|${record.name}|'
            '${record.parentId}|${record.relatedEntityId}|${record.isProtected}',
    ],
    'businessPolicies': [
      policies.defaultExchangeRate.toString(),
      policies.allowSaleWithInsufficientStock,
      policies.defaultCustomerDebtLimit.toString(),
      policies.defaultDebtDueDays,
      policies.overdueDebtAlertsEnabled,
    ],
    'operationalDefaults': [
      defaults.purchases.warehouseId.value,
      defaults.purchases.purchaseKind.name,
      defaults.purchases.paymentKind.name,
      defaults.purchases.currency.name,
      defaults.sales.warehouseId.value,
      defaults.sales.saleKind.name,
      defaults.sales.currency.name,
      defaults.cashbox.movementKind.name,
      defaults.cashbox.mainAccountId.value,
    ],
    'device': [
      device.deviceId,
      device.defaultPrinterName,
      device.paperSize.name,
      device.printCopies,
      device.printPreviewEnabled,
    ],
    'backupConfiguration': [
      backupConfiguration.deviceId,
      backupConfiguration.localPath,
      backupConfiguration.schedule.isEnabled,
      backupConfiguration.schedule.frequency.name,
      backupConfiguration.googleDriveFolderId,
    ],
    'backupHistory': [
      for (final record in backupHistory)
        '${record.id}|${record.createdAt}|${record.destination.name}|'
            '${record.status.name}|${record.localPath}|${record.byteSize}|'
            '${record.isEncrypted}|${record.checksum}|${record.remoteFileId}|'
            '${record.failureMessage}',
    ],
    'drive': [
      drive.status.name,
      drive.accountLabel,
      drive.selectedFolder?.id,
      drive.selectedFolder?.name,
      drive.message,
    ],
    'archive': [
      for (final document in archive)
        '${document.id}|${document.displayName}|${document.originalFileName}|'
            '${document.fileType.name}|${document.byteSize}|'
            '${document.checksumSha256}|${document.createdAt}|'
            '${document.createdByUserId}|${document.tags.toList()..sort()}',
    ],
    'users': [
      for (final user in users)
        '${user.id}|${user.fullName}|${user.username}|'
            '${user.roleIds.map((id) => id.value).toList()..sort()}|'
            '${user.status.name}|${user.isSystemUser}|${user.lastLoginAt}',
    ],
    'roles': [
      for (final role in roles)
        '${role.id}|${role.name}|'
            '${role.permissions.map((permission) => permission.value).toList()..sort()}|'
            '${role.isSystemRole}',
    ],
    'audit': [
      for (final record in audit.records)
        '${record.id}|${record.occurredAt}|${record.actorUserId}|'
            '${record.actorUsername}|${record.action.name}|'
            '${record.outcome.name}|${record.summary}|${record.details}|'
            '${record.metadata.deviceId}|${record.metadata.requestId}|'
            '${record.metadata.before}|${record.metadata.after}|'
            '${record.entityType}|${record.entityId}',
    ],
    'session': (await services.authentication.currentSession())?.id.value,
  };
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _login(
  WidgetTester tester, {
  String username = 'admin',
  String password = 'password',
}) async {
  await tester.enterText(find.byKey(const Key('usernameField')), username);
  await tester.enterText(find.byKey(const Key('passwordField')), password);
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
}

Future<void> _openAbout(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('dashboardCard_about')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('aboutScreen')), findsOneWidget);
}

Future<void> _openDataDialog(WidgetTester tester, Key buttonKey) async {
  final button = find.byKey(buttonKey);
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('aboutDataConfirmationDialog')), findsOneWidget);
}

Future<void> _confirmDataOperation(
  WidgetTester tester, {
  required Key buttonKey,
  required String phrase,
}) async {
  await _openDataDialog(tester, buttonKey);
  await tester.enterText(
    find.byKey(const Key('aboutDataConfirmationField')),
    phrase,
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const Key('aboutDataConfirmationConfirmButton')),
  );
  await tester.pumpAndSettle();
}

AppButton _button(WidgetTester tester, Finder finder) {
  return tester.widget<AppButton>(finder);
}
