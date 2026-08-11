import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/cashbox/domain/cashbox_voucher.dart';
import 'package:erp/features/cashbox/presentation/cashbox_controller.dart';
import 'package:erp/features/permissions/domain/permission_models.dart';
import 'package:erp/features/settings/domain/operational_master_data.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters and navigates repository cashbox vouchers', () async {
    final repositories = AppRepositories.demo();
    final controller = CashboxController(
      repository: repositories.cashbox,
      settingsRepository: repositories.businessSettings,
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.state.vouchers, hasLength(10));
    expect(
      controller.state.vouchers.first.entityId,
      EntityId('cashbox-001'),
    );
    expect(
      controller.state.vouchers.first.exchangeRateValue,
      ExchangeRate.parse('1310'),
    );
    expect(
      controller.state.vouchers.first.iqdAmount,
      Money.fromMajor(750000, AppCurrency.iqd),
    );

    controller.search('750,000');
    expect(controller.visibleVouchers, hasLength(1));
    expect(controller.visibleVouchers.first.number, 1);

    controller.search('');
    controller.first();
    expect(controller.selectedVoucher?.number, 1);

    controller.next();
    expect(controller.selectedVoucher?.number, 2);

    controller.last();
    expect(controller.selectedVoucher?.number, 10);

    controller.last();
    expect(controller.selectedVoucher, isNull);
  });

  test('recalculates and persists cashbox balances after mutations', () async {
    final repositories = AppRepositories.demo();
    final controller = CashboxController(
      repository: repositories.cashbox,
      settingsRepository: repositories.businessSettings,
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.state.vouchers, hasLength(10));
    expect(controller.summary.todayReceiptIqd, 1150000);
    expect(controller.summary.todayPaymentIqd, 125000);
    expect(
      controller.summary.iqdTodayReceipt,
      Money.fromMajor(1150000, AppCurrency.iqd),
    );

    controller.select('cashbox-003');
    final third = controller.selectedVoucher!;
    expect(controller.accountBalance(third.subaccountId).usd, -800);
    await controller.update(third.copyWith(amountUsd: 500));
    expect(controller.accountBalance(third.subaccountId).usd, -700);

    await controller.deleteSelected();
    expect(controller.accountBalance(third.subaccountId).usd, -1200);

    await controller.add(
      CashboxVoucher(
        id: 'cashbox-local',
        number: controller.nextNumber,
        createdAt: DateTime(2026, 7, 27, 10),
        type: CashboxVoucherType.payment,
        mainAccountId: third.mainAccountId,
        mainAccountLabel: third.mainAccountLabel,
        subaccountId: third.subaccountId,
        subaccountLabel: third.subaccountLabel,
        exchangeRate: 1310,
        amountIqd: 0,
        amountUsd: 10,
        balanceBeforeIqd: third.balanceBeforeIqd,
        balanceAfterIqd: third.balanceBeforeIqd,
        balanceBeforeUsd: -1200,
        balanceAfterUsd: -1190,
        notes: '',
      ),
    );
    expect(controller.accountBalance(third.subaccountId).usd, -1190);

    final reopened = CashboxController(
      repository: repositories.cashbox,
      settingsRepository: repositories.businessSettings,
    );
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.state.vouchers, hasLength(10));
    expect(reopened.accountBalance(third.subaccountId).usd, -1190);
  });

  testWidgets('opens Cashbox with the old structure and shared controls',
      (tester) async {
    await _openCashbox(tester);

    expect(find.byKey(const Key('cashboxScreen')), findsOneWidget);
    expect(find.byKey(const Key('cashboxForm')), findsOneWidget);
    expect(find.byKey(const Key('cashboxActionBar')), findsOneWidget);
    expect(find.byKey(const Key('cashboxTable')), findsOneWidget);
    expect(find.text('إدارة سندات القبض والصرف وحركات الصندوق'),
        findsOneWidget);
    final cashboxScaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byKey(const Key('cashboxScreen')),
        matching: find.byType(Scaffold),
      ),
    );
    expect(
      cashboxScaffold.backgroundColor,
      Color.alphaBlend(
        AppModuleColors.cashbox.withAlpha(12),
        AppColors.surface,
      ),
    );

    for (final fieldKey in [
      'cashboxBalanceIqdField',
      'cashboxBalanceUsdField',
      'cashboxTodayReceiptIqdField',
      'cashboxTodayPaymentIqdField',
      'cashboxTodayReceiptUsdField',
      'cashboxTodayPaymentUsdField',
      'cashboxVoucherNumberField',
      'cashboxTimeField',
      'cashboxCurrentBalanceIqdField',
      'cashboxCurrentBalanceUsdField',
      'cashboxEquivalentUsdField',
      'cashboxPreviousBalanceIqdField',
      'cashboxRemainingBalanceIqdField',
      'cashboxEquivalentIqdField',
      'cashboxPreviousBalanceUsdField',
      'cashboxRemainingBalanceUsdField',
    ]) {
      final fieldFinder = find.byKey(Key(fieldKey));
      final field = tester.widget<TextFormField>(fieldFinder);
      expect(field.enabled, isFalse);
      expect(
        _fieldDecoration(tester, fieldFinder).fillColor,
        AppColors.neutralSurface,
      );
    }
    expect(
      find.ancestor(
        of: find.byKey(const Key('cashboxTimeField')),
        matching: find.byType(AppTimeField),
      ),
      findsOneWidget,
    );

    expect(find.byKey(const Key('cashboxDateField')), findsOneWidget);
    expect(find.byKey(const Key('cashboxTypeField')), findsOneWidget);
    expect(find.byKey(const Key('cashboxExchangeRateField')),
        findsOneWidget);
    expect(find.byKey(const Key('cashboxMainAccountField')),
        findsOneWidget);
    expect(find.byKey(const Key('cashboxSubaccountField')),
        findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const Key('cashboxMainAccountField')),
        matching:
            find.byType(AppAutocompleteField<CashboxMainAccount>),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('cashboxSubaccountField')),
        matching:
            find.byType(AppAutocompleteField<CashboxSubaccount>),
      ),
      findsOneWidget,
    );
    expect(
      _editableText(
        tester,
        find.byKey(const Key('cashboxMainAccountField')),
      ).controller.text,
      'الصندوق الرئيسي',
    );
    expect(
      _editableText(
        tester,
        find.byKey(const Key('cashboxSubaccountField')),
      ).controller.text,
      '1 - النقدية اليومية',
    );
    expect(find.byKey(const Key('cashboxAmountIqdField')), findsOneWidget);
    expect(find.byKey(const Key('cashboxAmountUsdField')), findsOneWidget);
    expect(find.byKey(const Key('cashboxNotesField')), findsOneWidget);
    expect(find.byKey(const Key('cashboxPrintButton')), findsOneWidget);

    final dateField = tester.widget<TextFormField>(
      find.byKey(const Key('cashboxDateField')),
    );
    expect(dateField.enabled, isTrue);
    expect(
      _editableText(
        tester,
        find.byKey(const Key('cashboxDateField')),
      ).readOnly,
      isTrue,
    );
    expect(
      _fieldDecoration(
        tester,
        find.byKey(const Key('cashboxDateField')),
      ).fillColor,
      AppColors.surface,
    );

    _expectSameRow(tester, [
      'cashboxBalanceIqdField',
      'cashboxBalanceUsdField',
      'cashboxTodayReceiptIqdField',
      'cashboxTodayPaymentIqdField',
      'cashboxTodayReceiptUsdField',
      'cashboxTodayPaymentUsdField',
    ]);
    _expectSameRow(tester, [
      'cashboxVoucherNumberField',
      'cashboxDateField',
      'cashboxTimeField',
      'cashboxTypeField',
      'cashboxExchangeRateField',
      'cashboxCurrentBalanceIqdField',
      'cashboxCurrentBalanceUsdField',
    ]);
    _expectSameRow(tester, [
      'cashboxMainAccountField',
      'cashboxSubaccountField',
    ]);
    _expectSameRow(tester, [
      'cashboxAmountIqdField',
      'cashboxEquivalentUsdField',
      'cashboxPreviousBalanceIqdField',
      'cashboxRemainingBalanceIqdField',
    ]);
    _expectSameRow(tester, [
      'cashboxAmountUsdField',
      'cashboxEquivalentIqdField',
      'cashboxPreviousBalanceUsdField',
      'cashboxRemainingBalanceUsdField',
    ]);

    final typeDropdown =
        tester.widget<AppDropdownField<CashboxVoucherType>>(
      find.byType(AppDropdownField<CashboxVoucherType>),
    );
    expect(typeDropdown.useIntrinsicHeight, isTrue);
    expect(typeDropdown.accentColor, AppModuleColors.cashbox);

    final searchDecoration = _fieldDecoration(
      tester,
      find.byKey(const Key('cashboxSearchField')),
    );
    expect(
      (searchDecoration.focusedBorder as OutlineInputBorder)
          .borderSide
          .color,
      AppModuleColors.cashbox,
    );

    final notesInput = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('cashboxNotesField')),
        matching: find.byType(EditableText),
      ),
    );
    expect(notesInput.maxLines, 2);

    final table = tester.widget<AppDataTable>(
      find.byKey(const Key('cashboxTable')),
    );
    expect(table.accentColor, AppModuleColors.cashbox);
    expect(
      table.columns.map((column) => column.label),
      [
        'رقم السند',
        'التاريخ',
        'النوع',
        'الحساب الرئيسي',
        'الحساب الفرعي',
        'المبلغ دينار',
        'المبلغ دولار',
      ],
    );
    expect(table.rows, hasLength(10));
    expect(table.alternatingRowColor, isNull);

    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('cashboxSaveButton')),
      ).onPressed,
      isNotNull,
    );
    for (final buttonKey in [
      'cashboxUpdateButton',
      'cashboxUndoButton',
      'cashboxDeleteButton',
    ]) {
      expect(
        tester.widget<AppButton>(find.byKey(Key(buttonKey))).onPressed,
        isNull,
      );
    }

    await tester.tap(find.byKey(const Key('cashboxPrintButton')));
    await tester.pump();
    final toast = find.byKey(const Key('appToast'));
    expect(toast, findsOneWidget);
    expect(tester.widget<SnackBar>(toast).backgroundColor, AppColors.blue);
    expect(
      find.descendant(
        of: toast,
        matching: find.text('تم تجهيز معاينة طباعة الصندوق'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows and filters Cashbox account suggestions',
      (tester) async {
    await _openCashbox(tester);

    final mainAccount =
        find.byKey(const Key('cashboxMainAccountField'));
    final otherIncomeCount =
        find.text('إيرادات أخرى').evaluate().length;
    final expensesCount = find.text('المصاريف').evaluate().length;

    await tester.tap(mainAccount);
    await tester.pump();
    expect(
      find.text('إيرادات أخرى'),
      findsNWidgets(otherIncomeCount + 1),
    );

    await tester.enterText(mainAccount, 'مصا');
    await tester.pump();
    expect(
      find.text('إيرادات أخرى'),
      findsNWidgets(otherIncomeCount),
    );
    expect(
      find.text('المصاريف'),
      findsNWidgets(expensesCount + 1),
    );

    await tester.enterText(mainAccount, 'المصاريف');
    await tester.pump();
    expect(
      _editableText(
        tester,
        find.byKey(const Key('cashboxSubaccountField')),
      ).controller.text,
      '1 - نقل',
    );
  });

  testWidgets('searches, selects, and edits a Cashbox voucher',
      (tester) async {
    await _openCashbox(tester);

    final search = find.byKey(const Key('cashboxSearchField'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(_hasTextFocus(tester, search), isTrue);

    await tester.enterText(search, 'مجهز الرافدين');
    await tester.pump();

    final table = find.byKey(const Key('cashboxTable'));
    expect(
      find.descendant(
        of: table,
        matching: find.text('3 - مجهز الرافدين'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<AppDataTable>(table).rows,
      hasLength(1),
    );

    await tester.tap(find.byKey(const Key('cashboxRow_cashbox-003')));
    await tester.pump();

    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('cashboxVoucherNumberField')),
          )
          .controller
          ?.text,
      '3',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('cashboxAmountUsdField')),
          )
          .controller
          ?.text,
      '400.00',
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('cashboxDeleteButton')),
      ).onPressed,
      isNotNull,
    );

    final selectedRow = tester.widget<Material>(
      find.byKey(const Key('cashboxRow_cashbox-003')),
    );
    expect(
      selectedRow.color,
      Color.alphaBlend(
        AppModuleColors.cashbox.withAlpha(32),
        AppColors.surface,
      ),
    );

    await tester.enterText(
      find.byKey(const Key('cashboxNotesField')),
      'ملاحظة محدثة',
    );
    await tester.pump();

    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('cashboxUpdateButton')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('cashboxUndoButton')),
      ).onPressed,
      isNotNull,
    );
  });

  testWidgets('guards unsaved Cashbox data from system back',
      (tester) async {
    await _openCashbox(tester);
    await tester.enterText(
      find.byKey(const Key('cashboxNotesField')),
      'سند غير محفوظ',
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cashboxScreen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cashboxScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_cashbox')), findsOneWidget);
  });

  testWidgets('keeps invoice-generated Cashbox postings read-only',
      (tester) async {
    await _openCashbox(tester);
    await tester.enterText(
      find.byKey(const Key('cashboxSearchField')),
      'قيد آلي لفاتورة بيع رقم 102',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(
        const Key(
          'cashboxRow_'
          'cashbox-system-salesInvoice-sales-invoice-102',
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('cashboxDeleteButton')),
      ).onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const Key('cashboxNotesField')),
      'محاولة تعديل قيد آلي',
    );
    await tester.pump();
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('cashboxUpdateButton')),
      ).onPressed,
      isNull,
    );
  });

  testWidgets('quick-creates a subaccount under the selected main account',
      (tester) async {
    final store = AppStore.demo();
    addTearDown(store.dispose);
    await _openCashbox(tester, store: store);

    final defaults =
        await store.repositories.businessSettings.loadOperationalDefaults();
    final mainAccountId = defaults.cashbox.mainAccountId;
    final mainAccount = await store.repositories.operationalMasterData.getById(
      mainAccountId,
    );
    expect(mainAccount, isNotNull);

    const subaccountName = 'حساب فرعي للمرحلة الثانية';
    await tester.enterText(
      find.byKey(const Key('cashboxSubaccountField')),
      subaccountName,
    );
    await tester.pump();
    await tester.tap(find.text('إضافة حساب فرعي جديد'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cashboxQuickSubaccountDialog')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('cashboxQuickSubaccountConfirm')));
    await tester.pumpAndSettle();

    final stored = await store.repositories.operationalMasterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
      parentId: mainAccountId,
    );
    final created =
        stored.singleWhere((record) => record.name == subaccountName);
    expect(
      _fieldText(tester, const Key('cashboxSubaccountField')),
      '${created.number} - ${created.name}',
    );
    expect(created.parentId, mainAccountId);
    expect(created.id.value, isNotEmpty);
  });

  testWidgets(
      'blocks subaccount quick-create when displayed main text is stale',
      (tester) async {
    final store = AppStore.demo();
    addTearDown(store.dispose);
    await _openCashbox(tester, store: store);

    final defaults =
        await store.repositories.businessSettings.loadOperationalDefaults();
    final mainAccountId = defaults.cashbox.mainAccountId;
    final before = await store.repositories.operationalMasterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
      parentId: mainAccountId,
    );

    await tester.enterText(
      find.byKey(const Key('cashboxMainAccountField')),
      'حساب رئيسي معروض غير مطابق',
    );
    const rejectedName = 'حساب فرعي يجب ألا ينشأ';
    await tester.enterText(
      find.byKey(const Key('cashboxSubaccountField')),
      rejectedName,
    );
    await tester.pump();
    await tester.tap(find.text('إضافة حساب فرعي جديد'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('cashboxQuickSubaccountDialog')), findsNothing);
    final toast = find.byKey(const Key('appToast'));
    expect(toast, findsOneWidget);
    expect(tester.widget<SnackBar>(toast).backgroundColor, AppColors.orange);
    expect(
      find.descendant(
        of: toast,
        matching: find.text('اختر الحساب الرئيسي من القائمة أولاً'),
      ),
      findsOneWidget,
    );

    final after = await store.repositories.operationalMasterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
      parentId: mainAccountId,
    );
    expect(after.map((record) => record.id).toSet(),
        before.map((record) => record.id).toSet());
    expect(after.any((record) => record.name == rejectedName), isFalse);
  });

  testWidgets('quick-creates a main account with its required first subaccount',
      (tester) async {
    final store = AppStore.demo();
    addTearDown(store.dispose);
    await _openCashbox(tester, store: store);

    const mainName = 'صندوق المرحلة الثانية';
    const subaccountName = 'الحساب الافتتاحي';
    await tester.enterText(
      find.byKey(const Key('cashboxMainAccountField')),
      mainName,
    );
    await tester.pump();
    await tester.tap(find.text('إضافة حساب رئيسي جديد'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cashboxQuickMainAccountDialog')),
        findsOneWidget);
    expect(
      _fieldText(tester, const Key('cashboxQuickMainAccountMainNameField')),
      mainName,
    );
    await tester.enterText(
      find.byKey(
        const Key('cashboxQuickMainAccountSubaccountNameField'),
      ),
      subaccountName,
    );
    await tester.pump();
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('cashboxQuickMainAccountConfirm')),
      ).onPressed,
      isNotNull,
    );

    await tester.tap(
      find.byKey(const Key('cashboxQuickMainAccountConfirm')),
    );
    await tester.pumpAndSettle();
    expect(
      _fieldText(tester, const Key('cashboxMainAccountField')),
      mainName,
    );
    final mainAccounts =
        await store.repositories.operationalMasterData.getByKind(
      OperationalMasterDataKind.cashboxMainAccount,
    );
    final main =
        mainAccounts.singleWhere((record) => record.name == mainName);
    final subaccounts =
        await store.repositories.operationalMasterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
      parentId: main.id,
    );
    final subaccount = subaccounts.singleWhere(
      (record) => record.name == subaccountName,
    );
    expect(
      _fieldText(tester, const Key('cashboxSubaccountField')),
      '${subaccount.number} - ${subaccount.name}',
    );
    expect(subaccount.parentId, main.id);
    expect(main.id, isNot(subaccount.id));
  });

  testWidgets('hides cashbox master shortcuts without Settings manage',
      (tester) async {
    final store = AppStore.demo();
    addTearDown(store.dispose);
    await store.signIn(
      SignInCredentials(username: 'admin', password: 'password'),
    );
    final role = await store.services.administration.saveRole(
      RoleSaveRequest(
        name: 'إضافة الصندوق دون إدارة الإعدادات',
        permissions: {
          PermissionCode(
            module: 'cashbox',
            action: PermissionAction.view,
          ),
          PermissionCode(
            module: 'cashbox',
            action: PermissionAction.create,
          ),
        },
      ),
    );
    await store.services.administration.createUser(
      UserCreateRequest(
        fullName: 'مستخدم إضافة الصندوق',
        username: 'cashbox.creator',
        roleIds: {role.id},
        initialPassword: 'cashbox-password',
      ),
    );
    await store.signOut();

    await _openCashbox(
      tester,
      store: store,
      username: 'cashbox.creator',
      password: 'cashbox-password',
    );

    final mainField = tester.widget<AppAutocompleteField<CashboxMainAccount>>(
      find.ancestor(
        of: find.byKey(const Key('cashboxMainAccountField')),
        matching: find.byType(
          AppAutocompleteField<CashboxMainAccount>,
        ),
      ),
    );
    final subaccountField =
        tester.widget<AppAutocompleteField<CashboxSubaccount>>(
      find.ancestor(
        of: find.byKey(const Key('cashboxSubaccountField')),
        matching: find.byType(
          AppAutocompleteField<CashboxSubaccount>,
        ),
      ),
    );
    expect(mainField.onCreateRequested, isNull);
    expect(subaccountField.onCreateRequested, isNull);

    await tester.enterText(
      find.byKey(const Key('cashboxMainAccountField')),
      'صندوق غير موجود',
    );
    await tester.pump();
    expect(find.text('إضافة حساب رئيسي جديد'), findsNothing);
  });
}

Future<void> _openCashbox(
  WidgetTester tester, {
  AppStore? store,
  String username = 'admin',
  String password = 'password',
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(AlmumayazApp(store: store));
  await tester.enterText(find.byKey(const Key('usernameField')), username);
  await tester.enterText(find.byKey(const Key('passwordField')), password);
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('dashboardCard_cashbox')));
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, Key key) {
  return _editableText(tester, find.byKey(key)).controller.text;
}

bool _hasTextFocus(WidgetTester tester, Finder finder) {
  return _editableText(tester, finder).focusNode.hasFocus;
}

EditableText _editableText(WidgetTester tester, Finder field) {
  return tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
}

InputDecoration _fieldDecoration(WidgetTester tester, Finder field) {
  return tester
      .widget<InputDecorator>(
        find.descendant(of: field, matching: find.byType(InputDecorator)),
      )
      .decoration;
}

void _expectSameRow(WidgetTester tester, List<String> fieldKeys) {
  final firstY = tester.getTopLeft(find.byKey(Key(fieldKeys.first))).dy;
  for (final fieldKey in fieldKeys.skip(1)) {
    expect(
      tester.getTopLeft(find.byKey(Key(fieldKey))).dy,
      closeTo(firstY, 0.1),
    );
  }
}
