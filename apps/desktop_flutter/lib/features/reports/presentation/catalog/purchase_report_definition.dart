import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

final ReportDefinition purchaseInvoicesReportDefinition = ReportDefinition(
  id: 'purchaseInvoices',
  title: 'تقرير قوائم المشتريات',
  icon: Icons.shopping_cart_rounded,
  palette: AppModulePalettes.purchases,
  variants: [
    ReportVariantDefinition(
      id: 'main',
      label: 'قوائم المشتريات',
      icon: Icons.receipt_long_rounded,
      filters: _purchaseFilters,
      metrics: _purchaseMetrics,
      columns: _purchaseColumns,
    ),
  ],
);

const List<ReportFilterOption> _currencyOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('IQD', 'دينار'),
  ReportFilterOption('USD', 'دولار'),
];

const List<ReportFilterOption> _warehouseOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('main', 'الرئيسي'),
  ReportFilterOption('karrada', 'الكرادة'),
  ReportFilterOption('mansour', 'المنصور'),
  ReportFilterOption('rasafa', 'الرصافة'),
];

const List<ReportFilterDefinition> _purchaseFilters = [
  ReportFilterDefinition.dateRange(id: 'period', label: 'الفترة'),
  ReportFilterDefinition.dropdown(
    id: 'warehouse',
    label: 'المخزن',
    icon: Icons.warehouse_rounded,
    options: _warehouseOptions,
  ),
  ReportFilterDefinition.dropdown(
    id: 'supplier',
    label: 'المجهز',
    icon: Icons.local_shipping_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('karrada', 'مجهز الكرادة'),
      ReportFilterOption('global', 'شركة التجارة العالمية'),
      ReportFilterOption('rafidain', 'شركة الرافدين للتجهيز'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'purchaseType',
    label: 'نوع الشراء',
    icon: Icons.shopping_cart_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('local', 'محلي'),
      ReportFilterOption('import', 'إستيراد'),
      ReportFilterOption('return', 'إرجاع'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'paymentType',
    label: 'نوع الدفع',
    icon: Icons.payments_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('cash', 'نقدي'),
      ReportFilterOption('credit', 'آجل'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'currency',
    label: 'العملة',
    icon: Icons.currency_exchange_rounded,
    options: _currencyOptions,
  ),
];

const List<ReportMetricDefinition> _purchaseMetrics = [
  ReportMetricDefinition(
    label: 'عدد القوائم - دينار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.integer,
  ),
  ReportMetricDefinition(
    label: 'الإجمالي - دينار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 0,
  ),
  ReportMetricDefinition(
    label: 'المدفوع - دينار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 0,
  ),
  ReportMetricDefinition(
    label: 'المتبقي - دينار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 0,
  ),
  ReportMetricDefinition(
    label: 'عدد القوائم - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.integer,
  ),
  ReportMetricDefinition(
    label: 'الإجمالي - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
  ReportMetricDefinition(
    label: 'المدفوع - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
  ReportMetricDefinition(
    label: 'المتبقي - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
];

const List<ReportColumnDefinition> _purchaseColumns = [
  ReportColumnDefinition(
    label: 'ت',
    numeric: true,
    flex: 0.5,
    spreadsheetCellKind: ReportSpreadsheetCellKind.integer,
  ),
  ReportColumnDefinition(
    label: 'رقم القائمة',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.integer,
  ),
  ReportColumnDefinition(
    label: 'التاريخ',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.date,
  ),
  ReportColumnDefinition(label: 'المجهز', flex: 1.5),
  ReportColumnDefinition(label: 'المخزن'),
  ReportColumnDefinition(label: 'نوع الشراء'),
  ReportColumnDefinition(label: 'نوع الدفع'),
  ReportColumnDefinition(label: 'العملة'),
  ReportColumnDefinition(
    label: 'الإجمالي',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
  ),
  ReportColumnDefinition(
    label: 'المدفوع',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
  ),
  ReportColumnDefinition(
    label: 'المتبقي',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
  ),
  ReportColumnDefinition(
    label: 'عدد المواد',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.integer,
  ),
];
