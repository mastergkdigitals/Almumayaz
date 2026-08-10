import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/settings/domain/settings_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves negative purchase row results', () {
    const row = AppPurchaseInvoiceTableRowData(
      quantity: '1',
      purchasePrice: '10',
      discount: '20',
    );

    expect(row.totalValue, -10);
    expect(row.priceAfterDiscountValue, -10);

    final calculated = row.withCalculatedValues(
      'IQD',
      lineBaseTotal: -10,
      invoiceAdjustment: 0,
    );
    expect(calculated.priceAfterDiscount, '-10');
    expect(calculated.total, '-10');
    expect(calculated.cost, '-10');
    expect(calculated.totalCost, '-10');
  });

  testWidgets('builds the shared purchase invoice layout', (tester) async {
    await _openPurchaseScreen(tester);

    expect(find.byKey(const Key('purchaseScreen')), findsOneWidget);
    expect(
      find.byKey(const Key('purchaseTintBackground')),
      findsOneWidget,
    );

    const firstRowKeys = [
      'purchaseInvoiceNumberField',
      'purchaseDateField',
      'purchaseTimeField',
      'purchaseWarehouseField',
      'purchaseTypeField',
      'purchasePaymentTypeField',
      'purchaseCurrencyField',
      'purchaseExchangeRateField',
    ];
    const secondRowKeys = [
      'purchaseSupplierNameField',
      'purchaseNotesField',
    ];
    const totalsRowKeys = [
      'purchaseExpensesButton',
      'purchaseExpensesField',
      'purchaseInvoiceDiscountField',
      'purchaseDiscountPercentageField',
      'purchasePaidField',
      'purchaseTotalField',
      'purchaseRemainingField',
      'purchaseCurrentBalanceField',
    ];

    for (final key in [
      ...firstRowKeys,
      ...secondRowKeys,
      ...totalsRowKeys,
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(
      find.ancestor(
        of: find.byKey(const Key('purchaseSupplierNameField')),
        matching: find.byType(AppAutocompleteField<String>),
      ),
      findsOneWidget,
    );

    _expectRightToLeftOrder(tester, firstRowKeys);
    _expectRightToLeftOrder(tester, secondRowKeys);
    _expectRightToLeftOrder(tester, totalsRowKeys);

    for (final key in const [
      'purchaseWarehouseField',
      'purchaseTypeField',
      'purchasePaymentTypeField',
      'purchaseCurrencyField',
    ]) {
      final dropdown = tester.widget<AppDropdownField<String>>(
        find.ancestor(
          of: find.byKey(Key(key)),
          matching: find.byType(AppDropdownField<String>),
        ),
      );
      expect(dropdown.useIntrinsicHeight, isTrue);
      expect(dropdown.accentColor, AppModuleColors.purchases);
      expect(dropdown.textDirection, TextDirection.rtl);
      expect(dropdown.textAlign, TextAlign.right);
      expect(dropdown.menuTextDirection, TextDirection.rtl);
    }

    final purchaseType = _dropdown(tester, 'purchaseTypeField');
    expect(
      purchaseType.options.map((option) => option.label),
      containsAllInOrder(['محلي', 'إستيراد', 'إرجاع']),
    );
    final paymentType = _dropdown(
      tester,
      'purchasePaymentTypeField',
    );
    expect(
      paymentType.options.map((option) => option.label),
      containsAllInOrder(['نقدي', 'آجل']),
    );
    final currency = _dropdown(tester, 'purchaseCurrencyField');
    expect(
      currency.options.map((option) => option.label),
      containsAllInOrder(['دينار', 'دولار']),
    );

    for (final key in [
      'purchaseInvoiceNumberField',
      'purchaseDateField',
      'purchaseTimeField',
      'purchaseExchangeRateField',
      ...secondRowKeys,
      ...totalsRowKeys.where((key) => key != 'purchaseExpensesButton'),
    ]) {
      final textField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      );
      expect(textField.textDirection, TextDirection.rtl);
      expect(textField.textAlign, TextAlign.right);
    }
    for (final key in const [
      'purchaseExchangeRateField',
      'purchaseExpensesField',
      'purchaseInvoiceDiscountField',
      'purchaseDiscountPercentageField',
      'purchasePaidField',
    ]) {
      expect(
        find.ancestor(
          of: find.byKey(Key(key)),
          matching: find.byType(AppMoneyField),
        ),
        findsOneWidget,
      );
    }

    final exchangeRate = _textField(tester, 'purchaseExchangeRateField');
    expect(exchangeRate.enabled, isFalse);
    expect(exchangeRate.readOnly, isTrue);

    expect(find.byKey(const Key('purchaseItemsTable')), findsOneWidget);
    expect(
      find.byKey(const Key('appPurchaseInvoiceTableTemplate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appPurchaseInvoiceTableHeader')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appPurchaseInvoiceTableSummary')),
      findsOneWidget,
    );
    for (final label in const [
      'الحاوية',
      'سعر الشراء',
      'الكلفة',
      'إجمالي الكلفة',
      'سعر البيع',
    ]) {
      expect(
        find.descendant(
          of: find.byKey(
            const Key('appPurchaseInvoiceTableTemplate'),
          ),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '101');
    expect(
      _fieldValue(tester, 'purchaseSupplierNameField'),
      'شركة الرافدين للتجهيز',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appPurchaseInvoiceTemplateNameField-',
      ),
      'ورق طباعة A4',
    );
    expect(_fieldValue(tester, 'purchaseTotalField'), '150,000');
    expect(_fieldValue(tester, 'purchaseRemainingField'), '150,000');
    expect(
      _fieldValue(tester, 'purchaseCurrentBalanceField'),
      '450,000',
    );

    expect(
      tester.widget<AppRegularButton>(
        find.byKey(const Key('purchaseExpensesButton')),
      ).label,
      'المصاريف',
    );
    expect(
      tester.getSize(
        find.byKey(const Key('purchaseExpensesButton')),
      ).width,
      greaterThan(
        tester
            .getSize(
              find.byKey(const Key('purchaseExpensesField')),
            )
            .width,
      ),
    );

    const invoiceButtons = <String, (IconData, String)>{
      'purchaseSearchButton': (Icons.search_rounded, 'بحث'),
      'purchasePrintButton': (Icons.print_rounded, 'طباعة'),
      'purchasePrintWithoutPricesButton': (
        Icons.money_off_rounded,
        'طباعة بدون سعر',
      ),
      'purchaseStatementButton': (
        Icons.receipt_long_rounded,
        'كشف الحساب',
      ),
    };
    for (final entry in invoiceButtons.entries) {
      final finder = find.byKey(Key(entry.key));
      final button = tester.widget<AppHeaderIconButton>(finder);
      expect(button.icon, entry.value.$1);
      expect(button.tooltip, entry.value.$2);
      expect(tester.getSize(finder), const Size.square(52));
    }
    _expectRightToLeftOrder(tester, invoiceButtons.keys.toList());

    for (final key in const [
      'purchaseFirstButton',
      'purchasePreviousButton',
      'purchaseNextButton',
      'purchaseLastButton',
      'purchaseSaveButton',
      'purchaseUpdateButton',
      'purchaseUndoButton',
      'purchaseDeleteButton',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    for (final key in const [
      'purchaseFirstButton',
      'purchasePreviousButton',
      'purchaseSaveButton',
      'purchaseUpdateButton',
      'purchaseUndoButton',
    ]) {
      expect(_actionButton(tester, key).onPressed, isNull);
    }
    for (final key in const [
      'purchaseNextButton',
      'purchaseLastButton',
      'purchaseDeleteButton',
    ]) {
      expect(_actionButton(tester, key).onPressed, isNotNull);
    }

    final expectedTint = Color.alphaBlend(
      AppModuleColors.purchases.withAlpha(12),
      AppColors.surface,
    );
    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('purchaseScreen')),
    );
    expect(shell.subtitle, isNull);
    expect(shell.backgroundColor, expectedTint);
    expect(shell.onSave, isNull);
    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const Key('purchaseTintBackground')),
          )
          .color,
      expectedTint,
    );

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('purchaseScreen')), findsNothing);
    expect(
      find.byKey(const Key('dashboardCard_purchases')),
      findsOneWidget,
    );
  });

  testWidgets('calculates purchase rows costs discounts and cash payment',
      (tester) async {
    await _openPurchaseScreen(tester);

    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppTableActionButton>(
            find.byKey(
              const Key('appPurchaseInvoiceTemplateAddButton'),
            ),
          )
          .onPressed,
      isNull,
    );

    _dropdown(tester, 'purchaseCurrencyField').onChanged('USD');
    await tester.pump();
    _dropdown(tester, 'purchasePaymentTypeField').onChanged('آجل');
    await tester.pump();

    expect(
      _textField(tester, 'purchaseExchangeRateField').enabled,
      isTrue,
    );
    expect(
      _textField(tester, 'purchaseExchangeRateField').readOnly,
      isFalse,
    );

    await tester.enterText(
      _invoiceFieldByPrefix(
        'appPurchaseInvoiceTemplateQuantityField-',
      ),
      '2',
    );
    await tester.enterText(
      _invoiceFieldByPrefix(
        'appPurchaseInvoiceTemplatePurchasePriceField-',
      ),
      '100',
    );
    await tester.enterText(
      _invoiceFieldByPrefix(
        'appPurchaseInvoiceTemplateDiscountField-',
      ),
      '20',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseExpensesField')),
      '20',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppTableActionButton>(
            find.byKey(
              const Key('appPurchaseInvoiceTemplateAddButton'),
            ),
          )
          .onPressed,
      isNull,
    );

    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appPurchaseInvoiceTemplatePriceAfterDiscountField-',
      ),
      '90.00',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appPurchaseInvoiceTemplateTotalField-',
      ),
      '180.00',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appPurchaseInvoiceTemplateCostField-',
      ),
      '100.00',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appPurchaseInvoiceTemplateTotalCostField-',
      ),
      '200.00',
    );
    expect(_fieldValue(tester, 'purchaseTotalField'), '200.00');

    final summary = find.byKey(
      const Key('appPurchaseInvoiceTableSummary'),
    );
    expect(
      find.descendant(of: summary, matching: find.text('2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('20.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('200.00')),
      findsNWidgets(2),
    );

    await tester.enterText(
      find.byKey(const Key('purchaseInvoiceDiscountField')),
      '30',
    );
    await tester.pump();
    expect(
      _fieldValue(tester, 'purchaseDiscountPercentageField'),
      '15.00',
    );
    expect(_fieldValue(tester, 'purchaseTotalField'), '170.00');
    expect(_fieldValue(tester, 'purchaseRemainingField'), '170.00');
    expect(
      _fieldValue(tester, 'purchaseCurrentBalanceField'),
      '170.00',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appPurchaseInvoiceTemplateCostField-',
      ),
      '85.00',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appPurchaseInvoiceTemplateTotalCostField-',
      ),
      '170.00',
    );

    await tester.enterText(
      find.byKey(const Key('purchaseDiscountPercentageField')),
      '8.50',
    );
    await tester.pump();
    expect(
      _fieldValue(tester, 'purchaseInvoiceDiscountField'),
      '17.00',
    );
    expect(_fieldValue(tester, 'purchaseTotalField'), '183.00');
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appPurchaseInvoiceTemplateCostField-',
      ),
      '91.50',
    );

    await tester.enterText(
      find.byKey(const Key('purchasePaidField')),
      '50',
    );
    await tester.pump();
    expect(_fieldValue(tester, 'purchaseRemainingField'), '133.00');
    expect(
      _fieldValue(tester, 'purchaseCurrentBalanceField'),
      '133.00',
    );

    _dropdown(tester, 'purchasePaymentTypeField').onChanged('نقدي');
    await tester.pump();

    final paid = _textField(tester, 'purchasePaidField');
    expect(paid.enabled, isFalse);
    expect(paid.readOnly, isTrue);
    expect(_fieldValue(tester, 'purchasePaidField'), '183.00');
    expect(_fieldValue(tester, 'purchaseRemainingField'), '0.00');
    expect(
      _fieldValue(tester, 'purchaseCurrentBalanceField'),
      '0.00',
    );
  });

  testWidgets('caps purchase payment in IQD and USD when totals change',
      (tester) async {
    await _openPurchaseScreen(tester);

    await tester.enterText(
      find.byKey(const Key('purchasePaidField')),
      '999999',
    );
    await tester.pump();
    expect(_fieldValue(tester, 'purchasePaidField'), '150,000');
    expect(_fieldValue(tester, 'purchaseRemainingField'), '0');

    await tester.enterText(
      find.byKey(const Key('purchasePaidField')),
      '100000',
    );
    await tester.enterText(
      find.byKey(const Key('purchaseInvoiceDiscountField')),
      '100000',
    );
    await tester.pump();
    expect(_fieldValue(tester, 'purchaseTotalField'), '50,000');
    expect(_fieldValue(tester, 'purchasePaidField'), '50,000');

    _dropdown(tester, 'purchaseCurrencyField').onChanged('USD');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('purchasePaidField')),
      '999999',
    );
    await tester.pump();
    expect(_fieldValue(tester, 'purchasePaidField'), '50,000.00');
    expect(_fieldValue(tester, 'purchaseRemainingField'), '0.00');
  });

  testWidgets('guards purchase edits when Windows Back is used',
      (tester) async {
    await _openPurchaseScreen(tester);

    await tester.enterText(
      find.byKey(const Key('purchaseNotesField')),
      'تعديل غير محفوظ',
    );
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('purchaseScreen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('purchaseScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsOneWidget);
  });

  testWidgets(
      'requires complete purchase rows and ignores a trailing empty row',
      (tester) async {
    await _openPurchaseScreen(tester);
    await _openNewPurchaseForm(tester);
    await tester.enterText(
      find.byKey(const Key('purchaseSupplierNameField')),
      'مجهز اختبار',
    );

    await tester.tap(find.byKey(const Key('purchaseSaveButton')));
    await tester.pump();
    expect(find.text('اختر مجهزاً موجوداً من القائمة'), findsOneWidget);
    await _finishToast(tester);
    await tester.enterText(
      find.byKey(const Key('purchaseSupplierNameField')),
      'مجهز الفرات',
    );

    await tester.tap(find.byKey(const Key('purchaseSaveButton')));
    await tester.pump();
    expect(find.text('أضف مادة واحدة مكتملة على الأقل'), findsOneWidget);
    await _finishToast(tester);

    await tester.enterText(
      _invoiceFieldByPrefix('appPurchaseInvoiceTemplateCodeField-'),
      'P-TEST',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('purchaseSaveButton')));
    await tester.pump();
    expect(
      find.text(
        'أكمل بيانات سطر المادة: رمز المادة واسم المادة والكمية',
      ),
      findsOneWidget,
    );
    await _finishToast(tester);

    await tester.enterText(
      _invoiceFieldByPrefix('appPurchaseInvoiceTemplateNameField-'),
      'مادة اختبار',
    );
    await tester.enterText(
      _invoiceFieldByPrefix('appPurchaseInvoiceTemplateQuantityField-'),
      '1',
    );
    await tester.tap(find.byKey(const Key('purchaseSaveButton')));
    await tester.pump();
    expect(find.text('اختر مادة موجودة لكل سطر'), findsOneWidget);
    await _finishToast(tester);

    await _completeCurrentPurchaseRow(tester);
    final addButton = tester.widget<AppTableActionButton>(
      find.byKey(const Key('appPurchaseInvoiceTemplateAddButton')),
    );
    expect(addButton.onPressed, isNotNull);
    addButton.onPressed!();
    await tester.pump();

    await tester.tap(find.byKey(const Key('purchaseSaveButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.blue,
      message: 'تم حفظ قائمة الشراء',
    );
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('purchaseSearchButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('purchaseRecordSearchField')),
      '104',
    );
    await tester.pump();
    expect(find.textContaining('1 مواد'), findsOneWidget);
  });

  testWidgets('navigates and searches complete demo purchase invoices',
      (tester) async {
    await _openPurchaseScreen(tester);

    await tester.tap(find.byKey(const Key('purchaseNextButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '102');
    expect(
      _fieldValue(tester, 'purchaseSupplierNameField'),
      'شركة التجارة العالمية',
    );
    expect(_fieldLabel(tester, 'purchaseTotalField'), 'المجموع دولار');
    expect(_fieldValue(tester, 'purchasePaidField'), '500');
    expect(
      tester
          .widget<AppHeaderIconButton>(
            find.byKey(
              const Key('purchasePrintWithoutPricesButton'),
            ),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('purchaseSearchButton')));
    await tester.pumpAndSettle();
    final dialog = find.byKey(const Key('purchaseRecordSearchDialog'));
    expect(dialog, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(dialog).accentColor,
      AppModuleColors.purchases,
    );
    await tester.enterText(
      find.byKey(const Key('purchaseRecordSearchField')),
      '103',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('purchaseRecordSearchResult-0')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '103');
    expect(
      _fieldValue(tester, 'purchaseSupplierNameField'),
      'مجهز الكرادة',
    );
    expect(_dropdown(tester, 'purchasePaymentTypeField').value, 'نقدي');
    expect(_textField(tester, 'purchasePaidField').enabled, isFalse);
    expect(_fieldValue(tester, 'purchasePaidField'), '90,000');
  });

  testWidgets(
      'uses Purchase defaults and keeps repository edits after reopen',
      (tester) async {
    final store = AppStore.demo();
    final defaults =
        await store.repositories.businessSettings.loadOperationalDefaults();
    await store.repositories.businessSettings.saveOperationalDefaults(
      OperationalDefaults(
        purchases: PurchaseDefaults(
          warehouseId: EntityId('warehouse-004'),
          purchaseKind: PurchaseKind.imported,
          paymentKind: PaymentKind.credit,
          currency: AppCurrency.usd,
        ),
        sales: defaults.sales,
        cashbox: defaults.cashbox,
      ),
    );

    await _openPurchaseScreen(tester, store: store);
    await _openNewPurchaseForm(tester);

    expect(_dropdown(tester, 'purchaseWarehouseField').value, 'المنصور');
    expect(_dropdown(tester, 'purchaseTypeField').value, 'إستيراد');
    expect(_dropdown(tester, 'purchasePaymentTypeField').value, 'آجل');
    expect(_dropdown(tester, 'purchaseCurrencyField').value, 'USD');
    expect(_fieldValue(tester, 'purchaseExchangeRateField'), '1,310');

    await tester.tap(find.byKey(const Key('purchaseFirstButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('purchaseNotesField')),
      'تعديل محفوظ بعد إعادة الفتح',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('purchaseUpdateButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.green,
      message: 'تم تحديث قائمة الشراء',
    );
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboardCard_purchases')));
    await tester.pumpAndSettle();

    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '101');
    expect(
      _fieldValue(tester, 'purchaseNotesField'),
      'تعديل محفوظ بعد إعادة الفتح',
    );
  });

  testWidgets('shows and filters purchase supplier suggestions',
      (tester) async {
    await _openPurchaseScreen(tester);

    final supplier =
        find.byKey(const Key('purchaseSupplierNameField'));
    await tester.tap(supplier);
    await tester.pump();
    expect(find.text('شركة التجارة العالمية'), findsOneWidget);
    expect(find.text('مجهز الفرات'), findsOneWidget);

    await tester.enterText(supplier, 'الفر');
    await tester.pump();
    expect(find.text('شركة التجارة العالمية'), findsNothing);
    expect(find.text('مجهز الفرات'), findsOneWidget);
  });

  testWidgets('shows matching purchase action toasts', (tester) async {
    await _openPurchaseScreen(tester);

    await tester.enterText(
      find.byKey(const Key('purchaseNotesField')),
      'ملاحظة محدثة',
    );
    await tester.pump();
    expect(
      _actionButton(tester, 'purchaseUpdateButton').onPressed,
      isNotNull,
    );
    expect(
      _actionButton(tester, 'purchaseUndoButton').onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('purchaseUpdateButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.green,
      message: 'تم تحديث قائمة الشراء',
    );
    await _finishToast(tester);

    await tester.enterText(
      find.byKey(const Key('purchaseNotesField')),
      'تعديل غير محفوظ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('purchaseUndoButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.orange,
      message: 'تم التراجع عن التغييرات',
    );
    expect(_fieldValue(tester, 'purchaseNotesField'), 'ملاحظة محدثة');
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '104');

    await tester.enterText(
      find.byKey(const Key('purchaseSupplierNameField')),
      'مجهز الفرات',
    );
    await _completeCurrentPurchaseRow(tester);
    await tester.pump();
    await tester.tap(find.byKey(const Key('purchaseSaveButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.blue,
      message: 'تم حفظ قائمة الشراء',
    );
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('purchaseSearchButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('purchaseRecordSearchField')),
      '104',
    );
    await tester.pump();
    expect(find.textContaining('1 مواد'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('purchaseRecordSearchResult-0')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('purchaseDeleteButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.red,
      message: 'تم حذف قائمة الشراء',
    );
  });

  testWidgets('uses purchase theming in date and statement dialogs',
      (tester) async {
    await _openPurchaseScreen(tester);

    await tester.tap(find.byKey(const Key('purchaseDateField')));
    await tester.pump();
    expect(find.byKey(const Key('appDatePickerDialog')), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appDatePickerConfirm')),
          )
          .backgroundColor,
      AppModuleColors.purchases,
    );
    await tester.tap(find.byKey(const Key('appDatePickerCancel')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('purchaseStatementButton')));
    await tester.pumpAndSettle();
    final options = find.byKey(const Key('appStatementOptionsDialog'));
    expect(options, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(options).accentColor,
      AppModuleColors.purchases,
    );
    expect(
      _fieldValue(tester, 'appStatementParty'),
      'شركة الرافدين للتجهيز',
    );
    expect(
      _fieldLabel(tester, 'appStatementParty'),
      'اسم المجهز',
    );

    await tester.tap(find.byKey(const Key('appStatementConfirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final report = find.byKey(const Key('appStatementReportDialog'));
    expect(report, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(report).accentColor,
      AppModuleColors.purchases,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appStatementPrint')),
          )
          .backgroundColor,
      AppColors.blue,
    );
  });
}

AppDropdownField<String> _dropdown(
  WidgetTester tester,
  String key,
) {
  return tester.widget<AppDropdownField<String>>(
    find.ancestor(
      of: find.byKey(Key(key)),
      matching: find.byType(AppDropdownField<String>),
    ),
  );
}

AppButton _actionButton(WidgetTester tester, String key) {
  return tester.widget<AppButton>(find.byKey(Key(key)));
}

Finder _invoiceFieldByPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return widget is TextFormField &&
        key is ValueKey<String> &&
        key.value.startsWith(prefix);
  }).first;
}

String _invoiceFieldValueByPrefix(
  WidgetTester tester,
  String prefix,
) {
  return tester
      .widget<TextFormField>(_invoiceFieldByPrefix(prefix))
      .controller!
      .text;
}

Future<void> _openNewPurchaseForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('purchaseLastButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('purchaseLastButton')));
  await tester.pumpAndSettle();
}

Future<void> _completeCurrentPurchaseRow(WidgetTester tester) async {
  await tester.enterText(
    _invoiceFieldByPrefix('appPurchaseInvoiceTemplateCodeField-'),
    'P-1001',
  );
  await tester.enterText(
    _invoiceFieldByPrefix('appPurchaseInvoiceTemplateNameField-'),
    'طابعة ليزر',
  );
  await tester.enterText(
    _invoiceFieldByPrefix('appPurchaseInvoiceTemplateQuantityField-'),
    '1',
  );
  await tester.pump();
}

TextField _textField(WidgetTester tester, String key) {
  return tester.widget<TextField>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextField),
    ),
  );
}

String _fieldValue(WidgetTester tester, String key) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

String? _fieldLabel(WidgetTester tester, String key) {
  return _textField(tester, key).decoration?.labelText;
}

void _expectRightToLeftOrder(
  WidgetTester tester,
  List<String> keys,
) {
  for (var index = 1; index < keys.length; index++) {
    final previous = tester.getTopLeft(find.byKey(Key(keys[index - 1])));
    final current = tester.getTopLeft(find.byKey(Key(keys[index])));
    expect(previous.dx, greaterThan(current.dx));
    expect(previous.dy, closeTo(current.dy, 0.1));
  }
}

void _expectToast(
  WidgetTester tester, {
  required Color color,
  required String message,
}) {
  final toastFinder = find.descendant(
    of: find.byKey(const Key('purchaseScreen')),
    matching: find.byKey(const Key('appToast')),
  );
  expect(toastFinder, findsOneWidget);
  final toast = tester.widget<SnackBar>(toastFinder);
  expect(toast.backgroundColor, color);
  expect(
    find.descendant(
      of: toastFinder,
      matching: find.text(message),
    ),
    findsOneWidget,
  );
}

Future<void> _finishToast(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(AppToast.duration);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openPurchaseScreen(
  WidgetTester tester, {
  AppStore? store,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(AlmumayazApp(store: store));
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('dashboardCard_purchases')));
  await tester.pumpAndSettle();
}
