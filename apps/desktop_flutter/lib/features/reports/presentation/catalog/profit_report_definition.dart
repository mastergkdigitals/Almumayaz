import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

final ReportDefinition profitsReportDefinition = ReportDefinition(
  id: 'profits',
  title: 'تقرير الأرباح',
  icon: Icons.trending_up_rounded,
  palette: AppModulePalettes.company,
  variants: [
    ReportVariantDefinition(
      id: 'main',
      label: 'الأرباح',
      icon: Icons.query_stats_rounded,
      filters: _profitFilters,
      metrics: _profitMetrics,
      columns: _profitColumns,
      minimumColumnWidth: 145,
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

const List<ReportFilterDefinition> _profitFilters = [
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
    id: 'product',
    label: 'المادة',
    icon: Icons.inventory_2_rounded,
    options: [
      ReportFilterOption('all', 'الكل'),
      ReportFilterOption('notebook', 'دفتر ملاحظات'),
      ReportFilterOption('bluePen', 'قلم أزرق'),
      ReportFilterOption('calculator', 'حاسبة مكتبية'),
      ReportFilterOption('thermalPrinter', 'طابعة حرارية'),
      ReportFilterOption('barcodeScanner', 'ماسح باركود'),
      ReportFilterOption('printingPaper', 'ورق طباعة'),
      ReportFilterOption('printerInk', 'حبر طابعة'),
      ReportFilterOption('stapler', 'دباسة'),
    ],
  ),
  ReportFilterDefinition.dropdown(
    id: 'currency',
    label: 'العملة',
    icon: Icons.currency_exchange_rounded,
    options: _currencyOptions,
  ),
];

const List<ReportMetricDefinition> _profitMetrics = [
  ReportMetricDefinition(label: 'المبيعات المحتسبة - دينار'),
  ReportMetricDefinition(label: 'التكلفة - دينار'),
  ReportMetricDefinition(label: 'الربح - دينار'),
  ReportMetricDefinition(label: 'هامش الربح - دينار'),
  ReportMetricDefinition(label: 'المبيعات المحتسبة - دولار'),
  ReportMetricDefinition(label: 'التكلفة - دولار'),
  ReportMetricDefinition(label: 'الربح - دولار'),
  ReportMetricDefinition(label: 'هامش الربح - دولار'),
];

const List<ReportColumnDefinition> _profitColumns = [
  ReportColumnDefinition(label: 'ت', numeric: true, flex: 0.5),
  ReportColumnDefinition(label: 'رقم القائمة', numeric: true),
  ReportColumnDefinition(label: 'التاريخ', numeric: true),
  ReportColumnDefinition(label: 'الزبون', flex: 1.4),
  ReportColumnDefinition(label: 'المخزن'),
  ReportColumnDefinition(label: 'رمز المادة', numeric: true),
  ReportColumnDefinition(label: 'اسم المادة', flex: 1.4),
  ReportColumnDefinition(label: 'الكمية', numeric: true),
  ReportColumnDefinition(label: 'سعر البيع', numeric: true),
  ReportColumnDefinition(label: 'إجمالي البيع', numeric: true),
  ReportColumnDefinition(label: 'إجمالي التكلفة', numeric: true),
  ReportColumnDefinition(label: 'الربح', numeric: true),
  ReportColumnDefinition(label: 'نسبة الربح', numeric: true),
  ReportColumnDefinition(label: 'حالة التكلفة'),
  ReportColumnDefinition(label: 'طريقة التكلفة'),
  ReportColumnDefinition(label: 'العملة'),
];
