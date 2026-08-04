import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../presentation/report_definition.dart';

final ReportDefinition debtsInstallmentsReportDefinition = ReportDefinition(
  id: 'debtsInstallments',
  title: 'تقرير الديون والأقساط المستحقة',
  icon: Icons.event_note_rounded,
  palette: AppModulePalettes.reports,
  variants: [
    ReportVariantDefinition(
      id: 'main',
      label: 'الديون والأقساط',
      icon: Icons.request_quote_rounded,
      filters: _debtFilters,
      metrics: _debtMetrics,
      columns: _debtColumns,
    ),
  ],
);

const List<ReportFilterOption> _currencyOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('IQD', 'دينار'),
  ReportFilterOption('USD', 'دولار'),
];

const List<ReportFilterDefinition> _debtFilters = [
  ReportFilterDefinition.dateRange(id: 'period', label: 'فترة الاستحقاق'),
  ReportFilterDefinition.dropdown(
    id: 'customer',
    label: 'الزبون',
    icon: Icons.person_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('nakheel', 'شركة النخيل للتجارة'),
      ReportFilterOption('ahmed', 'أحمد كريم'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'recordType',
    label: 'نوع السجل',
    icon: Icons.description_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('debt', 'دين'),
      ReportFilterOption('installment', 'قسط'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'currency',
    label: 'العملة',
    icon: Icons.currency_exchange_rounded,
    options: _currencyOptions,
  ),
];

const List<ReportMetricDefinition> _debtMetrics = [
  ReportMetricDefinition(label: 'المتبقي - دينار'),
  ReportMetricDefinition(label: 'المتأخر - دينار'),
  ReportMetricDefinition(label: 'المستحق - دينار'),
  ReportMetricDefinition(label: 'المدفوع - دينار'),
  ReportMetricDefinition(label: 'المتبقي - دولار'),
  ReportMetricDefinition(label: 'المتأخر - دولار'),
  ReportMetricDefinition(label: 'المستحق - دولار'),
  ReportMetricDefinition(label: 'المدفوع - دولار'),
  ReportMetricDefinition(label: 'عدد المتأخر'),
  ReportMetricDefinition(label: 'عدد المستحق'),
];

const List<ReportColumnDefinition> _debtColumns = [
  ReportColumnDefinition(label: 'ت', numeric: true, flex: 0.5),
  ReportColumnDefinition(label: 'نوع السجل'),
  ReportColumnDefinition(label: 'رقم القائمة', numeric: true),
  ReportColumnDefinition(label: 'رقم القسط', numeric: true),
  ReportColumnDefinition(label: 'الزبون', flex: 1.5),
  ReportColumnDefinition(label: 'تاريخ الاستحقاق', numeric: true),
  ReportColumnDefinition(label: 'العملة'),
  ReportColumnDefinition(label: 'المبلغ الأصلي', numeric: true),
  ReportColumnDefinition(label: 'المدفوع', numeric: true),
  ReportColumnDefinition(label: 'المتبقي', numeric: true),
  ReportColumnDefinition(label: 'الحالة'),
  ReportColumnDefinition(label: 'الملاحظات', flex: 1.4),
];

final List<ReportRowDefinition> debtDemoRows =
    List<ReportRowDefinition>.unmodifiable([
  ReportRowDefinition(
    id: 'debt-101',
    date: DateTime(2026, 7, 28),
    filterValues: const {
      'customer': 'nakheel',
      'recordType': 'debt',
      'currency': 'IQD',
    },
    cells: const [
      '1',
      'دين',
      '101',
      '-',
      'شركة النخيل للتجارة',
      '2026/07/28',
      'دينار',
      '177,000',
      '0',
      '177,000',
      'متأخر',
      'بيع آجل',
    ],
  ),
  ReportRowDefinition(
    id: 'installment-102-1',
    date: DateTime(2026, 7, 26),
    filterValues: const {
      'customer': 'ahmed',
      'recordType': 'installment',
      'currency': 'USD',
    },
    cells: const [
      '2',
      'قسط',
      '102',
      '1',
      'أحمد كريم',
      '2026/07/26',
      'دولار',
      '250.00',
      '250.00',
      '0',
      'مدفوع',
      'القسط الأول',
    ],
  ),
  ReportRowDefinition(
    id: 'installment-102-2',
    date: DateTime(2026, 8, 10),
    filterValues: const {
      'customer': 'ahmed',
      'recordType': 'installment',
      'currency': 'USD',
    },
    cells: const [
      '3',
      'قسط',
      '102',
      '2',
      'أحمد كريم',
      '2026/08/10',
      'دولار',
      '500.00',
      '0',
      '500.00',
      'مستحق',
      '-',
    ],
  ),
  ReportRowDefinition(
    id: 'installment-102-3',
    date: DateTime(2026, 9, 10),
    filterValues: const {
      'customer': 'ahmed',
      'recordType': 'installment',
      'currency': 'USD',
    },
    cells: const [
      '4',
      'قسط',
      '102',
      '3',
      'أحمد كريم',
      '2026/09/10',
      'دولار',
      '500.00',
      '0',
      '500.00',
      'مستحق',
      '-',
    ],
  ),
]);
