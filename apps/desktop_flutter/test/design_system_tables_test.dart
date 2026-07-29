import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  test('identifies complete and fully empty invoice rows', () {
    expect(const AppSalesInvoiceTableRowData().isEmpty, isTrue);
    expect(
      const AppSalesInvoiceTableRowData(
        code: 'S-001',
        name: 'مادة تجريبية',
        quantity: '1',
      ).hasRequiredValues,
      isTrue,
    );
    expect(const AppPurchaseInvoiceTableRowData().isEmpty, isTrue);
    expect(
      const AppPurchaseInvoiceTableRowData(
        code: 'P-001',
        name: 'مادة تجريبية',
        quantity: '1',
      ).hasRequiredValues,
      isTrue,
    );
  });

  testWidgets('keeps the list table header fixed while rows scroll',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('جداول التطبيق'), findsOneWidget);
    expect(find.text('جداول القوائم والسجلات'), findsOneWidget);

    final table = find.byKey(const Key('designMaterialsTable'));
    await reveal(tester, table);
    final tableWidget = tester.widget<AppDataTable>(table);
    expect(tableWidget.accentColor, AppModuleColors.parties);

    final tableSurface = tester
        .widgetList<Container>(
          find.descendant(
            of: table,
            matching: find.byType(Container),
          ),
        )
        .firstWhere(
          (container) =>
              container.foregroundDecoration is BoxDecoration &&
              (container.foregroundDecoration! as BoxDecoration)
                  .border is Border,
        );
    final tableBorder =
        (tableSurface.foregroundDecoration! as BoxDecoration).border!
            as Border;
    expect(
      tableBorder.top.color,
      Color.lerp(
        AppModuleColors.parties,
        AppColors.surface,
        0.62,
      ),
    );
    expect(tableBorder.top.width, 1.4);

    final materialCodeHeader = find.descendant(
      of: table,
      matching: find.text('رمز المادة'),
    );
    expect(materialCodeHeader, findsOneWidget);
    expect(
      find.descendant(of: table, matching: find.text('P-001')),
      findsOneWidget,
    );
    expect(find.byTooltip('كشف'), findsWidgets);

    final headerY = tester.getTopLeft(materialCodeHeader).dy;
    final rows = find.descendant(of: table, matching: find.byType(ListView));
    expect(rows, findsOneWidget);

    await tester.drag(rows, const Offset(0, -500));
    await tester.pump();

    expect(find.text('P-012'), findsOneWidget);
    expect(
      tester.getTopLeft(materialCodeHeader).dy,
      closeTo(headerY, 0.1),
    );
  });

  testWidgets('shows sales and purchase tables on one shared foundation',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('جداول إدخال الفواتير'), findsOneWidget);
    expect(find.text('جدول المبيعات'), findsOneWidget);
    expect(find.text('جدول المشتريات'), findsOneWidget);

    final salesReference =
        find.byKey(const Key('designSalesInvoiceTable'));
    await reveal(tester, salesReference);

    expect(
      find.byKey(const Key('appSalesInvoiceTableTemplate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableHeader')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableRow-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableSummary')),
      findsOneWidget,
    );

    final salesFoundation = tester.widget<AppInvoiceFieldTable>(
      find.descendant(
        of: salesReference,
        matching: find.byType(AppInvoiceFieldTable),
      ),
    );
    expect(salesFoundation.accentColor, AppModulePalettes.sales.middle);

    const salesFieldKeys = [
      'appSalesInvoiceTemplateCodeField-r1',
      'appSalesInvoiceTemplateNameField-r1',
      'appSalesInvoiceTemplateWarehouseDropdown-r1',
      'appSalesInvoiceTemplateQuantityField-r1',
      'appSalesInvoiceTemplateSalePriceField-r1',
      'appSalesInvoiceTemplateDiscountField-r1',
      'appSalesInvoiceTemplatePriceAfterDiscountField-r1',
      'appSalesInvoiceTemplateTotalField-r1',
    ];
    for (final key in salesFieldKeys) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    final salesTable = tester.widget<Container>(
      find.byKey(const Key('appSalesInvoiceTableTemplate')),
    );
    final decoration = salesTable.decoration! as BoxDecoration;
    final foreground = salesTable.foregroundDecoration! as BoxDecoration;
    expect(salesTable.clipBehavior, Clip.antiAlias);
    expect(decoration.border, isNull);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(AppRadii.lg),
    );
    expect(foreground.border, isA<Border>());
    expect(
      foreground.borderRadius,
      BorderRadius.circular(AppRadii.lg),
    );

    final warehouseDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(
          const Key(
            'appSalesInvoiceTemplateWarehouseDropdown-r1',
          ),
        ),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(warehouseDropdown.useIntrinsicHeight, isTrue);
    expect(
      warehouseDropdown.minimumHeight,
      AppControlHeights.invoiceField,
    );
    expect(warehouseDropdown.showLabel, isFalse);
    expect(warehouseDropdown.borderRadius, AppRadii.sm);

    final codeFieldOutline = find.descendant(
      of: find.byKey(
        const Key('appSalesInvoiceTemplateCodeField-r1'),
      ),
      matching: find.byType(InputDecorator),
    );
    final warehouseDropdownOutline = find.descendant(
      of: find.byKey(
        const Key(
          'appSalesInvoiceTemplateWarehouseDropdown-r1',
        ),
      ),
      matching: find.byType(InputDecorator),
    );
    final codeRect = tester.getRect(codeFieldOutline);
    final dropdownRect = tester.getRect(warehouseDropdownOutline);
    expect(codeRect.height, AppControlHeights.invoiceField);
    expect(dropdownRect.height, closeTo(codeRect.height, 0.1));
    expect(dropdownRect.top, closeTo(codeRect.top, 0.1));
    expect(dropdownRect.bottom, closeTo(codeRect.bottom, 0.1));

    final salesAddButton =
        find.byKey(const Key('appSalesInvoiceTemplateAddButton'));
    await reveal(tester, salesAddButton);
    expect(
      tester.widget<AppTableActionButton>(salesAddButton).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(
        const Key('appSalesInvoiceTemplateCodeField-r1'),
      ),
      'S-001',
    );
    await tester.enterText(
      find.byKey(
        const Key('appSalesInvoiceTemplateNameField-r1'),
      ),
      'مادة تجريبية',
    );
    await tester.enterText(
      find.byKey(
        const Key('appSalesInvoiceTemplateQuantityField-r1'),
      ),
      '1',
    );
    await tester.pump();
    expect(
      tester.widget<AppTableActionButton>(salesAddButton).onPressed,
      isNotNull,
    );

    await tester.tap(salesAddButton);
    await tester.pump();

    expect(
      find.byKey(const Key('appSalesInvoiceTableRow-r2')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('appSalesInvoiceTemplateDeleteButton-r1'),
      ),
      findsOneWidget,
    );

    final purchaseReference =
        find.byKey(const Key('designPurchaseInvoiceTable'));
    await reveal(tester, purchaseReference);

    expect(
      find.byKey(const Key('appPurchaseInvoiceTableTemplate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appPurchaseInvoiceTableHeader')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appPurchaseInvoiceTableRow-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appPurchaseInvoiceTableSummary')),
      findsOneWidget,
    );

    final purchaseFoundation = tester.widget<AppInvoiceFieldTable>(
      find.descendant(
        of: purchaseReference,
        matching: find.byType(AppInvoiceFieldTable),
      ),
    );
    expect(
      purchaseFoundation.accentColor,
      AppModulePalettes.purchases.middle,
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
          of: purchaseReference,
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    const purchaseFieldKeys = [
      'appPurchaseInvoiceTemplateCodeField-r1',
      'appPurchaseInvoiceTemplateNameField-r1',
      'appPurchaseInvoiceTemplateWarehouseDropdown-r1',
      'appPurchaseInvoiceTemplateQuantityField-r1',
      'appPurchaseInvoiceTemplateContainerField-r1',
      'appPurchaseInvoiceTemplatePurchasePriceField-r1',
      'appPurchaseInvoiceTemplateDiscountField-r1',
      'appPurchaseInvoiceTemplatePriceAfterDiscountField-r1',
      'appPurchaseInvoiceTemplateTotalField-r1',
      'appPurchaseInvoiceTemplateCostField-r1',
      'appPurchaseInvoiceTemplateTotalCostField-r1',
      'appPurchaseInvoiceTemplateSalePriceField-r1',
    ];
    for (final key in purchaseFieldKeys) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    final purchaseWarehouseDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(
          const Key(
            'appPurchaseInvoiceTemplateWarehouseDropdown-r1',
          ),
        ),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(
      purchaseWarehouseDropdown.minimumHeight,
      AppControlHeights.invoiceField,
    );

    final purchaseCodeFieldOutline = find.descendant(
      of: find.byKey(
        const Key('appPurchaseInvoiceTemplateCodeField-r1'),
      ),
      matching: find.byType(InputDecorator),
    );
    final purchaseWarehouseDropdownOutline = find.descendant(
      of: find.byKey(
        const Key(
          'appPurchaseInvoiceTemplateWarehouseDropdown-r1',
        ),
      ),
      matching: find.byType(InputDecorator),
    );
    expect(
      tester.getRect(purchaseWarehouseDropdownOutline).height,
      closeTo(tester.getRect(purchaseCodeFieldOutline).height, 0.1),
    );

    final purchaseAddButton =
        find.byKey(const Key('appPurchaseInvoiceTemplateAddButton'));
    await reveal(tester, purchaseAddButton);
    expect(
      tester.widget<AppTableActionButton>(purchaseAddButton).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(
        const Key('appPurchaseInvoiceTemplateCodeField-r1'),
      ),
      'P-001',
    );
    await tester.enterText(
      find.byKey(
        const Key('appPurchaseInvoiceTemplateNameField-r1'),
      ),
      'مادة تجريبية',
    );
    await tester.enterText(
      find.byKey(
        const Key('appPurchaseInvoiceTemplateQuantityField-r1'),
      ),
      '1',
    );
    await tester.pump();
    expect(
      tester.widget<AppTableActionButton>(purchaseAddButton).onPressed,
      isNotNull,
    );

    await tester.tap(purchaseAddButton);
    await tester.pump();

    expect(
      find.byKey(const Key('appPurchaseInvoiceTableRow-r2')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('appPurchaseInvoiceTemplateDeleteButton-r1'),
      ),
      findsOneWidget,
    );
  });
}
