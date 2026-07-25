import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/purchases/presentation/widgets/purchase_items_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens the purchase screen with the approved shared design',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_purchases')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('purchaseScreen')), findsOneWidget);
    expect(find.text('إدارة فواتير الشراء من المجهزين'), findsOneWidget);
    expect(find.byKey(const Key('purchaseHeaderPanel')), findsOneWidget);
    expect(find.byKey(const Key('purchaseItemsTable')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTotalsPanel')), findsOneWidget);
    expect(find.byKey(const Key('purchaseActionBar')), findsOneWidget);
    expect(find.byKey(const Key('appScreenBackButton')), findsOneWidget);
    expect(
      tester
          .widget<Tooltip>(
            find.byKey(const Key('purchasePrintTooltip')),
          )
          .message,
      'طباعة',
    );
    expect(
      tester
          .widget<Tooltip>(
            find.byKey(const Key('purchaseStatementTooltip')),
          )
          .message,
      'كشف حساب المجهز',
    );

    for (final keyName in const [
      'purchaseInvoiceNumberField',
      'purchaseDateField',
      'purchaseTimeField',
      'purchaseWarehouseField',
      'purchaseTypeField',
      'purchasePaymentTypeField',
      'purchaseCurrencyField',
      'purchaseExchangeRateField',
      'purchaseSupplierField',
      'purchaseNotesField',
      'purchaseExpensesField',
      'purchaseInvoiceDiscountField',
      'purchaseDiscountPercentField',
      'purchasePaidAmountField',
      'purchaseTotalField',
      'purchaseRemainingField',
      'purchaseSupplierBalanceField',
    ]) {
      expect(find.byKey(Key(keyName)), findsOneWidget);
    }

    for (final header in const [
      'ت',
      'رمز المادة',
      'اسم المادة',
      'المخزن',
      'الكمية',
      'الحاوية',
      'سعر الشراء',
      'الخصم',
      'السعر بعد\nالخصم',
      'الإجمالي',
      'الكلفة',
      'إجمالي\nالكلفة',
      'سعر البيع',
    ]) {
      expect(
        find.descendant(
          of: find.byKey(const Key('purchaseTableHeader')),
          matching: find.text(header),
        ),
        findsOneWidget,
      );
    }

    final warehouseDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('purchaseWarehouseField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(warehouseDropdown.value, 'الرئيسي');
    expect(
      warehouseDropdown.options.map((option) => option.label),
      purchaseWarehouseNames,
    );
    expect(
      warehouseDropdown.accentColor,
      AppModuleColors.purchases,
    );

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
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('purchaseQuantity-r1')),
          )
          .controller
          ?.text,
      '0',
    );
    expect(
      tester
          .widget<AppTableActionButton>(
            find.byKey(const Key('purchaseDelete-r1')),
          )
          .onPressed,
      isNull,
    );

    final tableRect = tester.getRect(
      find.byKey(const Key('purchaseItemsTable')),
    );
    final deleteRect = tester.getRect(
      find.byKey(const Key('purchaseDelete-r1')),
    );
    expect(deleteRect.left, greaterThanOrEqualTo(tableRect.left));
    expect(deleteRect.right, lessThanOrEqualTo(tableRect.right));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('purchaseSearchField')),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('edits items, calculates totals, adds a row, and saves locally',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_purchases')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(
      find.byKey(const Key('purchaseSupplierField')),
      'مجهز الرافدين',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseCode-r1')),
      'P-001',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseName-r1')),
      'دفتر ملاحظات',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseQuantity-r1')),
      '2',
    );
    await tester.enterText(
      find.byKey(const Key('purchasePurchasePrice-r1')),
      '100',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseDiscount-r1')),
      '10',
    );
    await tester.pump();

    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('purchasePriceAfterDiscount-r1')),
          )
          .data,
      '95',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('purchaseTotal-r1')),
          )
          .data,
      '190',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('purchaseTotalField')),
          )
          .controller
          ?.text,
      '190',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('purchaseRemainingField')),
          )
          .controller
          ?.text,
      '190',
    );

    final salePrice = find.byKey(const Key('purchaseSalePrice-r1'));
    await tester.enterText(salePrice, '150');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('purchaseRow-r2')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('purchaseCode-r2')),
          )
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    tester
        .widget<AppButton>(
          find.byKey(const Key('purchaseSaveButton')),
        )
        .onPressed
        ?.call();
    await tester.pump();

    expect(find.text('تم حفظ فاتورة الشراء مؤقتاً'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('purchaseSaveButton')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('purchaseDeleteButton')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.enterText(
      find.byKey(const Key('purchaseNotesField')),
      'فاتورة تجريبية',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('purchaseUpdateButton')),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('purchaseUndoButton')),
          )
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
