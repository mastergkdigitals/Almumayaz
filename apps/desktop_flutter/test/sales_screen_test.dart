import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:erp/features/settings/domain/settings_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies every editable Sales row input as meaningful', () {
    expect(const AppSalesInvoiceTableRowData().isEmpty, isTrue);
    expect(
      const AppSalesInvoiceTableRowData(quantity: '2').isEmpty,
      isFalse,
    );
    expect(
      const AppSalesInvoiceTableRowData(salePrice: '25,000').isEmpty,
      isFalse,
    );
    expect(
      const AppSalesInvoiceTableRowData(discount: '500').isEmpty,
      isFalse,
    );
    expect(
      const AppSalesInvoiceTableRowData(warehouse: 'الرصافة').isEmpty,
      isFalse,
    );
    expect(
      const AppSalesInvoiceTableRowData(
        quantity: '2',
        salePrice: '1,000',
        discount: '500',
      ).totalDiscountValue,
      1000,
    );
    const cappedDiscount = AppSalesInvoiceTableRowData(
      quantity: '2',
      salePrice: '100',
      discount: '150',
    );
    expect(cappedDiscount.discountValue, 100);
    expect(cappedDiscount.totalDiscountValue, 200);
    expect(cappedDiscount.totalValue, 0);
  });

  testWidgets('builds the shared sales invoice layout', (tester) async {
    await _openSalesScreen(tester);

    expect(find.byKey(const Key('salesScreen')), findsOneWidget);
    expect(find.byKey(const Key('salesTintBackground')), findsOneWidget);

    const firstRowKeys = [
      'salesInvoiceNumberField',
      'salesDateField',
      'salesTimeField',
      'salesWarehouseField',
      'salesTypeField',
      'salesCurrencyField',
      'salesExchangeRateField',
    ];
    const secondRowKeys = [
      'salesCustomerNameField',
      'salesNotesField',
    ];
    const totalsRowKeys = [
      'salesDriverNameField',
      'salesInvoiceDiscountField',
      'salesDiscountPercentageField',
      'salesReceivedField',
      'salesTotalIqdField',
      'salesRemainingIqdField',
      'salesCurrentBalanceIqdField',
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
        of: find.byKey(const Key('salesCustomerNameField')),
        matching: find.byType(AppAutocompleteField<Party>),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('salesTimeField')),
        matching: find.byType(AppTimeField),
      ),
      findsOneWidget,
    );

    _expectRightToLeftOrder(tester, firstRowKeys);
    _expectRightToLeftOrder(tester, secondRowKeys);
    _expectRightToLeftOrder(tester, totalsRowKeys);

    for (final key in const [
      'salesWarehouseField',
      'salesTypeField',
      'salesCurrencyField',
    ]) {
      final dropdown = tester.widget<AppDropdownField<String>>(
        find.ancestor(
          of: find.byKey(Key(key)),
          matching: find.byType(AppDropdownField<String>),
        ),
      );
      expect(dropdown.useIntrinsicHeight, isTrue);
      expect(dropdown.accentColor, AppModuleColors.sales);
      expect(dropdown.textDirection, TextDirection.rtl);
      expect(dropdown.textAlign, TextAlign.right);
      expect(dropdown.menuTextDirection, TextDirection.rtl);
    }

    final saleTypeDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('salesTypeField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(
      saleTypeDropdown.options.map((option) => option.label),
      containsAllInOrder(['نقدي', 'آجل', 'أقساط']),
    );

    for (final key in [
      'salesInvoiceNumberField',
      'salesDateField',
      'salesTimeField',
      'salesExchangeRateField',
      ...secondRowKeys,
      ...totalsRowKeys,
    ]) {
      final textField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      );
      expect(
        textField.textDirection,
        TextDirection.rtl,
        reason: '$key must remain RTL outside the invoice table.',
      );
      expect(
        textField.textAlign,
        TextAlign.right,
        reason: '$key must align its value to the RTL side.',
      );
    }
    for (final key in const [
      'salesExchangeRateField',
      'salesInvoiceDiscountField',
      'salesDiscountPercentageField',
      'salesReceivedField',
    ]) {
      expect(
        find.ancestor(
          of: find.byKey(Key(key)),
          matching: find.byType(AppMoneyField),
        ),
        findsOneWidget,
      );
    }

    expect(find.byKey(const Key('salesItemsTable')), findsOneWidget);
    expect(
      find.byKey(const Key('appSalesInvoiceTableTemplate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableHeader')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableSummary')),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: _invoiceFieldByPrefix(
          'appSalesInvoiceTemplateQuantityField-',
        ),
        matching: find.byType(AppIntegerField),
      ),
      findsOneWidget,
    );
    for (final key in const [
      'appSalesInvoiceTemplateSalePriceField',
      'appSalesInvoiceTemplateDiscountField',
    ]) {
      expect(
        find.ancestor(
          of: _invoiceFieldByPrefix('$key-'),
          matching: find.byType(AppMoneyField),
        ),
        findsOneWidget,
      );
    }

    expect(find.byKey(const Key('salesActionBar')), findsOneWidget);
    expect(find.byKey(const Key('salesSearchField')), findsNothing);

    const invoiceButtons = <String, (IconData, String)>{
      'salesSearchButton': (Icons.search_rounded, 'بحث'),
      'salesPrintButton': (Icons.print_rounded, 'طباعة'),
      'salesPrintWithoutPricesButton': (
        Icons.money_off_rounded,
        'طباعة بدون سعر',
      ),
      'salesPdfButton': (
        Icons.picture_as_pdf_rounded,
        'تصدير PDF',
      ),
      'salesExcelButton': (
        Icons.table_view_rounded,
        'تصدير Excel',
      ),
      'salesInstallmentsButton': (
        Icons.table_chart_rounded,
        'جدول الأقساط',
      ),
      'salesStatementButton': (
        Icons.receipt_long_rounded,
        'كشف الحساب',
      ),
    };
    for (final entry in invoiceButtons.entries) {
      final finder = find.byKey(Key(entry.key));
      expect(finder, findsOneWidget);

      final button = tester.widget<AppHeaderIconButton>(finder);
      expect(button.icon, entry.value.$1);
      expect(button.tooltip, entry.value.$2);
      expect(tester.getSize(finder), const Size.square(52));
    }
    expect(
      tester
          .widget<AppHeaderIconButton>(
            find.byKey(const Key('salesInstallmentsButton')),
          )
          .onPressed,
      isNull,
    );
    _expectRightToLeftWrapOrder(tester, invoiceButtons.keys.toList());

    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '101');
    expect(
      _fieldValue(tester, 'salesCustomerNameField'),
      'شركة النخيل للتجارة',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplateNameField-',
      ),
      'ورق طباعة',
    );

    for (final key in const [
      'salesFirstButton',
      'salesPreviousButton',
      'salesNextButton',
      'salesLastButton',
      'salesSaveButton',
      'salesUpdateButton',
      'salesUndoButton',
      'salesDeleteButton',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    for (final key in const [
      'salesFirstButton',
      'salesPreviousButton',
      'salesSaveButton',
      'salesUpdateButton',
      'salesUndoButton',
    ]) {
      expect(_actionButton(tester, key).onPressed, isNull);
    }
    for (final key in const [
      'salesNextButton',
      'salesLastButton',
      'salesDeleteButton',
    ]) {
      expect(_actionButton(tester, key).onPressed, isNotNull);
    }

    final expectedTint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );
    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('salesScreen')),
    );
    expect(shell.subtitle, isNull);
    expect(shell.backgroundColor, expectedTint);
    expect(shell.onSave, isNull);

    final tintBackground = tester.widget<ColoredBox>(
      find.byKey(const Key('salesTintBackground')),
    );
    expect(tintBackground.color, expectedTint);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('salesScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_sales')), findsOneWidget);
  });

  testWidgets('navigates demo invoices and reaches a new Sales form',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '102');
    expect(_fieldValue(tester, 'salesCustomerNameField'), 'أحمد كريم');
    expect(
      tester
          .widget<AppHeaderIconButton>(
            find.byKey(const Key('salesInstallmentsButton')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '103');
    expect(_fieldValue(tester, 'salesCustomerNameField'), 'أسواق دجلة');

    await tester.tap(find.byKey(const Key('salesLastButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '104');
    expect(_fieldValue(tester, 'salesCustomerNameField'), isEmpty);
    expect(_actionButton(tester, 'salesSaveButton').onPressed, isNotNull);
    expect(_actionButton(tester, 'salesUpdateButton').onPressed, isNull);
    expect(_actionButton(tester, 'salesDeleteButton').onPressed, isNull);
    expect(_actionButton(tester, 'salesFirstButton').onPressed, isNotNull);
    expect(
      _actionButton(tester, 'salesPreviousButton').onPressed,
      isNotNull,
    );
    expect(_actionButton(tester, 'salesNextButton').onPressed, isNull);
    expect(_actionButton(tester, 'salesLastButton').onPressed, isNull);
    expect(
      tester
          .widget<AppTableActionButton>(
            find.byKey(
              const Key('appSalesInvoiceTemplateAddButton'),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('salesFirstButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '101');
    expect(
      _fieldValue(tester, 'salesCustomerNameField'),
      'شركة النخيل للتجارة',
    );
  });

  testWidgets('uses Sales defaults and keeps repository edits after reopen',
      (tester) async {
    final store = AppStore.demo();
    final defaults =
        await store.repositories.businessSettings.loadOperationalDefaults();
    await store.repositories.businessSettings.saveOperationalDefaults(
      OperationalDefaults(
        purchases: defaults.purchases,
        sales: SalesDefaults(
          warehouseId: EntityId('warehouse-004'),
          saleKind: SaleKind.installments,
          currency: AppCurrency.usd,
        ),
        cashbox: defaults.cashbox,
      ),
    );

    await _openSalesScreen(tester, store: store);
    await _openNewSalesForm(tester);

    expect(_dropdown(tester, 'salesWarehouseField').value, 'warehouse-004');
    expect(_dropdown(tester, 'salesTypeField').value, 'أقساط');
    expect(_dropdown(tester, 'salesCurrencyField').value, 'USD');
    expect(_fieldValue(tester, 'salesExchangeRateField'), '1,310');

    await tester.tap(find.byKey(const Key('salesFirstButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('salesNotesField')),
      'تعديل محفوظ بعد إعادة الفتح',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('salesUpdateButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.green,
      message: 'تم تحديث قائمة البيع',
    );
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboardCard_sales')));
    await tester.pumpAndSettle();

    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '101');
    expect(
      _fieldValue(tester, 'salesNotesField'),
      'تعديل محفوظ بعد إعادة الفتح',
    );
  });

  testWidgets('shows and filters Sales customer suggestions',
      (tester) async {
    await _openSalesScreen(tester);

    final customer =
        find.byKey(const Key('salesCustomerNameField'));
    await tester.tap(customer);
    await tester.pump();
    expect(find.text('أحمد كريم'), findsOneWidget);
    expect(find.text('أسواق دجلة'), findsOneWidget);

    await tester.enterText(customer, 'أسو');
    await tester.pump();
    expect(find.text('أحمد كريم'), findsNothing);
    expect(find.text('أسواق دجلة'), findsOneWidget);

    await tester.tap(find.byKey(const Key('salesNotesField')));
    await tester.pump();
    await tester.tap(customer);
    await tester.pump();
    expect(find.text('أحمد كريم'), findsOneWidget);
  });

  testWidgets('enables Sales actions for form and table edits',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.enterText(
      find.byKey(const Key('salesNotesField')),
      'ملاحظة معدلة',
    );
    await tester.pump();
    expect(_actionButton(tester, 'salesUpdateButton').onPressed, isNotNull);
    expect(_actionButton(tester, 'salesUndoButton').onPressed, isNotNull);
    expect(
      tester
          .widget<AppScreenShell>(
            find.byKey(const Key('salesScreen')),
          )
          .onSave,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('salesUndoButton')));
    await tester.pump();
    expect(
      _fieldValue(tester, 'salesNotesField'),
      'تضاف إلى حساب الزبون',
    );
    expect(_actionButton(tester, 'salesUpdateButton').onPressed, isNull);
    expect(_actionButton(tester, 'salesUndoButton').onPressed, isNull);

    final itemNameField = _invoiceFieldByPrefix(
      'appSalesInvoiceTemplateNameField-',
    );
    await tester.enterText(itemNameField, 'ورق طباعة معدل');
    await tester.pump();
    expect(_actionButton(tester, 'salesUpdateButton').onPressed, isNotNull);
    expect(_actionButton(tester, 'salesUndoButton').onPressed, isNotNull);
  });

  testWidgets('guards Sales edits before navigation', (tester) async {
    await _openSalesScreen(tester);

    await tester.enterText(
      find.byKey(const Key('salesCustomerNameField')),
      'زبون معدل',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '101');
    expect(_fieldValue(tester, 'salesCustomerNameField'), 'زبون معدل');

    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '102');
    expect(_fieldValue(tester, 'salesCustomerNameField'), 'أحمد كريم');
  });

  testWidgets('guards Sales edits from app, keyboard and Windows Back',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.enterText(
      find.byKey(const Key('salesNotesField')),
      'تعديل غير محفوظ',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('salesScreen')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('salesScreen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('salesScreen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('salesScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_sales')), findsOneWidget);
  });

  testWidgets('requires complete Sales rows and ignores a trailing empty row',
      (tester) async {
    await _openSalesScreen(tester);
    await _openNewSalesForm(tester);
    await tester.enterText(
      find.byKey(const Key('salesCustomerNameField')),
      'زبون اختبار',
    );

    await tester.tap(find.byKey(const Key('salesSaveButton')));
    await tester.pump();
    expect(find.text('اختر زبوناً موجوداً من القائمة'), findsOneWidget);
    await _finishToast(tester);
    await tester.enterText(
      find.byKey(const Key('salesCustomerNameField')),
      'علي حسن',
    );

    await tester.tap(find.byKey(const Key('salesSaveButton')));
    await tester.pump();
    expect(find.text('أضف مادة واحدة مكتملة على الأقل'), findsOneWidget);
    await _finishToast(tester);

    await tester.enterText(
      _invoiceFieldByPrefix('appSalesInvoiceTemplateSalePriceField-'),
      '25000',
    );
    await tester.tap(find.byKey(const Key('salesSaveButton')));
    await tester.pump();
    expect(
      find.text(
        'أكمل بيانات سطر المادة: رمز المادة واسم المادة والكمية',
      ),
      findsOneWidget,
    );
    await _finishToast(tester);
    await tester.enterText(
      _invoiceFieldByPrefix('appSalesInvoiceTemplateSalePriceField-'),
      '0',
    );

    await tester.enterText(
      _invoiceFieldByPrefix('appSalesInvoiceTemplateDiscountField-'),
      '500',
    );
    await tester.tap(find.byKey(const Key('salesSaveButton')));
    await tester.pump();
    expect(
      find.text(
        'أكمل بيانات سطر المادة: رمز المادة واسم المادة والكمية',
      ),
      findsOneWidget,
    );
    await _finishToast(tester);
    await tester.enterText(
      _invoiceFieldByPrefix('appSalesInvoiceTemplateDiscountField-'),
      '0',
    );

    await tester.enterText(
      _invoiceFieldByPrefix('appSalesInvoiceTemplateCodeField-'),
      'S-TEST',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('salesSaveButton')));
    await tester.pump();
    expect(
      find.text(
        'أكمل بيانات سطر المادة: رمز المادة واسم المادة والكمية',
      ),
      findsOneWidget,
    );
    await _finishToast(tester);

    await tester.enterText(
      _invoiceFieldByPrefix('appSalesInvoiceTemplateNameField-'),
      'مادة اختبار',
    );
    await tester.enterText(
      _invoiceFieldByPrefix('appSalesInvoiceTemplateQuantityField-'),
      '1',
    );
    await tester.tap(find.byKey(const Key('salesSaveButton')));
    await tester.pump();
    expect(find.text('اختر مادة موجودة لكل سطر'), findsOneWidget);
    await _finishToast(tester);

    await _completeCurrentSalesRow(tester);
    final addButton = tester.widget<AppTableActionButton>(
      find.byKey(const Key('appSalesInvoiceTemplateAddButton')),
    );
    expect(addButton.onPressed, isNotNull);
    addButton.onPressed!();
    await tester.pump();

    await tester.tap(find.byKey(const Key('salesSaveButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.blue,
      message: 'تم حفظ قائمة البيع',
    );
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('salesSearchButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('salesRecordSearchField')),
      '104',
    );
    await tester.pump();
    expect(find.textContaining('1 مواد'), findsOneWidget);
  });

  testWidgets('caps Sales receipt in IQD and USD when totals change',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.enterText(
      find.byKey(const Key('salesReceivedField')),
      '999999',
    );
    await tester.pump();
    expect(_fieldValue(tester, 'salesReceivedField'), '177,000');
    expect(_fieldValue(tester, 'salesRemainingIqdField'), '0');

    await tester.enterText(
      find.byKey(const Key('salesReceivedField')),
      '100000',
    );
    await tester.enterText(
      find.byKey(const Key('salesInvoiceDiscountField')),
      '100000',
    );
    await tester.pump();
    expect(_fieldValue(tester, 'salesTotalIqdField'), '77,000');
    expect(_fieldValue(tester, 'salesReceivedField'), '77,000');

    _dropdown(tester, 'salesCurrencyField').onChanged('USD');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('salesReceivedField')),
      '999999',
    );
    await tester.pump();
    expect(_fieldValue(tester, 'salesReceivedField'), '77,000.00');
    expect(_fieldValue(tester, 'salesRemainingIqdField'), '0.00');
  });

  testWidgets('normalizes a cleared noncash receipt before update',
      (tester) async {
    final store = AppStore.demo();
    await _openSalesScreen(tester, store: store);

    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '102');
    expect(_fieldValue(tester, 'salesReceivedField'), '250');

    await tester.enterText(
      find.byKey(const Key('salesReceivedField')),
      '',
    );
    await tester.pump();

    expect(_fieldValue(tester, 'salesReceivedField'), '0.00');
    expect(_actionButton(tester, 'salesUpdateButton').onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('salesUpdateButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.green,
      message: 'تم تحديث قائمة البيع',
    );

    final updated = (await store.repositories.sales.getAll()).firstWhere(
      (invoice) => invoice.documentNumber == 102,
    );
    expect(updated.received, Money.zero(AppCurrency.usd));
    await _finishToast(tester);
  });

  testWidgets('rounds Sales row money before switching USD to IQD and saving',
      (tester) async {
    final store = AppStore.demo();
    await _openSalesScreen(tester, store: store);
    await _openNewSalesForm(tester);

    _dropdown(tester, 'salesCurrencyField').onChanged('USD');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('salesCustomerNameField')),
      'علي حسن',
    );
    await _completeCurrentSalesRow(tester);
    await tester.enterText(
      _invoiceFieldByPrefix('appSalesInvoiceTemplateQuantityField-'),
      '2',
    );
    await tester.enterText(
      _invoiceFieldByPrefix('appSalesInvoiceTemplateSalePriceField-'),
      '0.50',
    );
    _dropdown(tester, 'salesTypeField').onChanged('آجل');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('salesInvoiceDiscountField')),
      '0.01',
    );
    await tester.enterText(
      find.byKey(const Key('salesReceivedField')),
      '0.01',
    );
    await tester.pump();

    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplateTotalField-',
      ),
      '1.00',
    );

    _dropdown(tester, 'salesCurrencyField').onChanged('IQD');
    await tester.pump();

    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplateSalePriceField-',
      ),
      '1',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplateDiscountField-',
      ),
      '0',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplateTotalField-',
      ),
      '2',
    );
    expect(_fieldValue(tester, 'salesInvoiceDiscountField'), '0');
    expect(_fieldValue(tester, 'salesTotalIqdField'), '2');
    expect(_fieldValue(tester, 'salesReceivedField'), '0');
    expect(_fieldValue(tester, 'salesRemainingIqdField'), '2');

    await tester.tap(find.byKey(const Key('salesSaveButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.blue,
      message: 'تم حفظ قائمة البيع',
    );

    final saved = (await store.repositories.sales.getAll()).firstWhere(
      (invoice) => invoice.documentNumber == 104,
    );
    expect(saved.currency, AppCurrency.iqd);
    expect(saved.lines.single.unitPrice.toPlainString(), '1');
    expect(saved.total.toPlainString(), '2');
    expect(saved.invoiceDiscount.toPlainString(), '0');
    expect(saved.received.toPlainString(), '0');
    expect(_fieldValue(tester, 'salesTotalIqdField'), '2');
    await _finishToast(tester);
  });

  testWidgets('caps Sales invoice discount amount and percentage',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.enterText(
      find.byKey(const Key('salesInvoiceDiscountField')),
      '999999',
    );
    await tester.pump();

    expect(_fieldValue(tester, 'salesInvoiceDiscountField'), '177,000');
    expect(_fieldValue(tester, 'salesDiscountPercentageField'), '100.00');
    expect(_fieldValue(tester, 'salesReceivedField'), '0');
    expect(_fieldValue(tester, 'salesTotalIqdField'), '0');
    expect(_fieldValue(tester, 'salesRemainingIqdField'), '0');

    await tester.enterText(
      find.byKey(const Key('salesDiscountPercentageField')),
      '125',
    );
    await tester.pump();

    expect(_fieldValue(tester, 'salesDiscountPercentageField'), '100.00');
    expect(_fieldValue(tester, 'salesInvoiceDiscountField'), '177,000');
    expect(_fieldValue(tester, 'salesTotalIqdField'), '0');
    expect(_fieldValue(tester, 'salesReceivedField'), '0');
  });

  testWidgets('shows matching Sales action toasts', (tester) async {
    await _openSalesScreen(tester);

    await tester.enterText(
      find.byKey(const Key('salesNotesField')),
      'ملاحظة محدثة',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('salesUpdateButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.green,
      message: 'تم تحديث قائمة البيع',
    );
    await _finishToast(tester);

    await tester.enterText(
      find.byKey(const Key('salesNotesField')),
      'تعديل غير محفوظ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('salesUndoButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.orange,
      message: 'تم التراجع عن التغييرات',
    );
    expect(_fieldValue(tester, 'salesNotesField'), 'ملاحظة محدثة');
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('salesLastButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesLastButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '104');

    await tester.enterText(
      find.byKey(const Key('salesCustomerNameField')),
      'علي حسن',
    );
    await _completeCurrentSalesRow(tester);
    await tester.pump();
    await tester.tap(find.byKey(const Key('salesSaveButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.blue,
      message: 'تم حفظ قائمة البيع',
    );
    expect(_actionButton(tester, 'salesDeleteButton').onPressed, isNotNull);
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('salesSearchButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('salesRecordSearchField')),
      '104',
    );
    await tester.pump();
    expect(find.textContaining('1 مواد'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('salesRecordSearchResult-0')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await _finishToast(tester);

    await tester.tap(find.byKey(const Key('salesDeleteButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pump();
    _expectToast(
      tester,
      color: AppColors.red,
      message: 'تم حذف قائمة البيع',
    );
    expect(_actionButton(tester, 'salesDeleteButton').onPressed, isNull);
  });

  testWidgets('updates installments availability and total currency labels',
      (tester) async {
    await _openSalesScreen(tester);

    AppHeaderIconButton installmentsButton() {
      return tester.widget<AppHeaderIconButton>(
        find.byKey(const Key('salesInstallmentsButton')),
      );
    }

    expect(installmentsButton().onPressed, isNull);
    expect(_fieldLabel(tester, 'salesTotalIqdField'), 'المجموع دينار');
    expect(
      _fieldLabel(tester, 'salesRemainingIqdField'),
      'المتبقي دينار',
    );
    expect(
      _fieldLabel(tester, 'salesCurrentBalanceIqdField'),
      'الرصيد الحالي دينار',
    );

    final saleTypeDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('salesTypeField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    saleTypeDropdown.onChanged('أقساط');
    await tester.pump();
    expect(installmentsButton().onPressed, isNull);

    final currencyDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('salesCurrencyField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    currencyDropdown.onChanged('USD');
    await tester.pump();

    expect(_fieldLabel(tester, 'salesTotalIqdField'), 'المجموع دولار');
    expect(
      _fieldLabel(tester, 'salesRemainingIqdField'),
      'المتبقي دولار',
    );
    expect(
      _fieldLabel(tester, 'salesCurrentBalanceIqdField'),
      'الرصيد الحالي دولار',
    );

    tester
        .widget<AppDropdownField<String>>(
          find.ancestor(
            of: find.byKey(const Key('salesTypeField')),
            matching: find.byType(AppDropdownField<String>),
          ),
        )
        .onChanged('نقدي');
    await tester.pump();
    expect(installmentsButton().onPressed, isNull);

    await tester.tap(find.byKey(const Key('salesUndoButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '102');
    expect(installmentsButton().onPressed, isNotNull);
  });

  testWidgets('calculates Sales rows discounts totals and cash receipt',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.tap(find.byKey(const Key('salesLastButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesLastButton')));
    await tester.pumpAndSettle();

    final currencyDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('salesCurrencyField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    currencyDropdown.onChanged('USD');
    await tester.pump();

    final saleTypeDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('salesTypeField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    saleTypeDropdown.onChanged('آجل');
    await tester.pump();

    await tester.enterText(
      _invoiceFieldByPrefix(
        'appSalesInvoiceTemplateQuantityField-',
      ),
      '2',
    );
    await tester.enterText(
      _invoiceFieldByPrefix(
        'appSalesInvoiceTemplateSalePriceField-',
      ),
      '100',
    );
    await tester.enterText(
      _invoiceFieldByPrefix(
        'appSalesInvoiceTemplateDiscountField-',
      ),
      '10',
    );
    await tester.pump();

    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplatePriceAfterDiscountField-',
      ),
      '90.00',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplateTotalField-',
      ),
      '180.00',
    );
    final summary = find.byKey(
      const Key('appSalesInvoiceTableSummary'),
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
      find.descendant(of: summary, matching: find.text('180.00')),
      findsOneWidget,
    );

    await tester.enterText(
      _invoiceFieldByPrefix(
        'appSalesInvoiceTemplateDiscountField-',
      ),
      '150',
    );
    await tester.pump();
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplateDiscountField-',
      ),
      '100.00',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplatePriceAfterDiscountField-',
      ),
      '0.00',
    );
    expect(
      _invoiceFieldValueByPrefix(
        tester,
        'appSalesInvoiceTemplateTotalField-',
      ),
      '0.00',
    );
    expect(
      find.descendant(of: summary, matching: find.text('200.00')),
      findsOneWidget,
    );
    await tester.enterText(
      _invoiceFieldByPrefix(
        'appSalesInvoiceTemplateDiscountField-',
      ),
      '10',
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('salesInvoiceDiscountField')),
      '27',
    );
    await tester.pump();
    expect(
      _fieldValue(tester, 'salesDiscountPercentageField'),
      '15.00',
    );
    expect(_fieldValue(tester, 'salesTotalIqdField'), '153.00');
    expect(_fieldValue(tester, 'salesRemainingIqdField'), '153.00');
    expect(_fieldValue(tester, 'salesCurrentBalanceIqdField'), '153.00');

    await tester.enterText(
      find.byKey(const Key('salesDiscountPercentageField')),
      '8.50',
    );
    await tester.pump();
    expect(_fieldValue(tester, 'salesInvoiceDiscountField'), '15.30');
    expect(_fieldValue(tester, 'salesTotalIqdField'), '164.70');

    tester
        .widget<AppDropdownField<String>>(
          find.ancestor(
            of: find.byKey(const Key('salesTypeField')),
            matching: find.byType(AppDropdownField<String>),
          ),
        )
        .onChanged('نقدي');
    await tester.pump();

    final received = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('salesReceivedField')),
        matching: find.byType(TextField),
      ),
    );
    expect(received.enabled, isFalse);
    expect(received.readOnly, isTrue);
    expect(_fieldValue(tester, 'salesReceivedField'), '164.70');
    expect(_fieldValue(tester, 'salesRemainingIqdField'), '0.00');
    expect(_fieldValue(tester, 'salesCurrentBalanceIqdField'), '0.00');
  });

  testWidgets('uses the Sales color in the shared date picker',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.tap(find.byKey(const Key('salesDateField')));
    await tester.pump();

    expect(find.byKey(const Key('appDatePickerDialog')), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appDatePickerConfirm')),
          )
          .backgroundColor,
      AppModuleColors.sales,
    );

    await tester.tap(find.byKey(const Key('appDatePickerCancel')));
    await tester.pump();
  });

  testWidgets('opens the sales-colored invoice search dialog',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.tap(find.byKey(const Key('salesSearchButton')));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const Key('salesRecordSearchDialog'));
    expect(dialog, findsOneWidget);
    final moduleDialog = tester.widget<AppModuleDialog>(dialog);
    expect(moduleDialog.title, 'بحث قوائم البيع');
    expect(moduleDialog.subtitle, 'ابحث عن قائمة بيع محفوظة ثم اخترها');
    expect(moduleDialog.accentColor, AppModuleColors.sales);

    final searchDecoration = tester
        .widget<InputDecorator>(
          find.descendant(
            of: find.byKey(const Key('salesRecordSearchField')),
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration;
    expect(searchDecoration.labelText, 'بحث في قوائم البيع');
    expect(
      searchDecoration.hintText,
      'رقم القائمة أو اسم الزبون أو اسم المادة',
    );
    expect(
      find.descendant(of: dialog, matching: find.text('أسواق دجلة')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('salesRecordSearchField')),
      'دجلة',
    );
    await tester.pump();

    expect(
      find.byKey(const Key('salesRecordSearchResult-0')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('أحمد كريم')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const Key('salesRecordSearchResult-0')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(dialog, findsNothing);
  });

  testWidgets('loads a complete demo invoice from Sales search',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.tap(find.byKey(const Key('salesSearchButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('salesRecordSearchField')),
      '102',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('salesRecordSearchResult-0')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '102');
    expect(_fieldValue(tester, 'salesCustomerNameField'), 'أحمد كريم');
    expect(_fieldValue(tester, 'salesReceivedField'), '250');
    expect(_fieldLabel(tester, 'salesTotalIqdField'), 'المجموع دولار');
    expect(
      tester
          .widget<AppHeaderIconButton>(
            find.byKey(const Key('salesInstallmentsButton')),
          )
          .onPressed,
      isNotNull,
    );

    final tableValues = tester
        .widgetList<EditableText>(
          find.descendant(
            of: find.byKey(const Key('salesItemsTable')),
            matching: find.byType(EditableText),
          ),
        )
        .map((field) => field.controller.text);
    expect(tableValues, contains('طابعة حرارية'));
    expect(tableValues, contains('ماسح باركود'));
  });

  testWidgets('opens sales statement options and report', (tester) async {
    await _openSalesScreen(tester);

    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    expect(_fieldValue(tester, 'salesCustomerNameField'), 'أسواق دجلة');
    await tester.tap(find.byKey(const Key('salesStatementButton')));
    await tester.pumpAndSettle();

    final optionsDialog =
        find.byKey(const Key('appStatementOptionsDialog'));
    expect(optionsDialog, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(optionsDialog).accentColor,
      AppModuleColors.sales,
    );

    final partyField = find.byKey(const Key('appStatementParty'));
    final partyInput = tester.widget<EditableText>(
      find.descendant(of: partyField, matching: find.byType(EditableText)),
    );
    expect(partyInput.controller.text, 'أسواق دجلة');
    expect(
      tester
          .widget<InputDecorator>(
            find.descendant(
              of: partyField,
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration
          .labelText,
      'اسم الزبون',
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appStatementConfirm')),
          )
          .backgroundColor,
      AppModuleColors.sales,
    );

    await tester.tap(find.byKey(const Key('appStatementConfirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final report = find.byKey(const Key('appStatementReportDialog'));
    expect(report, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(report).accentColor,
      AppModuleColors.sales,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appStatementPrint')),
          )
          .backgroundColor,
      AppColors.blue,
    );
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('appStatementReportTable')),
          )
          .accentColor,
      AppModuleColors.sales,
    );
    expect(
      find.descendant(of: report, matching: find.text('أسواق دجلة')),
      findsOneWidget,
    );
  });
}

AppButton _actionButton(WidgetTester tester, String key) {
  return tester.widget<AppButton>(find.byKey(Key(key)));
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

Future<void> _openNewSalesForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('salesLastButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('salesLastButton')));
  await tester.pumpAndSettle();
}

Future<void> _completeCurrentSalesRow(WidgetTester tester) async {
  await tester.enterText(
    _invoiceFieldByPrefix('appSalesInvoiceTemplateCodeField-'),
    'P-1001',
  );
  await tester.enterText(
    _invoiceFieldByPrefix('appSalesInvoiceTemplateNameField-'),
    'طابعة ليزر',
  );
  await tester.enterText(
    _invoiceFieldByPrefix('appSalesInvoiceTemplateQuantityField-'),
    '1',
  );
  await tester.pump();
}

void _expectToast(
  WidgetTester tester, {
  required Color color,
  required String message,
}) {
  final toastFinder = find.descendant(
    of: find.byKey(const Key('salesScreen')),
    matching: find.byKey(const Key('appToast')),
  );
  expect(toastFinder, findsOneWidget);
  final toast = tester.widget<SnackBar>(
    toastFinder,
  );
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
  return tester
      .widget<TextField>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      )
      .decoration
      ?.labelText;
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

void _expectRightToLeftWrapOrder(
  WidgetTester tester,
  List<String> keys,
) {
  for (var index = 1; index < keys.length; index++) {
    final previous = tester.getTopLeft(find.byKey(Key(keys[index - 1])));
    final current = tester.getTopLeft(find.byKey(Key(keys[index])));
    final isSameRun = (previous.dy - current.dy).abs() <= 0.1;

    if (isSameRun) {
      expect(previous.dx, greaterThan(current.dx));
    } else {
      expect(current.dy, greaterThan(previous.dy));
    }
  }
}

Future<void> _openSalesScreen(
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
  await tester.tap(find.byKey(const Key('dashboardCard_sales')));
  await tester.pumpAndSettle();
}
