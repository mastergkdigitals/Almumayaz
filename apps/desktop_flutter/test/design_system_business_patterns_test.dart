import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('shows the complete purchase table and shared delete action',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final purchase = find.byKey(const Key('designPurchaseItemsTable'));
    await reveal(tester, purchase);

    expect(purchase, findsOneWidget);
    expect(find.byKey(const Key('designSalesItemsTable')), findsNothing);
    expect(find.byKey(const Key('designPurchaseTableHeader')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseAdd')), findsNothing);
    expect(
      find.descendant(
        of: purchase,
        matching: find.text('إضافة مادة'),
      ),
      findsNothing,
    );

    const headers = {
      'index': 'ت',
      'code': 'رمز المادة',
      'name': 'اسم المادة',
      'warehouse': 'المخزن',
      'quantity': 'الكمية',
      'container': 'الحاوية',
      'purchasePrice': 'سعر الشراء',
      'discount': 'الخصم',
      'priceAfterDiscount': 'السعر بعد الخصم',
      'total': 'الإجمالي',
      'cost': 'الكلفة',
      'totalCost': 'إجمالي الكلفة',
      'salePrice': 'سعر البيع',
    };

    for (final header in headers.entries) {
      final headerFinder = find.byKey(
        Key('designPurchaseHeader-${header.key}'),
      );
      expect(headerFinder, findsOneWidget);
      expect(
        find.descendant(
          of: headerFinder,
          matching: find.text(header.value),
        ),
        findsOneWidget,
      );
    }

    expect(find.byKey(const Key('designPurchaseRow-p1')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseRow-p2')), findsOneWidget);

    final editableFields = <TextField>[
      for (final keyName in const [
        'Code',
        'Name',
        'Warehouse',
        'Quantity',
        'Container',
        'PurchasePrice',
        'Discount',
        'SalePrice',
      ])
        tester.widget<TextField>(
          find.byKey(Key('designPurchase$keyName-p1')),
        ),
    ];

    for (final field in editableFields) {
      expect(field.expands, isFalse);
      expect(field.maxLines, 1);
      expect(field.textAlignVertical, isNull);
      expect(field.cursorColor, Colors.black);
      expect(field.decoration?.isCollapsed, isTrue);
      expect(
        field.decoration?.contentPadding,
        const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      );
      expect(field.decoration?.filled, isFalse);
      for (final border in [
        field.decoration?.border,
        field.decoration?.enabledBorder,
        field.decoration?.focusedBorder,
        field.decoration?.disabledBorder,
        field.decoration?.errorBorder,
        field.decoration?.focusedErrorBorder,
      ]) {
        expect(border, InputBorder.none);
      }
    }

    for (final field in editableFields.take(3)) {
      expect(field.textAlign, TextAlign.right);
      expect(field.textDirection, TextDirection.rtl);
      expect(field.style?.fontSize, 18);
    }
    for (final field in editableFields.skip(3)) {
      expect(field.textAlign, TextAlign.center);
      expect(field.textDirection, TextDirection.ltr);
      expect(field.style?.fontSize, 18);
    }
    for (final field in [
      editableFields[3],
      editableFields[4],
    ]) {
      expect(
        field.inputFormatters!.single,
        isA<AppIntegerInputFormatter>(),
      );
    }

    expect(
      tester
          .getSize(find.byKey(const Key('designPurchaseIndexCell-p1'))),
      const Size(44, 44),
    );
    for (final keyName in const [
      'Code',
      'Name',
      'Warehouse',
      'Quantity',
      'Container',
      'PurchasePrice',
      'Discount',
      'SalePrice',
    ]) {
      final cell = find.byKey(
        Key('designPurchase${keyName}Cell-p1'),
      );
      final field = find.byKey(
        Key('designPurchase$keyName-p1'),
      );
      expect(tester.getSize(cell).height, 56);
      expect(
        tester.getCenter(field).dy,
        closeTo(tester.getCenter(cell).dy, 0.01),
      );
    }
    for (final keyName in const [
      'PriceAfterDiscount',
      'Total',
      'Cost',
      'TotalCost',
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

    expect(
      tester
          .widget<Text>(
            find.byKey(
              const Key('designPurchasePriceAfterDiscount-p1'),
            ),
          )
          .data,
      '2,450',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('designPurchaseTotal-p1')),
          )
          .data,
      '245,000',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('designPurchaseCost-p1')),
          )
          .data,
      '2,450',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('designPurchaseTotalCost-p1')),
          )
          .data,
      '245,000',
    );

    for (final update in const {
      'Quantity': '2',
      'PurchasePrice': '100',
      'Discount': '10',
    }.entries) {
      final field = tester.widget<TextField>(
        find.byKey(Key('designPurchase${update.key}-p1')),
      );
      field.controller!.text = update.value;
      field.onChanged?.call(update.value);
    }
    await tester.pump();
    expect(
      tester
          .widget<Text>(
            find.byKey(
              const Key('designPurchasePriceAfterDiscount-p1'),
            ),
          )
          .data,
      '95',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('designPurchaseTotal-p1')),
          )
          .data,
      '190',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('designPurchaseCost-p1')),
          )
          .data,
      '95',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('designPurchaseTotalCost-p1')),
          )
          .data,
      '190',
    );

    final deleteFinder =
        find.byKey(const Key('designPurchaseDelete-p1'));
    final deleteButton =
        tester.widget<AppTableActionButton>(deleteFinder);
    expect(deleteButton.tooltip, 'حذف السطر');
    expect(deleteButton.variant, AppButtonVariant.danger);
    expect(deleteButton.size, 44);
    expect(deleteButton.borderRadius, 13);
    expect(deleteButton.backgroundColor, isNull);
    expect(deleteButton.foregroundColor, isNull);
    expect(tester.getSize(deleteFinder), const Size(44, 44));
    expect(
      tester
          .widget<Tooltip>(
            find.byKey(
              const Key('designPurchaseDeleteTooltip-p1'),
            ),
          )
          .message,
      'حذف السطر',
    );
    expect(
      find.ancestor(
        of: find.byKey(
          const Key('designPurchaseDeleteTooltip-p1'),
        ),
        matching: find.byType(AppTooltip),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(
            find.descendant(
              of: deleteFinder,
              matching: find.byType(AppButton),
            ),
          )
          .variant,
      AppButtonVariant.danger,
    );

    final codeCellRect = tester.getRect(
      find.byKey(const Key('designPurchaseCodeCell-p1')),
    );
    await tester.tapAt(
      Offset(codeCellRect.center.dx, codeCellRect.top + 3),
    );
    await tester.pump();
    expect(editableFields.first.focusNode?.hasFocus, isTrue);

    await tester.enterText(
      find.byKey(const Key('designPurchaseCode-p1')),
      'NEW-001',
    );
    await tester.pump();
    expect(editableFields.first.controller?.text, 'NEW-001');

    final salePrice = find.byKey(
      const Key('designPurchaseSalePrice-p1'),
    );
    tester.widget<TextField>(salePrice).focusNode!.requestFocus();
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('designPurchaseRow-p3')), findsOneWidget);
    expect(find.byKey(const Key('designPurchaseDelete-p3')), findsOneWidget);
    for (final keyName in const [
      'Quantity',
      'Container',
      'PurchasePrice',
      'Discount',
      'SalePrice',
    ]) {
      expect(
        tester
            .widget<TextField>(
              find.byKey(Key('designPurchase$keyName-p3')),
            )
            .controller!
            .text,
        '0',
      );
    }

    tester
        .widget<AppTableActionButton>(
          find.byKey(const Key('designPurchaseDelete-p2')),
        )
        .onPressed
        ?.call();
    await tester.pump();

    expect(find.byKey(const Key('designPurchaseRow-p2')), findsNothing);

    tester
        .widget<AppTableActionButton>(
          find.byKey(const Key('designPurchaseDelete-p3')),
        )
        .onPressed
        ?.call();
    await tester.pump();

    expect(find.byKey(const Key('designPurchaseRow-p3')), findsNothing);
    expect(
      tester
          .widget<AppTableActionButton>(
            find.byKey(const Key('designPurchaseDelete-p1')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('moves through purchase fields with Enter and adds a row',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final purchase = find.byKey(const Key('designPurchaseItemsTable'));
    await reveal(tester, purchase);

    final fields = [
      for (final keyName in const [
        'Code',
        'Name',
        'Warehouse',
        'Quantity',
        'Container',
        'PurchasePrice',
        'Discount',
        'SalePrice',
      ])
        find.byKey(Key('designPurchase$keyName-p1')),
    ];

    await tester.tap(fields.first);
    await tester.pump();
    expect(
      tester.widget<TextField>(fields.first).focusNode!.hasFocus,
      isTrue,
    );

    for (var index = 1; index < fields.length; index++) {
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        tester.widget<TextField>(fields[index]).focusNode!.hasFocus,
        isTrue,
      );
    }

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final newCode = find.byKey(const Key('designPurchaseCode-p3'));
    expect(find.byKey(const Key('designPurchaseRow-p3')), findsOneWidget);
    expect(tester.widget<TextField>(newCode).focusNode!.hasFocus, isTrue);
    expect(
      tester.widget<TextField>(newCode).decoration!.focusedBorder,
      InputBorder.none,
    );
    final focusedCellDecoration = tester
        .widget<DecoratedBox>(
          find
              .descendant(
                of: find.byKey(
                  const Key('designPurchaseCodeCell-p3'),
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

  testWidgets('moves through purchase fields with Tab without adding a row',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final purchase = find.byKey(const Key('designPurchaseItemsTable'));
    await reveal(tester, purchase);

    final code = find.byKey(const Key('designPurchaseCode-p1'));
    final name = find.byKey(const Key('designPurchaseName-p1'));
    final salePrice = find.byKey(
      const Key('designPurchaseSalePrice-p1'),
    );
    final nextCode = find.byKey(const Key('designPurchaseCode-p2'));

    tester.widget<TextField>(code).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.widget<TextField>(name).focusNode!.hasFocus, isTrue);

    tester.widget<TextField>(salePrice).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.widget<TextField>(nextCode).focusNode!.hasFocus, isTrue);
    expect(find.byKey(const Key('designPurchaseRow-p3')), findsNothing);
  });
}
