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
  ReportMetricDefinition(label: 'عدد القوائم - دينار'),
  ReportMetricDefinition(label: 'الإجمالي - دينار'),
  ReportMetricDefinition(label: 'المقبوض - دينار'),
  ReportMetricDefinition(label: 'المتبقي - دينار'),
  ReportMetricDefinition(label: 'عدد القوائم - دولار'),
  ReportMetricDefinition(label: 'الإجمالي - دولار'),
  ReportMetricDefinition(label: 'المقبوض - دولار'),
  ReportMetricDefinition(label: 'المتبقي - دولار'),
];

const List<ReportColumnDefinition> _salesColumns = [
  ReportColumnDefinition(label: 'ت', numeric: true, flex: 0.5),
  ReportColumnDefinition(label: 'رقم القائمة', numeric: true),
  ReportColumnDefinition(label: 'التاريخ', numeric: true),
  ReportColumnDefinition(label: 'الزبون', flex: 1.4),
  ReportColumnDefinition(label: 'المخزن'),
  ReportColumnDefinition(label: 'نوع البيع'),
  ReportColumnDefinition(label: 'العملة'),
  ReportColumnDefinition(label: 'الإجمالي', numeric: true),
  ReportColumnDefinition(label: 'المقبوض', numeric: true),
  ReportColumnDefinition(label: 'المتبقي', numeric: true),
  ReportColumnDefinition(label: 'عدد المواد', numeric: true),
];
