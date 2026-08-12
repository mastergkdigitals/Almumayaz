import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

final ReportDefinition salesInvoicesReportDefinition = ReportDefinition(
  id: 'salesInvoices',
  title: 'تقرير قوائم المبيعات',
  icon: Icons.point_of_sale_rounded,
  palette: AppModulePalettes.sales,
  variants: [
    ReportVariantDefinition(
      id: 'main',
      label: 'قوائم المبيعات',
      icon: Icons.receipt_long_rounded,
      filters: _salesFilters,
      metrics: _salesMetrics,
      columns: _salesColumns,
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

const List<ReportFilterDefinition> _salesFilters = [
  ReportFilterDefinition.dateRange(id: 'period', label: 'الفترة'),
  ReportFilterDefinition.dropdown(
    id: 'warehouse',
    label: 'المخزن',
    icon: Icons.warehouse_rounded,
    options: _warehouseOptions,
  ),
  ReportFilterDefinition.dropdown(
    id: 'customer',
    label: 'الزبون',
    icon: Icons.person_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('dijla', 'أسواق دجلة'),
      ReportFilterOption('ahmed', 'أحمد كريم'),
      ReportFilterOption('nakheel', 'شركة النخيل للتجارة'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'saleType',
    label: 'نوع البيع',
    icon: Icons.point_of_sale_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('cash', 'نقدي'),
      ReportFilterOption('credit', 'آجل'),
      ReportFilterOption('installments', 'أقساط'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'currency',
    label: 'العملة',
    icon: Icons.currency_exchange_rounded,
    options: _currencyOptions,
  ),
];

const List<ReportMetricDefinition> _salesMetrics = [
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
    label: 'المقبوض - دينار',
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
    label: 'المقبوض - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
  ReportMetricDefinition(
    label: 'المتبقي - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
];

const List<ReportColumnDefinition> _salesColumns = [
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
  ReportColumnDefinition(label: 'الزبون', flex: 1.4),
  ReportColumnDefinition(label: 'المخزن'),
  ReportColumnDefinition(label: 'نوع البيع'),
  ReportColumnDefinition(label: 'العملة'),
  ReportColumnDefinition(
    label: 'الإجمالي',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
  ),
  ReportColumnDefinition(
    label: 'المقبوض',
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
