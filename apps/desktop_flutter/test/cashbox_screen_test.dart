import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/cashbox/domain/cashbox_voucher.dart';
import 'package:erp/features/cashbox/presentation/cashbox_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters and navigates temporary cashbox vouchers', () {
    final controller = CashboxController();
    addTearDown(controller.dispose);

    expect(controller.state.vouchers, hasLength(6));

    controller.search('750,000');
    expect(controller.visibleVouchers, hasLength(1));
    expect(controller.visibleVouchers.first.number, 1);

    controller.search('');
    controller.first();
    expect(controller.selectedVoucher?.number, 1);

    controller.next();
    expect(controller.selectedVoucher?.number, 2);

    controller.last();
    expect(controller.selectedVoucher?.number, 6);

    controller.last();
    expect(controller.selectedVoucher, isNull);
  });

  test('recalculates demo summaries and account balances after mutations', () {
    final first = CashboxVoucher(
      id: 'v-1',
      number: 1,
      createdAt: DateTime(2026, 7, 27, 8),
      type: CashboxVoucherType.receipt,
      mainAccountId: 'parties',
      mainAccountLabel: 'الأطراف',
      subaccountId: 'party-1',
      subaccountLabel: 'زبون',
      exchangeRate: 1310,
      amountIqd: 100,
      amountUsd: 0,
      balanceBeforeIqd: 1000,
      balanceAfterIqd: 900,
      balanceBeforeUsd: 0,
      balanceAfterUsd: 0,
      notes: '',
    );
    final second = first.copyWith(
      createdAt: DateTime(2026, 7, 27, 9),
      type: CashboxVoucherType.payment,
      amountIqd: 40,
    );
    final controller = CashboxController(
      initialVouchers: [
        first,
        CashboxVoucher(
          id: 'v-2',
          number: 2,
          createdAt: second.createdAt,
          type: second.type,
          mainAccountId: second.mainAccountId,
          mainAccountLabel: second.mainAccountLabel,
          subaccountId: second.subaccountId,
          subaccountLabel: second.subaccountLabel,
          exchangeRate: second.exchangeRate,
          amountIqd: second.amountIqd,
          amountUsd: second.amountUsd,
          balanceBeforeIqd: 900,
          balanceAfterIqd: 940,
          balanceBeforeUsd: 0,
          balanceAfterUsd: 0,
          notes: '',
        ),
      ],
    );
    addTearDown(controller.dispose);

    expect(controller.summary.todayReceiptIqd, 100);
    expect(controller.summary.todayPaymentIqd, 40);
    expect(controller.accountBalance('party-1').iqd, 940);

    controller.select('v-1');
    controller.update(first.copyWith(amountIqd: 250));
    expect(controller.accountBalance('party-1').iqd, 790);

    controller.select('v-2');
    controller.deleteSelected();
    expect(controller.accountBalance('party-1').iqd, 750);
    expect(controller.summary.todayPaymentIqd, 0);

    controller.add(
      CashboxVoucher(
        id: 'v-3',
        number: 3,
        createdAt: DateTime(2026, 7, 27, 10),
        type: CashboxVoucherType.payment,
        mainAccountId: 'parties',
        mainAccountLabel: 'الأطراف',
        subaccountId: 'party-1',
        subaccountLabel: 'زبون',
        exchangeRate: 1310,
        amountIqd: 10,
        amountUsd: 0,
        balanceBeforeIqd: 0,
        balanceAfterIqd: 0,
        balanceBeforeUsd: 0,
        balanceAfterUsd: 0,
        notes: '',
      ),
    );
    expect(controller.accountBalance('party-1').iqd, 760);
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
      'الأطراف',
    );
    expect(
      _editableText(
        tester,
        find.byKey(const Key('cashboxSubaccountField')),
      ).controller.text,
      '1 - شركة النخيل للتجارة',
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
    expect(table.rows, hasLength(6));
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
      'نقل',
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
}

Future<void> _openCashbox(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('dashboardCard_cashbox')));
  await tester.pumpAndSettle();
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
