import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the purchase fields and buttons without a table',
      (tester) async {
    await _openPurchaseScreen(tester);

    expect(find.byKey(const Key('purchaseScreen')), findsOneWidget);
    expect(find.text('إدارة فواتير الشراء من المجهزين'), findsOneWidget);
    expect(find.byKey(const Key('purchaseHeaderPanel')), findsOneWidget);
    expect(find.byKey(const Key('purchaseFutureTableSpace')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTotalsPanel')), findsOneWidget);
    expect(find.byKey(const Key('purchaseActionBar')), findsOneWidget);
    expect(find.byKey(const Key('purchaseItemsTable')), findsNothing);
    expect(find.byKey(const Key('purchaseTableHeader')), findsNothing);

    const firstRowFieldKeys = [
      'purchaseInvoiceNumberField',
      'purchaseDateField',
      'purchaseTimeField',
      'purchaseWarehouseField',
      'purchaseTypeField',
      'purchasePaymentTypeField',
      'purchaseCurrencyField',
      'purchaseExchangeRateField',
    ];
    const secondRowFieldKeys = [
      'purchaseSupplierField',
      'purchaseNotesField',
    ];

    for (final fieldKey in const [
      ...firstRowFieldKeys,
      ...secondRowFieldKeys,
      'purchaseExpensesField',
      'purchaseInvoiceDiscountField',
      'purchaseDiscountPercentField',
      'purchasePaidAmountField',
      'purchaseTotalField',
      'purchaseRemainingField',
      'purchaseSupplierBalanceField',
    ]) {
      expect(find.byKey(Key(fieldKey)), findsOneWidget);
    }

    final firstRowY = tester
        .getCenter(find.byKey(const Key('purchaseInvoiceNumberField')))
        .dy;
    for (final fieldKey in firstRowFieldKeys.skip(1)) {
      expect(
        tester.getCenter(find.byKey(Key(fieldKey))).dy,
        closeTo(firstRowY, 0.1),
      );
    }

    final secondRowY =
        tester.getCenter(find.byKey(const Key('purchaseSupplierField'))).dy;
    expect(
      tester.getCenter(find.byKey(const Key('purchaseNotesField'))).dy,
      closeTo(secondRowY, 0.1),
    );
    expect(secondRowY, greaterThan(firstRowY));

    for (final buttonKey in const [
      'purchaseFirstButton',
      'purchasePreviousButton',
      'purchaseNextButton',
      'purchaseLastButton',
      'purchaseSearchButton',
      'purchasePrintButton',
      'purchasePrintWithoutPricesButton',
      'purchaseStatementButton',
      'purchaseSaveButton',
      'purchaseUpdateButton',
      'purchaseUndoButton',
      'purchaseDeleteButton',
    ]) {
      expect(find.byKey(Key(buttonKey)), findsOneWidget);
    }

    final navigationY =
        tester.getCenter(find.byKey(const Key('purchaseFirstButton'))).dy;
    final utilityY =
        tester.getCenter(find.byKey(const Key('purchaseSearchButton'))).dy;
    final actionsY =
        tester.getCenter(find.byKey(const Key('purchaseSaveButton'))).dy;
    expect(utilityY, closeTo(navigationY, 0.1));
    expect(actionsY, closeTo(navigationY, 0.1));
    for (final buttonKey in const [
      'purchasePreviousButton',
      'purchaseNextButton',
      'purchaseLastButton',
      'purchasePrintButton',
      'purchasePrintWithoutPricesButton',
      'purchaseStatementButton',
      'purchaseUpdateButton',
      'purchaseUndoButton',
      'purchaseDeleteButton',
    ]) {
      expect(
        tester.getCenter(find.byKey(Key(buttonKey))).dy,
        closeTo(navigationY, 0.1),
      );
    }
    expect(
      tester.getCenter(find.byKey(const Key('purchaseFirstButton'))).dx,
      greaterThan(
        tester.getCenter(find.byKey(const Key('purchaseSearchButton'))).dx,
      ),
    );
    expect(
      tester.getCenter(find.byKey(const Key('purchaseSearchButton'))).dx,
      greaterThan(
        tester.getCenter(find.byKey(const Key('purchaseSaveButton'))).dx,
      ),
    );

    final screenShell = tester.widget<AppScreenShell>(
      find.byKey(const Key('purchaseScreen')),
    );
    expect(screenShell.backgroundColor, isNot(AppColors.background));

    final warehouse = _dropdown(tester, 'purchaseWarehouseField');
    expect(warehouse.value, 'الرئيسي');
    expect(
      warehouse.options.map((option) => option.label),
      const ['الرئيسي', 'الرصافة', 'الكرادة', 'المنصور'],
    );
    expect(warehouse.accentColor, AppModuleColors.purchases);

    final purchaseType = _dropdown(tester, 'purchaseTypeField');
    expect(purchaseType.value, 'local');
    expect(
      purchaseType.options.map((option) => option.label),
      const ['محلي', 'استيراد', 'إرجاع'],
    );

    final paymentType = _dropdown(tester, 'purchasePaymentTypeField');
    expect(paymentType.value, 'cash');
    expect(
      paymentType.options.map((option) => option.label),
      const ['نقد', 'آجل'],
    );

    final currency = _dropdown(tester, 'purchaseCurrencyField');
    expect(currency.value, 'IQD');
    expect(
      currency.options.map((option) => option.label),
      const ['دينار', 'دولار'],
    );

    for (final dropdownKey in const [
      'purchaseWarehouseField',
      'purchaseTypeField',
      'purchasePaymentTypeField',
      'purchaseCurrencyField',
    ]) {
      expect(
        tester.getSize(find.byKey(Key(dropdownKey))).height,
        AppControlHeights.large,
      );
    }

    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('purchaseTimeField')),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('purchaseExchangeRateField')),
          )
          .enabled,
      isFalse,
    );

    for (final disabledButton in const [
      'purchaseFirstButton',
      'purchasePreviousButton',
      'purchaseNextButton',
      'purchaseLastButton',
      'purchasePrintButton',
      'purchasePrintWithoutPricesButton',
      'purchaseStatementButton',
      'purchaseUpdateButton',
      'purchaseUndoButton',
      'purchaseDeleteButton',
    ]) {
      expect(_button(tester, disabledButton).onPressed, isNull);
    }
    expect(_button(tester, 'purchaseSearchButton').onPressed, isNotNull);
    expect(_button(tester, 'purchaseSaveButton').onPressed, isNotNull);

    final backButton = tester.widget<AppHeaderIconButton>(
      find.byKey(const Key('appScreenBackButton')),
    );
    expect(backButton.onPressed, isNotNull);
    backButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('purchaseScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsOneWidget);
  });

  testWidgets('filters and selects suppliers by name or number',
      (tester) async {
    await _openPurchaseScreen(tester, size: const Size(1440, 900));

    final supplier = find.byKey(const Key('purchaseSupplierField'));
    await tester.tap(supplier);
    await tester.pump();

    expect(find.text('مجهز الرافدين'), findsOneWidget);
    expect(find.text('شركة الموصل الحديثة'), findsOneWidget);
    expect(find.text('رقم المجهز: 6'), findsOneWidget);

    await tester.enterText(supplier, '6');
    await tester.pump();

    expect(find.text('شركة الموصل الحديثة'), findsOneWidget);
    expect(find.text('مجهز الرافدين'), findsNothing);

    await tester.tap(find.text('شركة الموصل الحديثة'));
    await tester.pump();

    expect(
      tester.widget<TextFormField>(supplier).controller?.text,
      'شركة الموصل الحديثة',
    );
    expect(
      _button(tester, 'purchaseStatementButton').onPressed,
      isNotNull,
    );
    expect(find.byKey(const Key('purchaseItemsTable')), findsNothing);
  });

  testWidgets('updates currency and temporary action states',
      (tester) async {
    await _openPurchaseScreen(tester, size: const Size(1440, 900));

    _dropdown(tester, 'purchaseCurrencyField').onChanged('USD');
    await tester.pump();

    expect(_dropdown(tester, 'purchaseCurrencyField').value, 'USD');
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('purchaseExchangeRateField')),
          )
          .enabled,
      isTrue,
    );

    await tester.enterText(
      find.byKey(const Key('purchaseExpensesField')),
      '1000',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseInvoiceDiscountField')),
      '100',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseDiscountPercentField')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('purchasePaidAmountField')),
      '100',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseSupplierField')),
      'مجهز الرافدين',
    );
    await tester.pump();

    expect(_fieldText(tester, 'purchaseTotalField'), '0.00');
    expect(_fieldText(tester, 'purchaseRemainingField'), '0.00');

    _button(tester, 'purchaseSaveButton').onPressed?.call();
    await tester.pump();

    expect(find.text('تم حفظ بيانات فاتورة الشراء مؤقتاً'), findsOneWidget);
    expect(_button(tester, 'purchaseSaveButton').onPressed, isNull);
    expect(_button(tester, 'purchaseDeleteButton').onPressed, isNotNull);
    expect(_button(tester, 'purchasePrintButton').onPressed, isNotNull);

    await tester.enterText(
      find.byKey(const Key('purchaseNotesField')),
      'ملاحظة مؤقتة',
    );
    await tester.pump();

    expect(_button(tester, 'purchaseUpdateButton').onPressed, isNotNull);
    expect(_button(tester, 'purchaseUndoButton').onPressed, isNotNull);
    expect(find.byKey(const Key('purchaseItemsTable')), findsNothing);
  });
}

AppDropdownField<String> _dropdown(
  WidgetTester tester,
  String fieldKey,
) {
  return tester.widget<AppDropdownField<String>>(
    find.ancestor(
      of: find.byKey(Key(fieldKey)),
      matching: find.byType(AppDropdownField<String>),
    ),
  );
}

AppButton _button(WidgetTester tester, String buttonKey) {
  return tester.widget<AppButton>(find.byKey(Key(buttonKey)));
}

String? _fieldText(WidgetTester tester, String fieldKey) {
  return tester
      .widget<TextFormField>(find.byKey(Key(fieldKey)))
      .controller
      ?.text;
}

Future<void> _openPurchaseScreen(
  WidgetTester tester, {
  Size size = const Size(1280, 720),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await _login(tester);
  await tester.tap(find.byKey(const Key('dashboardCard_purchases')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
