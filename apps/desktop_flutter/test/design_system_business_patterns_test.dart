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

  testWidgets('opens statement options with the shared business controls',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final button = find.byKey(const Key('designStatementDialogButton'));
    await reveal(tester, button);
    await tester.tap(button);
    await tester.pump();

    final statementDialog =
        find.byKey(const Key('appStatementOptionsDialog'));
    expect(statementDialog, findsOneWidget);
    expect(find.byKey(const Key('appStatementParty')), findsOneWidget);
    expect(find.byKey(const Key('appStatementFromDate')), findsOneWidget);
    expect(find.byKey(const Key('appStatementToDate')), findsOneWidget);
    expect(find.byKey(const Key('appStatementCurrency')), findsOneWidget);
    expect(
      find.descendant(
        of: statementDialog,
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appStatementConfirm')),
          )
          .width,
      176,
    );

    await tester.tap(find.byKey(const Key('appStatementCancel')));
    await tester.pump();
  });

  testWidgets('uses one themed shell for management dialogs', (tester) async {
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
    expect(find.text('مواد النقل'), findsOneWidget);

    final transferShell = tester.widget<AppModuleDialog>(transferDialog);
    expect(transferShell.accentColor, AppModuleColors.warehouses);
    expect(
      find.descendant(
        of: transferDialog,
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('designTransferDialogConfirm')),
          )
          .width,
      176,
    );

    await tester.tap(
      find.byKey(const Key('designTransferDialogCancel')),
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
      find.descendant(
        of: cashboxDialog,
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const Key('designCashboxTabsDialogCancel')),
    );
    await tester.pump();
  });

  testWidgets('documents the shared purchase and sales item tables',
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
    expect(
      find.descendant(of: purchase, matching: find.text('إجمالي الكلفة')),
      findsOneWidget,
    );

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
  });
}
