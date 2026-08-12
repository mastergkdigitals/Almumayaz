import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

final ReportDefinition cashboxReportDefinition = ReportDefinition(
  id: 'cashbox',
  title: 'تقرير الصندوق',
  icon: Icons.account_balance_wallet_rounded,
  palette: AppModulePalettes.cashbox,
  variants: [
    ReportVariantDefinition(
      id: 'main',
      label: 'حركات الصندوق',
      icon: Icons.payments_rounded,
      filters: _cashboxFilters,
      metrics: _cashboxMetrics,
      columns: _cashboxColumns,
    ),
  ],
);

const List<ReportFilterOption> _currencyOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('IQD', 'دينار'),
  ReportFilterOption('USD', 'دولار'),
];

const List<ReportFilterDefinition> _cashboxFilters = [
  ReportFilterDefinition.dateRange(id: 'period', label: 'الفترة'),
  ReportFilterDefinition.dropdown(
    id: 'transactionType',
    label: 'نوع الحركة',
    icon: Icons.swap_vert_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('in', 'قبض'),
      ReportFilterOption('out', 'صرف'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'mainAccount',
    label: 'الحساب الرئيسي',
    icon: Icons.account_balance_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('parties', 'الأطراف'),
      ReportFilterOption('expenses', 'المصاريف'),
      ReportFilterOption('otherIncome', 'إيرادات أخرى'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'subAccount',
    label: 'الحساب الفرعي',
    icon: Icons.account_tree_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('nakheel', '1 - شركة النخيل'),
      ReportFilterOption('transport', 'نقل'),
      ReportFilterOption('rafidain', '3 - مجهز الرافدين'),
      ReportFilterOption('services', 'خدمات'),
      ReportFilterOption('maintenance', 'صيانة'),
      ReportFilterOption('ahmed', '2 - أحمد كريم'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'currency',
    label: 'العملة',
    icon: Icons.currency_exchange_rounded,
    options: _currencyOptions,
  ),
];

const List<ReportMetricDefinition> _cashboxMetrics = [
  ReportMetricDefinition(
    label: 'القبض - دينار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 0,
  ),
  ReportMetricDefinition(
    label: 'الصرف - دينار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 0,
  ),
  ReportMetricDefinition(
    label: 'الصافي - دينار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 0,
  ),
  ReportMetricDefinition(
    label: 'الرصيد - دينار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 0,
  ),
  ReportMetricDefinition(
    label: 'القبض - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
  ReportMetricDefinition(
    label: 'الصرف - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
  ReportMetricDefinition(
    label: 'الصافي - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
  ReportMetricDefinition(
    label: 'الرصيد - دولار',
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
  ReportMetricDefinition(
    label: 'عدد الحركات',
    spreadsheetCellKind: ReportSpreadsheetCellKind.integer,
  ),
];

const List<ReportColumnDefinition> _cashboxColumns = [
  ReportColumnDefinition(
    label: 'ت',
    numeric: true,
    flex: 0.5,
    spreadsheetCellKind: ReportSpreadsheetCellKind.integer,
  ),
  ReportColumnDefinition(
    label: 'رقم السند',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.integer,
  ),
  ReportColumnDefinition(
    label: 'التاريخ',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.date,
  ),
  ReportColumnDefinition(
    label: 'الوقت',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.time,
  ),
  ReportColumnDefinition(label: 'نوع الحركة'),
  ReportColumnDefinition(label: 'الحساب الرئيسي'),
  ReportColumnDefinition(label: 'الحساب الفرعي', flex: 1.5),
  ReportColumnDefinition(
    label: 'مبلغ دينار',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 0,
  ),
  ReportColumnDefinition(
    label: 'مبلغ دولار',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
    spreadsheetDecimalPlaces: 2,
  ),
  ReportColumnDefinition(
    label: 'سعر الصرف',
    numeric: true,
    spreadsheetCellKind: ReportSpreadsheetCellKind.decimal,
  ),
  ReportColumnDefinition(label: 'الملاحظات', flex: 1.5),
];
