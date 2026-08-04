import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../presentation/report_definition.dart';

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
  ReportMetricDefinition(label: 'القبض - دينار'),
  ReportMetricDefinition(label: 'الصرف - دينار'),
  ReportMetricDefinition(label: 'الصافي - دينار'),
  ReportMetricDefinition(label: 'الرصيد - دينار'),
  ReportMetricDefinition(label: 'القبض - دولار'),
  ReportMetricDefinition(label: 'الصرف - دولار'),
  ReportMetricDefinition(label: 'الصافي - دولار'),
  ReportMetricDefinition(label: 'الرصيد - دولار'),
  ReportMetricDefinition(label: 'عدد الحركات'),
];

const List<ReportColumnDefinition> _cashboxColumns = [
  ReportColumnDefinition(label: 'ت', numeric: true, flex: 0.5),
  ReportColumnDefinition(label: 'رقم السند', numeric: true),
  ReportColumnDefinition(label: 'التاريخ', numeric: true),
  ReportColumnDefinition(label: 'الوقت', numeric: true),
  ReportColumnDefinition(label: 'نوع الحركة'),
  ReportColumnDefinition(label: 'الحساب الرئيسي'),
  ReportColumnDefinition(label: 'الحساب الفرعي', flex: 1.5),
  ReportColumnDefinition(label: 'مبلغ دينار', numeric: true),
  ReportColumnDefinition(label: 'مبلغ دولار', numeric: true),
  ReportColumnDefinition(label: 'سعر الصرف', numeric: true),
  ReportColumnDefinition(label: 'الملاحظات', flex: 1.5),
];

final List<ReportRowDefinition> cashboxDemoRows =
    List<ReportRowDefinition>.unmodifiable([
  ReportRowDefinition(
    id: 'cashbox-1',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'transactionType': 'in',
      'mainAccount': 'parties',
      'subAccount': 'nakheel',
      'currency': 'IQD',
    },
    cells: const [
      '1',
      '1',
      '2026/07/27',
      '08:30 ص',
      'قبض',
      'الأطراف',
      '1 - شركة النخيل',
      '750,000',
      '0',
      '1,310',
      'دفعة على الحساب',
    ],
  ),
  ReportRowDefinition(
    id: 'cashbox-2',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'transactionType': 'out',
      'mainAccount': 'expenses',
      'subAccount': 'transport',
      'currency': 'IQD',
    },
    cells: const [
      '2',
      '2',
      '2026/07/27',
      '09:10 ص',
      'صرف',
      'المصاريف',
      'نقل',
      '125,000',
      '0',
      '1,310',
      'نقل مواد',
    ],
  ),
  ReportRowDefinition(
    id: 'cashbox-3',
    date: DateTime(2026, 7, 27),
    filterValues: const {
      'transactionType': 'out',
      'mainAccount': 'parties',
      'subAccount': 'rafidain',
      'currency': 'USD',
    },
    cells: const [
      '3',
      '3',
      '2026/07/27',
      '10:05 ص',
      'صرف',
      'الأطراف',
      '3 - مجهز الرافدين',
      '0',
      '400.00',
      '1,310',
      'تسديد جزء',
    ],
  ),
  ReportRowDefinition(
    id: 'cashbox-4',
    date: DateTime(2026, 7, 26),
    filterValues: const {
      'transactionType': 'in',
      'mainAccount': 'otherIncome',
      'subAccount': 'services',
      'currency': 'IQD',
    },
    cells: const [
      '4',
      '4',
      '2026/07/26',
      '11:40 ص',
      'قبض',
      'إيرادات أخرى',
      'خدمات',
      '300,000',
      '0',
      '1,310',
      '-',
    ],
  ),
  ReportRowDefinition(
    id: 'cashbox-5',
    date: DateTime(2026, 7, 25),
    filterValues: const {
      'transactionType': 'out',
      'mainAccount': 'expenses',
      'subAccount': 'maintenance',
      'currency': 'IQD',
    },
    cells: const [
      '5',
      '5',
      '2026/07/25',
      '01:15 م',
      'صرف',
      'المصاريف',
      'صيانة',
      '85,000',
      '0',
      '1,310',
      'صيانة أجهزة المكتب',
    ],
  ),
  ReportRowDefinition(
    id: 'cashbox-6',
    date: DateTime(2026, 7, 24),
    filterValues: const {
      'transactionType': 'in',
      'mainAccount': 'parties',
      'subAccount': 'ahmed',
      'currency': 'IQD',
    },
    cells: const [
      '6',
      '6',
      '2026/07/24',
      '03:20 م',
      'قبض',
      'الأطراف',
      '2 - أحمد كريم',
      '475,000',
      '0',
      '1,310',
      'تسديد كامل الرصيد',
    ],
  ),
]);
