import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('shows the shared sales table reference', (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('قالب جداول التطبيق'), findsOneWidget);
    expect(find.text('جدول المبيعات'), findsOneWidget);

    final tableReference =
        find.byKey(const Key('designSalesInvoiceTable'));
    await reveal(tester, tableReference);

    expect(tableReference, findsOneWidget);
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

    const fieldKeys = [
      'appSalesInvoiceTemplateCodeField-r1',
      'appSalesInvoiceTemplateNameField-r1',
      'appSalesInvoiceTemplateWarehouseDropdown-r1',
      'appSalesInvoiceTemplateQuantityField-r1',
      'appSalesInvoiceTemplateSalePriceField-r1',
      'appSalesInvoiceTemplateDiscountField-r1',
      'appSalesInvoiceTemplatePriceAfterDiscountField-r1',
      'appSalesInvoiceTemplateTotalField-r1',
    ];
    for (final key in fieldKeys) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    final table = tester.widget<Container>(
      find.byKey(const Key('appSalesInvoiceTableTemplate')),
    );
    final decoration = table.decoration! as BoxDecoration;
    final foreground = table.foregroundDecoration! as BoxDecoration;
    expect(table.clipBehavior, Clip.antiAlias);
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
    expect(dropdownRect.height, closeTo(codeRect.height, 0.1));
    expect(dropdownRect.top, closeTo(codeRect.top, 0.1));
    expect(dropdownRect.bottom, closeTo(codeRect.bottom, 0.1));

    final addButton =
        find.byKey(const Key('appSalesInvoiceTemplateAddButton'));
    await reveal(tester, addButton);
    await tester.tap(addButton);
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
    expect(addButton, findsOneWidget);
  });
}
