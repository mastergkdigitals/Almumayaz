import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sales row deletion preserves the remaining stable line id',
      (tester) async {
    List<AppSalesInvoiceTableRowData> rows = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSalesInvoiceTableTemplate(
            initialRows: const [
              AppSalesInvoiceTableRowData(
                lineId: 'sales-line-one',
                itemId: 'item-001',
                code: 'P-1001',
                name: 'طابعة ليزر',
                quantity: '1',
              ),
              AppSalesInvoiceTableRowData(
                lineId: 'sales-line-two',
                itemId: 'item-002',
                code: 'P-1002',
                name: 'حبر طابعة أسود',
                quantity: '1',
              ),
            ],
            onRowsChanged: (value) => rows = value,
          ),
        ),
      ),
    );

    tester
        .widget<AppTableActionButton>(
          find.byKey(
            const Key('appSalesInvoiceTemplateDeleteButton-r1'),
          ),
        )
        .onPressed!();
    await tester.pump();

    expect(rows.single.lineId, 'sales-line-two');
    expect(rows.single.itemId, 'item-002');
  });

  testWidgets('Purchase row deletion preserves the remaining stable line id',
      (tester) async {
    List<AppPurchaseInvoiceTableRowData> rows = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPurchaseInvoiceTableTemplate(
            initialRows: const [
              AppPurchaseInvoiceTableRowData(
                lineId: 'purchase-line-one',
                itemId: 'item-001',
                code: 'P-1001',
                name: 'طابعة ليزر',
                quantity: '1',
              ),
              AppPurchaseInvoiceTableRowData(
                lineId: 'purchase-line-two',
                itemId: 'item-002',
                code: 'P-1002',
                name: 'حبر طابعة أسود',
                quantity: '1',
              ),
            ],
            onRowsChanged: (value) => rows = value,
          ),
        ),
      ),
    );

    tester
        .widget<AppTableActionButton>(
          find.byKey(
            const Key('appPurchaseInvoiceTemplateDeleteButton-r1'),
          ),
        )
        .onPressed!();
    await tester.pump();

    expect(rows.single.lineId, 'purchase-line-two');
    expect(rows.single.itemId, 'item-002');
  });
}
