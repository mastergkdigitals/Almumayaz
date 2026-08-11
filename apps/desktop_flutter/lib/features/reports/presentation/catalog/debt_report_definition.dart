import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

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
