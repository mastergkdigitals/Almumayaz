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
    final purchaseTable =
        find.byKey(const Key('designPurchaseItemsDataTable'));

    expect(
      tester.widget<AppDataTable>(purchaseTable).accentColor,
      AppModuleColors.purchases,
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
    quantityField.controller.text = '10';
    quantityField.onChanged?.call('10');
    await tester.pump();
    expect(
      find.descendant(of: purchase, matching: find.text('25,000')),
      findsOneWidget,
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
    final salesTable = find.byKey(const Key('designSalesItemsDataTable'));

    expect(
      tester.widget<AppDataTable>(salesTable).accentColor,
      AppModuleColors.sales,
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
  });
}
