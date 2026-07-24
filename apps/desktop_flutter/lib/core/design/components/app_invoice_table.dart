import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_table.dart';

enum AppInvoiceTableType { purchase, sale }

class AppInvoiceItemsTable extends StatelessWidget {
  const AppInvoiceItemsTable.purchase({
    required this.rows,
    super.key,
    this.tableKey,
    this.height = 300,
    this.isLoading = false,
  }) : type = AppInvoiceTableType.purchase;

  const AppInvoiceItemsTable.sale({
    required this.rows,
    super.key,
    this.tableKey,
    this.height = 300,
    this.isLoading = false,
  }) : type = AppInvoiceTableType.sale;

  final AppInvoiceTableType type;
  final List<AppTableRow> rows;
  final Key? tableKey;
  final double height;
  final bool isLoading;

  static const purchaseColumns = <AppTableColumn>[
    AppTableColumn(label: 'ت', numeric: true, flex: 0.55),
    AppTableColumn(label: 'رمز المادة', flex: 1.25),
    AppTableColumn(label: 'اسم المادة', flex: 1.9),
    AppTableColumn(label: 'المخزن', flex: 1.3),
    AppTableColumn(label: 'الكمية', numeric: true),
    AppTableColumn(label: 'الحاوية', numeric: true),
    AppTableColumn(label: 'سعر الشراء', numeric: true, flex: 1.2),
    AppTableColumn(label: 'الخصم', numeric: true),
    AppTableColumn(label: 'السعر بعد الخصم', numeric: true, flex: 1.45),
    AppTableColumn(label: 'الإجمالي', numeric: true, flex: 1.15),
    AppTableColumn(label: 'الكلفة', numeric: true),
    AppTableColumn(label: 'إجمالي الكلفة', numeric: true, flex: 1.3),
    AppTableColumn(label: 'سعر البيع', numeric: true, flex: 1.15),
    AppTableColumn(label: 'الإجراء', flex: 0.8),
  ];

  static const saleColumns = <AppTableColumn>[
    AppTableColumn(label: 'ت', numeric: true, flex: 0.55),
    AppTableColumn(label: 'رمز المادة', flex: 1.25),
    AppTableColumn(label: 'اسم المادة', flex: 1.9),
    AppTableColumn(label: 'المخزن', flex: 1.3),
    AppTableColumn(label: 'الكمية', numeric: true),
    AppTableColumn(label: 'سعر البيع', numeric: true, flex: 1.2),
    AppTableColumn(label: 'الخصم', numeric: true),
    AppTableColumn(label: 'السعر بعد الخصم', numeric: true, flex: 1.45),
    AppTableColumn(label: 'الإجمالي', numeric: true, flex: 1.15),
    AppTableColumn(label: 'الإجراء', flex: 0.8),
  ];

  @override
  Widget build(BuildContext context) {
    final isPurchase = type == AppInvoiceTableType.purchase;
    return AppDataTable(
      key: tableKey,
      columns: isPurchase ? purchaseColumns : saleColumns,
      rows: rows,
      height: height,
      headerHeight: 52,
      rowHeight: 54,
      minimumColumnWidth: 112,
      isLoading: isLoading,
      accentColor: isPurchase
          ? AppModuleColors.purchases
          : AppModuleColors.sales,
    );
  }
}
