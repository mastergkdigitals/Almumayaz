import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../presentation/report_definition.dart';

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
  ReportMetricDefinition(label: 'عدد القوائم - دينار'),
  ReportMetricDefinition(label: 'الإجمالي - دينار'),
  ReportMetricDefinition(label: 'المدفوع - دينار'),
  ReportMetricDefinition(label: 'المتبقي - دينار'),
  ReportMetricDefinition(label: 'عدد القوائم - دولار'),
  ReportMetricDefinition(label: 'الإجمالي - دولار'),
  ReportMetricDefinition(label: 'المدفوع - دولار'),
  ReportMetricDefinition(label: 'المتبقي - دولار'),
];

const List<ReportColumnDefinition> _purchaseColumns = [
  ReportColumnDefinition(label: 'ت', numeric: true, flex: 0.5),
  ReportColumnDefinition(label: 'رقم القائمة', numeric: true),
  ReportColumnDefinition(label: 'التاريخ', numeric: true),
  ReportColumnDefinition(label: 'المجهز', flex: 1.5),
  ReportColumnDefinition(label: 'المخزن'),
  ReportColumnDefinition(label: 'نوع الشراء'),
  ReportColumnDefinition(label: 'نوع الدفع'),
  ReportColumnDefinition(label: 'العملة'),
  ReportColumnDefinition(label: 'الإجمالي', numeric: true),
  ReportColumnDefinition(label: 'المدفوع', numeric: true),
  ReportColumnDefinition(label: 'المتبقي', numeric: true),
  ReportColumnDefinition(label: 'عدد المواد', numeric: true),
];

final List<ReportRowDefinition> purchaseInvoiceDemoRows =
    List<ReportRowDefinition>.unmodifiable([
  ReportRowDefinition(
    id: 'purchases-103',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'warehouse': 'main',
      'supplier': 'karrada',
      'purchaseType': 'return',
      'paymentType': 'cash',
      'currency': 'IQD',
    },
    cells: const [
      '1',
      '103',
      '2026/07/27',
      'مجهز الكرادة',
      'الرئيسي',
      'إرجاع',
      'نقدي',
      'دينار',
      '90,000',
      '90,000',
      '0',
      '1',
    ],
  ),
  ReportRowDefinition(
    id: 'purchases-102',
    date: DateTime(2026, 7, 26),
    filterValues: const {
      'warehouse': 'mansour',
      'supplier': 'global',
      'purchaseType': 'import',
      'paymentType': 'credit',
      'currency': 'USD',
    },
    cells: const [
      '2',
      '102',
      '2026/07/26',
      'شركة التجارة العالمية',
      'المنصور',
      'إستيراد',
      'آجل',
      'دولار',
      '1,500.00',
      '500.00',
      '1,000.00',
      '2',
    ],
  ),
  ReportRowDefinition(
    id: 'purchases-101',
    date: DateTime(2026, 7, 25),
    filterValues: const {
      'warehouse': 'rasafa',
      'supplier': 'rafidain',
      'purchaseType': 'local',
      'paymentType': 'credit',
      'currency': 'IQD',
    },
    cells: const [
      '3',
      '101',
      '2026/07/25',
      'شركة الرافدين للتجهيز',
      'الرصافة',
      'محلي',
      'آجل',
      'دينار',
      '150,000',
      '0',
      '150,000',
      '2',
    ],
  ),
]);
