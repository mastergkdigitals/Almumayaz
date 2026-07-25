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

  testWidgets('shows the selected soft-cell purchase table and row actions',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final purchase = find.byKey(const Key('designPurchaseItemsTable'));
    await reveal(tester, purchase);

    expect(purchase, findsOneWidget);
    expect(find.byKey(const Key('designSalesItemsTable')), findsNothing);
    expect(find.byKey(const Key('designPurchaseTableHeader')), findsOneWidget);

    for (final keyName in const [
      'index',
      'code',
      'name',
      'quantity',
      'price',
    ]) {
      expect(
        find.byKey(Key('designPurchaseHeader-$keyName')),
        findsOneWidget,
      );
    }

    expect(find.byKey(const Key('designPurchaseRow-p1')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseRow-p2')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseAdd')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseDelete-p1')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseDelete-p2')), findsOneWidget);

    final codeField = tester.widget<TextField>(
      find.byKey(const Key('designPurchaseCode-p1')),
    );
    final nameField = tester.widget<TextField>(
      find.byKey(const Key('designPurchaseName-p1')),
    );
    final quantityField = tester.widget<TextField>(
      find.byKey(const Key('designPurchaseQuantity-p1')),
    );
    final priceField = tester.widget<TextField>(
      find.byKey(const Key('designPurchasePrice-p1')),
    );

    for (final field in [
      codeField,
      nameField,
      quantityField,
      priceField,
    ]) {
      expect(field.expands, isTrue);
      expect(field.maxLines, isNull);
      expect(field.textAlignVertical, TextAlignVertical.center);
      expect(field.cursorColor, Colors.black);
    }

    expect(codeField.textAlign, TextAlign.right);
    expect(codeField.textDirection, TextDirection.rtl);
    expect(codeField.decoration?.border, InputBorder.none);
    expect(codeField.decoration?.focusedBorder, InputBorder.none);
    expect(codeField.style?.fontSize, 18);
    expect(nameField.textAlign, TextAlign.right);
    expect(nameField.textDirection, TextDirection.rtl);
    expect(nameField.style?.fontSize, 18);
    expect(quantityField.textAlign, TextAlign.center);
    expect(quantityField.textDirection, TextDirection.ltr);
    expect(quantityField.style?.fontSize, 18);
    expect(
      quantityField.inputFormatters!.single,
      isA<AppIntegerInputFormatter>(),
    );
    expect(priceField.textAlign, TextAlign.center);
    expect(priceField.textDirection, TextDirection.ltr);
    expect(priceField.style?.fontSize, 18);

    final codeHeader = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('designPurchaseHeader-code')),
        matching: find.text('رمز المادة'),
      ),
    );
    expect(codeHeader.style?.fontSize, 18);

    expect(
      tester
          .getSize(find.byKey(const Key('designPurchaseIndexCell-p1')))
          .height,
      44,
    );
    for (final keyName in const [
      'Code',
      'Name',
      'Quantity',
      'Price',
    ]) {
      expect(
        tester
            .getSize(
              find.byKey(Key('designPurchase${keyName}Cell-p1')),
            )
            .height,
        56,
      );
    }

    await tester.enterText(
      find.byKey(const Key('designPurchaseCode-p1')),
      'NEW-001',
    );
    await tester.pump();
    expect(codeField.controller?.text, 'NEW-001');

    final addButton = find.byKey(const Key('designPurchaseAdd'));
    await tester.ensureVisible(addButton);
    await tester.pump();
    await tester.tap(
      find.descendant(of: addButton, matching: find.byType(InkWell)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('designPurchaseRow-p3')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseDelete-p2')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseDelete-p3')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseAdd')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('designPurchaseQuantity-p3')),
          )
          .controller!
          .text,
      '0',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('designPurchasePrice-p3')),
          )
          .controller!
          .text,
      '0',
    );

    final deleteButton =
        find.byKey(const Key('designPurchaseDelete-p2'));
    await tester.ensureVisible(deleteButton);
    await tester.pump();
    await tester.tap(
      find.descendant(of: deleteButton, matching: find.byType(InkWell)),
    );
    await tester.pump();

    expect(find.byKey(const Key('designPurchaseRow-p2')), findsNothing);
    expect(find.byKey(const Key('designPurchaseAdd')), findsOneWidget);
  });

  testWidgets('moves through the selected purchase fields with Enter',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final purchase = find.byKey(const Key('designPurchaseItemsTable'));
    await reveal(tester, purchase);

    final code = find.byKey(const Key('designPurchaseCode-p1'));
    final name = find.byKey(const Key('designPurchaseName-p1'));
    final quantity = find.byKey(const Key('designPurchaseQuantity-p1'));
    final price = find.byKey(const Key('designPurchasePrice-p1'));
    final nextCode = find.byKey(const Key('designPurchaseCode-p2'));

    await tester.tap(code);
    await tester.pump();
    expect(tester.widget<TextField>(code).focusNode!.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(name).focusNode!.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(quantity).focusNode!.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(price).focusNode!.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(nextCode).focusNode!.hasFocus, isTrue);

    expect(
      tester.widget<TextField>(nextCode).decoration!.focusedBorder,
      InputBorder.none,
    );
    final focusedCellDecoration = tester
        .widget<DecoratedBox>(
          find
              .descendant(
                of: find.byKey(
                  const Key('designPurchaseCodeCell-p2'),
                ),
                matching: find.byType(DecoratedBox),
              )
              .first,
        )
        .decoration as BoxDecoration;
    expect(
      (focusedCellDecoration.border! as Border).top.color,
      const Color(0xFF10966A),
    );
  });
}
