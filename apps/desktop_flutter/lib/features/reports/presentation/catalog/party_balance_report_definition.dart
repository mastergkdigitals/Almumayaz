import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

final ReportDefinition partyBalancesReportDefinition = ReportDefinition(
  id: 'partyBalances',
  title: 'تقرير أرصدة الزبائن والمجهزين',
  icon: Icons.groups_rounded,
  palette: AppModulePalettes.parties,
  variants: [
    ReportVariantDefinition(
      id: 'main',
      label: 'أرصدة الزبائن والمجهزين',
      icon: Icons.account_balance_rounded,
      filters: _partyBalanceFilters,
      metrics: _partyBalanceMetrics,
      columns: _partyBalanceColumns,
    ),
  ],
);

const List<ReportFilterOption> _currencyOptions = [
  ReportFilterOption('all', 'الكل'),
  ReportFilterOption('IQD', 'دينار'),
  ReportFilterOption('USD', 'دولار'),
];

const List<ReportFilterDefinition> _partyBalanceFilters = [
  ReportFilterDefinition.dropdown(
    id: 'partyType',
    label: 'نوع الطرف',
    icon: Icons.groups_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('customer', 'زبون'),
      ReportFilterOption('supplier', 'مجهز'),
      ReportFilterOption('both', 'زبون ومجهز'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'direction',
    label: 'اتجاه الرصيد',
    icon: Icons.compare_arrows_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('receivable', 'لنا'),
      ReportFilterOption('payable', 'علينا'),
      ReportFilterOption('zero', 'صفر'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'currency',
    label: 'العملة',
    icon: Icons.currency_exchange_rounded,
    options: _currencyOptions,
  ),
  ReportFilterDefinition.dropdown(
    id: 'workEntity',
    label: 'جهة العمل',
    icon: Icons.business_center_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('general', 'التجارة العامة'),
      ReportFilterOption('retail', 'تجارة المفرد'),
      ReportFilterOption('supplies', 'تجهيز المواد'),
      ReportFilterOption('wholesale', 'تجارة الجملة'),
      ReportFilterOption('officeDevices', 'الأجهزة المكتبية'),
      ReportFilterOption('services', 'الخدمات'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'branch',
    label: 'الفرع',
    icon: Icons.account_tree_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('baghdad', 'بغداد'),
      ReportFilterOption('mansour', 'المنصور'),
      ReportFilterOption('basra', 'البصرة'),
      ReportFilterOption('najaf', 'النجف'),
      ReportFilterOption('mosul', 'الموصل'),
      ReportFilterOption('kadhimiya', 'الكاظمية'),
      ReportFilterOption('karbala', 'كربلاء'),
    ],
  ),
];

const List<ReportMetricDefinition> _partyBalanceMetrics = [
  ReportMetricDefinition(label: 'عدد الأطراف'),
  ReportMetricDefinition(label: 'بدون رصيد'),
  ReportMetricDefinition(label: 'ذمم لنا - دينار'),
  ReportMetricDefinition(label: 'ذمم لنا - دولار'),
  ReportMetricDefinition(label: 'ذمم علينا - دينار'),
  ReportMetricDefinition(label: 'ذمم علينا - دولار'),
];

const List<ReportColumnDefinition> _partyBalanceColumns = [
  ReportColumnDefinition(label: 'ت', numeric: true, flex: 0.5),
  ReportColumnDefinition(label: 'رقم الطرف', numeric: true),
  ReportColumnDefinition(label: 'اسم الطرف', flex: 1.5),
  ReportColumnDefinition(label: 'نوع الطرف'),
  ReportColumnDefinition(label: 'جهة العمل', flex: 1.3),
  ReportColumnDefinition(label: 'الفرع'),
  ReportColumnDefinition(label: 'الهاتف', numeric: true),
  ReportColumnDefinition(label: 'المدينة'),
  ReportColumnDefinition(label: 'رصيد الدينار', numeric: true),
  ReportColumnDefinition(label: 'اتجاهه'),
  ReportColumnDefinition(label: 'رصيد الدولار', numeric: true),
  ReportColumnDefinition(label: 'اتجاهه'),
];
