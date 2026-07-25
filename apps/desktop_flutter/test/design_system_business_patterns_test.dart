import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('documents global date time and number formats', (tester) async {
    await pumpDesignSystemGallery(tester);

    final dateFormat = find.byKey(const Key('designDateFormat'));
    await reveal(tester, dateFormat);

    expect(find.text('2026/12/31'), findsWidgets);
    expect(find.text('01:01 ص'), findsOneWidget);
    final timeDirection = tester.widget<Directionality>(
      find.descendant(
        of: find.byKey(const Key('designTimeFormat')),
        matching: find.byType(Directionality),
      ),
    );
    expect(timeDirection.textDirection, TextDirection.rtl);
    expect(
      find.descendant(
        of: find.byKey(const Key('designQuantityFormat')),
        matching: find.text('1,000,000'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('designIqdFormat')),
        matching: find.text('1,000,000'),
      ),
      findsOneWidget,
    );
    expect(find.text('100,000.00'), findsOneWidget);

    final timeField = tester.widget<TextFormField>(
      find.byKey(const Key('designGlobalReadOnlyTime')),
    );
    expect(timeField.enabled, isFalse);

    final rangeField = find.byKey(const Key('designGlobalDateRange'));
    await reveal(tester, rangeField);
    final rangeText = tester.widget<EditableText>(
      find.descendant(
        of: rangeField,
        matching: find.byType(EditableText),
      ),
    );
    expect(
      rangeText.controller.text,
      'من 2025/12/31 إلى 2026/12/31',
    );
  });

  testWidgets('opens the shared Arabic date picker', (tester) async {
    await pumpDesignSystemGallery(tester);

    final dateField = find.byKey(const Key('designGlobalDatePicker'));
    await reveal(tester, dateField);
    expect(
      find.descendant(
        of: dateField,
        matching: find.byTooltip('اختيار التاريخ'),
      ),
      findsOneWidget,
    );

    await tester.tap(dateField);
    await tester.pump();

    expect(find.byKey(const Key('appDatePickerDialog')), findsOneWidget);
    expect(find.text('اختر التاريخ'), findsOneWidget);
    expect(find.text('كانون الأول 2026'), findsOneWidget);
    expect(find.byTooltip('السابق'), findsOneWidget);
    expect(find.byTooltip('التالي'), findsOneWidget);

    final actions = tester.widget<Row>(
      find.byKey(const Key('appDatePickerActions')),
    );
    expect(actions.mainAxisAlignment, MainAxisAlignment.center);

    final cancelButton = tester.widget<AppButton>(
      find.byKey(const Key('appDatePickerCancel')),
    );
    final confirmButton = tester.widget<AppButton>(
      find.byKey(const Key('appDatePickerConfirm')),
    );
    expect(cancelButton.width, 144);
    expect(confirmButton.width, 144);

    await tester.tap(find.byKey(const Key('appDatePickerCancel')));
    await tester.pump();
  });

  testWidgets('selects a range with the shared Arabic date picker',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final rangeField = find.byKey(const Key('designGlobalDateRange'));
    await reveal(tester, rangeField);
    expect(
      find.descendant(
        of: rangeField,
        matching: find.byTooltip('اختيار نطاق التاريخ'),
      ),
      findsOneWidget,
    );

    await tester.tap(rangeField);
    await tester.pump();

    final dialog = find.byKey(const Key('appDateRangePickerDialog'));
    expect(dialog, findsOneWidget);
    expect(find.text('اختر نطاق التاريخ'), findsOneWidget);
    expect(find.text('كانون الأول 2025'), findsOneWidget);

    await tester.tap(
      find.descendant(of: dialog, matching: find.text('3')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appDatePickerConfirm')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.descendant(of: dialog, matching: find.text('7')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appDatePickerConfirm')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('appDatePickerConfirm')));
    await tester.pump();

    final selectedRange = tester.widget<EditableText>(
      find.descendant(
        of: rangeField,
        matching: find.byType(EditableText),
      ),
    );
    expect(
      selectedRange.controller.text,
      'من 2025/12/03 إلى 2025/12/07',
    );
  });

  testWidgets('opens options then the shared statement report',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final button = find.byKey(const Key('designStatementDialogButton'));
    await reveal(tester, button);
    await tester.tap(button);
    await tester.pump();

    final optionsDialog =
        find.byKey(const Key('appStatementOptionsDialog'));
    expect(optionsDialog, findsOneWidget);
    expect(find.byKey(const Key('appStatementParty')), findsOneWidget);
    expect(find.byKey(const Key('appStatementFromDate')), findsOneWidget);
    expect(find.byKey(const Key('appStatementToDate')), findsOneWidget);
    expect(find.byKey(const Key('appStatementCurrency')), findsOneWidget);
    expect(
      find.descendant(
        of: optionsDialog,
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<Row>(find.byKey(const Key('appStatementActions')))
          .mainAxisAlignment,
      MainAxisAlignment.center,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appStatementConfirm')),
          )
          .backgroundColor,
      AppModuleColors.parties,
    );

    await tester.tap(find.byKey(const Key('appStatementConfirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final report = find.byKey(const Key('appStatementReportDialog'));
    expect(report, findsOneWidget);
    expect(
      find.descendant(of: report, matching: find.text('أسواق دجلة')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: report, matching: find.text('دائن (له)')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: report, matching: find.text('مدين (عليه)')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: report, matching: find.text('PDF')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: report, matching: find.text('طباعة')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: report, matching: find.text('إكسل')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Row>(
            find.byKey(const Key('appStatementReportActions')),
          )
          .mainAxisAlignment,
      MainAxisAlignment.center,
    );

    expect(find.byKey(const Key('appStatementReportClose')), findsNothing);
    expect(find.byKey(const Key('appStatementPeriodText')), findsOneWidget);
    expect(find.byKey(const Key('appStatementCurrencyText')), findsOneWidget);

    final partyName = tester.widget<Text>(
      find.descendant(of: report, matching: find.text('أسواق دجلة')),
    );
    expect(partyName.style?.fontSize, 22);
    expect(partyName.style?.fontWeight, FontWeight.w800);

    final close = find.byKey(const Key('appModuleDialogClose'));
    expect(close, findsOneWidget);
    final reportIcon = find.descendant(
      of: report,
      matching: find.byIcon(Icons.receipt_long_rounded),
    );
    expect(
      tester.getCenter(reportIcon).dx,
      lessThan(tester.getCenter(close).dx),
    );

    await tester.tap(close);
    await tester.pump();
  });

  testWidgets('uses themed centered management and transfer dialogs',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final transferButton =
        find.byKey(const Key('designTransferDialogButton'));
    await reveal(tester, transferButton);
    await tester.tap(transferButton);
    await tester.pump();

    final transferDialog = find.byKey(const Key('designTransferDialog'));
    expect(transferDialog, findsOneWidget);
    expect(find.text('من مخزن'), findsOneWidget);
    expect(find.text('إلى مخزن'), findsOneWidget);
    expect(find.text('تاريخ النقل'), findsNothing);
    expect(
      find.byKey(const Key('designTransferSourceStock')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designTransferDestinationStock')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('designTransferProduct')), findsOneWidget);
    expect(find.byKey(const Key('designTransferQuantity')), findsOneWidget);
    expect(
      find.descendant(
        of: transferDialog,
        matching: find.byIcon(Icons.arrow_forward_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: transferDialog,
        matching: find.byIcon(Icons.arrow_back_rounded),
      ),
      findsNothing,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const Key('designTransferProduct')))
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('designTransferSourceStock')),
            )
            .dy,
      ),
    );
    expect(
      tester
          .widget<Row>(
            find.byKey(const Key('designTransferDialogActions')),
          )
          .mainAxisAlignment,
      MainAxisAlignment.center,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('designTransferDialogConfirm')),
          )
          .backgroundColor,
      AppModuleColors.warehouses,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('designTransferSourceStock')),
        matching: find.text('1,200'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('designTransferDestinationStock')),
        matching: find.text('80'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('designTransferDialogConfirm')),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('designTransferSourceStock')),
        matching: find.text('1,190'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('designTransferDestinationStock')),
        matching: find.text('90'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('designTransferDialogCancel')),
    );
    await tester.pump();

    final groupsButton =
        find.byKey(const Key('designGroupsTypesDialogButton'));
    await reveal(tester, groupsButton);
    await tester.tap(groupsButton);
    await tester.pump();

    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('designGroupsTypesDialogConfirm')),
          )
          .backgroundColor,
      AppModuleColors.warehouses,
    );
    expect(
      tester
          .widget<Row>(
            find.byKey(const Key('designGroupsTypesDialogActions')),
          )
          .mainAxisAlignment,
      MainAxisAlignment.center,
    );
    await tester.tap(
      find.byKey(const Key('designGroupsTypesDialogCancel')),
    );
    await tester.pump();

    final cashboxButton =
        find.byKey(const Key('designCashboxTabsDialogButton'));
    await reveal(tester, cashboxButton);
    await tester.tap(cashboxButton);
    await tester.pump();

    final cashboxDialog = find.byKey(const Key('designCashboxTabsDialog'));
    expect(cashboxDialog, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(cashboxDialog).accentColor,
      AppModuleColors.cashbox,
    );
    expect(find.text('الحسابات الرئيسية'), findsWidgets);
    expect(find.text('الحسابات الفرعية'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('designCashboxTabsDialogConfirm')),
          )
          .backgroundColor,
      AppModuleColors.cashbox,
    );
    expect(
      tester
          .widget<Row>(
            find.byKey(const Key('designCashboxTabsDialogActions')),
          )
          .mainAxisAlignment,
      MainAxisAlignment.center,
    );

    await tester.tap(
      find.byKey(const Key('designCashboxTabsDialogCancel')),
    );
    await tester.pump();
  });

  testWidgets('edits invoice cells and uses last-row actions',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final purchase = find.byKey(const Key('designPurchaseItemsTable'));
    await reveal(tester, purchase);
    final purchaseGrid = tester.widget<AppInvoiceItemsTable>(purchase);
    expect(purchaseGrid.type, AppInvoiceTableType.purchase);
    expect(
      AppInvoiceItemsTable.purchaseColumns
          .map((column) => column.width)
          .toList(),
      [54, 126, 190, 138, 104, 104, 126, 104, 146, 116, 104, 132, 116, 82],
    );
    expect(AppInvoiceItemsTable.purchaseColumns.last.label, isEmpty);
    expect(AppInvoiceItemsTable.headerHeight, 46);
    expect(AppInvoiceItemsTable.rowHeight, 54);
    expect(AppInvoiceItemsTable.summaryHeight, 46);
    expect(AppInvoiceItemsTable.outerRadius, 18);
    expect(purchaseGrid.height, 308);
    expect(purchaseGrid.summaryCells, isNotNull);

    final purchaseHeader = tester.widget<Container>(
      find.descendant(
        of: purchase,
        matching: find.byKey(const Key('appInvoiceTableHeader')),
      ),
    );
    expect(
      (purchaseHeader.decoration! as BoxDecoration).color,
      Color.lerp(
        AppModulePalettes.purchases.light,
        Colors.white,
        0.82,
      ),
    );
    expect(
      find.descendant(
        of: purchase,
        matching: find.byKey(const Key('appInvoiceTableSummary')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: purchase, matching: find.text('المجموع')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: purchase, matching: find.text('الحاوية')),
      findsOneWidget,
    );
    expect(tester.widget<AppInvoiceItemsTable>(purchase).rows, hasLength(2));
    expect(find.byKey(const Key('designPurchaseAddRow')), findsNothing);
    expect(find.byKey(const Key('designPurchaseAdd-p2')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseDelete-p1')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseDelete-p2')), findsNothing);
    expect(
      find.byKey(const Key('designPurchaseQuantity-p1')),
      findsOneWidget,
    );

    final quantityField = tester.widget<TextField>(
      find.byKey(const Key('designPurchaseQuantity-p1')),
    );
    expect(quantityField.style?.fontSize, 18);
    expect(quantityField.style?.fontWeight, FontWeight.w700);
    expect(quantityField.textInputAction, TextInputAction.next);
    expect(quantityField.onEditingComplete, isNotNull);
    final iqdPurchaseFormatter = tester
        .widget<TextField>(
          find.byKey(const Key('designPurchasePrice-p1')),
        )
        .inputFormatters!
        .whereType<AppMoneyInputFormatter>()
        .single;
    expect(
      iqdPurchaseFormatter.decimalPlaces,
      0,
    );
    quantityField.controller!.text = '10';
    quantityField.onChanged?.call('10');
    await tester.pump();
    final purchaseRowAfterQuantity =
        tester.widget<AppInvoiceItemsTable>(purchase).rows.first;
    expect(
      (purchaseRowAfterQuantity.cells[9] as AppInvoiceValueText).value,
      '25,000',
    );
    expect(
      (purchaseRowAfterQuantity.cells[11] as AppInvoiceValueText).value,
      '25,000',
    );

    final discountField = tester.widget<TextField>(
      find.byKey(const Key('designPurchaseDiscount-p1')),
    );
    discountField.controller!.text = '500';
    discountField.onChanged?.call('500');
    await tester.pump();

    final purchaseFirstRow =
        tester.widget<AppInvoiceItemsTable>(purchase).rows.first;
    expect(
      (purchaseFirstRow.cells[8] as AppInvoiceValueText).value,
      '2,450',
    );
    expect(
      (purchaseFirstRow.cells[9] as AppInvoiceValueText).value,
      '24,500',
    );
    expect(
      (purchaseFirstRow.cells[10] as AppInvoiceValueText).value,
      '2,450',
    );
    expect(
      (purchaseFirstRow.cells[11] as AppInvoiceValueText).value,
      '24,500',
    );
    expect(
      find.byKey(const Key('designPurchaseCost-p1')),
      findsOneWidget,
    );
    expect(
      tester.widget(find.byKey(const Key('designPurchaseCost-p1'))),
      isA<AppInvoiceValueText>(),
    );

    tester
        .widget<AppInvoiceCellDropdown>(
          find.byKey(const Key('designPurchaseCurrency')),
        )
        .onChanged('دولار');
    await tester.pump();
    final purchaseFirstRowInUsd =
        tester.widget<AppInvoiceItemsTable>(purchase).rows.first;
    expect(
      (purchaseFirstRowInUsd.cells[9] as AppInvoiceValueText).value,
      '24,500.00',
    );
    final usdPurchaseFormatter = tester
        .widget<TextField>(
          find.byKey(const Key('designPurchasePrice-p1')),
        )
        .inputFormatters!
        .whereType<AppMoneyInputFormatter>()
        .single;
    expect(
      usdPurchaseFormatter.decimalPlaces,
      2,
    );

    tester
        .widget<AppTableActionButton>(
          find.byKey(const Key('designPurchaseAdd-p2')),
        )
        .onPressed
        ?.call();
    await tester.pump();

    expect(tester.widget<AppInvoiceItemsTable>(purchase).rows, hasLength(3));
    expect(find.byKey(const Key('designPurchaseDelete-p2')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseAdd-p3')), findsOneWidget);

    tester
        .widget<AppTableActionButton>(
          find.byKey(const Key('designPurchaseDelete-p2')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    expect(tester.widget<AppInvoiceItemsTable>(purchase).rows, hasLength(2));

    final sales = find.byKey(const Key('designSalesItemsTable'));
    await reveal(tester, sales);
    final salesGrid = tester.widget<AppInvoiceItemsTable>(sales);
    expect(salesGrid.type, AppInvoiceTableType.sale);
    expect(salesGrid.height, 308);
    expect(
      AppInvoiceItemsTable.saleColumns
          .map((column) => column.width)
          .toList(),
      [54, 126, 190, 138, 104, 126, 104, 146, 116, 82],
    );
    expect(
      AppInvoiceItemsTable.saleColumns
          .map((column) => column.grow)
          .toList(),
      [0, 0.75, 3, 1.35, 0.70, 0.90, 0.70, 1.45, 1.55, 0],
    );
    expect(salesGrid.summaryCells, isNotNull);
    final salesHeader = tester.widget<Container>(
      find.descendant(
        of: sales,
        matching: find.byKey(const Key('appInvoiceTableHeader')),
      ),
    );
    expect(
      (salesHeader.decoration! as BoxDecoration).color,
      Color.lerp(
        AppModulePalettes.sales.light,
        Colors.white,
        0.82,
      ),
    );
    expect(
      find.descendant(of: sales, matching: find.text('الحاوية')),
      findsNothing,
    );
    expect(
      find.descendant(of: sales, matching: find.text('سعر البيع')),
      findsOneWidget,
    );
    expect(tester.widget<AppInvoiceItemsTable>(sales).rows, hasLength(2));
    expect(find.byKey(const Key('designSaleAddRow')), findsNothing);
    expect(find.byKey(const Key('designSaleAdd-s2')), findsOneWidget);
    expect(find.byKey(const Key('designSaleDelete-s1')), findsOneWidget);
    expect(find.byKey(const Key('designSalePrice-s1')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('designSaleDiscount-s1')),
          )
          .textInputAction,
      TextInputAction.done,
    );

    tester
        .widget<AppInvoiceCellDropdown>(
          find.byKey(const Key('designSaleCurrency')),
        )
        .onChanged('دولار');
    await tester.pump();
    final firstSaleRow = tester.widget<AppInvoiceItemsTable>(sales).rows.first;
    expect(
      (firstSaleRow.cells[7] as AppInvoiceValueText).value,
      '3,000.00',
    );
    expect(
      (firstSaleRow.cells[8] as AppInvoiceValueText).value,
      '15,000.00',
    );

    tester
        .widget<AppTableActionButton>(
          find.byKey(const Key('designSaleAdd-s2')),
        )
        .onPressed
        ?.call();
    await tester.pump();

    expect(tester.widget<AppInvoiceItemsTable>(sales).rows, hasLength(3));
    expect(find.byKey(const Key('designSaleDelete-s2')), findsOneWidget);
    expect(find.byKey(const Key('designSaleAdd-s3')), findsOneWidget);

    tester
        .widget<AppTableActionButton>(
          find.byKey(const Key('designSaleDelete-s2')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    expect(tester.widget<AppInvoiceItemsTable>(sales).rows, hasLength(2));

    final purchaseAdd = tester.widget<AppTableActionButton>(
      find.byKey(const Key('designPurchaseAdd-p3')),
    );
    final salesDelete = tester.widget<AppTableActionButton>(
      find.byKey(const Key('designSaleDelete-s1')),
    );
    expect(purchaseAdd.size, 32);
    expect(purchaseAdd.iconSize, 19);
    expect(purchaseAdd.borderRadius, 9);
    expect(purchaseAdd.backgroundColor, const Color(0xFF16A34A));
    expect(salesDelete.icon, Icons.close_rounded);
    expect(salesDelete.backgroundColor, const Color(0xFFDC2626));
  });
}
